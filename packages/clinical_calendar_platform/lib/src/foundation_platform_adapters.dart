import 'package:clinical_calendar_application/clinical_calendar_application.dart';

export 'foundation_identity_adapters.dart'
    show ProcessIdentifierGenerator, SystemClock;

final class DeferredNotificationService implements NotificationService {
  const DeferredNotificationService();

  @override
  Future<void> reconcileScheduledNotifications() async {}
}

/// Fails closed until ticket 65 binds a platform credential implementation.
final class DeferredSecureStorage implements SecureStorage {
  const DeferredSecureStorage();

  Never _unconfigured() =>
      throw StateError('Secure storage adapter is not configured.');

  @override
  Future<void> delete(String key) async => _unconfigured();

  @override
  Future<String?> read(String key) async => _unconfigured();

  @override
  Future<void> write(String key, String value) async => _unconfigured();
}

/// Fails closed until export and backup tickets bind a native file adapter.
final class DeferredFileService implements FileService {
  const DeferredFileService();

  Never _unconfigured() =>
      throw StateError('File service adapter is not configured.');

  @override
  Future<List<int>> read(Uri location) async => _unconfigured();

  @override
  Future<void> write(Uri location, List<int> bytes) async => _unconfigured();
}
