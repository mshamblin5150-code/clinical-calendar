import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:web/web.dart' as web;

String currentBrowserUserAgent() => web.window.navigator.userAgent;

SecureStorage createWebIdentityStorage() => const _WebIdentityStorage();

final class _WebIdentityStorage implements SecureStorage {
  const _WebIdentityStorage();

  static const _allowedKeys = {
    PasswordlessIdentityService.sessionStorageKey,
    PasswordlessIdentityService.deviceIdStorageKey,
  };

  String _key(String key) {
    if (!_allowedKeys.contains(key)) {
      throw ArgumentError.value(key, 'key', 'is not web identity storage');
    }
    return key;
  }

  @override
  Future<void> delete(String key) async =>
      web.window.localStorage.removeItem(_key(key));

  @override
  Future<String?> read(String key) async =>
      web.window.localStorage.getItem(_key(key));

  @override
  Future<void> write(String key, String value) async =>
      web.window.localStorage.setItem(_key(key), value);
}
