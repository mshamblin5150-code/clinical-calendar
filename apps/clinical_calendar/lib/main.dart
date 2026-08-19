import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:clinical_calendar_platform/clinical_calendar_platform.dart';
import 'package:clinical_calendar_platform/clinical_calendar_identity_platform.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_identity_presentation.dart';
import 'package:clinical_calendar_sync/clinical_calendar_sync.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/app_environment.dart';

typedef ProductionRepositoryBootstrap =
    Future<RepositoryRegistry> Function(
      String studentId,
      SecureStorage secureStorage,
      IdentifierGenerator identifiers,
    );

typedef AuthoritativePresentationSettingsLoader =
    Future<({String themeId, bool enhancedAccessibility})> Function(
      RepositoryRegistry repositories,
      Clock clock,
      IdentifierGenerator identifiers,
      String studentId,
    );

typedef GraphiteAssetPreflight = Future<void> Function();

abstract interface class ConnectivityStatusSource {
  Future<bool> current();

  Stream<bool> get changes;
}

final class ConnectivityPlusStatusSource implements ConnectivityStatusSource {
  ConnectivityPlusStatusSource([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> current() async =>
      _isConnected(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get changes =>
      _connectivity.onConnectivityChanged.map(_isConnected).distinct();
}

Future<void> main() => runClinicalCalendar(buildProductionRoot);

Future<void> runClinicalCalendar(Future<Widget> Function() bootstrap) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    runApp(await bootstrap());
  } on Object {
    runApp(const _StartupFailureApplication());
  }
}

Future<ClinicalCalendarApp> buildProductionApplication({
  SecureStorage? secureStorage,
  IdentifierGenerator? identifiers,
  ProductionRepositoryBootstrap? repositoryBootstrap,
  AppEnvironment? environment,
  SynchronizationAccessTokenProvider? accessTokenProvider,
  SynchronizationTransport? synchronizationTransport,
  SynchronizationRetryScheduler? retryScheduler,
  ConnectivityStatusSource? connectivitySource,
  SynchronizationTriggerFailureObserver? onSynchronizationFailure,
  Clock? clock,
  String? authenticatedStudentId,
  Future<void> Function()? onSuccessfulSynchronization,
  void Function(LocalDeviceCopyController controller)?
  onLocalCopyControllerReady,
  PasswordlessIdentityService? identity,
  String? identityEmail,
  Future<void> Function()? onLocalCopyRemoved,
  NotificationPlatform? notificationPlatform,
  NotificationDeliveryStore? notificationDeliveryStore,
  NotificationDevicePolicyStore? notificationDevicePolicyStore,
  String? deviceTimeZoneId,
  NotificationDeviceClass? notificationDeviceClass,
  RecoveryReauthenticationGate? recoveryReauthentication,
  NativeByteFileSaver? accountBackupFileSaver,
  BackupByteFilePicker? portableBackupFilePicker,
  bool resolveAuthoritativeTheme = false,
  VoidCallback? onPresentationRestart,
  AuthoritativePresentationSettingsLoader?
  authoritativePresentationSettingsLoader,
  GraphiteAssetPreflight? graphiteAssetPreflight,
}) async {
  final storage = secureStorage ?? const FlutterSecureStorageService();
  final identifierGenerator = identifiers ?? ProcessIdentifierGenerator();
  final applicationClock = clock ?? const SystemClock();
  final configuredEnvironment = environment ?? AppEnvironment.fromCompileTime();
  final studentId = authenticatedStudentId == null
      ? await StableStudentOwner.loadOrCreate(
          secureStorage: storage,
          identifiers: identifierGenerator,
        )
      : await _bindAuthenticatedStudentOwner(storage, authenticatedStudentId);
  final baseRepositories =
      await (repositoryBootstrap ?? _openProductionRepositories)(
        studentId,
        storage,
        identifierGenerator,
      );
  RepositoryRegistry applicationRepositories = baseRepositories;
  SynchronizationService synchronization =
      const OfflineSynchronizationService();
  Future<void> Function()? onLaunchOrResume;
  Future<void> Function(bool connected)? onConnectivityChanged;
  Future<void> Function()? onRealtimeHint;
  Stream<bool>? connectivityChanges;
  DurableSynchronizationService? durableSynchronization;

  final hasSession = await _hasCurrentSynchronizationSession(
    configuredEnvironment,
    accessTokenProvider,
  );
  if (hasSession) {
    final source = connectivitySource ?? ConnectivityPlusStatusSource();
    final initiallyConnected = await _initialConnectivity(source);
    final transport =
        synchronizationTransport ??
        SupabaseRpcSynchronizationTransport(
          projectUri: configuredEnvironment.synchronizationProjectUri!,
          publishableKey: configuredEnvironment.supabasePublishableKey,
          accessTokenProvider: accessTokenProvider!,
          onSuccessfulServerAccess: onSuccessfulSynchronization,
        );
    final durable = DurableSynchronizationService(
      repositories: baseRepositories,
      transport: transport,
      retryScheduler: retryScheduler ?? DartSynchronizationRetryScheduler(),
      clock: applicationClock,
      studentId: studentId,
      initiallyConnected: initiallyConnected,
    );
    durableSynchronization = durable;
    final coordinator = SynchronizationTriggerCoordinator(durable);
    applicationRepositories = SynchronizationTriggeringRepositoryRegistry(
      base: baseRepositories,
      synchronization: durable,
      onTriggerFailure:
          onSynchronizationFailure ?? _reportSynchronizationFailure,
    );
    synchronization = durable;
    onLaunchOrResume = () async {
      await coordinator.onLaunchOrResume();
    };
    onConnectivityChanged = (connected) async {
      await coordinator.onConnectivityChanged(connected);
    };
    onRealtimeHint = () async {
      await coordinator.onRealtimeHint();
    };
    connectivityChanges = source.changes;
  }

  final resolvedDeviceClass =
      notificationDeviceClass ?? _notificationDeviceClass();
  final resolvedTimeZoneId = deviceTimeZoneId ?? await _loadDeviceTimeZoneId();
  final deviceId =
      await storage.read(PasswordlessIdentityService.deviceIdStorageKey) ??
      'local-device';
  final nativeNotifications =
      notificationPlatform ?? FlutterLocalNotificationPlatform();
  final deliveryStore =
      notificationDeliveryStore ??
      SecureNotificationDeliveryStore.applicationStorage(
        storage: storage,
        deviceId: deviceId,
      );
  final devicePolicyStore =
      notificationDevicePolicyStore ??
      SecureNotificationDevicePolicyStore.applicationStorage(
        storage: storage,
        deviceId: deviceId,
      );
  final timeZones = TimeZonePackageReminderResolver();
  final interactions = StreamController<NotificationInteraction>.broadcast();
  late final ProductionNotificationService notificationService;
  notificationService = ProductionNotificationService(
    source: RepositoryReminderCandidateSource(
      repositories: applicationRepositories,
      placements: PlacementApplicationService(
        repositories: applicationRepositories,
        clock: applicationClock,
        identifiers: identifierGenerator,
        studentId: studentId,
      ),
      studentId: studentId,
      deviceId: deviceId,
      deviceTimeZoneId: resolvedTimeZoneId,
      timeZones: timeZones,
    ),
    policy: ReminderPolicy(timeZones),
    reconciler: NotificationReconciler(nativeNotifications, deliveryStore),
    states: ReminderStateApplicationService(applicationRepositories),
    devicePolicies: devicePolicyStore,
    clock: applicationClock,
    identifiers: identifierGenerator,
    studentId: studentId,
    deviceClass: resolvedDeviceClass,
    deviceTimeZoneId: resolvedTimeZoneId,
    onBodyTap: interactions.add,
  );
  if (nativeNotifications case final FlutterLocalNotificationPlatform native) {
    try {
      await native
          .initialize(
            onInteraction: (interaction) =>
                unawaited(notificationService.handleInteraction(interaction)),
          )
          .timeout(const Duration(seconds: 1));
    } on Object {
      // The app remains usable when the OS notification plugin is unavailable.
    }
  }
  final synchronizationLaunchOrResume = onLaunchOrResume;
  onLaunchOrResume = () async {
    await synchronizationLaunchOrResume?.call();
    await notificationService.reconcileScheduledNotifications();
  };

  final dependencies = ApplicationDependencies(
    repositories: applicationRepositories,
    clock: applicationClock,
    identifiers: identifierGenerator,
    synchronization: synchronization,
    notifications: notificationService,
    secureStorage: storage,
    files: const DartIoFileService(),
  );
  var appliedThemeId = variantFThemeId;
  var enhancedAccessibility = false;
  if (resolveAuthoritativeTheme) {
    try {
      final settings =
          await (authoritativePresentationSettingsLoader ??
              _loadAuthoritativePresentationSettings)(
            applicationRepositories,
            applicationClock,
            identifierGenerator,
            studentId,
          );
      appliedThemeId = settings.themeId;
      enhancedAccessibility = settings.enhancedAccessibility;
    } on Object catch (error) {
      throw _AuthoritativeSettingsUnavailable(error);
    }
  }
  if (ClinicalCalendarThemeBundleRegistry.standard
          .resolveApplied(appliedThemeId)
          .bundle
          .id ==
      graphiteThemeId) {
    try {
      await (graphiteAssetPreflight ?? _preflightGraphiteFrame)();
    } on Object catch (error) {
      throw _GraphitePresentationUnavailable(error);
    }
  }
  final recoveryStore = baseRepositories is RecoveryStore
      ? baseRepositories as RecoveryStore
      : null;
  final recoveryProofGate = recoveryReauthentication == null
      ? OneShotRecoveryReauthenticationGate()
      : null;
  final recoveryService = recoveryStore == null
      ? null
      : RecoveryApplicationService(
          store: recoveryStore,
          reauthentication: recoveryReauthentication ?? recoveryProofGate!,
          identifiers: identifierGenerator,
        );
  final nativeFileSaver = accountBackupFileSaver ?? NativeExportFileSaver();
  final createAccountBackup = baseRepositories is SqliteRepositoryRegistry
      ? (String passphrase) async {
          final createdAtUtc = applicationClock.nowUtc();
          final bytes = await baseRepositories.runPortableBackupExclusive(
            (service) => service.createEncryptedBackup(
              passphrase: passphrase,
              createdAtUtc: createdAtUtc,
            ),
          );
          final date = createdAtUtc.toIso8601String().substring(0, 10);
          final outcome = await nativeFileSaver.save(
            NativeFileSaveRequest(
              suggestedFileName: 'clinical-calendar-backup-$date.ccbackup',
              mimeType: 'application/octet-stream',
              bytes: bytes,
            ),
          );
          return outcome == NativeFileSaveOutcome.saved;
        }
      : null;
  PortableBackupWorkflows? portableBackupWorkflows;
  if (baseRepositories is SqliteRepositoryRegistry &&
      createAccountBackup != null) {
    final sqliteRepositories = baseRepositories;
    final picker = portableBackupFilePicker ?? NativeBackupFilePicker();
    PortableRestorePreview? selectedPreview;
    portableBackupWorkflows = PortableBackupWorkflows(
      create: createAccountBackup,
      choose: (passphrase) async {
        final encryptedBytes = await picker.pickBackupBytes();
        if (encryptedBytes == null) {
          selectedPreview = null;
          return null;
        }
        final preview = await sqliteRepositories.runPortableBackupExclusive(
          (service) => service.previewRestore(
            encryptedBytes: encryptedBytes,
            passphrase: passphrase,
          ),
        );
        selectedPreview = preview;
        return BackupRestorePreviewViewModel(
          additions: preview.additions,
          backupUpdates: preview.backupUpdates,
          localRecordsKept: preview.items
              .where(
                (item) => item.disposition == RestoreMergeDisposition.keepLocal,
              )
              .length,
          conflicts: [
            for (final item in preview.conflicts)
              BackupConflictViewModel(
                identity: item.identity.stableValue,
                title: '${item.identity.table} record',
                localSummary: 'Current revision ${item.localRevision}',
                backupSummary: 'Backup revision ${item.backupRevision}',
              ),
          ],
        );
      },
      apply: (choices) async {
        final preview = selectedPreview;
        if (preview == null) {
          throw StateError('No validated backup preview is available.');
        }
        final conflictsByIdentity = {
          for (final item in preview.conflicts)
            item.identity.stableValue: item.identity,
        };
        final resolved = <BackupRecordIdentity, RestoreConflictChoice>{};
        for (final entry in choices.entries) {
          final identity = conflictsByIdentity[entry.key];
          if (identity == null) {
            throw StateError('Restore choices do not match the preview.');
          }
          resolved[identity] = switch (entry.value) {
            BackupConflictSelection.keepLocal =>
              RestoreConflictChoice.keepLocal,
            BackupConflictSelection.useBackup =>
              RestoreConflictChoice.useBackup,
          };
        }
        await sqliteRepositories.runPortableBackupExclusive(
          (service) =>
              service.applyRestore(preview: preview, conflictChoices: resolved),
        );
        selectedPreview = null;
      },
    );
  }
  final exportData = ExportDataService(
    applicationRepositories,
    PlacementApplicationService(
      repositories: applicationRepositories,
      clock: applicationClock,
      identifiers: identifierGenerator,
      studentId: studentId,
    ),
    applicationClock,
    studentId,
  );
  ExportWorkflowService buildExportWorkflow(
    ExportReauthenticationGate reauthentication,
  ) => ExportWorkflowService(
    data: exportData,
    encoder: const DartExportEncoder(),
    reauthentication: reauthentication,
    fileSaver: nativeFileSaver,
  );
  if (recoveryStore != null) {
    final existingLaunchOrResume = onLaunchOrResume;
    onLaunchOrResume = () async {
      await existingLaunchOrResume();
      await recoveryStore.createDailySnapshot(
        nowUtc: applicationClock.nowUtc(),
      );
    };
  }
  if (baseRepositories is SqliteRepositoryRegistry &&
      onLocalCopyControllerReady != null) {
    final sqliteRepositories = baseRepositories;
    onLocalCopyControllerReady(
      ProductionLocalDeviceCopyController(
        databasePath: sqliteRepositories.databasePath,
        secureStorage: storage,
        preview: () async {
          final preview = await sqliteRepositories.localRemovalPreview();
          return LocalRemovalPreview(
            pendingChangeCount: preview.count,
            oldestPendingAtUtc: preview.oldestAtUtc,
          );
        },
        stopLifecycleAndCloseDatabase: () async {
          await durableSynchronization?.shutdown();
          await sqliteRepositories.close();
        },
        credentialKeys: const {
          ClinicalCalendarDatabase.encryptionKeyStorageKey,
          StableStudentOwner.storageKey,
          PasswordlessIdentityService.sessionStorageKey,
          PasswordlessIdentityService.deviceIdStorageKey,
        },
      ),
    );
  }
  return ClinicalCalendarApp(
    dependencies: dependencies,
    environmentName: configuredEnvironment.name,
    studentId: studentId,
    themeId: appliedThemeId,
    enhancedAccessibility: enhancedAccessibility,
    onPresentationRestart: onPresentationRestart,
    onLaunchOrResume: onLaunchOrResume,
    connectivityChanges: connectivityChanges,
    onConnectivityChanged: onConnectivityChanged,
    onRealtimeHint: onRealtimeHint,
    identity: identity,
    identityEmail: identityEmail,
    onLocalCopyRemoved: onLocalCopyRemoved,
    createAccountBackup: createAccountBackup,
    portableBackupWorkflows: portableBackupWorkflows,
    exportWorkflowFactory: buildExportWorkflow,
    notificationInteractions: interactions.stream,
    notificationDevicePolicyStore: devicePolicyStore,
    notificationDeviceClass: resolvedDeviceClass,
    recoveryStore: recoveryStore,
    recoveryService: recoveryService,
    recoveryProofGate: recoveryProofGate,
    todayResolver: (nowUtc) {
      final local = timeZones.toLocal(nowUtc, resolvedTimeZoneId);
      return LocalDate(local.year, local.month, local.day);
    },
    scheduleDateFactory: (date) => ZonedScheduleDate.resolvingOffsets(
      date: date,
      timeZone: TimeZoneId(resolvedTimeZoneId),
      offsetAt: (boundaryDate, boundaryTime) => UtcOffset.inMinutes(
        timeZones
            .offsetAtLocal(
              DateTime.utc(
                boundaryDate.year,
                boundaryDate.month,
                boundaryDate.day,
                boundaryTime.hour,
                boundaryTime.minute,
              ),
              resolvedTimeZoneId,
            )
            .inMinutes,
      ),
    ),
  );
}

Future<({String themeId, bool enhancedAccessibility})>
_loadAuthoritativePresentationSettings(
  RepositoryRegistry repositories,
  Clock clock,
  IdentifierGenerator identifiers,
  String studentId,
) async {
  final support = await SupportApplicationService(
    repositories: repositories,
    clock: clock,
    identifiers: identifiers,
    studentId: studentId,
  ).load();
  return (
    themeId: support.settings.value.themeId,
    enhancedAccessibility: support.settings.value.enhancedAccessibility,
  );
}

Future<void> _preflightGraphiteFrame() async {
  final bytes = await rootBundle.load(
    'packages/clinical_calendar_presentation/$graphiteFrameAsset',
  );
  if (bytes.lengthInBytes < 33 ||
      bytes.getUint32(16, Endian.big) != 1536 ||
      bytes.getUint32(20, Endian.big) != 1024 ||
      bytes.getUint8(25) != 6) {
    throw StateError('The Graphite frame is not a 1536 by 1024 RGBA PNG.');
  }
  final encoded = bytes.buffer.asUint8List(
    bytes.offsetInBytes,
    bytes.lengthInBytes,
  );
  final codec = await ui.instantiateImageCodec(encoded);
  try {
    final decoded = await codec.getNextFrame();
    try {
      if (decoded.image.width != 1536 || decoded.image.height != 1024) {
        throw StateError(
          'The decoded Graphite frame is not 1536 by 1024 pixels.',
        );
      }
    } finally {
      decoded.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

Future<String> _loadDeviceTimeZoneId() async {
  try {
    return await const FlutterDeviceTimeZoneProvider()
        .currentTimeZoneId()
        .timeout(const Duration(seconds: 1));
  } on Object {
    return 'UTC';
  }
}

NotificationDeviceClass _notificationDeviceClass() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return NotificationDeviceClass.desktop;
  }
  if (Platform.isAndroid) return NotificationDeviceClass.tablet;
  return NotificationDeviceClass.phone;
}

Future<Widget> buildProductionRoot({
  SecureStorage? secureStorage,
  IdentifierGenerator? identifiers,
  Clock? clock,
  AppEnvironment? environment,
  ProductionRepositoryBootstrap? repositoryBootstrap,
  PasswordlessIdentityGateway? identityGateway,
  ConnectivityStatusSource? connectivitySource,
  DeviceDescriptor? currentDevice,
  AuthoritativePresentationSettingsLoader?
  authoritativePresentationSettingsLoader,
  GraphiteAssetPreflight? graphiteAssetPreflight,
}) async {
  final storage = secureStorage ?? const FlutterSecureStorageService();
  final identifierGenerator = identifiers ?? ProcessIdentifierGenerator();
  final applicationClock = clock ?? const SystemClock();
  final configuredEnvironment = environment ?? AppEnvironment.fromCompileTime();
  if (!configuredEnvironment.hasSynchronizationConfiguration) {
    return buildProductionApplication(
      secureStorage: storage,
      identifiers: identifierGenerator,
      clock: applicationClock,
      environment: configuredEnvironment,
      repositoryBootstrap: repositoryBootstrap,
    );
  }
  final localCopy = _DeferredLocalDeviceCopyController();
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
        DeviceDescriptor(name: _deviceName(), platform: _devicePlatform()),
    localCopy: localCopy,
  );
  return _ProductionIdentityGate(
    identity: identity,
    secureStorage: storage,
    identifiers: identifierGenerator,
    clock: applicationClock,
    environment: configuredEnvironment,
    repositoryBootstrap: repositoryBootstrap,
    initialSession: await identity.restoreForOfflineLaunch(),
    localCopy: localCopy,
    connectivitySource: connectivitySource,
    authoritativePresentationSettingsLoader:
        authoritativePresentationSettingsLoader,
    graphiteAssetPreflight: graphiteAssetPreflight,
  );
}

final class _ProductionIdentityGate extends StatefulWidget {
  const _ProductionIdentityGate({
    required this.identity,
    required this.secureStorage,
    required this.identifiers,
    required this.clock,
    required this.environment,
    required this.initialSession,
    required this.localCopy,
    required this.connectivitySource,
    required this.authoritativePresentationSettingsLoader,
    required this.graphiteAssetPreflight,
    this.repositoryBootstrap,
  });

  final PasswordlessIdentityService identity;
  final SecureStorage secureStorage;
  final IdentifierGenerator identifiers;
  final Clock clock;
  final AppEnvironment environment;
  final IdentitySession? initialSession;
  final _DeferredLocalDeviceCopyController localCopy;
  final ConnectivityStatusSource? connectivitySource;
  final AuthoritativePresentationSettingsLoader?
  authoritativePresentationSettingsLoader;
  final GraphiteAssetPreflight? graphiteAssetPreflight;
  final ProductionRepositoryBootstrap? repositoryBootstrap;

  @override
  State<_ProductionIdentityGate> createState() =>
      _ProductionIdentityGateState();
}

final class _ProductionIdentityGateState
    extends State<_ProductionIdentityGate> {
  Future<ClinicalCalendarApp>? _application;
  IdentitySession? _activeSession;
  bool _deviceEnhancedAccessibility = false;
  int _deviceAccessibilityRevision = 0;
  Future<void> _deviceAccessibilityWrites = Future.value();

  @override
  void initState() {
    super.initState();
    unawaited(_loadDeviceEnhancedAccessibility());
    if (widget.initialSession case final session?) _open(session);
  }

  Future<void> _loadDeviceEnhancedAccessibility() async {
    final revision = _deviceAccessibilityRevision;
    final stored = await widget.secureStorage.read(
      _deviceEnhancedAccessibilityStorageKey,
    );
    if (!mounted || revision != _deviceAccessibilityRevision) return;
    setState(() => _deviceEnhancedAccessibility = stored == 'true');
  }

  Future<void> _setDeviceEnhancedAccessibility(bool value) async {
    final previous = _deviceEnhancedAccessibility;
    final revision = ++_deviceAccessibilityRevision;
    setState(() => _deviceEnhancedAccessibility = value);
    final operation = _deviceAccessibilityWrites.then(
      (_) => widget.secureStorage.write(
        _deviceEnhancedAccessibilityStorageKey,
        value.toString(),
      ),
    );
    _deviceAccessibilityWrites = operation.catchError((_) {});
    try {
      await operation;
    } on Object {
      if (mounted && revision == _deviceAccessibilityRevision) {
        setState(() => _deviceEnhancedAccessibility = previous);
      }
    }
  }

  void _open(IdentitySession session) {
    _activeSession = session;
    _application = buildProductionApplication(
      secureStorage: widget.secureStorage,
      identifiers: widget.identifiers,
      clock: widget.clock,
      environment: widget.environment,
      repositoryBootstrap: widget.repositoryBootstrap,
      authenticatedStudentId: session.studentId,
      accessTokenProvider: widget.identity.currentAccessToken,
      onSuccessfulSynchronization: () async {
        await widget.identity.markSynchronized();
      },
      onLocalCopyControllerReady: widget.localCopy.attach,
      connectivitySource: widget.connectivitySource,
      identity: widget.identity,
      identityEmail: session.email,
      onLocalCopyRemoved: _onLocalCopyRemoved,
      resolveAuthoritativeTheme: true,
      onPresentationRestart: () {
        if (mounted) setState(() => _open(session));
      },
      authoritativePresentationSettingsLoader:
          widget.authoritativePresentationSettingsLoader,
      graphiteAssetPreflight: widget.graphiteAssetPreflight,
    );
  }

  Future<void> _onLocalCopyRemoved() async {
    if (!mounted) return;
    setState(() {
      _activeSession = null;
      _application = null;
    });
  }

  void _retryOpen() {
    final session = _activeSession;
    if (session != null) setState(() => _open(session));
  }

  @override
  Widget build(BuildContext context) {
    final application = _application;
    if (application == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildGraphiteTheme(
          enhancedAccessibility: _deviceEnhancedAccessibility,
        ),
        builder: (context, child) =>
            EnhancedGlobalFocusOverlay(child: child ?? const SizedBox.shrink()),
        home: PasswordlessSignInSurface(
          identity: widget.identity,
          enhancedAccessibility: _deviceEnhancedAccessibility,
          onEnhancedAccessibilityChanged: _setDeviceEnhancedAccessibility,
          onSignedIn: (session) async => setState(() => _open(session)),
        ),
      );
    }
    return FutureBuilder<ClinicalCalendarApp>(
      future: application,
      builder: (context, snapshot) {
        if (snapshot.error is _AuthoritativeSettingsUnavailable) {
          return _AuthoritativeSettingsFailureApplication(onRetry: _retryOpen);
        }
        if (snapshot.error is _GraphitePresentationUnavailable) {
          return _GraphitePresentationFailureApplication(onRestart: _retryOpen);
        }
        if (snapshot.hasError) return const _StartupFailureApplication();
        if (snapshot.data case final app?) return app;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildGraphiteTheme(),
          home: Scaffold(
            body: Center(
              child: Semantics(
                label: 'Loading authoritative Student settings',
                child: const CircularProgressIndicator(),
              ),
            ),
          ),
        );
      },
    );
  }
}

const _deviceEnhancedAccessibilityStorageKey =
    'clinical_calendar.device.enhanced_accessibility';

final class _AuthoritativeSettingsUnavailable implements Exception {
  const _AuthoritativeSettingsUnavailable(this.cause);

  final Object cause;
}

final class _GraphitePresentationUnavailable implements Exception {
  const _GraphitePresentationUnavailable(this.cause);

  final Object cause;
}

final class _DeferredLocalDeviceCopyController
    implements LocalDeviceCopyController {
  LocalDeviceCopyController? _delegate;

  void attach(LocalDeviceCopyController controller) {
    _delegate = controller;
  }

  LocalDeviceCopyController get _requiredDelegate =>
      _delegate ?? (throw const IdentityException('local_copy_unavailable'));

  @override
  Future<LocalRemovalPreview> previewRemoval() =>
      _requiredDelegate.previewRemoval();

  @override
  Future<void> removeLocalCopy() async {
    await _requiredDelegate.removeLocalCopy();
    _delegate = null;
  }
}

Future<String> _bindAuthenticatedStudentOwner(
  SecureStorage storage,
  String authenticatedStudentId,
) async {
  final normalized = authenticatedStudentId.trim().toLowerCase();
  final existing = await storage.read(StableStudentOwner.storageKey);
  if (existing != null && existing.trim().toLowerCase() != normalized) {
    throw StateError('The authenticated Student does not own this local copy.');
  }
  await storage.write(StableStudentOwner.storageKey, normalized);
  return normalized;
}

DevicePlatform _devicePlatform() {
  if (Platform.isWindows) return DevicePlatform.windows;
  if (Platform.isIOS) return DevicePlatform.ios;
  if (Platform.isAndroid) return DevicePlatform.android;
  throw UnsupportedError(
    'Clinical Calendar supports Windows, iOS, and Android.',
  );
}

String _deviceName() {
  final host = Platform.localHostname.trim();
  if (host.isNotEmpty) return host;
  return switch (_devicePlatform()) {
    DevicePlatform.windows => 'Windows device',
    DevicePlatform.ios => 'iPhone or iPad',
    DevicePlatform.android => 'Android device',
  };
}

Future<bool> _hasCurrentSynchronizationSession(
  AppEnvironment environment,
  SynchronizationAccessTokenProvider? accessTokenProvider,
) async {
  if (!environment.hasSynchronizationConfiguration ||
      accessTokenProvider == null) {
    return false;
  }
  try {
    return (await accessTokenProvider())?.trim().isNotEmpty ?? false;
  } on Object {
    return false;
  }
}

Future<bool> _initialConnectivity(ConnectivityStatusSource source) async {
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
      library: 'Clinical Calendar synchronization',
      context: ErrorDescription('while waking synchronization after a save'),
    ),
  );
}

bool _isConnected(List<ConnectivityResult> results) =>
    results.any((result) => result != ConnectivityResult.none);

Future<RepositoryRegistry> _openProductionRepositories(
  String studentId,
  SecureStorage secureStorage,
  IdentifierGenerator identifiers,
) async {
  final database = await ClinicalCalendarDatabase.open(
    path: await clinicalCalendarDatabasePath(),
    secureStorage: secureStorage,
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

final class _StartupFailureApplication extends StatelessWidget {
  const _StartupFailureApplication();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Clinical Calendar',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D1013),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF37D6B4),
        onPrimary: Color(0xFF06251E),
        surface: Color(0xFF151A1F),
        onSurface: Color(0xFFF4F6F7),
      ),
    ),
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 40),
                const SizedBox(height: 16),
                Text(
                  'Clinical Calendar could not start.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your local data was left unchanged. Close the app and try '
                  'again. If the problem continues, use Help before making '
                  'any changes to the database or secure storage.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

final class _AuthoritativeSettingsFailureApplication extends StatelessWidget {
  const _AuthoritativeSettingsFailureApplication({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => CodeOnlyPresentationRecoveryApplication(
    surfaceKey: const Key('authoritative-settings-unavailable'),
    icon: Icons.sync_problem_outlined,
    title: 'Student settings are unavailable.',
    guidance:
        'The authenticated Calendar remains hidden. Check the connection or '
        'the valid offline copy, then try loading settings again.',
    actionLabel: 'Retry settings',
    onAction: onRetry,
  );
}

final class _GraphitePresentationFailureApplication extends StatelessWidget {
  const _GraphitePresentationFailureApplication({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => CodeOnlyPresentationRecoveryApplication(
    surfaceKey: const Key('graphite-presentation-unavailable'),
    icon: Icons.restart_alt,
    title: 'Presentation could not start.',
    guidance:
        'No Calendar or Student data was displayed. Restart the presentation. '
        'If this continues, record the app version and device model for Help.',
    actionLabel: 'Restart',
    onAction: onRestart,
  );
}
