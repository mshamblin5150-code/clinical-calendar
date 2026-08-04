import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_identity_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('passwordless setup sends and verifies an emailed code', (
    tester,
  ) async {
    final gateway = _Gateway();
    final identity = _service(gateway);
    IdentitySession? signedIn;
    await tester.pumpWidget(
      MaterialApp(
        home: PasswordlessSignInSurface(
          identity: identity,
          onSignedIn: (value) async => signedIn = value,
        ),
      ),
    );

    expect(
      find.textContaining('No password or Google account'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('identity-email')),
      'student@example.com',
    );
    await tester.tap(find.byKey(const Key('send-identity-code')));
    await tester.pumpAndSettle();
    expect(gateway.codeEmail, 'student@example.com');

    await tester.enterText(find.byKey(const Key('identity-otp')), '123456');
    await tester.tap(find.byKey(const Key('verify-identity-code')));
    await tester.pumpAndSettle();
    expect(signedIn?.studentId, _studentId);
  });

  testWidgets('connected devices show state and truthful revocation warning', (
    tester,
  ) async {
    final gateway = _Gateway();
    final identity = _service(gateway);
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

    expect(find.text('Windows laptop (this device)'), findsOneWidget);
    expect(find.text('Android tablet'), findsOneWidget);
    await tester.tap(find.text('Revoke'));
    await tester.pumpAndSettle();
    expect(find.textContaining('cannot erase a copy'), findsOneWidget);
  });

  testWidgets('email change sends verification to the replacement address', (
    tester,
  ) async {
    final gateway = _Gateway();
    final identity = _service(gateway);
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

    await tester.tap(find.byKey(const Key('change-email-action')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('new-identity-email')),
      'replacement@example.com',
    );
    await tester.tap(find.byKey(const Key('request-email-change')));
    await tester.pumpAndSettle();

    expect(gateway.changedEmail, 'replacement@example.com');
    expect(
      find.textContaining('Verify the replacement address'),
      findsOneWidget,
    );
  });

  testWidgets(
    'local removal reports pending changes and requires confirmation',
    (tester) async {
      var removed = false;
      final identity = _service(_Gateway(), localCopy: _LocalCopy());
      await identity.verifySignInCode('student@example.com', '123456');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IdentityDevicesSurface(
              identity: identity,
              email: 'student@example.com',
              onLocalCopyRemoved: () async => removed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sign-out-remove-local-action')));
      await tester.pumpAndSettle();
      expect(find.textContaining('3 pending change'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('remove-local-copy')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('confirm-local-removal')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('remove-local-copy')));
      await tester.pumpAndSettle();
      expect(removed, isTrue);
    },
  );
}

PasswordlessIdentityService _service(
  _Gateway gateway, {
  LocalDeviceCopyController? localCopy,
}) => PasswordlessIdentityService(
  gateway: gateway,
  secureStorage: _Storage(),
  identifiers: _Identifiers(),
  clock: _Clock(),
  currentDevice: DeviceDescriptor(
    name: 'Windows laptop',
    platform: DevicePlatform.windows,
  ),
  localCopy: localCopy ?? _LocalCopy(),
);

final class _Gateway implements PasswordlessIdentityGateway {
  String? codeEmail;
  String? changedEmail;
  @override
  Future<void> sendSignInCode(String email) async => codeEmail = email;
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
  }) async => true;
  @override
  Future<List<ConnectedDevice>> listConnectedDevices(
    String accessToken,
  ) async => [
    ConnectedDevice(
      id: _deviceId,
      name: 'Windows laptop',
      platform: DevicePlatform.windows,
      isCurrent: true,
      isRevoked: false,
    ),
    ConnectedDevice(
      id: _otherDeviceId,
      name: 'Android tablet',
      platform: DevicePlatform.android,
      isCurrent: false,
      isRevoked: false,
    ),
  ];
  @override
  Future<String> revokeConnectedDevice(
    String accessToken,
    String deviceId,
  ) async => 'revoked';
  @override
  Future<void> requestEmailChange(String accessToken, String newEmail) async {
    changedEmail = newEmail;
  }

  @override
  Future<void> signOutCurrentSession(String accessToken) async {}
  @override
  Future<bool> markCurrentDeviceSynchronized(String accessToken) async => true;
}

final class _LocalCopy implements LocalDeviceCopyController {
  @override
  Future<LocalRemovalPreview> previewRemoval() async =>
      const LocalRemovalPreview(pendingChangeCount: 3);
  @override
  Future<void> removeLocalCopy() async {}
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
  DateTime nowUtc() => DateTime.utc(2026, 8, 3, 12);
}

final _session = IdentitySession(
  accessToken: 'access',
  refreshToken: 'refresh',
  studentId: _studentId,
  sessionId: _sessionId,
  email: 'student@example.com',
  expiresAtUtc: DateTime.utc(2026, 8, 3, 13),
);

const _studentId = '10000000-0000-4000-8000-000000000001';
const _sessionId = '20000000-0000-4000-8000-000000000001';
const _deviceId = '30000000-0000-4000-8000-000000000001';
const _otherDeviceId = '30000000-0000-4000-8000-000000000002';
