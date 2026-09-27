import 'dart:convert';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:http/http.dart' as http;

typedef WorkScheduleFeedAccessTokenProvider = Future<String?> Function();

final class SupabaseWorkScheduleFeedRelayGateway
    implements WorkScheduleFeedRelayGateway {
  SupabaseWorkScheduleFeedRelayGateway({
    required Uri projectUri,
    required String publishableKey,
    required WorkScheduleFeedAccessTokenProvider accessTokenProvider,
    http.Client? client,
  }) : _projectUri = _validatedProjectUri(projectUri),
       _publishableKey = _required(publishableKey, 'publishableKey'),
       // ignore: prefer_initializing_formals, preserves the public name.
       _accessTokenProvider = accessTokenProvider,
       _client = client ?? http.Client();

  final Uri _projectUri;
  final String _publishableKey;
  final WorkScheduleFeedAccessTokenProvider _accessTokenProvider;
  final http.Client _client;

  @override
  Future<String> stageAndFetch({
    required String feedId,
    required Uri url,
  }) async {
    await _request('/rest/v1/rpc/stage_work_schedule_feed_preview', {
      'p_feed_id': feedId,
      'p_url': url.toString(),
    }, allowEmpty: true);
    return fetch(feedId: feedId);
  }

  @override
  Future<String> fetch({required String feedId}) async {
    final response = await _request('/functions/v1/work-schedule-feed', {
      'feedId': feedId,
    });
    if (response is! Map<String, dynamic>) {
      throw const WorkScheduleFeedRelayException('invalid_response');
    }
    final error = response['errorClass'];
    final ics = response['ics'];
    if (error is String) throw WorkScheduleFeedRelayException(error);
    if (ics is! String) {
      throw const WorkScheduleFeedRelayException('invalid_response');
    }
    return ics;
  }

  @override
  Future<void> discard({required String feedId}) async {
    await _request('/rest/v1/rpc/discard_work_schedule_feed', {
      'p_feed_id': feedId,
    }, allowEmpty: true);
  }

  Future<Object?> _request(
    String path,
    Map<String, Object?> body, {
    bool allowEmpty = false,
  }) async {
    final token = (await _accessTokenProvider())?.trim();
    if (token == null || token.isEmpty) {
      throw const WorkScheduleFeedRelayException('unauthenticated');
    }
    final request = http.Request('POST', _projectUri.resolve(path))
      ..headers.addAll({
        'apikey': _publishableKey,
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      })
      ..body = jsonEncode(body);
    http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request));
    } on http.ClientException {
      throw const WorkScheduleFeedRelayException('network_unavailable');
    }
    Object? decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on Object {
        throw const WorkScheduleFeedRelayException('invalid_response');
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final code = decoded is Map<String, dynamic>
          ? decoded['errorClass'] ?? decoded['code']
          : null;
      throw WorkScheduleFeedRelayException(
        code is String ? code : 'relay_unavailable',
      );
    }
    if (decoded == null && !allowEmpty) {
      throw const WorkScheduleFeedRelayException('invalid_response');
    }
    return decoded;
  }
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
