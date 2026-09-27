import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Student sees the privacy boundary and every attached field', (
    tester,
  ) async {
    final gateway = _TicketGateway();
    final context = TicketContext(
      screen: 'Calendar',
      build: '0.1.0+46',
      device: 'Surface Pro',
      platform: 'Windows',
      capturedAtUtc: DateTime.utc(2026, 9, 27, 14, 30),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PutInTicketSurface(gateway: gateway, attachedContext: context),
      ),
    );

    expect(find.textContaining('Do not include patient information'), findsOne);
    expect(find.text('Attached context'), findsOne);
    expect(find.textContaining('Calendar'), findsWidgets);
    expect(find.textContaining('0.1.0+46'), findsOne);
    expect(find.textContaining('Surface Pro'), findsOne);
    expect(find.textContaining('Windows'), findsOne);

    await tester.tap(find.byType(DropdownButtonFormField<TicketKind>));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Something's wrong").last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('ticket-text')),
      'The save action stayed busy.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Send Ticket'));
    await tester.pumpAndSettle();

    expect(gateway.submissions, hasLength(1));
    expect(gateway.submissions.single.kind, TicketKind.problem);
    expect(gateway.submissions.single.context, same(context));
    expect(find.text('Ticket sent.'), findsOne);
  });

  testWidgets('Tickets lists the sender statuses', (tester) async {
    final gateway = _TicketGateway(
      own: [
        Ticket(
          id: 'ticket-251',
          senderId: 'student-251',
          kind: TicketKind.idea,
          text: 'Please add a weekly summary.',
          status: TicketStatus.seen,
          context: TicketContext(
            screen: 'Calendar',
            build: '0.1.0+46',
            device: 'Surface Pro',
            platform: 'Windows',
            capturedAtUtc: DateTime.utc(2026, 9, 27, 14, 30),
          ),
          createdAtUtc: DateTime.utc(2026, 9, 27, 14, 30),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: TicketsSurface(gateway: gateway)),
    );
    await tester.pumpAndSettle();

    expect(find.text('An idea'), findsOne);
    expect(find.textContaining('Please add a weekly summary.'), findsOne);
    expect(find.textContaining('Seen'), findsOne);
  });

  testWidgets('Maintainer opening a Ticket marks it Seen', (tester) async {
    final sent = _ticket(status: TicketStatus.sent);
    final gateway = _TicketGateway(
      maintainer: true,
      all: [sent],
      opened: sent.copyWith(status: TicketStatus.seen),
    );
    var menuOpens = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TicketsSurface(
          gateway: gateway,
          onOpenApplicationMenu: () => menuOpens++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ticket-ticket-251')));
    await tester.pumpAndSettle();

    expect(gateway.openedIds, ['ticket-251']);
    expect(find.text('Seen'), findsOne);
    expect(find.text('Attached context'), findsOne);
    await tester.tap(find.byKey(const Key('ticket-detail-menu-action')));
    expect(menuOpens, 1);
  });

  testWidgets('Maintainer closes Done with a sender-visible reason', (
    tester,
  ) async {
    final seen = _ticket(status: TicketStatus.seen);
    final done = _ticket(
      status: TicketStatus.done,
      closeReason: 'The fix is live on the web app.',
      closedAtUtc: DateTime.now().toUtc(),
    );
    final gateway = _TicketGateway(
      maintainer: true,
      all: [seen],
      opened: seen,
      closed: done,
    );
    await tester.pumpWidget(
      MaterialApp(home: TicketsSurface(gateway: gateway)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ticket-ticket-251')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Close as Done'));
    await tester.pumpAndSettle();
    expect(find.textContaining('live on the web app'), findsOne);
    await tester.enterText(
      find.byKey(const Key('ticket-close-reason')),
      'The fix is live on the web app.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Close Ticket'));
    await tester.pumpAndSettle();

    expect(gateway.closes.single.outcome, TicketStatus.done);
    expect(gateway.closes.single.reason, 'The fix is live on the web app.');
    expect(find.text('Done'), findsOne);
    expect(find.text('The fix is live on the web app.'), findsOne);
  });

  testWidgets('sender sees the reason and reopens within 14 days', (
    tester,
  ) async {
    final done = _ticket(
      status: TicketStatus.done,
      closeReason: 'The fix is live now.',
      closedAtUtc: DateTime.now().toUtc().subtract(const Duration(days: 13)),
      canReopen: true,
    );
    final reopened = done.copyWith(
      status: TicketStatus.seen,
      reopenedAtUtc: DateTime.now().toUtc(),
      reopenNote: 'The same failure happened again.',
    );
    final gateway = _TicketGateway(own: [done], reopened: reopened);
    await tester.pumpWidget(
      MaterialApp(home: TicketsSurface(gateway: gateway)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ticket-ticket-251')));
    await tester.pumpAndSettle();

    expect(find.text('The fix is live now.'), findsOne);
    await tester.tap(find.text('Reopen Ticket'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('ticket-reopen-note')),
      'The same failure happened again.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Reopen'));
    await tester.pumpAndSettle();

    expect(gateway.reopens.single, 'The same failure happened again.');
    expect(find.text('Reopened'), findsOne);
  });

  testWidgets('sender is directed to a new Ticket after 14 days', (
    tester,
  ) async {
    final closed = _ticket(
      status: TicketStatus.wontDo,
      closeReason: 'This change would make the calendar harder to read.',
      closedAtUtc: DateTime.now().toUtc().subtract(const Duration(days: 15)),
    );
    final gateway = _TicketGateway(own: [closed]);
    await tester.pumpWidget(
      MaterialApp(home: TicketsSurface(gateway: gateway)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ticket-ticket-251')));
    await tester.pumpAndSettle();

    expect(find.text('Reopen Ticket'), findsNothing);
    await tester.drag(find.byType(ListView).last, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.textContaining('put in a new Ticket'), findsOne);
  });

  testWidgets('Maintainer question moves the Ticket to Waiting on you', (
    tester,
  ) async {
    final seen = _ticket(status: TicketStatus.seen);
    final gateway = _TicketGateway(
      maintainer: true,
      all: [seen],
      opened: seen,
      askedResult: seen.copyWith(
        status: TicketStatus.waitingOnYou,
        questionCount: 1,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: TicketsSurface(gateway: gateway)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ticket-ticket-251')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('ticket-question')),
      'Which action was still busy?',
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Ask sender'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Ask sender'));
    await tester.pumpAndSettle();

    expect(gateway.questions, ['Which action was still busy?']);
    expect(find.text('Waiting on you'), findsOne);
    expect(find.text('Questions or diagnostics: 1 of 2'), findsOne);
  });

  testWidgets('sender previews and attaches exactly the diagnostic shown', (
    tester,
  ) async {
    final waiting = _ticket(status: TicketStatus.waitingOnYou);
    final diagnostic = TicketDiagnosticSnapshot.fromJson({
      'snapshot_version': 1,
      'build': '253',
      'time_zone': 'America/New_York',
      'count.preceptors': 2,
    });
    final gateway = _TicketGateway(
      own: [waiting],
      thread: [_diagnosticRequest()],
      diagnosticResponseResult: waiting.copyWith(status: TicketStatus.seen),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TicketsSurface(
          gateway: gateway,
          diagnosticBuilder: () async => diagnostic,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ticket-ticket-251')));
    await tester.pumpAndSettle();

    expect(find.text('The Maintainer asked for a diagnostic'), findsOne);
    expect(find.textContaining('build: 253'), findsOne);
    expect(find.textContaining('count.preceptors: 2'), findsOne);
    expect(find.textContaining('time_zone: America/New_York'), findsOne);
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Attach'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Attach'));
    await tester.pumpAndSettle();

    expect(gateway.attachedDiagnostics.single, same(diagnostic));
    expect(gateway.declinedRequestIds, isEmpty);
    expect(find.text('Seen'), findsOne);
  });

  testWidgets('declining a diagnostic attaches nothing', (tester) async {
    final waiting = _ticket(status: TicketStatus.waitingOnYou);
    final gateway = _TicketGateway(
      own: [waiting],
      thread: [_diagnosticRequest()],
      diagnosticResponseResult: waiting.copyWith(status: TicketStatus.seen),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TicketsSurface(
          gateway: gateway,
          diagnosticBuilder: () async => TicketDiagnosticSnapshot.fromJson({
            'snapshot_version': 1,
            'build': '253',
            'time_zone': 'America/New_York',
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ticket-ticket-251')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Decline'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Decline'));
    await tester.pumpAndSettle();

    expect(gateway.declinedRequestIds, [_diagnosticRequestId]);
    expect(gateway.attachedDiagnostics, isEmpty);
    expect(find.text('Seen'), findsOne);
  });

  testWidgets('offline menu explains why putting in a Ticket is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TicketApplicationMenu(
            onDestinationSelected: (_) {},
            onTicketSelected: (_) {},
            ticketSubmissionAvailable: false,
          ),
        ),
      ),
    );

    expect(find.text('Put in a Ticket'), findsOne);
    expect(find.text('Connect to send a Ticket.'), findsOne);
    expect(
      tester
          .widget<ListTile>(
            find.ancestor(
              of: find.text('Put in a Ticket'),
              matching: find.byType(ListTile),
            ),
          )
          .onTap,
      isNull,
    );
  });
}

Ticket _ticket({
  required TicketStatus status,
  String? closeReason,
  DateTime? closedAtUtc,
  bool canReopen = false,
}) => Ticket(
  id: 'ticket-251',
  senderId: 'student-251',
  kind: TicketKind.problem,
  text: 'The save action stayed busy.',
  status: status,
  context: TicketContext(
    screen: 'Calendar',
    build: '0.1.0+46',
    device: 'Surface Pro',
    platform: 'Windows',
    capturedAtUtc: DateTime.utc(2026, 9, 27, 14, 30),
  ),
  createdAtUtc: DateTime.utc(2026, 9, 27, 14, 30),
  closeReason: closeReason,
  closedAtUtc: closedAtUtc,
  canReopen: canReopen,
);

final class _Close {
  const _Close(this.outcome, this.reason);

  final TicketStatus outcome;
  final String reason;
}

const _diagnosticRequestId = 'diagnostic-request-253';

TicketThreadEntry _diagnosticRequest() => TicketThreadEntry(
  id: _diagnosticRequestId,
  ticketId: 'ticket-251',
  author: TicketThreadAuthor.maintainer,
  kind: TicketThreadEntryKind.diagnosticRequest,
  createdAtUtc: DateTime.utc(2026, 9, 27, 14, 32),
);

final class _Submission {
  const _Submission(this.kind, this.text, this.context);
  final TicketKind kind;
  final String text;
  final TicketContext context;
}

final class _TicketGateway implements TicketGateway {
  _TicketGateway({
    this.maintainer = false,
    this.own = const [],
    this.all = const [],
    this.opened,
    this.closed,
    this.reopened,
    this.thread = const [],
    this.askedResult,
    this.diagnosticResponseResult,
  });

  final bool maintainer;
  final List<Ticket> own;
  final List<Ticket> all;
  final Ticket? opened;
  final Ticket? closed;
  final Ticket? reopened;
  final List<TicketThreadEntry> thread;
  final Ticket? askedResult;
  final Ticket? diagnosticResponseResult;
  final submissions = <_Submission>[];
  final openedIds = <String>[];
  final questions = <String>[];
  final answers = <String>[];
  final attachedDiagnostics = <TicketDiagnosticSnapshot>[];
  final declinedRequestIds = <String>[];
  final closes = <_Close>[];
  final reopens = <String>[];

  @override
  Future<Ticket> answerQuestion(
    String ticketId,
    String questionId, {
    required String answer,
  }) async {
    answers.add(answer);
    return diagnosticResponseResult ?? askedResult ?? opened!;
  }

  @override
  Future<Ticket> askQuestion(
    String ticketId, {
    required String question,
  }) async {
    questions.add(question);
    return askedResult!;
  }

  @override
  Future<Ticket> attachDiagnostic(
    String ticketId,
    String requestId,
    TicketDiagnosticSnapshot diagnostic,
  ) async {
    attachedDiagnostics.add(diagnostic);
    return diagnosticResponseResult!;
  }

  @override
  Future<Ticket> declineDiagnostic(String ticketId, String requestId) async {
    declinedRequestIds.add(requestId);
    return diagnosticResponseResult!;
  }

  @override
  Future<Ticket> close(
    String ticketId, {
    required TicketStatus outcome,
    required String reason,
  }) async {
    closes.add(_Close(outcome, reason));
    return closed!;
  }

  @override
  Future<bool> hasMaintainerGrant() async => maintainer;

  @override
  Future<Ticket> openForMaintainer(String ticketId) async {
    openedIds.add(ticketId);
    return opened!;
  }

  @override
  Future<Ticket> openForSender(String ticketId) async =>
      own.singleWhere((ticket) => ticket.id == ticketId);

  @override
  Future<List<TicketThreadEntry>> readThread(String ticketId) async => thread;

  @override
  Future<void> putIn({
    required TicketKind kind,
    required String text,
    required TicketContext context,
  }) async => submissions.add(_Submission(kind, text, context));

  @override
  Future<List<Ticket>> readForMaintainer() async => all;

  @override
  Future<List<Ticket>> readMine() async => own;

  @override
  Future<Ticket> reopen(String ticketId, {required String note}) async {
    reopens.add(note);
    return reopened!;
  }

  @override
  Future<Ticket> requestDiagnostic(String ticketId) async =>
      diagnosticResponseResult ?? askedResult ?? opened!;
}
