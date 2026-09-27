import 'dart:convert';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_platform/clinical_calendar_platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'putIn sends only approved Ticket fields through the authenticated RPC',
    () async {
      late http.Request captured;
      final gateway = _gateway(
        MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode(_ticketId), 200);
        }),
      );

      await gateway.putIn(
        kind: TicketKind.problem,
        text: 'Save stayed busy.',
        context: _context,
      );

      expect(captured.url.path, '/rest/v1/rpc/put_in_ticket');
      expect(captured.headers['authorization'], 'Bearer access-token');
      expect(jsonDecode(captured.body), {
        'p_kind': 'problem',
        'p_text': 'Save stayed busy.',
        'p_screen_context': 'Calendar',
        'p_build_context': '0.1.0+46',
        'p_device_context': 'Surface Pro',
        'p_platform_context': 'windows',
        'p_context_captured_at': '2026-09-27T14:30:00.000Z',
      });
    },
  );

  test('grant, list, and Maintainer open decode the server contract', () async {
    var call = 0;
    final gateway = _gateway(
      MockClient((request) async {
        call++;
        if (call == 1) return http.Response('true', 200);
        if (call == 2) return http.Response(jsonEncode([_row('sent')]), 200);
        return http.Response(jsonEncode(_row('seen')), 200);
      }),
    );

    expect(await gateway.hasMaintainerGrant(), isTrue);
    final tickets = await gateway.readForMaintainer();
    expect(tickets.single.kind, TicketKind.problem);
    expect(tickets.single.status, TicketStatus.sent);
    final opened = await gateway.openForMaintainer(_ticketId);
    expect(opened.status, TicketStatus.seen);
  });

  test(
    'stable rate-limit refusal is preserved without response text',
    () async {
      final gateway = _gateway(
        MockClient(
          (_) async => http.Response(
            jsonEncode({'code': 'P2851', 'message': 'private server detail'}),
            400,
          ),
        ),
      );

      await expectLater(
        gateway.putIn(
          kind: TicketKind.idea,
          text: 'Another idea',
          context: _context,
        ),
        throwsA(
          isA<TicketSubmissionRejected>().having(
            (error) => error.reason,
            'reason',
            TicketSubmissionRefusal.rateLimited,
          ),
        ),
      );
    },
  );
}

const _ticketId = '10000000-0000-4000-8000-000000000251';

final _context = TicketContext(
  screen: 'Calendar',
  build: '0.1.0+46',
  device: 'Surface Pro',
  platform: 'windows',
  capturedAtUtc: DateTime.utc(2026, 9, 27, 14, 30),
);

Map<String, Object?> _row(String status) => {
  'id': _ticketId,
  'sender_id': '00000000-0000-4000-8000-000000000252',
  'kind': 'problem',
  'text': 'Save stayed busy.',
  'state': status,
  'screen_context': 'Calendar',
  'build_context': '0.1.0+46',
  'device_context': 'Surface Pro',
  'platform_context': 'windows',
  'context_captured_at': '2026-09-27T14:30:00.000Z',
  'created_at': '2026-09-27T14:30:01.000Z',
  'seen_at': status == 'seen' ? '2026-09-27T14:31:00.000Z' : null,
};

SupabaseTicketGateway _gateway(http.Client client) => SupabaseTicketGateway(
  projectUri: Uri.parse('https://project.supabase.co'),
  publishableKey: 'publishable-key',
  accessTokenProvider: () async => 'access-token',
  client: client,
);
