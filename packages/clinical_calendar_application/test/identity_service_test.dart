import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:test/test.dart';

void main() {
  late _Storage storage;
  late _Gateway gateway;
  late PasswordlessIdentityService service;

  setUp(() {
    storage = _Storage();
    gateway = _Gateway();
    service = PasswordlessIdentityService(
      gateway: gateway,
      secureStorage: storage,
      identifiers: _Identifiers(),
      clock: _Clock(DateTime.utc(2026, 8, 3, 12)),
      currentDevice: DeviceDescriptor(
        name: 'Windows laptop',
        platform: DevicePlatform.windows,
      ),
      localCopy: _LocalCopy(),
    );
  });

  test(
    'verifies a six-digit OTP, registers the session, then stores it',
    () async {
      final session = await service.verifySignInCode(
        'Student@Example.com',
        '123456',
      );

      expect(session.studentId, _studentId);
      expect(gateway.verifiedEmail, 'student@example.com');
      expect(gateway.registeredDeviceId, _deviceId);
      expect(
        storage.values.keys,
        containsAll([
          PasswordlessIdentityService.deviceIdStorageKey,
          PasswordlessIdentityService.sessionStorageKey,
        ]),
      );
    },
  );

  test('rejects malformed OTP before network access', () async {
    await expectLater(
      service.verifySignInCode('student@example.com', '12 34'),
      throwsA(
        isA<IdentityException>().having((e) => e.code, 'code', 'invalid_otp'),
      ),
    );
    expect(gateway.verifiedEmail, isNull);
  });

  test(
    'offline launch restores expired credentials without network access',
    () async {
      await service.verifySignInCode('student@example.com', '123456');
      gateway.refreshFailure = const IdentityException(
        'network',
        offline: true,
      );

      final restored = await service.restoreForOfflineLaunch();

      expect(restored?.studentId, _studentId);
      expect(gateway.refreshCount, 0);
    },
  );

  test('expired session refresh rotates secure credentials', () async {
    await service.verifySignInCode('student@example.com', '123456');

    expect(await service.currentAccessToken(), 'refreshed-access');
    expect(gateway.refreshCount, 1);
    expect(
      storage.values[PasswordlessIdentityService.sessionStorageKey],
      contains('refreshed-access'),
    );
  });

  test('offline refresh preserves credentials for offline launch', () async {
    await service.verifySignInCode('student@example.com', '123456');
    gateway.refreshFailure = const IdentityException('network', offline: true);

    expect(await service.currentAccessToken(), isNull);
    expect(
      storage.values,
      contains(PasswordlessIdentityService.sessionStorageKey),
    );
  });

  test('revoked refresh clears unusable credentials', () async {
    await service.verifySignInCode('student@example.com', '123456');
    gateway.refreshFailure = const IdentityException('invalid_refresh_token');

    expect(await service.currentAccessToken(), isNull);
    expect(
      storage.values,
      isNot(contains(PasswordlessIdentityService.sessionStorageKey)),
    );
  });

  test('current device cannot be remotely revoked', () async {
    gateway.revokeResult = 'current_device';
    await service.verifySignInCode('student@example.com', '123456');

    await expectLater(
      service.revokeDevice(_deviceId),
      throwsA(
        isA<IdentityException>().having(
          (e) => e.code,
          'code',
          'current_device_requires_local_sign_out',
        ),
      ),
    );
  });

  test(
    'local removal requires confirmation and signs out only current session',
    () async {
      await service.verifySignInCode('student@example.com', '123456');
      await expectLater(
        service.signOutAndRemoveLocalCopy(confirmed: false),
        throwsA(isA<IdentityException>()),
      );

      await service.signOutAndRemoveLocalCopy(confirmed: true);

      expect(gateway.signedOut, isTrue);
      expect(
        storage.values,
        isNot(contains(PasswordlessIdentityService.sessionStorageKey)),
      );
    },
  );

  test(
    'offline sign-out still removes the explicitly confirmed local copy',
    () async {
      final localCopy = _LocalCopy();
      gateway.signOutFailure = const IdentityException(
        'network_unavailable',
        offline: true,
      );
      service = PasswordlessIdentityService(
        gateway: gateway,
        secureStorage: storage,
        identifiers: _Identifiers(),
        clock: _Clock(DateTime.utc(2026, 8, 3, 12)),
        currentDevice: DeviceDescriptor(
          name: 'Windows laptop',
          platform: DevicePlatform.windows,
        ),
        localCopy: localCopy,
      );
      await service.verifySignInCode('student@example.com', '123456');

      await service.signOutAndRemoveLocalCopy(confirmed: true);

      expect(localCopy.removed, isTrue);
      expect(
        storage.values,
        isNot(contains(PasswordlessIdentityService.sessionStorageKey)),
      );
    },
  );

  test(
    'account erasure requires a fresh OTP and clears revoked session',
    () async {
      gateway.erasureRequest = AccountErasureRequest(
        status: AccountErasureRequestStatus.pending,
        requestedAtUtc: DateTime.utc(2026, 8, 3, 12),
        purgeAfterUtc: DateTime.utc(2026, 9, 2, 12),
      );

      final result = await service.requestAccountErasure(
        email: 'Student@Example.com',
        code: '123456',
        backupChoice: AccountErasureBackupChoice.completed,
      );

      expect(result.status, AccountErasureRequestStatus.pending);
      expect(gateway.events, ['verify', 'register', 'request_erasure']);
      expect(gateway.erasureBackupChoice, AccountErasureBackupChoice.completed);
      expect(
        storage.values,
        isNot(contains(PasswordlessIdentityService.sessionStorageKey)),
      );
    },
  );

  test(
    'cancelling the backup leaves the fresh signed-in session intact',
    () async {
      gateway.erasureRequest = const AccountErasureRequest(
        status: AccountErasureRequestStatus.backupCancelled,
      );

      final result = await service.requestAccountErasure(
        email: 'student@example.com',
        code: '123456',
        backupChoice: AccountErasureBackupChoice.cancelled,
      );

      expect(result.status, AccountErasureRequestStatus.backupCancelled);
      expect(
        storage.values,
        contains(PasswordlessIdentityService.sessionStorageKey),
      );
    },
  );

  test(
    'grace cancellation occurs before the fresh device is rebound',
    () async {
      gateway.cancellationStatus = AccountErasureCancellationStatus.cancelled;

      final status = await service.cancelAccountErasure(
        email: 'student@example.com',
        code: '123456',
      );

      expect(status, AccountErasureCancellationStatus.cancelled);
      expect(gateway.events, ['verify', 'cancel_erasure', 'register']);
      expect(
        storage.values,
        contains(PasswordlessIdentityService.sessionStorageKey),
      );
    },
  );

  test('expired grace does not rebind or retain the fresh session', () async {
    gateway.cancellationStatus = AccountErasureCancellationStatus.graceExpired;

    final status = await service.cancelAccountErasure(
      email: 'student@example.com',
      code: '123456',
    );

    expect(status, AccountErasureCancellationStatus.graceExpired);
    expect(gateway.events, ['verify', 'cancel_erasure']);
    expect(
      storage.values,
      isNot(contains(PasswordlessIdentityService.sessionStorageKey)),
    );
  });
}

const _studentId = '10000000-0000-4000-8000-000000000001';
const _sessionId = '20000000-0000-4000-8000-000000000001';
const _deviceId = '30000000-0000-4000-8000-000000000001';

IdentitySession _session({
  String access = 'access',
  String refresh = 'refresh',
}) => IdentitySession(
  accessToken: access,
  refreshToken: refresh,
  studentId: _studentId,
  sessionId: _sessionId,
  email: 'student@example.com',
  expiresAtUtc: DateTime.utc(2026, 8, 3, 11),
);

final class _Gateway implements PasswordlessIdentityGateway {
  String? verifiedEmail;
  String? registeredDeviceId;
  int refreshCount = 0;
  IdentityException? refreshFailure;
  String revokeResult = 'revoked';
  bool signedOut = false;
  IdentityException? signOutFailure;
  final events = <String>[];
  AccountErasureRequest erasureRequest = const AccountErasureRequest(
    status: AccountErasureRequestStatus.backupCancelled,
  );
  AccountErasureBackupChoice? erasureBackupChoice;
  AccountErasureCancellationStatus cancellationStatus =
      AccountErasureCancellationStatus.notPending;

  @override
  Future<void> sendSignInCode(String email) async {}
  @override
  Future<IdentitySession> verifySignInCode(String email, String code) async {
    events.add('verify');
    verifiedEmail = email;
    return _session();
  }

  @override
  Future<IdentitySession> refreshSession(String refreshToken) async {
    refreshCount++;
    if (refreshFailure case final failure?) throw failure;
    return _session(access: 'refreshed-access', refresh: 'rotated-refresh');
  }

  @override
  Future<bool> registerCurrentDevice({
    required String accessToken,
    required String deviceId,
    required DeviceDescriptor descriptor,
  }) async {
    events.add('register');
    registeredDeviceId = deviceId;
    return true;
  }

  @override
  Future<List<ConnectedDevice>> listConnectedDevices(
    String accessToken,
  ) async => [];
  @override
  Future<String> revokeConnectedDevice(
    String accessToken,
    String deviceId,
  ) async => revokeResult;
  @override
  Future<void> requestEmailChange(String accessToken, String newEmail) async {}
  @override
  Future<void> signOutCurrentSession(String accessToken) async {
    if (signOutFailure case final failure?) throw failure;
    signedOut = true;
  }

  @override
  Future<bool> markCurrentDeviceSynchronized(String accessToken) async => true;

  @override
  Future<AccountErasureRequest> requestAccountErasure(
    String accessToken,
    AccountErasureBackupChoice backupChoice,
  ) async {
    events.add('request_erasure');
    erasureBackupChoice = backupChoice;
    return erasureRequest;
  }

  @override
  Future<AccountErasureCancellationStatus> cancelPendingAccountErasure(
    String accessToken,
  ) async {
    events.add('cancel_erasure');
    return cancellationStatus;
  }
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

final class _Identifiers implements IdentifierGenerator {
  @override
  String nextIdentifier() => _deviceId;
}

final class _Clock implements Clock {
  _Clock(this.value);
  final DateTime value;
  @override
  DateTime nowUtc() => value;
}

final class _LocalCopy implements LocalDeviceCopyController {
  bool removed = false;
  @override
  Future<LocalRemovalPreview> previewRemoval() async =>
      const LocalRemovalPreview(pendingChangeCount: 2);
  @override
  Future<void> removeLocalCopy() async => removed = true;
}
