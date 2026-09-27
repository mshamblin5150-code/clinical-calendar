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

  test('close and reopen use the authenticated Ticket outcome RPCs', () async {
    final requests = <http.Request>[];
    final gateway = _gateway(
      MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(
            _row(requests.length == 1 ? 'done' : 'seen', closed: true),
          ),
          200,
        );
      }),
    );

    final closed = await gateway.close(
      _ticketId,
      outcome: TicketStatus.done,
      reason: 'The fix is live on the web app.',
    );
    final reopened = await gateway.reopen(
      _ticketId,
      note: 'The same failure happened again.',
    );

    expect(requests[0].url.path, '/rest/v1/rpc/close_ticket');
    expect(jsonDecode(requests[0].body), {
      'p_ticket_id': _ticketId,
      'p_outcome': 'done',
      'p_reason': 'The fix is live on the web app.',
    });
    expect(closed.status, TicketStatus.done);
    expect(closed.closeReason, 'The fix is live on the web app.');
    expect(requests[1].url.path, '/rest/v1/rpc/reopen_ticket');
    expect(jsonDecode(requests[1].body), {
      'p_ticket_id': _ticketId,
      'p_note': 'The same failure happened again.',
    });
    expect(reopened.status, TicketStatus.seen);
    expect(reopened.reopenNote, 'The same failure happened again.');
  });

  test('sender open uses the server reopening deadline verdict', () async {
    late http.Request captured;
    final gateway = _gateway(
      MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode(_row('done', closed: true, canReopen: true)),
          200,
        );
      }),
    );

    final ticket = await gateway.openForSender(_ticketId);

    expect(captured.url.path, '/rest/v1/rpc/open_ticket_for_sender');
    expect(jsonDecode(captured.body), {'p_ticket_id': _ticketId});
    expect(ticket.canReopen, isTrue);
    expect(ticket.reopenUntilUtc, DateTime.utc(2026, 10, 11, 14, 32));
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

Map<String, Object?> _row(
  String status, {
  bool closed = false,
  bool canReopen = false,
}) => {
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
  'close_reason': closed ? 'The fix is live on the web app.' : null,
  'closed_at': closed ? '2026-09-27T14:32:00.000Z' : null,
  'reopened_at': status == 'seen' && closed ? '2026-09-27T14:33:00.000Z' : null,
  'reopen_note': status == 'seen' && closed
      ? 'The same failure happened again.'
      : null,
  'can_reopen': canReopen,
  'reopen_until': closed ? '2026-10-11T14:32:00.000Z' : null,
};

SupabaseTicketGateway _gateway(http.Client client) => SupabaseTicketGateway(
  projectUri: Uri.parse('https://project.supabase.co'),
  publishableKey: 'publishable-key',
  accessTokenProvider: () async => 'access-token',
  client: client,
);
