import 'dart:convert';

import 'package:clinical_calendar/web_credential_storage.dart';
import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web persistence accepts only the session and device id', () async {
    final browser = _MemoryBrowserStore();
    final storage = WebCredentialStorage(browser);

    await storage.write(
      PasswordlessIdentityService.sessionStorageKey,
      jsonEncode({
        'access_token': 'access',
        'refresh_token': 'refresh',
        'student_id': 'student',
        'session_id': 'session',
        'email': 'student@example.com',
        'expires_at_utc': '2026-09-27T13:00:00.000Z',
      }),
    );
    await storage.write(
      PasswordlessIdentityService.deviceIdStorageKey,
      'connected-device',
    );

    expect(
      browser.values.keys,
      unorderedEquals(WebCredentialStorage.allowedKeys),
    );
    expect(
      jsonDecode(
        browser.values[PasswordlessIdentityService.sessionStorageKey]!,
      ),
      {'refresh_token': 'refresh'},
    );
    expect(
      jsonDecode(
        (await WebCredentialStorage(
          browser,
        ).read(PasswordlessIdentityService.sessionStorageKey))!,
      ),
      {'refresh_token': 'refresh'},
    );
    await expectLater(
      storage.write('clinical_calendar_student_owner_id_v1', 'calendar-owner'),
      throwsStateError,
    );
    expect(
      browser.values.keys,
      unorderedEquals(WebCredentialStorage.allowedKeys),
    );
  });
}

final class _MemoryBrowserStore implements BrowserKeyValueStore {
  final values = <String, String>{};

  @override
  void delete(String key) => values.remove(key);

  @override
  String? read(String key) => values[key];

  @override
  void write(String key, String value) => values[key] = value;
}
