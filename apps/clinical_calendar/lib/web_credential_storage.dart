import 'dart:convert';

import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:clinical_calendar_application/clinical_calendar_application.dart';

abstract interface class BrowserKeyValueStore {
  String? read(String key);

  void write(String key, String value);

  void delete(String key);
}

/// Browser persistence constrained to the two credentials permitted by
/// ADR-0001. Calendar data, sync state, and presentation preferences cannot be
/// written through this adapter.
final class WebCredentialStorage implements SecureStorage {
  WebCredentialStorage(this._store);

  static const allowedKeys = {
    PasswordlessIdentityService.sessionStorageKey,
    PasswordlessIdentityService.deviceIdStorageKey,
  };

  final BrowserKeyValueStore _store;
  String? _sessionInMemory;

  @override
  Future<void> delete(String key) async {
    final allowed = _allowed(key);
    if (allowed == PasswordlessIdentityService.sessionStorageKey) {
      _sessionInMemory = null;
    }
    _store.delete(allowed);
  }

  @override
  Future<String?> read(String key) async {
    final allowed = _allowed(key);
    if (allowed == PasswordlessIdentityService.sessionStorageKey) {
      return _sessionInMemory ?? _store.read(allowed);
    }
    return _store.read(allowed);
  }

  @override
  Future<void> write(String key, String value) async {
    final allowed = _allowed(key);
    if (allowed == PasswordlessIdentityService.sessionStorageKey) {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic> ||
          decoded['refresh_token'] is! String) {
        throw const FormatException('Invalid remembered session.');
      }
      _sessionInMemory = value;
      _store.write(
        allowed,
        jsonEncode({'refresh_token': decoded['refresh_token']}),
      );
      return;
    }
    _store.write(allowed, value);
  }

  String _allowed(String key) {
    if (!allowedKeys.contains(key)) {
      throw StateError('Browser storage is restricted to sign-in credentials.');
    }
    return key;
  }
}
