import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recent Ticket actions are bounded and cannot capture entered text', () {
    final actions = TicketActivityLog(limit: 3)
      ..record(TicketActivity.openedBatchPlanner)
      ..record(TicketActivity.tappedNext)
      ..recordRefusal('select_at_least_one_calendar_date');

    const enteredText = 'Patient Jane Doe at Memorial Hospital';
    expect(actions.snapshot(), <String>[
      'opened batch planner',
      'tapped Next',
      'refused: select_at_least_one_calendar_date',
    ]);
    expect(actions.snapshot().join(' '), isNot(contains(enteredText)));
    expect(
      () => actions.recordRefusal(enteredText),
      throwsA(isA<ArgumentError>()),
    );

    actions.record(TicketActivity.tappedApplyBatch);
    expect(actions.snapshot(), <String>[
      'tapped Next',
      'refused: select_at_least_one_calendar_date',
      'tapped Apply batch',
    ]);
  });

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
      recentActions: const [
        'opened batch planner',
        'tapped Next',
        'refused: select_at_least_one_calendar_date',
      ],
      refusalCode: 'select_at_least_one_calendar_date',
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
    expect(find.textContaining('opened batch planner'), findsOne);
    expect(find.textContaining('tapped Next'), findsOne);
    expect(
      find.textContaining('select_at_least_one_calendar_date'),
      findsWidgets,
    );

    await tester.tap(find.byType(DropdownButtonFormField<TicketKind>));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Something's wrong").last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('ticket-text')),
      'The save action stayed busy.',
    );
    await tester.drag(
      find.byKey(const Key('put-in-ticket-surface')).last,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('send-ticket-action')).last);
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

  testWidgets('a refusal offer opens a problem Ticket with the stable code', (
    tester,
  ) async {
    final actions = TicketActivityLog()..record(TicketActivity.tappedSave);
    TicketRefusalContext? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: TicketSupportScope(
          actions: actions,
          onOpenRefusal: (refusal) async => opened = refusal,
          child: const Scaffold(
            body: TicketRefusalOffer(
              screen: 'Work Shift editor',
              refusalCode: 'schedule_conflict',
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Think this is wrong? Put in a Ticket'));
    await tester.pump();

    expect(opened?.screen, 'Work Shift editor');
    expect(opened?.code, 'schedule_conflict');
    expect(actions.snapshot(), ['tapped Save', 'refused: schedule_conflict']);
  });
}

Ticket _ticket({required TicketStatus status}) => Ticket(
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
  });

  final bool maintainer;
  final List<Ticket> own;
  final List<Ticket> all;
  final Ticket? opened;
  final submissions = <_Submission>[];
  final openedIds = <String>[];

  @override
  Future<bool> hasMaintainerGrant() async => maintainer;

  @override
  Future<Ticket> openForMaintainer(String ticketId) async {
    openedIds.add(ticketId);
    return opened!;
  }

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
}
