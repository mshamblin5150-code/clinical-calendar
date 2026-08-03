import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:clinical_calendar_platform/clinical_calendar_platform.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:clinical_calendar_sync/clinical_calendar_sync.dart';
import 'package:flutter/widgets.dart';

import 'config/app_environment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repositories = DeferredRepositoryRegistry();
  await repositories.initialize();

  final dependencies = ApplicationDependencies(
    repositories: repositories,
    clock: const SystemClock(),
    identifiers: ProcessIdentifierGenerator(),
    synchronization: const OfflineSynchronizationService(),
    notifications: const DeferredNotificationService(),
    secureStorage: const DeferredSecureStorage(),
    files: const DeferredFileService(),
  );
  final environment = AppEnvironment.fromCompileTime();

  runApp(
    ClinicalCalendarApp(
      dependencies: dependencies,
      environmentName: environment.name,
    ),
  );
}
