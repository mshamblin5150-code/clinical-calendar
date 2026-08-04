import 'dart:convert';

import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:clinical_calendar_platform/clinical_calendar_identity_platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test(
    'sends email OTP request without a password or privileged key',
    () async {
      late http.Request captured;
      final gateway = _gateway((request) async {
        captured = request;
        return http.Response('{}', 200);
      });

      await gateway.sendSignInCode('student@example.com');

      expect(captured.url.path, '/auth/v1/otp');
      expect(jsonDecode(captured.body), {
        'email': 'student@example.com',
        'create_user': true,
      });
      expect(captured.headers['apikey'], 'publishable-key');
      expect(captured.headers, isNot(contains('service_role')));
    },
  );

  test('expired OTP receives a stable application failure', () async {
    final gateway = _gateway(
      (_) async => http.Response(jsonEncode({'code': 'otp_expired'}), 403),
    );

    await expectLater(
      gateway.verifySignInCode('student@example.com', '123456'),
      throwsA(
        isA<IdentityException>().having((e) => e.code, 'code', 'expired_otp'),
      ),
    );
  });

  test(
    'refresh rotates tokens and preserves the session identity claim',
    () async {
      late http.Request captured;
      final gateway = _gateway((request) async {
        captured = request;
        return http.Response(jsonEncode(_sessionResponse()), 200);
      });

      final session = await gateway.refreshSession('old-refresh');

      expect(captured.url.queryParameters['grant_type'], 'refresh_token');
      expect(jsonDecode(captured.body), {'refresh_token': 'old-refresh'});
      expect(session.sessionId, _sessionId);
      expect(session.refreshToken, 'rotated-refresh');
    },
  );

  test(
    'lists connected devices without exposing another payload shape',
    () async {
      final gateway = _gateway(
        (request) async => http.Response(
          jsonEncode([
            {
              'device_id': _deviceId,
              'device_name': 'Windows laptop',
              'platform': 'windows',
              'last_synchronized_at_utc': '2026-08-03T12:00:00Z',
              'is_current': true,
              'is_revoked': false,
            },
          ]),
          200,
        ),
      );

      final devices = await gateway.listConnectedDevices('access');

      expect(devices.single.name, 'Windows laptop');
      expect(devices.single.isCurrent, isTrue);
    },
  );

  test('sign out uses local scope so other devices remain signed in', () async {
    final captured = <http.Request>[];
    final gateway = _gateway((request) async {
      captured.add(request);
      return request.url.path.endsWith('/deactivate_current_device')
          ? http.Response('true', 200)
          : http.Response('', 204);
    });

    await gateway.signOutCurrentSession('access');

    expect(captured.first.url.path, '/rest/v1/rpc/deactivate_current_device');
    expect(captured.last.url.path, '/auth/v1/logout');
    expect(captured.last.url.queryParameters['scope'], 'local');
  });
}

SupabasePasswordlessIdentityGateway _gateway(
  Future<http.Response> Function(http.Request request) handler,
) => SupabasePasswordlessIdentityGateway(
  projectUri: Uri.parse('https://example.supabase.co'),
  publishableKey: 'publishable-key',
  client: _Client(handler),
);

final class _Client extends http.BaseClient {
  _Client(this.handler);
  final Future<http.Response> Function(http.Request request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final concrete = request as http.Request;
    final response = await handler(concrete);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

Map<String, Object?> _sessionResponse() => {
  'access_token': _jwt(),
  'refresh_token': 'rotated-refresh',
  'expires_in': 3600,
  'user': {'id': _studentId, 'email': 'student@example.com'},
};

String _jwt() {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.${part({'sub': _studentId, 'session_id': _sessionId, 'exp': 2000000000})}.';
}

const _studentId = '10000000-0000-4000-8000-000000000001';
const _sessionId = '20000000-0000-4000-8000-000000000001';
const _deviceId = '30000000-0000-4000-8000-000000000001';
