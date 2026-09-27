import 'dart:convert';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_platform/clinical_calendar_web_platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('stages the owned credential before asking the relay for ICS', () async {
    final requests = <http.Request>[];
    final gateway = SupabaseWorkScheduleFeedRelayGateway(
      projectUri: Uri.parse('https://project.supabase.co'),
      publishableKey: 'publishable',
      accessTokenProvider: () async => 'student-token',
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/stage_work_schedule_feed_preview')) {
          return http.Response('', 204);
        }
        return http.Response(
          jsonEncode({
            'ics': 'BEGIN:VCALENDAR\r\nEND:VCALENDAR',
            'fetchedAt': '2026-09-27T12:00:00Z',
            'upstreamStatus': 200,
            'fromCache': false,
            'errorClass': null,
          }),
          200,
        );
      }),
    );

    final ics = await gateway.stageAndFetch(
      feedId: '10000000-0000-4000-8000-000000000001',
      url: Uri.parse('webcal://secret.example/me'),
    );

    expect(ics, contains('VCALENDAR'));
    expect(requests, hasLength(2));
    expect(
      requests.first.url.path,
      '/rest/v1/rpc/stage_work_schedule_feed_preview',
    );
    expect(jsonDecode(requests.first.body), {
      'p_feed_id': '10000000-0000-4000-8000-000000000001',
      'p_url': 'webcal://secret.example/me',
    });
    expect(requests.last.url.path, '/functions/v1/work-schedule-feed');
    expect(requests.last.headers['authorization'], 'Bearer student-token');
  });

  test(
    'classifies relay metadata errors without exposing response text',
    () async {
      final gateway = SupabaseWorkScheduleFeedRelayGateway(
        projectUri: Uri.parse('https://project.supabase.co'),
        publishableKey: 'publishable',
        accessTokenProvider: () async => 'student-token',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'ics': null, 'errorClass': 'upstream_unavailable'}),
            502,
          ),
        ),
      );

      await expectLater(
        gateway.fetch(feedId: '10000000-0000-4000-8000-000000000001'),
        throwsA(
          isA<WorkScheduleFeedRelayException>().having(
            (error) => error.code,
            'code',
            'upstream_unavailable',
          ),
        ),
      );
    },
  );
}
