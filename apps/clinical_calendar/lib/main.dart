import 'dart:async';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:clinical_calendar_platform/clinical_calendar_platform.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:clinical_calendar_sync/clinical_calendar_sync.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'config/app_environment.dart';

typedef ProductionRepositoryBootstrap =
    Future<RepositoryRegistry> Function(
      String studentId,
      SecureStorage secureStorage,
      IdentifierGenerator identifiers,
    );

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

Future<void> main() => runClinicalCalendar(buildProductionApplication);

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
}) async {
  final storage = secureStorage ?? const FlutterSecureStorageService();
  final identifierGenerator = identifiers ?? ProcessIdentifierGenerator();
  final applicationClock = clock ?? const SystemClock();
  final configuredEnvironment = environment ?? AppEnvironment.fromCompileTime();
  final studentId = await StableStudentOwner.loadOrCreate(
    secureStorage: storage,
    identifiers: identifierGenerator,
  );
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
        );
    final durable = DurableSynchronizationService(
      repositories: baseRepositories,
      transport: transport,
      retryScheduler: retryScheduler ?? DartSynchronizationRetryScheduler(),
      clock: applicationClock,
      studentId: studentId,
      initiallyConnected: initiallyConnected,
    );
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

  final dependencies = ApplicationDependencies(
    repositories: applicationRepositories,
    clock: applicationClock,
    identifiers: identifierGenerator,
    synchronization: synchronization,
    notifications: const DeferredNotificationService(),
    secureStorage: storage,
    files: const DartIoFileService(),
  );
  return ClinicalCalendarApp(
    dependencies: dependencies,
    environmentName: configuredEnvironment.name,
    studentId: studentId,
    onLaunchOrResume: onLaunchOrResume,
    connectivityChanges: connectivityChanges,
    onConnectivityChanged: onConnectivityChanged,
    onRealtimeHint: onRealtimeHint,
  );
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
