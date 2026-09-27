import 'dart:async';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:clinical_calendar_platform/clinical_calendar_web_identity_platform.dart';
import 'package:clinical_calendar_platform/clinical_calendar_web_platform.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_identity_presentation.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:clinical_calendar_sync/clinical_calendar_sync.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'browser_runtime.dart';
import 'browser_runtime_contracts.dart';
import 'config/app_environment.dart';
import 'sync_build_number.dart';
import 'web_build_version_runtime.dart';
import 'web_device_descriptor.dart';
import 'web_identity_runtime.dart';
import 'web_credential_storage.dart';

export 'sync_build_number.dart';

DeviceDescriptor currentWebDeviceDescriptor() =>
    webDeviceDescriptor(currentBrowserUserAgent());

typedef WebRepositoryBootstrap =
    Future<RepositoryRegistry> Function(
      String studentId,
      IdentifierGenerator identifiers,
      BrowserRuntime browser,
    );

abstract interface class WebConnectivityStatusSource {
  Future<bool> current();

  Stream<bool> get changes;
}

final class ConnectivityPlusWebStatusSource
    implements WebConnectivityStatusSource {
  ConnectivityPlusWebStatusSource([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> current() async =>
      _isConnected(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get changes =>
      _connectivity.onConnectivityChanged.map(_isConnected).distinct();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(buildWebRoot());
}

Widget buildWebRoot({
  BrowserRuntime? browserRuntime,
  SecureStorage? secureStorage,
  IdentifierGenerator? identifiers,
  Clock? clock,
  AppEnvironment? environment,
  PasswordlessIdentityGateway? identityGateway,
  WebRepositoryBootstrap? repositoryBootstrap,
  SynchronizationTransport? synchronizationTransport,
  SynchronizationRetryScheduler? retryScheduler,
  WebConnectivityStatusSource? connectivitySource,
  WebBuildVersionCoordinator? buildVersionCoordinator,
  DeviceDescriptor? currentDevice,
  LocalDeviceCopyController? localCopy,
}) {
  final browser = browserRuntime ?? createBrowserRuntime();
  final storage = secureStorage ?? WebCredentialStorage(browser.credentials);
  final identifierGenerator = identifiers ?? ProcessIdentifierGenerator();
  final applicationClock = clock ?? const SystemClock();
  final configuredEnvironment = environment ?? AppEnvironment.fromCompileTime();

  if (!configuredEnvironment.hasSynchronizationConfiguration) {
    return const _WebStartupFailureApplication();
  }

  final deferredLocalCopy = _DeferredWebLocalCopyController(
    additional: localCopy,
  );
  final identity = PasswordlessIdentityService(
    gateway:
        identityGateway ??
        SupabasePasswordlessIdentityGateway(
          projectUri: configuredEnvironment.synchronizationProjectUri!,
          publishableKey: configuredEnvironment.supabasePublishableKey,
        ),
    secureStorage: storage,
    identifiers: identifierGenerator,
    clock: applicationClock,
    currentDevice:
        currentDevice ??
        DeviceDescriptor(
          name: browser.deviceName,
          platform: DevicePlatform.web,
        ),
    localCopy: deferredLocalCopy,
  );

  return _WebIdentityGate(
    identity: identity,
    secureStorage: storage,
    identifiers: identifierGenerator,
    clock: applicationClock,
    environment: configuredEnvironment,
    browser: browser,
    localCopy: deferredLocalCopy,
    repositoryBootstrap: repositoryBootstrap,
    synchronizationTransport: synchronizationTransport,
    retryScheduler: retryScheduler,
    connectivitySource: connectivitySource,
    buildVersionCoordinator: buildVersionCoordinator,
  );
}

Future<ClinicalCalendarApp> buildWebApplication({
  required IdentitySession session,
  required PasswordlessIdentityService identity,
  required SecureStorage secureStorage,
  required IdentifierGenerator identifiers,
  required Clock clock,
  required AppEnvironment environment,
  required BrowserRuntime browser,
  WebRepositoryBootstrap? repositoryBootstrap,
  SynchronizationTransport? synchronizationTransport,
  SynchronizationRetryScheduler? retryScheduler,
  WebConnectivityStatusSource? connectivitySource,
  WebBuildVersionCoordinator? buildVersionCoordinator,
  void Function(LocalDeviceCopyController controller)?
  onLocalCopyControllerReady,
  Future<void> Function()? onLocalCopyRemoved,
}) async {
  final repositories = await (repositoryBootstrap ?? _openWebRepositories)(
    session.studentId,
    identifiers,
    browser,
  );
  final source = connectivitySource ?? ConnectivityPlusWebStatusSource();
  final initiallyConnected = await _initialConnectivity(source);
  final transport =
      synchronizationTransport ??
      SupabaseRpcSynchronizationTransport(
        projectUri: environment.synchronizationProjectUri!,
        publishableKey: environment.supabasePublishableKey,
        buildNumber: currentSyncBuildNumber,
        accessTokenProvider: identity.currentAccessToken,
        onSuccessfulServerAccess: () async {
          await identity.markSynchronized();
        },
      );
  final synchronization = DurableSynchronizationService(
    repositories: repositories,
    transport: transport,
    retryScheduler: retryScheduler ?? DartSynchronizationRetryScheduler(),
    clock: clock,
    studentId: session.studentId,
    initiallyConnected: initiallyConnected,
  );
  final coordinator = SynchronizationTriggerCoordinator(synchronization);
  final initialSynchronization = await coordinator.onLaunchOrResume();
  if (initialSynchronization.disposition !=
      SynchronizationDisposition.synchronized) {
    await synchronization.shutdown();
    if (repositories case final SqliteRepositoryRegistry sqlite) {
      await sqlite.close();
    }
    throw StateError('Initial browser synchronization did not complete.');
  }

  final guard = browser.createUnsentChangesGuard();
  final pending = _PendingSynchronizationMonitor(
    repositories: repositories,
    synchronization: synchronization,
    clock: clock,
    studentId: session.studentId,
    guard: guard,
  );
  final applicationRepositories = SynchronizationTriggeringRepositoryRegistry(
    base: repositories,
    synchronization: synchronization,
    onTriggerFailure: _reportSynchronizationFailure,
    onCommitted: pending.afterCommit,
  );
  await pending.initialize();

  var themeId = variantFThemeId;
  var enhancedAccessibility = false;
  try {
    final support = await SupportApplicationService(
      repositories: applicationRepositories,
      clock: clock,
      identifiers: identifiers,
      studentId: session.studentId,
    ).load();
    themeId = support.settings.value.themeId;
    enhancedAccessibility = support.settings.value.enhancedAccessibility;
  } on Object {
    // A new Student can start with the standard presentation while the
    // authoritative settings mutation is retried through the same outbox.
  }
  await pending.refresh();

  final resolvedBuildCoordinator =
      buildVersionCoordinator ??
      createProductionWebBuildVersionCoordinator(
        currentBuildNumber: currentSyncBuildNumber,
        hasUnsentChanges: () async => pending.count > 0,
        unsentChangesDrained: synchronization.outboxDrained,
      );

  onLocalCopyControllerReady?.call(
    _WebLocalCopyController(
      pending: pending,
      shutdown: () async {
        await synchronization.shutdown();
        await pending.dispose();
        if (repositories case final SqliteRepositoryRegistry sqlite) {
          // The still-mounted application can have presentation reads queued.
          // Let the identity gate unmount it while the FIFO drains and closes.
          unawaited(_closeWebRepositories(sqlite));
        }
      },
    ),
  );

  Future<void> launchOrResume() async {
    await coordinator.onLaunchOrResume();
    await pending.refresh();
  }

  Future<void> connectivityChanged(bool connected) async {
    await coordinator.onConnectivityChanged(connected);
    await pending.refresh();
  }

  return ClinicalCalendarApp(
    dependencies: ApplicationDependencies(
      repositories: applicationRepositories,
      clock: clock,
      identifiers: identifiers,
      synchronization: synchronization,
      notifications: const DeferredNotificationService(),
      secureStorage: secureStorage,
      files: const DeferredFileService(),
    ),
    environmentName: environment.name,
    studentId: session.studentId,
    themeId: themeId,
    enhancedAccessibility: enhancedAccessibility,
    onLaunchOrResume: launchOrResume,
    onBuildVersionCheck: resolvedBuildCoordinator?.checkOnOpenOrResume,
    minimumSyncBuildRequired: synchronization.minimumSyncBuildRequired,
    minimumSyncBuildRequiredChanges:
        synchronization.minimumSyncBuildRequiredChanges,
    pendingSynchronizationCount: pending.count,
    pendingSynchronizationCountChanges: pending.changes,
    connectivityChanges: source.changes,
    onConnectivityChanged: connectivityChanged,
    identity: identity,
    identityEmail: session.email,
    onLocalCopyRemoved: onLocalCopyRemoved,
  );
}

final class _WebIdentityGate extends StatefulWidget {
  const _WebIdentityGate({
    required this.identity,
    required this.secureStorage,
    required this.identifiers,
    required this.clock,
    required this.environment,
    required this.browser,
    required this.localCopy,
    required this.repositoryBootstrap,
    required this.synchronizationTransport,
    required this.retryScheduler,
    required this.connectivitySource,
    required this.buildVersionCoordinator,
  });

  final PasswordlessIdentityService identity;
  final SecureStorage secureStorage;
  final IdentifierGenerator identifiers;
  final Clock clock;
  final AppEnvironment environment;
  final BrowserRuntime browser;
  final _DeferredWebLocalCopyController localCopy;
  final WebRepositoryBootstrap? repositoryBootstrap;
  final SynchronizationTransport? synchronizationTransport;
  final SynchronizationRetryScheduler? retryScheduler;
  final WebConnectivityStatusSource? connectivitySource;
  final WebBuildVersionCoordinator? buildVersionCoordinator;

  @override
  State<_WebIdentityGate> createState() => _WebIdentityGateState();
}

final class _WebIdentityGateState extends State<_WebIdentityGate> {
  bool _restoring = true;
  bool _restoreFailed = false;
  bool _enhancedAccessibility = false;
  Future<ClinicalCalendarApp>? _application;

  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final remembered =
        await widget.secureStorage.read(
          PasswordlessIdentityService.sessionStorageKey,
        ) !=
        null;
    final session = await widget.identity.restoreForOnlineLaunch();
    if (!mounted) return;
    setState(() {
      _restoring = false;
      _restoreFailed = remembered && session == null;
      if (session != null) _open(session);
    });
  }

  void _open(IdentitySession session) {
    _application = buildWebApplication(
      session: session,
      identity: widget.identity,
      secureStorage: widget.secureStorage,
      identifiers: widget.identifiers,
      clock: widget.clock,
      environment: widget.environment,
      browser: widget.browser,
      repositoryBootstrap: widget.repositoryBootstrap,
      synchronizationTransport: widget.synchronizationTransport,
      retryScheduler: widget.retryScheduler,
      connectivitySource: widget.connectivitySource,
      buildVersionCoordinator: widget.buildVersionCoordinator,
      onLocalCopyControllerReady: widget.localCopy.attach,
      onLocalCopyRemoved: _signedOut,
    );
  }

  Future<void> _signedOut() async {
    if (!mounted) return;
    setState(() => _application = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) return const _WebLoadingApplication();
    if (_restoreFailed) return const _WebStartupFailureApplication();
    final application = _application;
    if (application == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Clinical Calendar',
        theme: buildGraphiteTheme(
          enhancedAccessibility: _enhancedAccessibility,
        ),
        home: PasswordlessSignInSurface(
          identity: widget.identity,
          enhancedAccessibility: _enhancedAccessibility,
          onEnhancedAccessibilityChanged: (value) {
            setState(() => _enhancedAccessibility = value);
          },
          onSignedIn: (session) async => setState(() => _open(session)),
        ),
      );
    }
    return FutureBuilder<ClinicalCalendarApp>(
      future: application,
      builder: (context, snapshot) {
        if (snapshot.data case final app?) return app;
        if (snapshot.hasError) return const _WebStartupFailureApplication();
        return const _WebLoadingApplication();
      },
    );
  }
}

final class _PendingSynchronizationMonitor {
  _PendingSynchronizationMonitor({
    required this.repositories,
    required this.synchronization,
    required this.clock,
    required this.studentId,
    required this.guard,
  });

  final RepositoryRegistry repositories;
  final DurableSynchronizationService synchronization;
  final Clock clock;
  final String studentId;
  final UnsentChangesGuard guard;
  final _changes = StreamController<int>.broadcast();
  StreamSubscription<void>? _drainedSubscription;
  Future<void> _tail = Future.value();
  bool _disposed = false;
  int count = 0;

  Stream<int> get changes => _changes.stream;

  Future<void> initialize() async {
    _drainedSubscription = synchronization.outboxDrained.listen(
      (_) => _scheduleRefresh(),
    );
    await refresh();
  }

  void afterCommit() => _scheduleRefresh();

  void _scheduleRefresh() {
    if (_disposed) return;
    unawaited(refresh().catchError((_) {}));
  }

  Future<void> refresh() {
    if (_disposed) return Future.value();
    final operation = _tail.then((_) async {
      final next = await repositories.read(
        (values) => values.outbox
            .pending(
              studentId: studentId,
              asOfUtc: clock.nowUtc(),
              policy: const OutboxPendingPolicy(
                retryEligibility: OutboxRetryEligibility.includeDeferred,
              ),
              limit: 1000000,
            )
            .length,
      );
      if (next != count) {
        count = next;
        _changes.add(next);
      }
      guard.update(next > 0);
    });
    _tail = operation.catchError((_) {});
    return operation;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final drainedSubscription = _drainedSubscription;
    if (drainedSubscription != null) {
      unawaited(drainedSubscription.cancel());
    }
    await _tail;
    unawaited(guard.dispose());
    // A mounted StreamBuilder can keep the close future pending until the
    // identity gate unmounts it. Closing is still required, but teardown must
    // not wait on that consumer before the local database can be discarded.
    unawaited(_changes.close());
  }
}

final class _DeferredWebLocalCopyController
    implements LocalDeviceCopyController {
  _DeferredWebLocalCopyController({this.additional});

  final LocalDeviceCopyController? additional;
  LocalDeviceCopyController? _delegate;

  void attach(LocalDeviceCopyController controller) => _delegate = controller;

  LocalDeviceCopyController get _required =>
      _delegate ?? (throw const IdentityException('local_copy_unavailable'));

  @override
  Future<LocalRemovalPreview> previewRemoval() => _required.previewRemoval();

  @override
  Future<void> removeLocalCopy() async {
    await _required.removeLocalCopy();
    await additional?.removeLocalCopy();
    _delegate = null;
  }
}

final class _WebLocalCopyController implements LocalDeviceCopyController {
  const _WebLocalCopyController({
    required this.pending,
    required this.shutdown,
  });

  final _PendingSynchronizationMonitor pending;
  final Future<void> Function() shutdown;

  @override
  Future<LocalRemovalPreview> previewRemoval() async => LocalRemovalPreview(
    pendingChangeCount: pending.count,
    oldestPendingAtUtc: null,
  );

  @override
  Future<void> removeLocalCopy() => shutdown();
}

Future<RepositoryRegistry> _openWebRepositories(
  String studentId,
  IdentifierGenerator identifiers,
  BrowserRuntime browser,
) async {
  final database = ClinicalCalendarDatabase.openInMemory(
    await browser.openInMemorySqlite(),
  );
  try {
    final repositories = SqliteRepositoryRegistry(
      studentId: studentId,
      database: database,
      identifierGenerator: identifiers,
    );
    await repositories.initialize();
    return repositories;
  } on Object {
    await database.close();
    rethrow;
  }
}

Future<bool> _initialConnectivity(WebConnectivityStatusSource source) async {
  try {
    return await source.current();
  } on Object {
    return false;
  }
}

void _reportSynchronizationFailure(Object error, StackTrace stackTrace) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'Clinical Calendar web synchronization',
      context: ErrorDescription('while pushing a committed browser change'),
    ),
  );
}

Future<void> _closeWebRepositories(
  SqliteRepositoryRegistry repositories,
) async {
  try {
    await repositories.close();
  } on Object catch (error, stackTrace) {
    _reportSynchronizationFailure(error, stackTrace);
  }
}

bool _isConnected(List<ConnectivityResult> results) =>
    results.any((result) => result != ConnectivityResult.none);

final class _WebLoadingApplication extends StatelessWidget {
  const _WebLoadingApplication();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Clinical Calendar',
    theme: buildGraphiteTheme(),
    home: const Scaffold(body: Center(child: CircularProgressIndicator())),
  );
}

final class _WebStartupFailureApplication extends StatelessWidget {
  const _WebStartupFailureApplication();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Clinical Calendar',
    theme: buildGraphiteTheme(),
    home: const Scaffold(
      key: Key('web-startup-failure'),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Clinical Calendar could not start. Check the connection and '
            'reload this page.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
