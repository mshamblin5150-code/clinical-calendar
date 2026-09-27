import 'dart:convert';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:http/http.dart' as http;

typedef TicketAccessTokenProvider = Future<String?> Function();

final class SupabaseTicketGateway implements TicketGateway {
  SupabaseTicketGateway({
    required Uri projectUri,
    required String publishableKey,
    required TicketAccessTokenProvider accessTokenProvider,
    http.Client? client,
  }) : _projectUri = _validatedProjectUri(projectUri),
       _publishableKey = _required(publishableKey, 'publishableKey'),
       // ignore: prefer_initializing_formals, preserves the public name.
       _accessTokenProvider = accessTokenProvider,
       _client = client ?? http.Client();

  final Uri _projectUri;
  final String _publishableKey;
  final TicketAccessTokenProvider _accessTokenProvider;
  final http.Client _client;

  @override
  Future<void> putIn({
    required TicketKind kind,
    required String text,
    required TicketContext context,
  }) async {
    try {
      await _rpc('put_in_ticket', {
        'p_kind': kind.databaseValue,
        'p_text': text,
        'p_screen_context': context.screen,
        'p_build_context': context.build,
        'p_device_context': context.device,
        'p_platform_context': context.platform,
        'p_context_captured_at': context.capturedAtUtc
            .toUtc()
            .toIso8601String(),
      });
    } on _TicketServerFailure catch (error) {
      final refusal = switch (error.code) {
        'P2851' => TicketSubmissionRefusal.rateLimited,
        'P2852' => TicketSubmissionRefusal.textInvalid,
        'P2853' => TicketSubmissionRefusal.contextIncomplete,
        _ => null,
      };
      if (refusal != null) throw TicketSubmissionRejected(refusal);
      rethrow;
    }
  }

  @override
  Future<bool> hasMaintainerGrant() async {
    final response = await _rpc('has_ticket_maintainer_grant', const {});
    if (response is! bool) throw const TicketUnavailable();
    return response;
  }

  @override
  Future<List<Ticket>> readMine() => _readTickets();

  @override
  Future<List<Ticket>> readForMaintainer() => _readTickets();

  @override
  Future<Ticket> openForMaintainer(String ticketId) async {
    try {
      final response = await _rpc('open_ticket_for_maintainer', {
        'p_ticket_id': ticketId,
      });
      if (response is! Map<String, dynamic>) {
        throw const TicketUnavailable();
      }
      return _ticket(response);
    } on _TicketServerFailure catch (error) {
      if (error.code == 'P2854') throw const TicketUnavailable();
      rethrow;
    }
  }

  @override
  Future<Ticket> openForSender(String ticketId) async {
    try {
      final response = await _rpc('open_ticket_for_sender', {
        'p_ticket_id': ticketId,
      });
      if (response is! Map<String, dynamic>) {
        throw const TicketUnavailable();
      }
      return _ticket(response);
    } on _TicketServerFailure catch (error) {
      if (error.code == 'P2860') throw const TicketUnavailable();
      rethrow;
    }
  }

  @override
  Future<Ticket> close(
    String ticketId, {
    required TicketStatus outcome,
    required String reason,
  }) => _mutate('close_ticket', {
    'p_ticket_id': ticketId,
    'p_outcome': outcome.databaseValue,
    'p_reason': reason,
  });

  @override
  Future<Ticket> reopen(String ticketId, {required String note}) =>
      _mutate('reopen_ticket', {'p_ticket_id': ticketId, 'p_note': note});

  Future<Ticket> _mutate(String function, Map<String, Object?> body) async {
    try {
      final response = await _rpc(function, body);
      if (response is! Map<String, dynamic>) {
        throw const TicketUnavailable();
      }
      return _ticket(response);
    } on _TicketServerFailure catch (error) {
      final refusal = switch (error.code) {
        'P2855' => TicketMutationRefusal.closingReasonRequired,
        'P2856' => TicketMutationRefusal.cannotClose,
        'P2857' => TicketMutationRefusal.reopeningNoteRequired,
        'P2858' => TicketMutationRefusal.cannotReopen,
        'P2859' => TicketMutationRefusal.reopenExpired,
        _ => null,
      };
      if (refusal != null) throw TicketMutationRejected(refusal);
      rethrow;
    }
  }

  Future<List<Ticket>> _readTickets() async {
    const fields =
        'id,sender_id,kind,text,state,screen_context,build_context,'
        'device_context,platform_context,context_captured_at,created_at,seen_at,'
        'close_reason,closed_at,reopened_at,reopen_note';
    final response = await _request(
      'GET',
      '/rest/v1/tickets',
      query: {'select': fields, 'order': 'created_at.desc'},
    );
    if (response is! List) throw const TicketUnavailable();
    try {
      return [for (final row in response) _ticket(row as Map<String, dynamic>)];
    } on Object {
      throw const TicketUnavailable();
    }
  }

  Future<Object?> _rpc(String function, Map<String, Object?> body) =>
      _request('POST', '/rest/v1/rpc/$function', body: body);

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, String> query = const {},
    Map<String, Object?>? body,
  }) async {
    final accessToken = await _accessTokenProvider();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw const TicketAccessRejected();
    }
    final endpoint = _projectUri.resolve(path).replace(queryParameters: query);
    final request = http.Request(method, endpoint)
      ..headers.addAll({
        'apikey': _publishableKey,
        'authorization': 'Bearer ${accessToken.trim()}',
        'content-type': 'application/json',
      });
    if (body != null) request.body = jsonEncode(body);

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(request);
    } on http.ClientException {
      throw const TicketUnavailable();
    }
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const TicketAccessRejected();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _serverFailure(response.body);
    }
    if (response.body.trim().isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } on Object {
      throw const TicketUnavailable();
    }
  }
}

Ticket _ticket(Map<String, dynamic> row) => Ticket(
  id: row['id'] as String,
  senderId: row['sender_id'] as String,
  kind: TicketKind.fromDatabase(row['kind'] as String),
  text: row['text'] as String,
  status: TicketStatus.fromDatabase(row['state'] as String),
  context: TicketContext(
    screen: row['screen_context'] as String,
    build: row['build_context'] as String,
    device: row['device_context'] as String,
    platform: row['platform_context'] as String,
    capturedAtUtc: DateTime.parse(row['context_captured_at'] as String).toUtc(),
  ),
  createdAtUtc: DateTime.parse(row['created_at'] as String).toUtc(),
  seenAtUtc: row['seen_at'] == null
      ? null
      : DateTime.parse(row['seen_at'] as String).toUtc(),
  closeReason: row['close_reason'] as String?,
  closedAtUtc: row['closed_at'] == null
      ? null
      : DateTime.parse(row['closed_at'] as String).toUtc(),
  reopenedAtUtc: row['reopened_at'] == null
      ? null
      : DateTime.parse(row['reopened_at'] as String).toUtc(),
  reopenNote: row['reopen_note'] as String?,
  canReopen: row['can_reopen'] as bool? ?? false,
  reopenUntilUtc: row['reopen_until'] == null
      ? null
      : DateTime.parse(row['reopen_until'] as String).toUtc(),
);

_TicketServerFailure _serverFailure(String responseBody) {
  try {
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic> && decoded['code'] is String) {
      return _TicketServerFailure(decoded['code'] as String);
    }
  } on Object {
    // The status remains classified without exposing response text.
  }
  return const _TicketServerFailure('ticket_request_failed');
}

final class _TicketServerFailure implements Exception {
  const _TicketServerFailure(this.code);

  final String code;
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
