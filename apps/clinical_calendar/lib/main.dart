import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:clinical_calendar_platform/clinical_calendar_platform.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:clinical_calendar_sync/clinical_calendar_sync.dart';
import 'package:flutter/material.dart';

import 'config/app_environment.dart';

typedef ProductionRepositoryBootstrap =
    Future<RepositoryRegistry> Function(
      String studentId,
      SecureStorage secureStorage,
      IdentifierGenerator identifiers,
    );

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
}) async {
  final storage = secureStorage ?? const FlutterSecureStorageService();
  final identifierGenerator = identifiers ?? ProcessIdentifierGenerator();
  final studentId = await StableStudentOwner.loadOrCreate(
    secureStorage: storage,
    identifiers: identifierGenerator,
  );
  final repositories =
      await (repositoryBootstrap ?? _openProductionRepositories)(
        studentId,
        storage,
        identifierGenerator,
      );
  final dependencies = ApplicationDependencies(
    repositories: repositories,
    clock: const SystemClock(),
    identifiers: identifierGenerator,
    synchronization: const OfflineSynchronizationService(),
    notifications: const DeferredNotificationService(),
    secureStorage: storage,
    files: const DartIoFileService(),
  );
  final environment = AppEnvironment.fromCompileTime();
  return ClinicalCalendarApp(
    dependencies: dependencies,
    environmentName: environment.name,
    studentId: studentId,
  );
}

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
