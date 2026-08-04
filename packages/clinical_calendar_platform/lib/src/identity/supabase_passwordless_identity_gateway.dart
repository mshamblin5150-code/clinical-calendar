import 'dart:convert';

import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:http/http.dart' as http;

final class SupabasePasswordlessIdentityGateway
    implements PasswordlessIdentityGateway {
  SupabasePasswordlessIdentityGateway({
    required Uri projectUri,
    required String publishableKey,
    http.Client? client,
  }) : _projectUri = _validatedProjectUri(projectUri),
       _publishableKey = _required(publishableKey, 'publishableKey'),
       _client = client ?? http.Client();

  final Uri _projectUri;
  final String _publishableKey;
  final http.Client _client;

  @override
  Future<void> sendSignInCode(String email) async {
    await _request(
      'POST',
      '/auth/v1/otp',
      body: {'email': email, 'create_user': true},
    );
  }

  @override
  Future<IdentitySession> verifySignInCode(String email, String code) async =>
      _sessionFrom(
        await _request(
          'POST',
          '/auth/v1/verify',
          body: {'type': 'email', 'email': email, 'token': code},
        ),
      );

  @override
  Future<IdentitySession> refreshSession(String refreshToken) async =>
      _sessionFrom(
        await _request(
          'POST',
          '/auth/v1/token',
          query: {'grant_type': 'refresh_token'},
          body: {'refresh_token': refreshToken},
        ),
      );

  @override
  Future<bool> registerCurrentDevice({
    required String accessToken,
    required String deviceId,
    required DeviceDescriptor descriptor,
  }) async =>
      await _rpc(
        'register_current_device',
        accessToken,
        body: {
          'p_device_id': deviceId,
          'p_device_name': descriptor.name,
          'p_platform': descriptor.platform.name,
        },
      ) ==
      true;

  @override
  Future<List<ConnectedDevice>> listConnectedDevices(String accessToken) async {
    final response = await _rpc(
      'list_connected_devices',
      accessToken,
      body: const {},
    );
    if (response is! List) {
      throw const IdentityException('invalid_device_response');
    }
    try {
      return response
          .map((value) {
            final row = value as Map<String, dynamic>;
            return ConnectedDevice(
              id: row['device_id'] as String,
              name: row['device_name'] as String,
              platform: DevicePlatform.values.byName(row['platform'] as String),
              lastSynchronizedAtUtc: row['last_synchronized_at_utc'] == null
                  ? null
                  : DateTime.parse(row['last_synchronized_at_utc'] as String),
              isCurrent: row['is_current'] as bool,
              isRevoked: row['is_revoked'] as bool,
            );
          })
          .toList(growable: false);
    } on Object {
      throw const IdentityException('invalid_device_response');
    }
  }

  @override
  Future<String> revokeConnectedDevice(
    String accessToken,
    String deviceId,
  ) async {
    final response = await _rpc(
      'revoke_connected_device',
      accessToken,
      body: {'p_device_id': deviceId},
    );
    if (response is! String) {
      throw const IdentityException('invalid_device_response');
    }
    return response;
  }

  @override
  Future<void> requestEmailChange(String accessToken, String newEmail) async {
    await _request(
      'PUT',
      '/auth/v1/user',
      accessToken: accessToken,
      body: {'email': newEmail},
    );
  }

  @override
  Future<void> signOutCurrentSession(String accessToken) async {
    final deactivated = await _rpc(
      'deactivate_current_device',
      accessToken,
      body: const {},
    );
    if (deactivated != true) {
      throw const IdentityException('device_deactivation_failed');
    }
    await _request(
      'POST',
      '/auth/v1/logout',
      query: {'scope': 'local'},
      accessToken: accessToken,
    );
  }

  @override
  Future<bool> markCurrentDeviceSynchronized(String accessToken) async =>
      await _rpc(
        'mark_current_device_synchronized',
        accessToken,
        body: const {},
      ) ==
      true;

  @override
  Future<AccountErasureRequest> requestAccountErasure(
    String accessToken,
    AccountErasureBackupChoice backupChoice,
  ) async {
    final response = await _rpc(
      'request_account_erasure',
      accessToken,
      body: {'p_backup_choice': _backupChoiceName(backupChoice)},
    );
    if (response is! Map<String, dynamic>) {
      throw const IdentityException('invalid_account_erasure_response');
    }
    final status = response['status'];
    if (status == 'backup_cancelled') {
      return const AccountErasureRequest(
        status: AccountErasureRequestStatus.backupCancelled,
      );
    }
    if (status != 'pending') {
      throw IdentityException(
        status is String ? status : 'invalid_account_erasure_response',
      );
    }
    try {
      return AccountErasureRequest(
        status: AccountErasureRequestStatus.pending,
        requestedAtUtc: DateTime.parse(
          response['requested_at_utc'] as String,
        ).toUtc(),
        purgeAfterUtc: DateTime.parse(
          response['purge_after_utc'] as String,
        ).toUtc(),
      );
    } on Object {
      throw const IdentityException('invalid_account_erasure_response');
    }
  }

  @override
  Future<AccountErasureCancellationStatus> cancelPendingAccountErasure(
    String accessToken,
  ) async {
    final response = await _rpc(
      'cancel_account_erasure',
      accessToken,
      body: const {},
    );
    return switch (response) {
      'cancelled' => AccountErasureCancellationStatus.cancelled,
      'not_pending' => AccountErasureCancellationStatus.notPending,
      'grace_expired' => AccountErasureCancellationStatus.graceExpired,
      final String status => throw IdentityException(status),
      _ => throw const IdentityException('invalid_account_erasure_response'),
    };
  }

  Future<Object?> _rpc(
    String function,
    String accessToken, {
    required Map<String, Object?> body,
  }) => _request(
    'POST',
    '/rest/v1/rpc/$function',
    accessToken: accessToken,
    body: body,
  );

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, String> query = const {},
    String? accessToken,
    Map<String, Object?>? body,
  }) async {
    final endpoint = _projectUri.resolve(path).replace(queryParameters: query);
    final request = http.Request(method, endpoint)
      ..headers.addAll({
        'apikey': _publishableKey,
        'content-type': 'application/json',
        if (accessToken != null) 'authorization': 'Bearer $accessToken',
      });
    if (body != null) request.body = jsonEncode(body);

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(request);
    } on http.ClientException {
      throw const IdentityException('network_unavailable', offline: true);
    }
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _failure(response);
    }
    if (response.body.trim().isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } on Object {
      throw const IdentityException('invalid_server_response');
    }
  }
}

String _backupChoiceName(AccountErasureBackupChoice value) => switch (value) {
  AccountErasureBackupChoice.completed => 'completed',
  AccountErasureBackupChoice.skipped => 'skipped',
  AccountErasureBackupChoice.cancelled => 'cancelled',
};

IdentitySession _sessionFrom(Object? response) {
  if (response is! Map<String, dynamic>) {
    throw const IdentityException('invalid_session_response');
  }
  try {
    final accessToken = response['access_token'] as String;
    final refreshToken = response['refresh_token'] as String;
    final user = response['user'] as Map<String, dynamic>;
    final claims = _jwtClaims(accessToken);
    if (claims['sub'] != user['id']) {
      throw const IdentityException('invalid_session_response');
    }
    final expiresIn = response['expires_in'];
    final expiresAt = claims['exp'] is int
        ? DateTime.fromMillisecondsSinceEpoch(
            (claims['exp'] as int) * 1000,
            isUtc: true,
          )
        : DateTime.now().toUtc().add(Duration(seconds: expiresIn as int));
    return IdentitySession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      studentId: user['id'] as String,
      sessionId: claims['session_id'] as String,
      email: user['email'] as String,
      expiresAtUtc: expiresAt,
    );
  } on IdentityException {
    rethrow;
  } on Object {
    throw const IdentityException('invalid_session_response');
  }
}

Map<String, dynamic> _jwtClaims(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw const IdentityException('invalid_session_response');
  }
  try {
    return jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        )
        as Map<String, dynamic>;
  } on Object {
    throw const IdentityException('invalid_session_response');
  }
}

IdentityException _failure(http.Response response) {
  String? code;
  try {
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) {
      code = (body['code'] ?? body['error_code'] ?? body['msg'])?.toString();
    }
  } on Object {
    // Status mapping below remains intentionally free of response contents.
  }
  if (code == 'otp_expired' || code == 'expired_token') {
    return const IdentityException('expired_otp');
  }
  if (response.statusCode == 429) {
    return const IdentityException('rate_limited');
  }
  if (response.statusCode == 401 || response.statusCode == 403) {
    return const IdentityException('unauthenticated');
  }
  if (response.statusCode >= 500) {
    return const IdentityException('server_unavailable', offline: true);
  }
  return IdentityException(code ?? 'invalid_request');
}

String _required(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, name);
  return normalized;
}

Uri _validatedProjectUri(Uri value) {
  if (!value.hasScheme || value.host.isEmpty) {
    throw ArgumentError.value(value, 'projectUri');
  }
  return value;
}
