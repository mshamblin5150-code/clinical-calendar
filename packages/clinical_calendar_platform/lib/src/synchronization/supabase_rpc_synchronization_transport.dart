import 'dart:convert';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_sync/synchronization.dart';
import 'package:http/http.dart' as http;

typedef SynchronizationAccessTokenProvider = Future<String?> Function();

final class SupabaseRpcSynchronizationTransport
    implements SynchronizationTransport {
  SupabaseRpcSynchronizationTransport({
    required this._projectUri,
    required String publishableKey,
    required this._accessTokenProvider,
    Future<void> Function()? onSuccessfulServerAccess,
    http.Client? client,
  }) : _publishableKey = _required(publishableKey, 'publishableKey'),
       // ignore: prefer_initializing_formals, preserves the public name.
       _onSuccessfulServerAccess = onSuccessfulServerAccess,
       _client = client ?? http.Client();

  final Uri _projectUri;
  final String _publishableKey;
  final SynchronizationAccessTokenProvider _accessTokenProvider;
  final Future<void> Function()? _onSuccessfulServerAccess;
  final http.Client _client;

  @override
  Future<SynchronizationPushResult> push(OutboxOperation operation) async {
    final response = await _post('apply_sync_operation', {
      'p_idempotency_key': operation.mutation.idempotencyKey,
      'p_entity_type': operation.entityType,
      'p_entity_id': operation.entityId,
      'p_operation_type': _operationType(operation.type),
      'p_base_revision': operation.baseRevision,
      'p_payload': jsonDecode(operation.payloadJson),
    });
    if (response is! Map<String, dynamic> || response['accepted'] is! bool) {
      throw const SynchronizationTransportException(
        'invalid_push_response',
        offline: false,
      );
    }
    if (response['accepted'] == true) {
      final cursor = response['cursor'];
      final revision = response['revision'];
      if (cursor is! int || revision is! int) {
        throw const SynchronizationTransportException(
          'invalid_push_response',
          offline: false,
        );
      }
      return SynchronizationPushResult.accepted(
        cursor: cursor,
        revision: revision,
      );
    }
    final rejection = response['rejection'];
    if (rejection is! Map<String, dynamic> || rejection['code'] is! String) {
      throw const SynchronizationTransportException(
        'invalid_push_response',
        offline: false,
      );
    }
    if (rejection['code'] == 'revoked_device') {
      throw const SynchronizationTransportException(
        'unauthenticated',
        offline: false,
      );
    }
    return SynchronizationPushResult.rejected(
      code: rejection['code'] as String,
      rejectionJson: jsonEncode(rejection),
    );
  }

  @override
  Future<List<RemoteSynchronizationChange>> pull({
    required int afterCursor,
    required int limit,
  }) async {
    if (afterCursor < 0) {
      throw ArgumentError.value(afterCursor, 'afterCursor');
    }
    if (limit <= 0 || limit > 500) {
      throw ArgumentError.value(limit, 'limit', 'must be from 1 to 500');
    }
    final response = await _post('pull_changes_after', {
      'p_after_cursor': afterCursor,
      'p_limit': limit,
    });
    if (response is! List) {
      throw const SynchronizationTransportException(
        'invalid_pull_response',
        offline: false,
      );
    }
    try {
      return response
          .map((raw) {
            if (raw is! Map<String, dynamic> ||
                raw['payload'] is! Map<String, dynamic>) {
              throw const FormatException();
            }
            return RemoteSynchronizationChange(
              cursor: raw['cursor'] as int,
              entityType: raw['entity_type'] as String,
              entityId: raw['entity_id'] as String,
              revision: raw['revision'] as int,
              operationType: switch (raw['operation_type']) {
                'upsert' => OutboxOperationType.upsert,
                'delete' => OutboxOperationType.delete,
                'resolve_conflict' => OutboxOperationType.resolveConflict,
                _ => throw const FormatException(),
              },
              payloadJson: jsonEncode(raw['payload']),
            );
          })
          .toList(growable: false);
    } on Object catch (error) {
      throw SynchronizationTransportException(
        'invalid_pull_response',
        offline: false,
        cause: error,
      );
    }
  }

  Future<Object?> _post(String function, Map<String, Object?> body) async {
    final token = await _accessTokenProvider();
    if (token == null || token.trim().isEmpty) {
      throw const SynchronizationTransportException(
        'unauthenticated',
        offline: false,
      );
    }
    final endpoint = _projectUri.resolve('/rest/v1/rpc/$function');
    http.Response response;
    try {
      response = await _client.post(
        endpoint,
        headers: {
          'apikey': _publishableKey,
          'authorization': 'Bearer ${token.trim()}',
          'content-type': 'application/json',
        },
        body: jsonEncode(body),
      );
    } on http.ClientException catch (error) {
      throw SynchronizationTransportException(
        'network_unavailable',
        offline: true,
        cause: error,
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const SynchronizationTransportException(
        'unauthenticated',
        offline: false,
      );
    }
    if (response.statusCode == 429) {
      throw const SynchronizationTransportException(
        'rate_limited',
        offline: false,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SynchronizationTransportException(
        response.statusCode >= 500 ? 'server_unavailable' : 'invalid_request',
        offline: false,
      );
    }
    try {
      final decoded = jsonDecode(response.body);
      try {
        await _onSuccessfulServerAccess?.call();
      } on Object {
        // Last-sync display is best effort and cannot invalidate durable sync.
      }
      return decoded;
    } on Object catch (error) {
      throw SynchronizationTransportException(
        'invalid_rpc_response',
        offline: false,
        cause: error,
      );
    }
  }
}

String _operationType(OutboxOperationType type) => switch (type) {
  OutboxOperationType.upsert => 'upsert',
  OutboxOperationType.delete => 'delete',
  OutboxOperationType.resolveConflict => 'resolve_conflict',
};

String _required(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be empty');
  }
  return normalized;
}
