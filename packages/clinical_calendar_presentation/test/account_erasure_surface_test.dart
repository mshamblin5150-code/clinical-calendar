import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:clinical_calendar_presentation/src/identity/account_erasure_surface.dart';
import 'package:clinical_calendar_presentation/src/identity/identity_devices_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cancelled backup choice never requests deletion', (
    tester,
  ) async {
    final gateway = _Gateway();
    await _pump(tester, gateway: gateway);

    await tester.tap(find.byKey(const Key('begin-account-erasure')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cancel-account-erasure')));
    await tester.pumpAndSettle();

    expect(gateway.erasureRequests, 0);
    expect(gateway.sentCodes, 0);
    expect(find.text('Deletion pending'), findsNothing);
    expect(find.byKey(const Key('begin-account-erasure')), findsOneWidget);
  });

  testWidgets('failed backup neither advances nor claims deletion success', (
    tester,
  ) async {
    final gateway = _Gateway();
    String? receivedPassphrase;
    await _pump(
      tester,
      gateway: gateway,
      createBackup: (passphrase) async {
        receivedPassphrase = passphrase;
        return false;
      },
    );

    await tester.tap(find.byKey(const Key('begin-account-erasure')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-account-backup-first')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('erasure-backup-passphrase')),
      'short',
    );
    await tester.enterText(
      find.byKey(const Key('erasure-backup-confirmation')),
      'short',
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('confirm-erasure-backup-passphrase')),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(
      find.byKey(const Key('erasure-backup-passphrase')),
      'correct horse battery',
    );
    await tester.enterText(
      find.byKey(const Key('erasure-backup-confirmation')),
      'correct horse battery',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('confirm-erasure-backup-passphrase')),
    );
    await tester.pumpAndSettle();

    expect(gateway.erasureRequests, 0);
    expect(gateway.sentCodes, 0);
    expect(receivedPassphrase, 'correct horse battery');
    expect(find.textContaining('deletion was not requested'), findsOneWidget);
    expect(find.byKey(const Key('begin-account-erasure')), findsOneWidget);
  });

  testWidgets(
    'successful encrypted backup advances without retaining passphrase',
    (tester) async {
      final gateway = _Gateway();
      await _pump(
        tester,
        gateway: gateway,
        createBackup: (passphrase) async => passphrase == 'twelve characters',
      );

      await tester.tap(find.byKey(const Key('begin-account-erasure')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-account-backup-first')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('erasure-backup-passphrase')),
        'twelve characters',
      );
      await tester.enterText(
        find.byKey(const Key('erasure-backup-confirmation')),
        'twelve characters',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('confirm-erasure-backup-passphrase')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('send-erasure-code')), findsOneWidget);
      expect(find.text('twelve characters'), findsNothing);
      expect(gateway.erasureRequests, 0);
    },
  );

  testWidgets(
    'fresh OTP requests deletion, shows purge truth, and fresh OTP cancels',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gateway = _Gateway();
      var requested = false;
      var cancelled = false;
      await _pump(
        tester,
        gateway: gateway,
        onRequested: (_) => requested = true,
        onCancelled: () => cancelled = true,
      );

      await tester.ensureVisible(
        find.byKey(const Key('begin-account-erasure')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('begin-account-erasure')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('continue-without-account-backup')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('send-erasure-code')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('send-erasure-code')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('account-erasure-otp')),
        '123456',
      );
      await tester.ensureVisible(
        find.byKey(const Key('confirm-account-erasure')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-account-erasure')));
      await tester.pumpAndSettle();

      expect(gateway.erasureRequests, 1);
      expect(gateway.backupChoice, AccountErasureBackupChoice.skipped);
      expect(requested, isTrue);
      expect(find.text('Purge date: 2026-09-03'), findsOneWidget);
      expect(
        find.textContaining('Every Connected Device is revoked'),
        findsOneWidget,
      );
      expect(find.textContaining('cannot be remotely erased'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('send-cancel-erasure-code')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('send-cancel-erasure-code')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('account-erasure-otp')),
        '654321',
      );
      await tester.ensureVisible(
        find.byKey(const Key('confirm-cancel-erasure')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-cancel-erasure')));
      await tester.pumpAndSettle();

      expect(gateway.sentCodes, 2);
      expect(gateway.verifiedCodes, ['123456', '654321']);
      expect(gateway.cancellations, 1);
      expect(cancelled, isTrue);
      expect(find.text('Account deletion cancelled'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pending grace starts at fresh-OTP cancellation', (tester) async {
    final gateway = _Gateway();
    await _pump(tester, gateway: gateway, pendingRequest: _pendingRequest);

    expect(find.text('Deletion pending'), findsOneWidget);
    expect(find.text('Purge date: 2026-09-03'), findsOneWidget);
    expect(find.byKey(const Key('send-cancel-erasure-code')), findsOneWidget);
    expect(find.byKey(const Key('begin-account-erasure')), findsNothing);
  });

  testWidgets('Connected Devices opens the distinct guarded deletion surface', (
    tester,
  ) async {
    final gateway = _Gateway();
    final identity = _identity(gateway);
    await identity.verifySignInCode('student@example.com', '123456');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IdentityDevicesSurface(
            identity: identity,
            email: 'student@example.com',
            onLocalCopyRemoved: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('delete-account-all-data-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('account-erasure-surface')), findsOneWidget);
    expect(find.text('This is not Sign Out'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required _Gateway gateway,
  Future<bool> Function(String passphrase)? createBackup,
  AccountErasureRequest? pendingRequest,
  ValueChanged<AccountErasureRequest>? onRequested,
  VoidCallback? onCancelled,
}) async {
  final identity = _identity(gateway);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AccountErasureSurface(
          identity: identity,
          email: 'student@example.com',
          createBackup: createBackup,
          pendingRequest: pendingRequest,
          onErasureRequested: onRequested,
          onErasureCancelled: onCancelled,
          onClose: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

PasswordlessIdentityService _identity(_Gateway gateway) =>
    PasswordlessIdentityService(
      gateway: gateway,
      secureStorage: _Storage(),
      identifiers: _Identifiers(),
      clock: _Clock(),
      currentDevice: DeviceDescriptor(
        name: 'Windows laptop',
        platform: DevicePlatform.windows,
      ),
    );

final class _Gateway implements PasswordlessIdentityGateway {
  int sentCodes = 0;
  final verifiedCodes = <String>[];
  int erasureRequests = 0;
  int cancellations = 0;
  AccountErasureBackupChoice? backupChoice;

  @override
  Future<void> sendSignInCode(String email) async => sentCodes++;

  @override
  Future<IdentitySession> verifySignInCode(String email, String code) async {
    verifiedCodes.add(code);
    return IdentitySession(
      accessToken: 'fresh-access',
      refreshToken: 'fresh-refresh',
      studentId: _studentId,
      sessionId: _sessionId,
      email: email,
      expiresAtUtc: DateTime.utc(2026, 8, 4, 13),
    );
  }

  @override
  Future<bool> registerCurrentDevice({
    required String accessToken,
    required String deviceId,
    required DeviceDescriptor descriptor,
  }) async => true;

  @override
  Future<AccountErasureRequest> requestAccountErasure(
    String accessToken,
    AccountErasureBackupChoice backupChoice,
  ) async {
    erasureRequests++;
    this.backupChoice = backupChoice;
    return _pendingRequest;
  }

  @override
  Future<AccountErasureCancellationStatus> cancelPendingAccountErasure(
    String accessToken,
  ) async {
    cancellations++;
    return AccountErasureCancellationStatus.cancelled;
  }

  @override
  Future<IdentitySession> refreshSession(String refreshToken) async =>
      throw UnimplementedError();
  @override
  Future<List<ConnectedDevice>> listConnectedDevices(
    String accessToken,
  ) async => const [];
  @override
  Future<bool> markCurrentDeviceSynchronized(String accessToken) async => true;
  @override
  Future<void> requestEmailChange(String accessToken, String newEmail) async {}
  @override
  Future<String> revokeConnectedDevice(
    String accessToken,
    String deviceId,
  ) async => 'revoked';
  @override
  Future<void> signOutCurrentSession(String accessToken) async {}
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
  @override
  DateTime nowUtc() => DateTime.utc(2026, 8, 4, 12);
}

final _pendingRequest = AccountErasureRequest(
  status: AccountErasureRequestStatus.pending,
  requestedAtUtc: DateTime.utc(2026, 8, 4, 12),
  purgeAfterUtc: DateTime.utc(2026, 9, 3, 12),
);

const _studentId = '10000000-0000-4000-8000-000000000001';
const _sessionId = '20000000-0000-4000-8000-000000000001';
const _deviceId = '30000000-0000-4000-8000-000000000001';
