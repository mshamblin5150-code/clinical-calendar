import 'dart:convert';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_platform/src/synchronization/supabase_rpc_synchronization_transport.dart';
import 'package:clinical_calendar_sync/synchronization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _studentId = '00000000-0000-4000-8000-000000000001';
const _entityId = '00000000-0000-4000-8000-000000000002';

void main() {
  test('push sends the verified Supabase RPC envelope unchanged', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'accepted': true,
          'cursor': 12,
          'entity_type': 'preceptor',
          'entity_id': _entityId,
          'revision': 1,
        }),
        200,
      );
    });
    final transport = _transport(client);
    final result = await transport.push(_operation());

    expect(result.accepted, isTrue);
    expect(result.cursor, 12);
    expect(captured.url.path, '/rest/v1/rpc/apply_sync_operation');
    expect(captured.headers['apikey'], 'publishable-key');
    expect(captured.headers['authorization'], 'Bearer access-token');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['p_idempotency_key'], _id(11));
    expect(body['p_entity_type'], 'preceptor');
    expect(body['p_entity_id'], _entityId);
    expect(body['p_operation_type'], 'upsert');
    expect(body['p_base_revision'], 0);
    expect(
      (body['p_payload'] as Map<String, dynamic>)['student_id'],
      _studentId,
    );
  });

  test(
    'stable rejection and ordered pull rows decode without interpretation',
    () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        if (calls == 1) {
          return http.Response(
            jsonEncode({
              'accepted': false,
              'entity_type': 'preceptor',
              'entity_id': _entityId,
              'rejection': {'code': 'stale_revision', 'current_revision': 2},
            }),
            200,
          );
        }
        final requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        expect(requestBody, {'p_after_cursor': 7, 'p_limit': 100});
        return http.Response(
          jsonEncode([
            {
              'cursor': 8,
              'entity_type': 'preceptor',
              'entity_id': _entityId,
              'revision': 2,
              'operation_type': 'upsert',
              'payload': jsonDecode(_payload(revision: 2)),
            },
          ]),
          200,
        );
      });
      final transport = _transport(client);

      final rejection = await transport.push(_operation());
      expect(rejection.accepted, isFalse);
      expect(rejection.rejectionCode, 'stale_revision');
      expect(rejection.rejectionJson, contains('current_revision'));
      final changes = await transport.pull(afterCursor: 7, limit: 100);
      expect(changes.single.cursor, 8);
      expect(changes.single.revision, 2);
      expect(changes.single.payloadJson, contains('Preceptor'));
    },
  );

  test('authentication and transport failures are classified safely', () async {
    final unauthenticated = SupabaseRpcSynchronizationTransport(
      projectUri: Uri.parse('https://project.supabase.co'),
      publishableKey: 'publishable-key',
      accessTokenProvider: () async => null,
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    await expectLater(
      unauthenticated.push(_operation()),
      throwsA(
        isA<SynchronizationTransportException>()
            .having((error) => error.code, 'code', 'unauthenticated')
            .having((error) => error.offline, 'offline', isFalse),
      ),
    );

    final offline = _transport(
      MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      offline.pull(afterCursor: 0, limit: 100),
      throwsA(
        isA<SynchronizationTransportException>()
            .having((error) => error.code, 'code', 'network_unavailable')
            .having((error) => error.offline, 'offline', isTrue),
      ),
    );
  });
}

SupabaseRpcSynchronizationTransport _transport(http.Client client) =>
    SupabaseRpcSynchronizationTransport(
      projectUri: Uri.parse('https://project.supabase.co'),
      publishableKey: 'publishable-key',
      accessTokenProvider: () async => 'access-token',
      client: client,
    );

OutboxOperation _operation() => OutboxOperation(
  mutation: MutationToken(
    operationId: _id(10),
    idempotencyKey: _id(11),
    occurredAtUtc: DateTime.utc(2026, 8, 3, 12),
  ),
  studentId: _studentId,
  entityType: 'preceptor',
  entityId: _entityId,
  type: OutboxOperationType.upsert,
  baseRevision: 0,
  payloadJson: _payload(),
);

String _payload({int revision = 1}) => jsonEncode({
  'schema_version': 1,
  'entity_type': 'preceptor',
  'entity_id': _entityId,
  'student_id': _studentId,
  'revision': revision,
  'created_at_utc': '2026-08-03T12:00:00.000Z',
  'updated_at_utc': '2026-08-03T12:00:00.000Z',
  'deleted_at_utc': null,
  'value': {'name': 'Preceptor'},
});

String _id(int value) =>
    '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';
