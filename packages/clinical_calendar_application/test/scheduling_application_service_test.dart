import 'dart:io';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

const _studentId = '00000000-0000-4000-8000-000000000001';
final _now = DateTime.utc(2026, 8, 10, 16);
final _zone = TimeZoneId('America/New_York');
final _offset = UtcOffset.inMinutes(-240);

void main() {
  late _MemoryRegistry registry;
  late _SequenceIdentifiers identifiers;
  late SchedulingApplicationService service;
  late WorkScheduleFeedApplicationService feedService;
  late ClinicalPlacement placement;
  late Preceptor primary;
  late Preceptor alternate;

  setUp(() {
    registry = _MemoryRegistry();
    identifiers = _SequenceIdentifiers(1000);
    service = SchedulingApplicationService(
      registry,
      _FixedClock(_now),
      identifiers,
    );
    feedService = WorkScheduleFeedApplicationService(
      registry,
      _FixedClock(_now),
      identifiers,
    );
    primary = Preceptor(id: _id(10), name: 'Primary');
    alternate = Preceptor(id: _id(11), name: 'Alternate');
    placement = _placement(primary.id, alternate.id);
    registry.repositories.preceptors.seed(_studentId, primary);
    registry.repositories.preceptors.seed(_studentId, alternate);
    registry.repositories.clinicalPlacements.seed(_studentId, placement);
  });

  test(
    'ER Schedule preview classifies events and replaces matching hand-entered shifts only after confirmation',
    () async {
      final matching = WorkShift(
        id: _id(15),
        plannedInterval: _interval(12, 7, 19),
      );
      final unrelated = WorkShift(
        id: _id(16),
        plannedInterval: _interval(18, 7, 19),
      );
      registry.repositories.workShifts.seed(_studentId, matching);
      registry.repositories.workShifts.seed(_studentId, unrelated);

      final preview = await feedService.previewConnection(
        WorkScheduleFeedConnectionRequest(
          studentId: _studentId,
          name: 'ER Schedule',
          url: Uri.parse('webcal://example.invalid/private/token.ics'),
          ics: File(
            'test/fixtures/work_schedule_feeds/er_schedule.ics',
          ).readAsStringSync(),
          studentTimeZone: _zone,
        ),
      );

      expect(preview.upcomingShifts, hasLength(1));
      expect(preview.matchingHandEnteredWorkShiftIds, [matching.id]);
      expect(preview.notImported.map((event) => event.reason), [
        WorkScheduleFeedNotImportedReason.allDay,
        WorkScheduleFeedNotImportedReason.skipWord,
      ]);
      expect(preview.feed.skipWords, WorkScheduleFeed.defaultSkipWords);
      expect(preview.feed.maskedUrl, 'webcal://example.invalid/…');
      expect(registry.repositories.workShifts.values, [matching, unrelated]);
      expect(registry.repositories.workScheduleFeeds.values, isEmpty);

      await feedService.confirmConnection(preview);

      expect(registry.repositories.workScheduleFeeds.values, [preview.feed]);
      expect(
        registry.repositories.workShifts.values.map((shift) => shift.id),
        containsAll(<String>[unrelated.id, preview.upcomingShifts.single.id]),
      );
      expect(
        registry.repositories.workShifts.values.map((shift) => shift.id),
        isNot(contains(matching.id)),
      );
      expect(preview.upcomingShifts.single.sourceEventUid, 'shift-1');
      expect(
        preview.upcomingShifts.single.plannedInterval.startInstantUtc,
        DateTime.utc(2026, 8, 12, 11),
      );
    },
  );

  test('connecting can keep matching hand-entered shifts', () async {
    final matching = WorkShift(
      id: _id(17),
      plannedInterval: _interval(12, 7, 19),
    );
    registry.repositories.workShifts.seed(_studentId, matching);
    final preview = await feedService.previewConnection(
      WorkScheduleFeedConnectionRequest(
        studentId: _studentId,
        name: 'ER Schedule',
        url: Uri.parse('https://example.invalid/private.ics'),
        ics: File(
          'test/fixtures/work_schedule_feeds/er_schedule.ics',
        ).readAsStringSync(),
        studentTimeZone: _zone,
      ),
    );

    await feedService.confirmConnection(preview, replaceMatching: false);

    expect(
      registry.repositories.workShifts.values.map((shift) => shift.id),
      containsAll([matching.id, preview.upcomingShifts.single.id]),
    );
  });

  test(
    'changing vendor UIDs fall back to times and two devices converge without duplicates',
    () async {
      final preview = await feedService.previewConnection(
        WorkScheduleFeedConnectionRequest(
          studentId: _studentId,
          name: 'ER Schedule',
          url: Uri.parse('https://example.invalid/private/token.ics'),
          ics: File(
            'test/fixtures/work_schedule_feeds/er_schedule.ics',
          ).readAsStringSync(),
          studentTimeZone: _zone,
        ),
      );
      await feedService.confirmConnection(preview);
      final originalId = preview.upcomingShifts.single.id;

      final secondRegistry = _MemoryRegistry();
      final secondService = WorkScheduleFeedApplicationService(
        secondRegistry,
        _FixedClock(_now.add(const Duration(hours: 2))),
        _SequenceIdentifiers(3000),
      );
      await secondService.confirmConnection(preview);
      final changedUidIcs = File(
        'test/fixtures/work_schedule_feeds/changing_uids.ics',
      ).readAsStringSync();

      final first = await feedService.refresh(
        WorkScheduleFeedRefreshRequest(
          studentId: _studentId,
          feedId: preview.feed.id,
          ics: changedUidIcs,
          studentTimeZone: _zone,
        ),
      );
      final second = await secondService.refresh(
        WorkScheduleFeedRefreshRequest(
          studentId: _studentId,
          feedId: preview.feed.id,
          ics: changedUidIcs,
          studentTimeZone: _zone,
        ),
      );

      expect(first.disposition, WorkScheduleFeedRefreshDisposition.updated);
      expect(second.disposition, WorkScheduleFeedRefreshDisposition.updated);
      expect(registry.repositories.workShifts.values, hasLength(1));
      expect(secondRegistry.repositories.workShifts.values, hasLength(1));
      expect(registry.repositories.workShifts.values.single.id, originalId);
      expect(
        secondRegistry.repositories.workShifts.values.single.id,
        originalId,
      );
      expect(
        registry.repositories.workShifts.values.single.sourceEventUid,
        'vendor-regenerated-uid',
      );
    },
  );

  test('team feeds are refused on connect and held on refresh', () async {
    final teamIcs = File(
      'test/fixtures/work_schedule_feeds/team_feed.ics',
    ).readAsStringSync();
    await expectLater(
      feedService.previewConnection(
        WorkScheduleFeedConnectionRequest(
          studentId: _studentId,
          name: 'Department schedule',
          url: Uri.parse('https://example.invalid/team.ics'),
          ics: teamIcs,
          studentTimeZone: _zone,
        ),
      ),
      throwsA(isA<WorkScheduleFeedTeamFeedException>()),
    );

    final preview = await feedService.previewConnection(
      WorkScheduleFeedConnectionRequest(
        studentId: _studentId,
        name: 'ER Schedule',
        url: Uri.parse('https://example.invalid/private.ics'),
        ics: File(
          'test/fixtures/work_schedule_feeds/er_schedule.ics',
        ).readAsStringSync(),
        studentTimeZone: _zone,
      ),
    );
    await feedService.confirmConnection(preview);
    final previousSuccess = preview.feed.lastSuccessfulUpdateAtUtc;
    final existingShift = registry.repositories.workShifts.values.single;

    final held = await feedService.refresh(
      WorkScheduleFeedRefreshRequest(
        studentId: _studentId,
        feedId: preview.feed.id,
        ics: teamIcs,
        studentTimeZone: _zone,
      ),
    );

    expect(held.disposition, WorkScheduleFeedRefreshDisposition.heldTeamFeed);
    expect(held.feed.heldReason, isNotEmpty);
    expect(held.feed.lastSuccessfulUpdateAtUtc, previousSuccess);
    expect(registry.repositories.workShifts.values.single, same(existingShift));
  });

  test(
    'rolling windows freeze started shifts and mirror upcoming shifts',
    () async {
      final preview = await feedService.previewConnection(
        WorkScheduleFeedConnectionRequest(
          studentId: _studentId,
          name: 'ER Schedule',
          url: Uri.parse('https://example.invalid/private.ics'),
          ics: File(
            'test/fixtures/work_schedule_feeds/er_schedule.ics',
          ).readAsStringSync(),
          studentTimeZone: _zone,
        ),
      );
      await feedService.confirmConnection(preview);
      final started = preview.upcomingShifts.single;
      final removedUpcoming = WorkShift.imported(
        id: _id(99),
        plannedInterval: _interval(18, 7, 19),
        workScheduleFeedId: preview.feed.id,
        workScheduleFeedName: preview.feed.name,
        sourceEventUid: 'removed-upcoming',
      );
      registry.repositories.workShifts.seed(_studentId, removedUpcoming);

      final laterService = WorkScheduleFeedApplicationService(
        registry,
        _FixedClock(DateTime.utc(2026, 8, 13, 0)),
        _SequenceIdentifiers(4000),
      );
      await laterService.refresh(
        WorkScheduleFeedRefreshRequest(
          studentId: _studentId,
          feedId: preview.feed.id,
          ics: File(
            'test/fixtures/work_schedule_feeds/rolling_window.ics',
          ).readAsStringSync(),
          studentTimeZone: _zone,
        ),
      );

      final shifts = registry.repositories.workShifts.values;
      expect(shifts.map((shift) => shift.id), contains(started.id));
      expect(
        shifts.map((shift) => shift.id),
        isNot(contains(removedUpcoming.id)),
      );
      expect(
        shifts.map((shift) => shift.sourceEventUid),
        contains('new-window'),
      );
      expect(shifts, hasLength(2));
    },
  );

  test(
    'an empty feed requires confirmation before upcoming shifts are removed',
    () async {
      final preview = await feedService.previewConnection(
        WorkScheduleFeedConnectionRequest(
          studentId: _studentId,
          name: 'ER Schedule',
          url: Uri.parse('https://example.invalid/private.ics'),
          ics: File(
            'test/fixtures/work_schedule_feeds/er_schedule.ics',
          ).readAsStringSync(),
          studentTimeZone: _zone,
        ),
      );
      await feedService.confirmConnection(preview);
      final emptyIcs = File(
        'test/fixtures/work_schedule_feeds/empty_feed.ics',
      ).readAsStringSync();
      final laterFeedService = WorkScheduleFeedApplicationService(
        registry,
        _FixedClock(_now.add(const Duration(hours: 2))),
        _SequenceIdentifiers(3500),
      );

      final pending = await laterFeedService.refresh(
        WorkScheduleFeedRefreshRequest(
          studentId: _studentId,
          feedId: preview.feed.id,
          ics: emptyIcs,
          studentTimeZone: _zone,
        ),
      );

      expect(
        pending.disposition,
        WorkScheduleFeedRefreshDisposition.requiresEmptyConfirmation,
      );
      expect(registry.repositories.workShifts.values, hasLength(1));
      expect(
        pending.feed.lastSuccessfulUpdateAtUtc,
        preview.feed.lastSuccessfulUpdateAtUtc,
      );
      expect(pending.feed.lastCheckedAtUtc, _now.add(const Duration(hours: 2)));

      final confirmed = await laterFeedService.refresh(
        WorkScheduleFeedRefreshRequest(
          studentId: _studentId,
          feedId: preview.feed.id,
          ics: emptyIcs,
          studentTimeZone: _zone,
          confirmEmpty: true,
        ),
      );
      expect(confirmed.disposition, WorkScheduleFeedRefreshDisposition.updated);
      expect(registry.repositories.workShifts.values, isEmpty);
    },
  );

  test(
    'TZID events keep their zone and floating events use the Student zone',
    () async {
      final preview = await feedService.previewConnection(
        WorkScheduleFeedConnectionRequest(
          studentId: _studentId,
          name: 'Mixed zones',
          url: Uri.parse('https://example.invalid/zones.ics'),
          ics: File(
            'test/fixtures/work_schedule_feeds/tzid_events.ics',
          ).readAsStringSync(),
          studentTimeZone: _zone,
        ),
      );

      final byUid = {
        for (final shift in preview.upcomingShifts)
          shift.sourceEventUid!: shift,
      };
      expect(
        byUid['chicago']!.plannedInterval.timeZone.value,
        'America/Chicago',
      );
      expect(byUid['chicago']!.plannedInterval.startOffset.minutes, -300);
      expect(byUid['chicago']!.plannedInterval.startTime, LocalTime(7, 0));
      expect(byUid['floating']!.plannedInterval.timeZone, _zone);
      expect(byUid['floating']!.plannedInterval.startOffset.minutes, -240);
      expect(byUid['floating']!.plannedInterval.startTime, LocalTime(8, 30));
    },
  );

  test('disconnect removes only that feed future and keeps its past', () async {
    final preview = await feedService.previewConnection(
      WorkScheduleFeedConnectionRequest(
        studentId: _studentId,
        name: 'ER Schedule',
        url: Uri.parse('https://example.invalid/private.ics'),
        ics: File(
          'test/fixtures/work_schedule_feeds/er_schedule.ics',
        ).readAsStringSync(),
        studentTimeZone: _zone,
      ),
    );
    await feedService.confirmConnection(preview);
    final past = WorkShift.imported(
      id: _id(96),
      plannedInterval: _interval(8, 7, 19),
      workScheduleFeedId: preview.feed.id,
      workScheduleFeedName: preview.feed.name,
      sourceEventUid: 'past',
    );
    final handEntered = WorkShift(
      id: _id(97),
      plannedInterval: _interval(18, 7, 19),
    );
    final otherFeed = WorkShift.imported(
      id: _id(98),
      plannedInterval: _interval(19, 7, 19),
      workScheduleFeedId: 'other-feed',
      workScheduleFeedName: 'Other Feed',
      sourceEventUid: 'other',
    );
    registry.repositories.workShifts.seed(_studentId, past);
    registry.repositories.workShifts.seed(_studentId, handEntered);
    registry.repositories.workShifts.seed(_studentId, otherFeed);

    await feedService.disconnect(
      studentId: _studentId,
      feedId: preview.feed.id,
    );

    expect(registry.repositories.workScheduleFeeds.values, isEmpty);
    expect(
      registry.repositories.workShifts.values.map((shift) => shift.id),
      containsAll([past.id, handEntered.id, otherFeed.id]),
    );
    expect(
      registry.repositories.workShifts.values.map((shift) => shift.id),
      isNot(contains(preview.upcomingShifts.single.id)),
    );
  });

  test('a shift is frozen at its exact start instant', () async {
    final preview = await feedService.previewConnection(
      WorkScheduleFeedConnectionRequest(
        studentId: _studentId,
        name: 'ER Schedule',
        url: Uri.parse('https://example.invalid/private.ics'),
        ics: File(
          'test/fixtures/work_schedule_feeds/er_schedule.ics',
        ).readAsStringSync(),
        studentTimeZone: _zone,
      ),
    );
    await feedService.confirmConnection(preview);
    final shift = preview.upcomingShifts.single;
    final atStart = WorkScheduleFeedApplicationService(
      registry,
      _FixedClock(shift.plannedInterval.startInstantUtc),
      _SequenceIdentifiers(4500),
    );

    await atStart.disconnect(studentId: _studentId, feedId: preview.feed.id);

    expect(registry.repositories.workShifts.values, [shift]);
    expect(registry.repositories.workScheduleFeeds.values, isEmpty);
  });

  test(
    'skip words are editable and malformed refreshes change nothing',
    () async {
      final preview = await feedService.previewConnection(
        WorkScheduleFeedConnectionRequest(
          studentId: _studentId,
          name: 'ER Schedule',
          url: Uri.parse('https://example.invalid/private.ics'),
          ics: File(
            'test/fixtures/work_schedule_feeds/er_schedule.ics',
          ).readAsStringSync(),
          studentTimeZone: _zone,
        ),
      );
      await feedService.confirmConnection(preview);
      final updated = await feedService.updateSkipWords(
        studentId: _studentId,
        feedId: preview.feed.id,
        skipWords: ['PTO', 'Training', 'pto'],
      );
      expect(updated.value.skipWords, ['PTO', 'Training']);
      final beforeFeed = registry.repositories.workScheduleFeeds.values.single;
      final beforeShift = registry.repositories.workShifts.values.single;
      final beforeMutations = registry.repositories.mutations.length;

      await expectLater(
        feedService.refresh(
          WorkScheduleFeedRefreshRequest(
            studentId: _studentId,
            feedId: preview.feed.id,
            ics: 'not a calendar',
            studentTimeZone: _zone,
          ),
        ),
        throwsA(isA<WorkScheduleFeedFormatException>()),
      );

      expect(
        registry.repositories.workScheduleFeeds.values.single,
        same(beforeFeed),
      );
      expect(registry.repositories.workShifts.values.single, same(beforeShift));
      expect(registry.repositories.mutations, hasLength(beforeMutations));
    },
  );

  test('creates a mixed-Preceptor Clinical Session batch atomically', () async {
    final result = await service.createClinicalSessionBatch(
      ClinicalSessionBatchRequest(
        studentId: _studentId,
        clinicalPlacementId: placement.id,
        items: [
          ClinicalSessionBatchItem(
            interval: _interval(12, 9, 15),
            preceptorId: primary.id,
          ),
          ClinicalSessionBatchItem(
            interval: _interval(18, 9, 15),
            preceptorId: alternate.id,
          ),
        ],
      ),
    );

    expect(result.committed, isTrue);
    expect(result.records, hasLength(2));
    expect(
      result.records.map((record) => record.value.plannedInterval.startDate),
      [LocalDate(2026, 8, 12), LocalDate(2026, 8, 18)],
    );
    expect(result.records.map((record) => record.value.preceptorId), [
      primary.id,
      alternate.id,
    ]);
    expect(
      result.records.every(
        (record) =>
            record.value.clinicalPlacementId == placement.id &&
            record.value.plannedMinutes == 360,
      ),
      isTrue,
    );
    expect(registry.repositories.mutations, hasLength(2));
    _expectDistinctMutationTokens(registry.repositories.mutations);
  });

  test(
    'staged per-date Preceptor assignments persist through one batch Apply',
    () async {
      final coordinator = SchedulingBatchCoordinator(service);
      final result = await coordinator.apply(
        BatchSchedulingDraft(
          studentId: _studentId,
          type: BatchCommitmentType.clinicalSession,
          dates: [_zonedDate(12), _zonedDate(18)],
          startTime: LocalTime(9, 0),
          endTime: LocalTime(15, 0),
          clinicalPlacementId: placement.id,
          preceptorId: primary.id,
          preceptorOverrides: {LocalDate(2026, 8, 18): alternate.id},
        ),
      );

      expect(result.applied, isTrue);
      expect(result.persistedCount, 2);
      expect(
        registry.repositories.clinicalSessions.values.map(
          (session) => session.preceptorId,
        ),
        [primary.id, alternate.id],
      );
      expect(registry.repositories.mutations, hasLength(2));
      _expectDistinctMutationTokens(registry.repositories.mutations);
    },
  );

  test(
    'calendar period query includes bounds, overnight coverage, and labels',
    () async {
      final overnight = WorkShift(
        id: _id(65),
        plannedInterval: ZonedInterval(
          startDate: LocalDate(2026, 8, 31),
          startTime: LocalTime(22, 0),
          endTime: LocalTime(2, 0),
          timeZone: _zone,
          startOffset: _offset,
          endOffset: _offset,
        ),
      );
      final session = ClinicalSession.schedule(
        id: _id(66),
        clinicalPlacementId: placement.id,
        preceptorId: alternate.id,
        plannedInterval: _interval(8, 9, 12),
        asOfUtc: _now,
      );
      final protected = ProtectedDay(id: _id(67), date: LocalDate(2026, 9, 1));
      registry.repositories.workShifts.seed(_studentId, overnight);
      registry.repositories.clinicalSessions.seed(_studentId, session);
      registry.repositories.protectedDays.seed(_studentId, protected);

      final snapshot = await service.readCalendarPeriod(
        studentId: _studentId,
        firstDate: LocalDate(2026, 8, 8),
        lastDate: LocalDate(2026, 9, 1),
      );

      expect(snapshot.workShifts.single.value.id, overnight.id);
      expect(snapshot.clinicalSessions.single.value.id, session.id);
      expect(snapshot.protectedDays.single.value.date, LocalDate(2026, 9, 1));
      final assignment = snapshot.clinicalAssignmentsBySessionId[session.id]!;
      expect(assignment.clinicalPlacementName, placement.name);
      expect(assignment.preceptorName, alternate.name);

      final continuationOnly = await service.readCalendarPeriod(
        studentId: _studentId,
        firstDate: LocalDate(2026, 9, 1),
        lastDate: LocalDate(2026, 9, 1),
      );
      expect(continuationOnly.workShifts.single.value.id, overnight.id);
    },
  );

  test('calendar period exposes Imported Work Shift conflicts', () async {
    final imported = WorkShift.imported(
      id: _id(68),
      plannedInterval: _interval(12, 8, 12),
      workScheduleFeedId: 'feed-1',
      workScheduleFeedName: 'ER Schedule',
    );
    final session = ClinicalSession.schedule(
      id: _id(69),
      clinicalPlacementId: placement.id,
      preceptorId: primary.id,
      plannedInterval: _interval(12, 10, 14),
      asOfUtc: _now,
    );
    registry.repositories.workShifts.seed(_studentId, imported);
    registry.repositories.clinicalSessions.seed(_studentId, session);

    final snapshot = await service.readCalendarPeriod(
      studentId: _studentId,
      firstDate: LocalDate(2026, 8, 12),
      lastDate: LocalDate(2026, 8, 12),
    );

    expect(snapshot.flaggedConflicts, hasLength(1));
    expect(
      snapshot.flaggedConflicts.single.conflictingCommitmentId,
      session.id,
    );
  });

  test(
    'one conflicting date reports all conflicts and writes no outbox',
    () async {
      registry.repositories.workShifts.seed(
        _studentId,
        WorkShift(id: _id(20), plannedInterval: _interval(12, 8, 12)),
      );
      registry.repositories.protectedDays.seed(
        _studentId,
        ProtectedDay(id: _id(21), date: LocalDate(2026, 8, 18)),
      );

      final result = await service.createClinicalSessionBatch(
        ClinicalSessionBatchRequest(
          studentId: _studentId,
          clinicalPlacementId: placement.id,
          items: [
            ClinicalSessionBatchItem(
              interval: _interval(12, 9, 15),
              preceptorId: primary.id,
            ),
            ClinicalSessionBatchItem(
              interval: _interval(18, 9, 15),
              preceptorId: primary.id,
            ),
          ],
        ),
      );

      expect(result.committed, isFalse);
      expect(
        result.conflicts.map((error) => error.violation),
        containsAll([
          ScheduleInvariantViolation.commitmentOverlap,
          ScheduleInvariantViolation.commitmentTouchesProtectedDay,
        ]),
      );
      expect(registry.repositories.clinicalSessions.values, isEmpty);
      expect(registry.repositories.mutations, isEmpty);
    },
  );

  test('overnight batches validate both covered dates', () async {
    registry.repositories.workShifts.seed(
      _studentId,
      WorkShift(id: _id(30), plannedInterval: _interval(13, 1, 3)),
    );
    registry.repositories.protectedDays.seed(
      _studentId,
      ProtectedDay(id: _id(31), date: LocalDate(2026, 8, 13)),
    );

    final result = await service.createWorkShiftBatch(
      WorkShiftBatchRequest(
        studentId: _studentId,
        intervals: [_interval(12, 22, 2)],
      ),
    );

    expect(result.committed, isFalse);
    expect(result.conflicts, hasLength(2));
    expect(
      result.conflicts.map((error) => error.conflictDate),
      everyElement(LocalDate(2026, 8, 13)),
    );
    expect(registry.repositories.mutations, isEmpty);
  });

  test(
    'Protected Day batch, move, removal update Planning Incomplete',
    () async {
      final created = await service.createProtectedDayBatch(
        ProtectedDayBatchRequest(
          studentId: _studentId,
          dates: [LocalDate(2026, 8, 2), LocalDate(2026, 8, 11)],
        ),
      );
      expect(created.committed, isTrue);
      final second = created.records[1];

      final moved = await service.moveProtectedDay(
        studentId: _studentId,
        id: second.value.id,
        destination: LocalDate(2026, 8, 13),
      );
      expect(moved.committed, isTrue);
      expect(moved.records.single.value.date, LocalDate(2026, 8, 13));

      final beforeRemoval = await service.missingProtectedDayWeeks(
        studentId: _studentId,
        year: 2026,
        month: 8,
      );
      await service.removeProtectedDay(
        studentId: _studentId,
        id: second.value.id,
      );
      final afterRemoval = await service.missingProtectedDayWeeks(
        studentId: _studentId,
        year: 2026,
        month: 8,
      );
      expect(afterRemoval.length, beforeRemoval.length + 1);
    },
  );

  test('moves commitments preserving data and rejecting collisions', () async {
    final shift = WorkShift(id: _id(40), plannedInterval: _interval(12, 7, 11));
    final session = ClinicalSession.schedule(
      id: _id(41),
      clinicalPlacementId: placement.id,
      preceptorId: alternate.id,
      plannedInterval: _interval(12, 13, 17),
      asOfUtc: _now,
    );
    registry.repositories.workShifts.seed(_studentId, shift);
    registry.repositories.clinicalSessions.seed(_studentId, session);

    final movedShift = await service.moveWorkShift(
      studentId: _studentId,
      id: shift.id,
      plannedInterval: _interval(14, 7, 11),
    );
    expect(movedShift.records.single.value.id, shift.id);
    expect(
      movedShift.records.single.value.plannedMinutes,
      shift.plannedMinutes,
    );

    final rejected = await service.reviseClinicalSession(
      studentId: _studentId,
      id: session.id,
      plannedInterval: _interval(14, 8, 10),
      preceptorId: session.preceptorId,
    );
    expect(rejected.committed, isFalse);
    expect(
      registry
          .repositories
          .clinicalSessions
          .values
          .single
          .plannedInterval
          .startDate,
      LocalDate(2026, 8, 12),
    );

    final movedPast = await service.reviseClinicalSession(
      studentId: _studentId,
      id: session.id,
      plannedInterval: _interval(8, 13, 17),
      preceptorId: session.preceptorId,
    );
    expect(movedPast.records.single.value.preceptorId, alternate.id);
    expect(
      movedPast.records.single.value.state,
      ClinicalSessionState.awaitingConfirmation,
    );
  });

  test('Imported Work Shifts cannot be moved or deleted by hand', () async {
    final imported = WorkShift.imported(
      id: _id(42),
      plannedInterval: _interval(12, 7, 11),
      workScheduleFeedId: 'feed-1',
      workScheduleFeedName: 'ER Schedule',
    );
    registry.repositories.workShifts.seed(_studentId, imported);

    final failures = <Future<Object?>>[
      service.moveWorkShift(
        studentId: _studentId,
        id: imported.id,
        plannedInterval: _interval(14, 7, 11),
      ),
      service.deleteWorkShift(
        ErroneousDeletionRequest(
          studentId: _studentId,
          id: imported.id,
          reason: ErroneousDeletionReason.erroneous,
          confirmed: true,
        ),
      ),
    ];

    for (final failure in failures) {
      await expectLater(
        failure,
        throwsA(
          isA<SchedulingUseCaseException>().having(
            (error) => error.kind,
            'kind',
            SchedulingUseCaseFailureKind.importedWorkShiftReadOnly,
          ),
        ),
      );
    }
    expect(registry.repositories.workShifts.values.single, same(imported));
  });

  test(
    'reassigns an existing Scheduled Session and refreshes its projections',
    () async {
      final session = ClinicalSession.schedule(
        id: _id(42),
        clinicalPlacementId: placement.id,
        preceptorId: primary.id,
        plannedInterval: _interval(18, 9, 15),
        asOfUtc: _now,
      );
      registry.repositories.clinicalSessions.seed(_studentId, session);

      final result = await service.reviseClinicalSession(
        studentId: _studentId,
        id: session.id,
        plannedInterval: session.plannedInterval,
        preceptorId: alternate.id,
      );

      final saved = result.records.single.value;
      expect(saved.id, session.id);
      expect(saved.clinicalPlacementId, placement.id);
      expect(saved.plannedInterval, same(session.plannedInterval));
      expect(saved.state, ClinicalSessionState.scheduled);
      expect(saved.preceptorId, alternate.id);

      final calendar = await service.readCalendarPeriod(
        studentId: _studentId,
        firstDate: LocalDate(2026, 8, 18),
        lastDate: LocalDate(2026, 8, 18),
      );
      expect(
        calendar.clinicalAssignmentsBySessionId[session.id]!.preceptorName,
        alternate.name,
      );
    },
  );

  test(
    'rejects reassignment to a detached Preceptor without mutation',
    () async {
      final detached = Preceptor(id: _id(12), name: 'Detached');
      registry.repositories.preceptors.seed(_studentId, detached);
      final session = ClinicalSession.schedule(
        id: _id(43),
        clinicalPlacementId: placement.id,
        preceptorId: primary.id,
        plannedInterval: _interval(18, 9, 15),
        asOfUtc: _now,
      );
      registry.repositories.clinicalSessions.seed(_studentId, session);

      await expectLater(
        service.reviseClinicalSession(
          studentId: _studentId,
          id: session.id,
          plannedInterval: session.plannedInterval,
          preceptorId: detached.id,
        ),
        throwsA(isA<DomainValidationException>()),
      );

      expect(
        registry.repositories.clinicalSessions.values.single.preceptorId,
        primary.id,
      );
      expect(registry.repositories.mutations, isEmpty);
    },
  );

  test('moving a Completed Session to today clears Completed Hours', () async {
    final completed = ClinicalSession.restore(
      id: _id(50),
      clinicalPlacementId: placement.id,
      preceptorId: primary.id,
      plannedInterval: _interval(8, 9, 12),
      state: ClinicalSessionState.completed,
      actualInterval: _intervalMinutes(8, 9, 0, 12, 37),
    );
    registry.repositories.clinicalSessions.seed(_studentId, completed);

    final moved = await service.reviseClinicalSession(
      studentId: _studentId,
      id: completed.id,
      plannedInterval: _interval(10, 9, 12),
      preceptorId: completed.preceptorId,
    );

    expect(moved.records.single.value.state, ClinicalSessionState.scheduled);
    expect(moved.records.single.value.actualInterval, isNull);
    final progress = await service.readPlacementProgress(
      studentId: _studentId,
      clinicalPlacementId: placement.id,
      today: LocalDate(2026, 8, 10),
    );
    expect(progress.completedMinutes, 0);
  });

  test(
    'template application copies values and ignores later template edits',
    () async {
      final templateId = _id(60);
      registry.repositories.scheduleTemplates.seed(
        _studentId,
        ScheduleTemplate(
          id: templateId,
          name: 'Clinic morning',
          type: ScheduleTemplateType.clinicalSession,
          startTime: LocalTime(8, 15),
          endTime: LocalTime(12, 45),
          clinicalPlacementId: placement.id,
          preceptorId: primary.id,
        ),
      );
      final result = await service.applyTemplate(
        TemplateBatchRequest(
          studentId: _studentId,
          templateId: templateId,
          dates: [_zonedDate(17)],
        ),
      );
      final saved = result.records.single.value as ClinicalSession;

      registry.repositories.scheduleTemplates.replaceSeed(
        _studentId,
        ScheduleTemplate(
          id: templateId,
          name: 'Changed',
          type: ScheduleTemplateType.clinicalSession,
          startTime: LocalTime(10, 0),
          endTime: LocalTime(11, 0),
          clinicalPlacementId: placement.id,
          preceptorId: alternate.id,
        ),
      );

      expect(saved.plannedInterval.startTime, LocalTime(8, 15));
      expect(saved.plannedInterval.endTime, LocalTime(12, 45));
      expect(saved.preceptorId, primary.id);
    },
  );

  test(
    'military/12-hour display does not change stored interval or duration',
    () async {
      final result = await service.createWorkShiftBatch(
        WorkShiftBatchRequest(
          studentId: _studentId,
          intervals: [_intervalMinutes(12, 13, 5, 21, 47)],
        ),
      );
      final interval = result.records.single.value.plannedInterval;
      final startInstant = interval.startInstantUtc;
      final duration = interval.elapsedMinutes;

      expect(interval.startTime.military, '13:05');
      expect(interval.startTime.twelveHour, '1:05 PM');
      expect(interval.startInstantUtc, startInstant);
      expect(interval.elapsedMinutes, duration);
      expect(duration, 522);
    },
  );

  test(
    'confirmation corrects actual times and Preceptor with exact minutes',
    () async {
      final awaiting = ClinicalSession.schedule(
        id: _id(70),
        clinicalPlacementId: placement.id,
        preceptorId: primary.id,
        plannedInterval: _interval(8, 8, 16),
        asOfUtc: _now,
      );
      registry.repositories.clinicalSessions.seed(_studentId, awaiting);

      final confirmed = await service.confirmClinicalSession(
        studentId: _studentId,
        id: awaiting.id,
        actualInterval: _intervalMinutes(8, 8, 17, 15, 53),
        preceptorId: alternate.id,
      );
      expect(confirmed.records.single.value.completedMinutes, 456);
      expect(confirmed.records.single.value.preceptorId, alternate.id);

      final progress = await service.readPlacementProgress(
        studentId: _studentId,
        clinicalPlacementId: placement.id,
        today: LocalDate(2026, 8, 10),
      );
      expect(progress.completedMinutes, 456);
      expect(progress.awaitingConfirmationMinutes, 0);
      expect(progress.preceptorProgress[alternate.id]!.completedMinutes, 456);
      expect(progress.preceptorProgress[primary.id]!.completedMinutes, 0);
    },
  );

  test(
    'cancel, Missed, delete, and placement lifecycle guards are enforced',
    () async {
      final awaiting = ClinicalSession.schedule(
        id: _id(80),
        clinicalPlacementId: placement.id,
        preceptorId: primary.id,
        plannedInterval: _interval(8, 9, 12),
        asOfUtc: _now,
      );
      final scheduled = ClinicalSession.schedule(
        id: _id(81),
        clinicalPlacementId: placement.id,
        preceptorId: primary.id,
        plannedInterval: _interval(20, 9, 12),
        asOfUtc: _now,
      );
      registry.repositories.clinicalSessions.seed(_studentId, awaiting);
      registry.repositories.clinicalSessions.seed(_studentId, scheduled);

      expect(
        (await service.markClinicalSessionMissed(
          studentId: _studentId,
          id: awaiting.id,
        )).value.state,
        ClinicalSessionState.missed,
      );
      expect(
        (await service.cancelClinicalSession(
          studentId: _studentId,
          id: scheduled.id,
        )).value.state,
        ClinicalSessionState.cancelled,
      );
      await expectLater(
        service.deleteClinicalSession(
          ErroneousDeletionRequest(
            studentId: _studentId,
            id: awaiting.id,
            reason: ErroneousDeletionReason.erroneous,
            confirmed: false,
          ),
        ),
        throwsA(
          isA<SchedulingUseCaseException>().having(
            (error) => error.kind,
            'kind',
            SchedulingUseCaseFailureKind.deletionNotConfirmed,
          ),
        ),
      );
      await service.deleteClinicalSession(
        ErroneousDeletionRequest(
          studentId: _studentId,
          id: awaiting.id,
          reason: ErroneousDeletionReason.duplicate,
          confirmed: true,
        ),
      );
      expect(registry.repositories.clinicalSessions.values, hasLength(1));

      registry.repositories.clinicalPlacements.replaceSeed(
        _studentId,
        ClinicalPlacement.restore(
          id: placement.id,
          name: placement.name,
          targetHours: placement.targetHours,
          startDate: placement.startDate,
          completionDeadline: placement.completionDeadline,
          attachedPreceptorIds: placement.attachedPreceptorIds,
          primaryPreceptorId: placement.primaryPreceptorId,
          evaluationPlanId: placement.evaluationPlanId,
          state: ClinicalPlacementState.completed,
        ),
      );
      await expectLater(
        service.createClinicalSessionBatch(
          ClinicalSessionBatchRequest(
            studentId: _studentId,
            clinicalPlacementId: placement.id,
            items: [
              ClinicalSessionBatchItem(
                interval: _interval(24, 9, 12),
                preceptorId: primary.id,
              ),
            ],
          ),
        ),
        throwsA(
          isA<SchedulingUseCaseException>().having(
            (error) => error.kind,
            'kind',
            SchedulingUseCaseFailureKind.completedPlacement,
          ),
        ),
      );
      final unresolved = ClinicalSession.schedule(
        id: _id(82),
        clinicalPlacementId: placement.id,
        preceptorId: primary.id,
        plannedInterval: _interval(25, 9, 12),
        asOfUtc: _now,
      );
      registry.repositories.clinicalSessions.seed(_studentId, unresolved);
      await expectLater(
        service.cancelClinicalSession(studentId: _studentId, id: unresolved.id),
        throwsA(
          isA<SchedulingUseCaseException>().having(
            (error) => error.kind,
            'kind',
            SchedulingUseCaseFailureKind.completedPlacement,
          ),
        ),
      );
    },
  );

  test(
    'corrected confirmation conflict leaves Awaiting Session unchanged',
    () async {
      final awaiting = ClinicalSession.schedule(
        id: _id(85),
        clinicalPlacementId: placement.id,
        preceptorId: primary.id,
        plannedInterval: _interval(8, 8, 12),
        asOfUtc: _now,
      );
      registry.repositories.clinicalSessions.seed(_studentId, awaiting);
      registry.repositories.workShifts.seed(
        _studentId,
        WorkShift(id: _id(86), plannedInterval: _interval(8, 14, 18)),
      );
      final mutationCount = registry.repositories.mutations.length;

      final result = await service.confirmClinicalSession(
        studentId: _studentId,
        id: awaiting.id,
        actualInterval: _interval(8, 13, 16),
        preceptorId: alternate.id,
      );

      expect(result.committed, isFalse);
      expect(
        result.conflicts.single.violation,
        ScheduleInvariantViolation.commitmentOverlap,
      );
      expect(
        registry.repositories.clinicalSessions.values.single.state,
        ClinicalSessionState.awaitingConfirmation,
      );
      expect(registry.repositories.mutations, hasLength(mutationCount));
    },
  );

  test(
    'Protected Day move rejects commitments and crossing week boundary',
    () async {
      final day = ProtectedDay(id: _id(90), date: LocalDate(2026, 8, 9));
      registry.repositories.protectedDays.seed(_studentId, day);
      registry.repositories.workShifts.seed(
        _studentId,
        WorkShift(id: _id(91), plannedInterval: _interval(11, 8, 12)),
      );

      final conflict = await service.moveProtectedDay(
        studentId: _studentId,
        id: day.id,
        destination: LocalDate(2026, 8, 11),
      );
      expect(conflict.committed, isFalse);
      expect(
        conflict.conflicts.single.violation,
        ScheduleInvariantViolation.commitmentTouchesProtectedDay,
      );
      await expectLater(
        service.moveProtectedDay(
          studentId: _studentId,
          id: day.id,
          destination: LocalDate(2026, 8, 16),
        ),
        throwsA(
          isA<SchedulingUseCaseException>().having(
            (error) => error.kind,
            'kind',
            SchedulingUseCaseFailureKind.protectedDayMoveChangesWeek,
          ),
        ),
      );
      expect(registry.repositories.protectedDays.values.single.date, day.date);
    },
  );
}

ClinicalPlacement _placement(String primaryId, String alternateId) =>
    ClinicalPlacement.create(
      id: _id(2),
      name: 'Family Medicine',
      targetHours: TargetHours.fromWholeHours(270),
      startDate: LocalDate(2026, 8, 1),
      completionDeadline: LocalDate(2026, 12, 31),
      attachedPreceptorIds: [primaryId, alternateId],
      primaryPreceptorId: primaryId,
      evaluationPlanId: _id(3),
    );

ZonedInterval _interval(int day, int startHour, int endHour) => ZonedInterval(
  startDate: LocalDate(2026, 8, day),
  startTime: LocalTime(startHour, 0),
  endTime: LocalTime(endHour, 0),
  timeZone: _zone,
  startOffset: _offset,
  endOffset: _offset,
);

ZonedInterval _intervalMinutes(
  int day,
  int startHour,
  int startMinute,
  int endHour,
  int endMinute,
) => ZonedInterval(
  startDate: LocalDate(2026, 8, day),
  startTime: LocalTime(startHour, startMinute),
  endTime: LocalTime(endHour, endMinute),
  timeZone: _zone,
  startOffset: _offset,
  endOffset: _offset,
);

ZonedScheduleDate _zonedDate(int day) => ZonedScheduleDate(
  date: LocalDate(2026, 8, day),
  timeZone: _zone,
  startOffset: _offset,
  endOffset: _offset,
);

String _id(int value) =>
    '00000000-0000-4000-8000-${value.toRadixString(16).padLeft(12, '0')}';

void _expectDistinctMutationTokens(List<MutationToken> mutations) {
  expect(
    mutations.map((mutation) => mutation.operationId).toSet(),
    hasLength(mutations.length),
  );
  expect(
    mutations.map((mutation) => mutation.idempotencyKey).toSet(),
    hasLength(mutations.length),
  );
}

final class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime nowUtc() => value;
}

final class _SequenceIdentifiers implements IdentifierGenerator {
  _SequenceIdentifiers(this.next);

  int next;

  @override
  String nextIdentifier() => _id(next++);
}

final class _MemoryRegistry implements RepositoryRegistry {
  final _MemoryRepositories repositories = _MemoryRepositories();

  @override
  Future<void> initialize() async {}

  @override
  Future<R> read<R>(
    R Function(LocalReadRepositories repositories) callback,
  ) async => callback(repositories);

  @override
  Future<R> mutate<R>(
    R Function(LocalWriteRepositories repositories) callback,
  ) async {
    final snapshot = repositories.snapshot();
    try {
      return callback(repositories);
    } on Object {
      repositories.restore(snapshot);
      rethrow;
    }
  }
}

final class _MemoryRepositories
    implements WorkScheduleFeedLocalWriteRepositories {
  @override
  final _MemoryRepository<WorkScheduleFeed> workScheduleFeeds =
      _MemoryRepository((value) => value.id);
  @override
  final _MemoryRepository<WorkShift> workShifts = _MemoryRepository(
    (value) => value.id,
  );
  @override
  final _MemoryRepository<ClinicalSession> clinicalSessions = _MemoryRepository(
    (value) => value.id,
  );
  @override
  final _MemoryRepository<ProtectedDay> protectedDays = _MemoryRepository(
    (value) => value.id,
  );
  @override
  final _MemoryRepository<ScheduleTemplate> scheduleTemplates =
      _MemoryRepository((value) => value.id);
  @override
  final _MemoryRepository<Preceptor> preceptors = _MemoryRepository(
    (value) => value.id,
  );
  @override
  final _MemoryRepository<ClinicalPlacement> clinicalPlacements =
      _MemoryRepository((value) => value.id);
  @override
  final _MemoryRepository<HistoricalHoursEntry> historicalHoursEntries =
      _MemoryRepository((value) => value.id);
  @override
  final _MemoryRepository<EvaluationPlan> evaluationPlans = _MemoryRepository(
    (value) => value.id,
  );
  @override
  final _MemoryOutbox outbox = _MemoryOutbox();
  @override
  final _MemorySyncCursors syncCursors = _MemorySyncCursors();
  @override
  final _MemoryActivePlacementSelection activePlacementSelection =
      _MemoryActivePlacementSelection();

  final List<MutationToken> mutations = [];

  _MemoryRepositories() {
    for (final repository in _all) {
      repository.onMutation = mutations.add;
    }
  }

  List<_MemoryRepository<Object>> get _all => [
    workScheduleFeeds,
    workShifts,
    clinicalSessions,
    protectedDays,
    scheduleTemplates,
    preceptors,
    clinicalPlacements,
    historicalHoursEntries,
    evaluationPlans,
  ];

  _RepositoriesSnapshot snapshot() => _RepositoriesSnapshot(
    maps: [for (final repository in _all) repository.copyRecords()],
    mutations: List.of(mutations),
  );

  void restore(_RepositoriesSnapshot snapshot) {
    for (var index = 0; index < _all.length; index++) {
      _all[index].restoreRecords(snapshot.maps[index]);
    }
    mutations
      ..clear()
      ..addAll(snapshot.mutations);
  }
}

final class _RepositoriesSnapshot {
  const _RepositoriesSnapshot({required this.maps, required this.mutations});

  final List<Map<String, StoredDomainRecord<Object>>> maps;
  final List<MutationToken> mutations;
}

final class _MemoryRepository<T> implements MutableRepository<T> {
  _MemoryRepository(this.idOf);

  final String Function(T) idOf;
  final Map<String, StoredDomainRecord<T>> _records = {};
  void Function(MutationToken mutation)? onMutation;

  List<T> get values => _records.values
      .where((record) => !record.isDeleted)
      .map((record) => record.value)
      .toList(growable: false);

  void seed(String studentId, T value) {
    _records[idOf(value)] = StoredDomainRecord(
      value: value,
      studentId: studentId,
      revision: 1,
      createdAtUtc: _now,
      updatedAtUtc: _now,
    );
  }

  void replaceSeed(String studentId, T value) => seed(studentId, value);

  @override
  StoredDomainRecord<T>? find({
    required String studentId,
    required String id,
    bool includeDeleted = false,
  }) {
    final record = _records[id];
    if (record == null || record.studentId != studentId) return null;
    if (!includeDeleted && record.isDeleted) return null;
    return record;
  }

  @override
  List<StoredDomainRecord<T>> list({
    required String studentId,
    bool includeDeleted = false,
  }) => _records.values
      .where(
        (record) =>
            record.studentId == studentId &&
            (includeDeleted || !record.isDeleted),
      )
      .toList(growable: false);

  @override
  MutationReceipt<T> put({
    required String studentId,
    required T value,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    final current = _records[idOf(value)];
    final revision = current?.revision ?? 0;
    if (revision != expectedRevision) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'Revision mismatch.',
      );
    }
    final record = StoredDomainRecord(
      value: value,
      studentId: studentId,
      revision: revision + 1,
      createdAtUtc: current?.createdAtUtc ?? mutation.occurredAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
    );
    _records[idOf(value)] = record;
    onMutation?.call(mutation);
    return MutationReceipt(record: record, replayed: false);
  }

  @override
  MutationReceipt<T> tombstone({
    required String studentId,
    required String id,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    final current = _records[id];
    if (current == null || current.revision != expectedRevision) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'Revision mismatch.',
      );
    }
    final record = StoredDomainRecord(
      value: current.value,
      studentId: studentId,
      revision: current.revision + 1,
      createdAtUtc: current.createdAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
      deletedAtUtc: mutation.occurredAtUtc,
    );
    _records[id] = record;
    onMutation?.call(mutation);
    return MutationReceipt(record: record, replayed: false);
  }

  Map<String, StoredDomainRecord<Object>> copyRecords() => {
    for (final entry in _records.entries)
      entry.key: entry.value as StoredDomainRecord<Object>,
  };

  void restoreRecords(Map<String, StoredDomainRecord<Object>> source) {
    _records
      ..clear()
      ..addEntries(
        source.entries.map(
          (entry) => MapEntry(entry.key, entry.value as StoredDomainRecord<T>),
        ),
      );
  }
}

final class _MemoryOutbox implements OutboxMaintenanceRepository {
  @override
  void acknowledge({
    required String studentId,
    required String operationId,
    required int serverCursor,
    required DateTime acknowledgedAtUtc,
  }) {}

  @override
  List<OutboxOperation> pending({
    required String studentId,
    required DateTime asOfUtc,
    OutboxPendingPolicy policy = const OutboxPendingPolicy(),
    int limit = 100,
  }) => const [];

  @override
  void recordFailedAttempt({
    required String studentId,
    required String operationId,
    required DateTime attemptedAtUtc,
    required DateTime nextAttemptAtUtc,
    required String failureCode,
  }) {}
}

final class _MemorySyncCursors implements SyncCursorRepository {
  final Map<String, SyncCursor> values = {};

  @override
  SyncCursor? find({required String studentId, required String remoteScope}) =>
      values['$studentId/$remoteScope'];

  @override
  void put(SyncCursor cursor) {
    values['${cursor.studentId}/${cursor.remoteScope}'] = cursor;
  }
}

final class _MemoryActivePlacementSelection
    implements ActivePlacementSelectionRepository {
  StoredDomainRecord<String?>? value;

  @override
  StoredDomainRecord<String?>? find({required String studentId}) =>
      value?.studentId == studentId ? value : null;

  @override
  MutationReceipt<String?> put({
    required String studentId,
    required String? clinicalPlacementId,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    final currentRevision = value?.revision ?? 0;
    if (currentRevision != expectedRevision) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'Revision mismatch.',
      );
    }
    final record = StoredDomainRecord<String?>(
      value: clinicalPlacementId,
      studentId: studentId,
      revision: currentRevision + 1,
      createdAtUtc: value?.createdAtUtc ?? mutation.occurredAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
    );
    value = record;
    return MutationReceipt(record: record, replayed: false);
  }
}
