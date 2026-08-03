import 'package:clinical_calendar_application/clinical_calendar_application.dart';

final class OfflineSynchronizationService implements SynchronizationService {
  const OfflineSynchronizationService();

  @override
  Future<SynchronizationResult> synchronize() async =>
      const SynchronizationResult(
        SynchronizationDisposition.offline,
        detail: 'Synchronization adapter is not configured.',
      );
}
