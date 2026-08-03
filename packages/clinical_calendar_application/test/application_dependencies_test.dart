import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:test/test.dart';

void main() {
  test('composition contract requires every external capability', () {
    final dependencies = ApplicationDependencies(
      repositories: _Repositories(),
      clock: _Clock(),
      identifiers: _Identifiers(),
      synchronization: _Synchronization(),
      notifications: _Notifications(),
      secureStorage: _SecureStorage(),
      files: _Files(),
    );

    expect(dependencies.clock.nowUtc().isUtc, isTrue);
    expect(dependencies.identifiers.nextIdentifier(), isNotEmpty);
  });
}

final class _Repositories implements RepositoryRegistry {
  @override
  Future<void> initialize() async {}
}

final class _Clock implements Clock {
  @override
  DateTime nowUtc() => DateTime.utc(2026, 8, 3);
}

final class _Identifiers implements IdentifierGenerator {
  @override
  String nextIdentifier() => 'test-id';
}

final class _Synchronization implements SynchronizationService {
  @override
  Future<SynchronizationResult> synchronize() async =>
      const SynchronizationResult(SynchronizationDisposition.offline);
}

final class _Notifications implements NotificationService {
  @override
  Future<void> reconcileScheduledNotifications() async {}
}

final class _SecureStorage implements SecureStorage {
  @override
  Future<void> delete(String key) async {}

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}
}

final class _Files implements FileService {
  @override
  Future<List<int>> read(Uri location) async => const [];

  @override
  Future<void> write(Uri location, List<int> bytes) async {}
}
