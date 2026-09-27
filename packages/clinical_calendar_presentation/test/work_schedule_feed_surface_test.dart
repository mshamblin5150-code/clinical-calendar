import 'dart:async';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refresh on open starts only after 60 minutes', () {
    final checked = DateTime.utc(2026, 9, 27, 12);
    expect(
      workScheduleFeedRefreshDue(
        nowUtc: DateTime.utc(2026, 9, 27, 13),
        lastCheckedAtUtc: checked,
      ),
      isFalse,
    );
    expect(
      workScheduleFeedRefreshDue(
        nowUtc: DateTime.utc(2026, 9, 27, 13, 0, 1),
        lastCheckedAtUtc: checked,
      ),
      isTrue,
    );
  });

  testWidgets('connect preview lists skipped events and confirms replacements', (
    tester,
  ) async {
    WorkScheduleFeedConnectionPreview? confirmed;
    bool? replaceMatchingChoice;
    final preview = _preview(matches: 2);
    await _pump(
      tester,
      WorkScheduleFeedSurface(
        initialFeeds: const [],
        onPreviewConnection: (name, url) async => preview,
        onConfirmConnection: (value, {required bool replaceMatching}) async {
          confirmed = value;
          replaceMatchingChoice = replaceMatching;
        },
        onRefresh: _unusedRefresh,
        onUpdateSkipWords: _unusedSkipWords,
        onDisconnect: _unusedDisconnect,
      ),
    );

    await tester.enterText(find.byKey(const Key('feed-name-field')), 'ER');
    await tester.enterText(
      find.byKey(const Key('feed-url-field')),
      'webcal://schedule.example/me',
    );
    await tester.tap(find.byKey(const Key('preview-feed-action')));
    await tester.pumpAndSettle();

    expect(find.text('2 upcoming shifts'), findsOneWidget);
    expect(find.text('PTO — skipped by word'), findsOneWidget);
    expect(
      find.text(
        '2 hand-entered shifts match. Replace them with the imported versions?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('confirm-feed-action')));
    await tester.pumpAndSettle();
    expect(find.text('Replace matching shifts?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('replace-matching-shifts-action')));
    await tester.pumpAndSettle();
    expect(confirmed, same(preview));
    expect(replaceMatchingChoice, isTrue);
    expect(find.text('ER Schedule'), findsOneWidget);
  });

  testWidgets('team feed refusal is shown without a preview', (tester) async {
    await _pump(
      tester,
      WorkScheduleFeedSurface(
        initialFeeds: const [],
        onPreviewConnection: (_, _) async =>
            throw const WorkScheduleFeedTeamFeedException(),
        onConfirmConnection: (_, {required replaceMatching}) async {},
        onRefresh: _unusedRefresh,
        onUpdateSkipWords: _unusedSkipWords,
        onDisconnect: _unusedDisconnect,
      ),
    );
    await tester.enterText(find.byKey(const Key('feed-name-field')), 'Team');
    await tester.enterText(
      find.byKey(const Key('feed-url-field')),
      'https://schedule.example/team',
    );
    await tester.tap(find.byKey(const Key('preview-feed-action')));
    await tester.pumpAndSettle();

    expect(
      find.text(WorkScheduleFeedTeamFeedException.message),
      findsOneWidget,
    );
    expect(find.byKey(const Key('confirm-feed-action')), findsNothing);
  });

  testWidgets('leaving during preview discards the staged credential', (
    tester,
  ) async {
    final pending = Completer<WorkScheduleFeedConnectionPreview>();
    WorkScheduleFeed? discarded;
    await _pump(
      tester,
      WorkScheduleFeedSurface(
        initialFeeds: const [],
        onPreviewConnection: (_, _) => pending.future,
        onConfirmConnection: (_, {required replaceMatching}) async {},
        onDiscardPreview: (feed) async => discarded = feed,
        onRefresh: _unusedRefresh,
        onUpdateSkipWords: _unusedSkipWords,
        onDisconnect: _unusedDisconnect,
      ),
    );
    await tester.enterText(find.byKey(const Key('feed-name-field')), 'ER');
    await tester.enterText(
      find.byKey(const Key('feed-url-field')),
      'https://schedule.example/me',
    );
    await tester.tap(find.byKey(const Key('preview-feed-action')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());

    final preview = _preview();
    pending.complete(preview);
    await tester.pump();

    expect(discarded, same(preview.feed));
  });

  testWidgets('feed page edits skip words, refreshes, and disconnects', (
    tester,
  ) async {
    List<String>? savedWords;
    var refreshed = 0;
    var disconnected = false;
    final feed = _feed();
    await _pump(
      tester,
      WorkScheduleFeedSurface(
        initialFeeds: [feed],
        onPreviewConnection: (_, _) async => _preview(),
        onConfirmConnection: (_, {required replaceMatching}) async {},
        onRefresh: (value, {confirmEmpty = false}) async {
          refreshed += 1;
          return WorkScheduleFeedRefreshResult(
            disposition: WorkScheduleFeedRefreshDisposition.updated,
            feed: value,
            upcomingShifts: const [],
          );
        },
        onUpdateSkipWords: (value, words) async {
          savedWords = words;
          return value.copyWith(skipWords: words);
        },
        onDisconnect: (_) async => disconnected = true,
      ),
    );

    await tester.tap(find.text('ER Schedule'));
    await tester.pumpAndSettle();
    expect(find.text('updated 09-27-2026 12:00'), findsOneWidget);
    expect(find.text('PTO — skipped by word'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('feed-skip-words-field')),
      'PTO, Training',
    );
    await tester.tap(find.byKey(const Key('save-skip-words-action')));
    await tester.pumpAndSettle();
    expect(savedWords, ['PTO', 'Training']);
    expect(refreshed, 1);

    await tester.tap(find.byKey(const Key('refresh-feed-action')));
    await tester.pumpAndSettle();
    expect(refreshed, 2);

    await tester.tap(find.byKey(const Key('disconnect-feed-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-disconnect-feed-action')));
    await tester.pumpAndSettle();
    expect(disconnected, isTrue);
    expect(find.text('No Work Schedule Feeds connected.'), findsOneWidget);
  });

  testWidgets('zero-upcoming refresh asks before removing shifts', (
    tester,
  ) async {
    final confirmations = <bool>[];
    await _pump(
      tester,
      WorkScheduleFeedSurface(
        initialFeeds: [_feed()],
        onPreviewConnection: (_, _) async => _preview(),
        onConfirmConnection: (_, {required replaceMatching}) async {},
        onRefresh: (feed, {confirmEmpty = false}) async {
          confirmations.add(confirmEmpty);
          return WorkScheduleFeedRefreshResult(
            disposition: confirmEmpty
                ? WorkScheduleFeedRefreshDisposition.updated
                : WorkScheduleFeedRefreshDisposition.requiresEmptyConfirmation,
            feed: feed,
            upcomingShifts: const [],
          );
        },
        onUpdateSkipWords: (feed, _) async => feed,
        onDisconnect: _unusedDisconnect,
      ),
    );
    await tester.tap(find.text('ER Schedule'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('refresh-feed-action')));
    await tester.pumpAndSettle();
    expect(find.text('No upcoming shifts were found'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-empty-feed-action')));
    await tester.pumpAndSettle();
    expect(confirmations, [false, true]);
  });

  testWidgets('failed refresh changes the page and list to stale status', (
    tester,
  ) async {
    final feed = _feed();
    await _pump(
      tester,
      WorkScheduleFeedSurface(
        initialFeeds: [feed],
        onPreviewConnection: (_, _) async => _preview(),
        onConfirmConnection: (_, {required replaceMatching}) async {},
        onRefresh: (value, {confirmEmpty = false}) async {
          final failed = value.copyWith(
            lastCheckedAtUtc: value.lastCheckedAtUtc.add(
              const Duration(hours: 2),
            ),
            heldReason: 'The feed could not be fetched.',
          );
          return WorkScheduleFeedRefreshResult(
            disposition: WorkScheduleFeedRefreshDisposition.failed,
            feed: failed,
            upcomingShifts: const [],
          );
        },
        onUpdateSkipWords: _unusedSkipWords,
        onDisconnect: _unusedDisconnect,
      ),
    );

    await tester.tap(find.text('ER Schedule'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('refresh-feed-action')));
    await tester.pumpAndSettle();
    expect(
      find.text("ER Schedule hasn't updated since 09-27-2026"),
      findsWidgets,
    );
    expect(find.text('updated 09-27-2026 12:00'), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      find.text("ER Schedule hasn't updated since 09-27-2026"),
      findsOneWidget,
    );
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildVariantFTheme(),
      home: Scaffold(body: SizedBox(width: 700, height: 800, child: child)),
    ),
  );
  await tester.pump();
}

WorkScheduleFeed _feed() => WorkScheduleFeed(
  id: '10000000-0000-4000-8000-000000000001',
  name: 'ER Schedule',
  url: Uri.parse('webcal://secret.example/feed'),
  lastCheckedAtUtc: DateTime.utc(2026, 9, 27, 12),
  lastSuccessfulUpdateAtUtc: DateTime.utc(2026, 9, 27, 12),
  notImported: [
    WorkScheduleFeedNotImportedEvent(
      sourceEventUid: 'pto-1',
      title: 'PTO',
      reason: WorkScheduleFeedNotImportedReason.skipWord,
    ),
  ],
);

WorkScheduleFeedConnectionPreview _preview({int matches = 0}) =>
    WorkScheduleFeedConnectionPreview(
      studentId: 'student',
      feed: _feed(),
      upcomingShifts: [
        WorkShift.imported(
          id: '20000000-0000-4000-8000-000000000001',
          plannedInterval: ZonedInterval(
            startDate: LocalDate(2026, 9, 28),
            startTime: LocalTime(7, 0),
            endTime: LocalTime(15, 0),
            timeZone: TimeZoneId('UTC'),
            startOffset: UtcOffset.utc,
            endOffset: UtcOffset.utc,
          ),
          workScheduleFeedId: '10000000-0000-4000-8000-000000000001',
          workScheduleFeedName: 'ER Schedule',
          sourceEventUid: 'shift-1',
        ),
        WorkShift.imported(
          id: '20000000-0000-4000-8000-000000000002',
          plannedInterval: ZonedInterval(
            startDate: LocalDate(2026, 9, 29),
            startTime: LocalTime(7, 0),
            endTime: LocalTime(15, 0),
            timeZone: TimeZoneId('UTC'),
            startOffset: UtcOffset.utc,
            endOffset: UtcOffset.utc,
          ),
          workScheduleFeedId: '10000000-0000-4000-8000-000000000001',
          workScheduleFeedName: 'ER Schedule',
          sourceEventUid: 'shift-2',
        ),
      ],
      matchingHandEnteredWorkShiftIds: [
        for (var index = 0; index < matches; index += 1) 'manual-$index',
      ],
      notImported: _feed().notImported,
    );

Future<WorkScheduleFeedRefreshResult> _unusedRefresh(
  WorkScheduleFeed feed, {
  bool confirmEmpty = false,
}) => throw UnimplementedError();

Future<WorkScheduleFeed> _unusedSkipWords(
  WorkScheduleFeed feed,
  List<String> words,
) => throw UnimplementedError();

Future<void> _unusedDisconnect(WorkScheduleFeed feed) async {}
