import 'dart:async';
import 'dart:convert';

// Public constructor names describe capabilities; private field names do not.
// ignore_for_file: prefer_initializing_formals

import '../ports.dart';
import 'identity_models.dart';

abstract interface class PasswordlessIdentityGateway {
  Future<void> sendSignInCode(String email);

  Future<IdentitySession> verifySignInCode(String email, String code);

  Future<IdentitySession> refreshSession(String refreshToken);

  Future<bool> registerCurrentDevice({
    required String accessToken,
    required String deviceId,
    required DeviceDescriptor descriptor,
  });

  Future<List<ConnectedDevice>> listConnectedDevices(String accessToken);

  Future<String> revokeConnectedDevice(String accessToken, String deviceId);

  Future<void> requestEmailChange(String accessToken, String newEmail);

  Future<void> signOutCurrentSession(String accessToken);

  Future<bool> markCurrentDeviceSynchronized(String accessToken);

  Future<AccountErasureRequest> requestAccountErasure(
    String accessToken,
    AccountErasureBackupChoice backupChoice,
  );

  Future<AccountErasureCancellationStatus> cancelPendingAccountErasure(
    String accessToken,
  );
}

enum AccountErasureBackupChoice { completed, skipped, cancelled }

enum AccountErasureRequestStatus { pending, backupCancelled }

final class AccountErasureRequest {
  const AccountErasureRequest({
    required this.status,
    this.requestedAtUtc,
    this.purgeAfterUtc,
  });

  final AccountErasureRequestStatus status;
  final DateTime? requestedAtUtc;
  final DateTime? purgeAfterUtc;
}

enum AccountErasureCancellationStatus { cancelled, notPending, graceExpired }

abstract interface class LocalDeviceCopyController {
  Future<LocalRemovalPreview> previewRemoval();

  Future<void> removeLocalCopy();
}

final class PasswordlessIdentityService {
  PasswordlessIdentityService({
    required PasswordlessIdentityGateway gateway,
    required SecureStorage secureStorage,
    required IdentifierGenerator identifiers,
    required Clock clock,
    required DeviceDescriptor currentDevice,
    LocalDeviceCopyController? localCopy,
  }) : _gateway = gateway,
       _secureStorage = secureStorage,
       _identifiers = identifiers,
       _clock = clock,
       _currentDevice = currentDevice,
       _localCopy = localCopy;

  static const sessionStorageKey = 'clinical_calendar_auth_session_v1';
  static const deviceIdStorageKey = 'clinical_calendar_device_id_v1';

  final PasswordlessIdentityGateway _gateway;
  final SecureStorage _secureStorage;
  final IdentifierGenerator _identifiers;
  final Clock _clock;
  final DeviceDescriptor _currentDevice;
  final LocalDeviceCopyController? _localCopy;
  Future<IdentitySession?>? _refreshInFlight;

  Future<IdentitySession?> restoreForOfflineLaunch() async {
    final encoded = await _secureStorage.read(sessionStorageKey);
    if (encoded == null) return null;
    try {
      return _decodeSession(encoded);
    } on Object {
      await _secureStorage.delete(sessionStorageKey);
      return null;
    }
  }

  Future<void> sendSignInCode(String email) =>
      _gateway.sendSignInCode(email.trim().toLowerCase());

  Future<IdentitySession> verifySignInCode(String email, String code) async {
    final session = await _verifyFreshSession(email, code);
    await _register(session);
    await _store(session);
    return session;
  }

  /// Starts Delete Account and All Data after a genuinely new passwordless
  /// Auth session. Refreshing stored tokens is deliberately insufficient.
  Future<AccountErasureRequest> requestAccountErasure({
    required String email,
    required String code,
    required AccountErasureBackupChoice backupChoice,
  }) async {
    final session = await _verifyFreshSession(email, code);
    await _register(session);
    await _store(session);
    final request = await _gateway.requestAccountErasure(
      session.accessToken,
      backupChoice,
    );
    if (request.status == AccountErasureRequestStatus.pending) {
      // The backend has revoked every Connected Device. Retaining this session
      // locally would falsely present the app as signed in during grace.
      await _secureStorage.delete(sessionStorageKey);
    }
    return request;
  }

  /// Cancels a pending deletion with a newly issued Auth session, then binds
  /// the current installation again only when cancellation is still allowed.
  Future<AccountErasureCancellationStatus> cancelAccountErasure({
    required String email,
    required String code,
  }) async {
    final session = await _verifyFreshSession(email, code);
    final status = await _gateway.cancelPendingAccountErasure(
      session.accessToken,
    );
    if (status == AccountErasureCancellationStatus.graceExpired) {
      await _secureStorage.delete(sessionStorageKey);
      return status;
    }
    await _register(session);
    await _store(session);
    return status;
  }

  Future<IdentitySession> _verifyFreshSession(String email, String code) {
    final normalizedCode = code.trim();
    if (!RegExp(r'^\d{6,8}$').hasMatch(normalizedCode)) {
      throw const IdentityException('invalid_otp');
    }
    return _gateway.verifySignInCode(
      email.trim().toLowerCase(),
      normalizedCode,
    );
  }

  Future<void> _register(IdentitySession session) async {
    final deviceId = await _loadOrCreateDeviceId();
    final registered = await _gateway.registerCurrentDevice(
      accessToken: session.accessToken,
      deviceId: deviceId,
      descriptor: _currentDevice,
    );
    if (!registered) {
      throw const IdentityException('device_registration_failed');
    }
  }

  Future<String?> currentAccessToken() async {
    final session = await restoreForOfflineLaunch();
    if (session == null) return null;
    if (session.expiresAtUtc.isAfter(
      _clock.nowUtc().add(const Duration(minutes: 1)),
    )) {
      return session.accessToken;
    }
    final refreshed = await _refreshOnce(session.refreshToken);
    return refreshed?.accessToken;
  }

  Future<List<ConnectedDevice>> connectedDevices() async {
    final token = await _requiredAccessToken();
    return _gateway.listConnectedDevices(token);
  }

  Future<void> revokeDevice(String deviceId) async {
    final token = await _requiredAccessToken();
    final result = await _gateway.revokeConnectedDevice(token, deviceId);
    switch (result) {
      case 'revoked':
        return;
      case 'current_device':
        throw const IdentityException('current_device_requires_local_sign_out');
      case 'not_found':
        throw const IdentityException('device_not_found');
      default:
        throw const IdentityException('invalid_device_response');
    }
  }

  Future<void> requestEmailChange(String newEmail) async {
    final token = await _requiredAccessToken();
    await _gateway.requestEmailChange(token, newEmail.trim().toLowerCase());
  }

  Future<bool> markSynchronized() async {
    final token = await currentAccessToken();
    if (token == null) return false;
    return _gateway.markCurrentDeviceSynchronized(token);
  }

  Future<LocalRemovalPreview> previewLocalRemoval() async {
    final copy = _localCopy;
    if (copy == null) throw const IdentityException('local_copy_unavailable');
    return copy.previewRemoval();
  }

  Future<void> signOutAndRemoveLocalCopy({required bool confirmed}) async {
    if (!confirmed) throw const IdentityException('confirmation_required');
    final copy = _localCopy;
    if (copy == null) throw const IdentityException('local_copy_unavailable');
    final token = await _requiredAccessToken();
    try {
      await _gateway.signOutCurrentSession(token);
    } on IdentityException catch (error) {
      // Removing a device-local copy must remain possible offline. The remote
      // Auth session expires independently and can be revoked from another
      // Connected Device when connectivity returns.
      if (!error.offline) rethrow;
    }
    await copy.removeLocalCopy();
    await _secureStorage.delete(sessionStorageKey);
    await _secureStorage.delete(deviceIdStorageKey);
  }

  Future<String> _requiredAccessToken() async {
    final token = await currentAccessToken();
    if (token == null) throw const IdentityException('unauthenticated');
    return token;
  }

  Future<IdentitySession?> _refreshOnce(String refreshToken) {
    final existing = _refreshInFlight;
    if (existing != null) return existing;
    final future = _refresh(refreshToken);
    _refreshInFlight = future;
    return future.whenComplete(() => _refreshInFlight = null);
  }

  Future<IdentitySession?> _refresh(String refreshToken) async {
    try {
      final session = await _gateway.refreshSession(refreshToken);
      await _store(session);
      return session;
    } on IdentityException catch (error) {
      if (!error.offline) await _secureStorage.delete(sessionStorageKey);
      return null;
    }
  }

  Future<String> _loadOrCreateDeviceId() async {
    final stored = await _secureStorage.read(deviceIdStorageKey);
    if (stored != null) return stored;
    final created = _identifiers.nextIdentifier();
    await _secureStorage.write(deviceIdStorageKey, created);
    return created;
  }

  Future<void> _store(IdentitySession session) => _secureStorage.write(
    sessionStorageKey,
    jsonEncode({
      'access_token': session.accessToken,
      'refresh_token': session.refreshToken,
      'student_id': session.studentId,
      'session_id': session.sessionId,
      'email': session.email,
      'expires_at_utc': session.expiresAtUtc.toIso8601String(),
    }),
  );
}

IdentitySession _decodeSession(String encoded) {
  final value = jsonDecode(encoded);
  if (value is! Map<String, dynamic>) throw const FormatException();
  return IdentitySession(
    accessToken: value['access_token'] as String,
    refreshToken: value['refresh_token'] as String,
    studentId: value['student_id'] as String,
    sessionId: value['session_id'] as String,
    email: value['email'] as String,
    expiresAtUtc: DateTime.parse(value['expires_at_utc'] as String),
  );
}
