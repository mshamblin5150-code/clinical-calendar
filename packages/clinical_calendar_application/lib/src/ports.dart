abstract interface class Clock {
  DateTime nowUtc();
}

abstract interface class IdentifierGenerator {
  String nextIdentifier();
}

enum SynchronizationDisposition { offline, synchronized, deferred }

final class SynchronizationResult {
  const SynchronizationResult(this.disposition, {this.detail});

  final SynchronizationDisposition disposition;
  final String? detail;
}

abstract interface class SynchronizationService {
  Future<SynchronizationResult> synchronize();
}

abstract interface class NotificationService {
  Future<void> reconcileScheduledNotifications();
}

abstract interface class SecureStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

abstract interface class FileService {
  Future<List<int>> read(Uri location);

  Future<void> write(Uri location, List<int> bytes);
}
