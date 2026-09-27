import 'dart:async';

import 'package:clinical_calendar/browser_runtime_contracts.dart';
import 'package:clinical_calendar/config/app_environment.dart';
import 'package:clinical_calendar/main_web.dart' as web_app;
import 'package:clinical_calendar/web_device_descriptor.dart';
import 'package:clinical_calendar/web_credential_storage.dart';
import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:clinical_calendar_sync/clinical_calendar_sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  testWidgets(
    'a browser registers as a web Connected Device before the app starts',
    (tester) async {
      final storage = _Storage();
      final gateway = _Gateway();
      final localCopy = _WebLocalCopy();
      final descriptor = webDeviceDescriptor(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 '
        'Mobile/15E148 Safari/604.1',
      );

      await tester.pumpWidget(
        web_app.buildWebRoot(
          environment: const AppEnvironment(
            name: 'test',
            supabaseUrl: 'https://project.supabase.co',
            supabasePublishableKey: 'public-client-key',
          ),
          secureStorage: storage,
          identifiers: const _Identifiers(),
          clock: const _Clock(),
          identityGateway: gateway,
          currentDevice: descriptor,
          localCopy: localCopy,
          browserRuntime: _BrowserRuntime(),
          synchronizationTransport: _Transport(),
          retryScheduler: _RetryScheduler(),
          connectivitySource: _Connectivity(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('identity-email')),
        'student@example.com',
      );
      await tester.tap(find.byKey(const Key('send-identity-code')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('identity-otp')), '123456');
      final verify = find.byKey(const Key('verify-identity-code'));
      await tester.ensureVisible(verify);
      await tester.pump();
      await tester.tap(verify);
      for (var attempt = 0; attempt < 100; attempt++) {
        await tester.pump(const Duration(milliseconds: 20));
        if (find.byType(ClinicalCalendarApp).evaluate().isNotEmpty) break;
      }

      expect(gateway.registeredDescriptor?.name, 'Safari on iPhone');
      expect(gateway.registeredDescriptor?.platform, DevicePlatform.web);
      expect(gateway.registeredDeviceId, _deviceId);
      expect(find.byType(ClinicalCalendarApp), findsOneWidget);
      expect(
        storage.values.keys,
        containsAll({
          PasswordlessIdentityService.sessionStorageKey,
          PasswordlessIdentityService.deviceIdStorageKey,
        }),
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

final class _Storage implements SecureStorage {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

final class _WebLocalCopy implements LocalDeviceCopyController {
  bool removed = false;

  @override
  Future<LocalRemovalPreview> previewRemoval() async =>
      const LocalRemovalPreview(pendingChangeCount: 0);

  @override
  Future<void> removeLocalCopy() async => removed = true;
}

final class _BrowserRuntime implements BrowserRuntime {
  final _credentials = _BrowserStore();

  @override
  BrowserKeyValueStore get credentials => _credentials;

  @override
  UnsentChangesGuard createUnsentChangesGuard() => _Guard();

  @override
  String get deviceName => 'Safari on iPhone';

  @override
  String get timeZoneName => 'America/New_York';

  @override
  Future<CommonDatabase> openInMemorySqlite() async => sqlite3.openInMemory();
}

final class _BrowserStore implements BrowserKeyValueStore {
  final values = <String, String>{};

  @override
  void delete(String key) => values.remove(key);

  @override
  String? read(String key) => values[key];

  @override
  void write(String key, String value) => values[key] = value;
}

final class _Guard implements UnsentChangesGuard {
  @override
  Future<void> dispose() async {}

  @override
  void update(bool hasUnsentChanges) {}
}

final class _Transport implements SynchronizationTransport {
  @override
  Future<List<RemoteSynchronizationChange>> pull({
    required int afterCursor,
    required int limit,
  }) async => const [];

  @override
  Future<SynchronizationPushResult> push(OutboxOperation operation) async =>
      SynchronizationPushResult.accepted(
        cursor: 1,
        revision: operation.baseRevision + 1,
      );
}

final class _RetryScheduler implements SynchronizationRetryScheduler {
  @override
  void cancel() {}

  @override
  void schedule(DateTime atUtc, Future<void> Function() callback) {}
}

final class _Connectivity implements web_app.WebConnectivityStatusSource {
  @override
  Stream<bool> get changes => const Stream<bool>.empty();

  @override
  Future<bool> current() async => true;
}

final class _Gateway implements PasswordlessIdentityGateway {
  DeviceDescriptor? registeredDescriptor;
  String? registeredDeviceId;
  bool signedOut = false;

  @override
  Future<void> sendSignInCode(String email) async {}

  @override
  Future<IdentitySession> verifySignInCode(String email, String code) async =>
      _session;

  @override
  Future<IdentitySession> refreshSession(String refreshToken) async => _session;

  @override
  Future<bool> registerCurrentDevice({
    required String accessToken,
    required String deviceId,
    required DeviceDescriptor descriptor,
  }) async {
    registeredDescriptor = descriptor;
    registeredDeviceId = deviceId;
    return true;
  }

  @override
  Future<List<ConnectedDevice>> listConnectedDevices(
    String accessToken,
  ) async => [
    ConnectedDevice(
      id: registeredDeviceId!,
      name: registeredDescriptor!.name,
      platform: registeredDescriptor!.platform,
      isCurrent: true,
      isRevoked: false,
    ),
  ];

  @override
  Future<String> revokeConnectedDevice(
    String accessToken,
    String deviceId,
  ) async => 'revoked';

  @override
  Future<void> requestEmailChange(String accessToken, String newEmail) async {}

  @override
  Future<void> signOutCurrentSession(String accessToken) async {
    signedOut = true;
  }

  @override
  Future<bool> markCurrentDeviceSynchronized(String accessToken) async => true;

  @override
  Future<AccountErasureRequest> requestAccountErasure(
    String accessToken,
    AccountErasureBackupChoice backupChoice,
  ) async => const AccountErasureRequest(
    status: AccountErasureRequestStatus.backupCancelled,
  );

  @override
  Future<AccountErasureCancellationStatus> cancelPendingAccountErasure(
    String accessToken,
  ) async => AccountErasureCancellationStatus.notPending;
}

final class _Identifiers implements IdentifierGenerator {
  const _Identifiers();

  @override
  String nextIdentifier() => _deviceId;
}

final class _Clock implements Clock {
  const _Clock();

  @override
  DateTime nowUtc() => DateTime.utc(2026, 9, 27, 12);
}

final _session = IdentitySession(
  accessToken: 'access',
  refreshToken: 'refresh',
  studentId: _studentId,
  sessionId: _sessionId,
  email: 'student@example.com',
  expiresAtUtc: DateTime.utc(2026, 9, 27, 13),
);

const _studentId = '10000000-0000-4000-8000-000000000001';
const _sessionId = '20000000-0000-4000-8000-000000000001';
const _deviceId = '30000000-0000-4000-8000-000000000001';
