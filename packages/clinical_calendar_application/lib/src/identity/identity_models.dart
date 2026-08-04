enum DevicePlatform { windows, ios, android }

final class DeviceDescriptor {
  DeviceDescriptor({required String name, required this.platform})
    : name = _required(name, 'name');

  final String name;
  final DevicePlatform platform;
}

final class IdentitySession {
  IdentitySession({
    required String accessToken,
    required String refreshToken,
    required String studentId,
    required String sessionId,
    required String email,
    required DateTime expiresAtUtc,
  }) : accessToken = _required(accessToken, 'accessToken'),
       refreshToken = _required(refreshToken, 'refreshToken'),
       studentId = _uuid(studentId, 'studentId'),
       sessionId = _uuid(sessionId, 'sessionId'),
       email = _email(email),
       expiresAtUtc = expiresAtUtc.toUtc();

  final String accessToken;
  final String refreshToken;
  final String studentId;
  final String sessionId;
  final String email;
  final DateTime expiresAtUtc;
}

final class ConnectedDevice {
  ConnectedDevice({
    required String id,
    required String name,
    required this.platform,
    required this.isCurrent,
    required this.isRevoked,
    DateTime? lastSynchronizedAtUtc,
  }) : id = _uuid(id, 'id'),
       name = _required(name, 'name'),
       lastSynchronizedAtUtc = lastSynchronizedAtUtc?.toUtc();

  final String id;
  final String name;
  final DevicePlatform platform;
  final DateTime? lastSynchronizedAtUtc;
  final bool isCurrent;
  final bool isRevoked;
}

final class LocalRemovalPreview {
  const LocalRemovalPreview({
    required this.pendingChangeCount,
    this.oldestPendingAtUtc,
  });

  final int pendingChangeCount;
  final DateTime? oldestPendingAtUtc;

  bool get hasPendingChanges => pendingChangeCount > 0;
}

final class IdentityException implements Exception {
  const IdentityException(this.code, {this.offline = false});

  final String code;
  final bool offline;

  @override
  String toString() => 'IdentityException($code)';
}

String _required(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, name);
  return normalized;
}

String _email(String value) {
  final normalized = _required(value, 'email').toLowerCase();
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized)) {
    throw ArgumentError.value(value, 'email');
  }
  return normalized;
}

String _uuid(String value, String name) {
  final normalized = _required(value, name).toLowerCase();
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  ).hasMatch(normalized)) {
    throw ArgumentError.value(value, name);
  }
  return normalized;
}
