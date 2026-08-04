import 'package:clinical_calendar_application/src/reminders/reminder_policy.dart';
import 'package:test/test.dart';

void main() {
  final zones = _FixedZones(const Duration(hours: -5));
  final policy = ReminderPolicy(zones);

  test('quiet hours delay every notification category', () {
    final at = DateTime.utc(2026, 1, 3, 3); // 22:00 local previous day.
    final result = policy.build(
      nowUtc: at.subtract(const Duration(hours: 1)),
      candidates: [
        ReminderCandidate(
          kind: ReminderKind.weeklySummary,
          subjectId: 'w',
          anchorUtc: at,
          title: 'Weekly',
          route: '/weekly',
        ),
        ReminderCandidate(
          kind: ReminderKind.syncConflict,
          subjectId: 'c',
          anchorUtc: at,
          title: 'Conflict',
          route: '/sync',
        ),
      ],
      deviceTimeZoneId: 'fixed',
    );
    expect(
      result
          .singleWhere((e) => e.kind == ReminderKind.weeklySummary)
          .scheduledForUtc,
      DateTime.utc(2026, 1, 3, 12),
    );
    expect(
      result
          .singleWhere((e) => e.kind == ReminderKind.syncConflict)
          .scheduledForUtc,
      DateTime.utc(2026, 1, 3, 12),
    );
  });

  test('only configurable reminder kinds can be disabled', () {
    final at = DateTime.utc(2026, 1, 3, 15);
    final result = policy.build(
      nowUtc: at.subtract(const Duration(hours: 1)),
      candidates: [
        ReminderCandidate(
          kind: ReminderKind.weeklySummary,
          subjectId: 'w',
          anchorUtc: at,
          title: 'Weekly',
          route: '/weekly',
        ),
        ReminderCandidate(
          kind: ReminderKind.deadlineRisk,
          subjectId: 'd',
          anchorUtc: at,
          title: 'Risk',
          route: '/risk',
        ),
      ],
      deviceTimeZoneId: 'fixed',
      disabledKinds: {ReminderKind.weeklySummary, ReminderKind.deadlineRisk},
    );
    expect(result.map((e) => e.kind), [ReminderKind.deadlineRisk]);
  });

  test(
    'synchronized snooze changes stable occurrence and contextual actions',
    () {
      final at = DateTime.utc(2026, 1, 3, 15);
      final base = 'clinicalConfirmation:s:${at.toIso8601String()}';
      final snooze = at.add(const Duration(hours: 1));
      final result = policy.build(
        nowUtc: at.subtract(const Duration(hours: 1)),
        candidates: [
          ReminderCandidate(
            kind: ReminderKind.clinicalConfirmation,
            subjectId: 's',
            anchorUtc: at,
            title: 'Confirm',
            route: '/session/s',
          ),
        ],
        deviceTimeZoneId: 'fixed',
        synchronizedSnoozes: {base: snooze},
      );
      expect(result.single.scheduledForUtc, snooze);
      expect(result.single.snoozeOptions, [
        ReminderSnooze.oneHour,
        ReminderSnooze.tomorrowMorning,
      ]);
      expect(result.single.occurrenceKey, contains(snooze.toIso8601String()));
    },
  );

  test('default schedules expand required anchors', () {
    final schedules = DefaultReminderSchedules(zones);
    final start = DateTime.utc(2026, 2, 10, 14);
    expect(
      schedules
          .upcoming(
            kind: ReminderKind.upcomingClinicalSession,
            subjectId: 's',
            startsAtUtc: start,
            commitmentTimeZoneId: 'fixed',
            route: '/s',
          )
          .map((e) => e.anchorUtc),
      [
        start.subtract(const Duration(hours: 24)),
        start.subtract(const Duration(hours: 2)),
      ],
    );
    expect(
      schedules
          .protectedWeek(weekId: 'w', weekStartsUtc: start, route: '/w')
          .length,
      2,
    );
    expect(
      schedules
          .initialSelfAssessment(
            placementId: 'p',
            placementStartsUtc: start,
            throughUtc: start.add(const Duration(days: 7)),
            route: '/p',
          )
          .map((e) => e.anchorUtc),
      containsAll([
        start.subtract(const Duration(days: 7)),
        start.subtract(const Duration(days: 1)),
        start,
      ]),
    );
    expect(
      schedules.interimReview(
        placementId: 'p',
        completedHours: 42,
        thresholdHours: 50,
        nowUtc: start,
        nextSessionStartsUtc: start.add(const Duration(days: 1)),
        nextSessionHours: 8,
        selfAssessmentComplete: false,
        preceptorAssessmentComplete: true,
        throughUtc: start.add(const Duration(days: 7)),
        route: '/p',
      ),
      isNotEmpty,
    );
    expect(
      schedules
          .finalEvaluation(
            kind: ReminderKind.finalSelfAssessment,
            requirementId: 'final-self',
            completedHours: 100,
            targetHours: 100,
            nowUtc: start,
            deadlineUtc: start.add(const Duration(days: 20)),
            hasFutureClinicalSessions: false,
            evaluationComplete: false,
            throughUtc: start.add(const Duration(days: 7)),
            route: '/p',
          )
          .first
          .title,
      'Final evaluation is due',
    );
  });

  test('per-commitment upcoming overrides can change leads or disable', () {
    final schedules = DefaultReminderSchedules(zones);
    final start = DateTime.utc(2026, 2, 10, 14);
    expect(
      schedules
          .upcoming(
            kind: ReminderKind.upcomingWorkShift,
            subjectId: 'work',
            startsAtUtc: start,
            commitmentTimeZoneId: 'fixed',
            route: '/work',
            first: const Duration(hours: 12),
            second: const Duration(hours: 1),
          )
          .map((value) => value.anchorUtc),
      [
        start.subtract(const Duration(hours: 12)),
        start.subtract(const Duration(hours: 1)),
      ],
    );
    expect(
      schedules.upcoming(
        kind: ReminderKind.upcomingClinicalSession,
        subjectId: 'session',
        startsAtUtc: start,
        commitmentTimeZoneId: 'fixed',
        route: '/session',
        enabled: false,
      ),
      isEmpty,
    );
  });

  test('every contextual snooze choice resolves deterministically', () {
    final chosenAt = DateTime.utc(2026, 1, 3, 15); // 10:00 fixed local.
    expect(
      policy.snoozedUntilUtc(
        choice: ReminderSnooze.fifteenMinutes,
        chosenAtUtc: chosenAt,
        deviceTimeZoneId: 'fixed',
      ),
      DateTime.utc(2026, 1, 3, 15, 15),
    );
    expect(
      policy.snoozedUntilUtc(
        choice: ReminderSnooze.oneHour,
        chosenAtUtc: chosenAt,
        deviceTimeZoneId: 'fixed',
      ),
      DateTime.utc(2026, 1, 3, 16),
    );
    expect(
      policy.snoozedUntilUtc(
        choice: ReminderSnooze.laterToday,
        chosenAtUtc: chosenAt,
        deviceTimeZoneId: 'fixed',
      ),
      DateTime.utc(2026, 1, 3, 23),
    );
    expect(
      policy.snoozedUntilUtc(
        choice: ReminderSnooze.tomorrowMorning,
        chosenAtUtc: chosenAt,
        deviceTimeZoneId: 'fixed',
      ),
      DateTime.utc(2026, 1, 4, 14),
    );
    expect(
      policy.snoozedUntilUtc(
        choice: ReminderSnooze.threeDays,
        chosenAtUtc: chosenAt,
        deviceTimeZoneId: 'fixed',
      ),
      DateTime.utc(2026, 1, 6, 15),
    );
    expect(
      policy.snoozedUntilUtc(
        choice: ReminderSnooze.oneWeek,
        chosenAtUtc: chosenAt,
        deviceTimeZoneId: 'fixed',
      ),
      DateTime.utc(2026, 1, 10, 15),
    );
  });

  test('default schedules cover every normative reminder category', () {
    final schedules = DefaultReminderSchedules(zones);
    final clock = _FakeClock(DateTime.utc(2026, 2, 1, 12));
    final end = clock.nowUtc.add(const Duration(days: 15));
    final candidates = <ReminderCandidate>[
      ...schedules.upcoming(
        kind: ReminderKind.upcomingWorkShift,
        subjectId: 'work',
        startsAtUtc: end,
        commitmentTimeZoneId: 'fixed',
        route: '/work',
      ),
      ...schedules.upcoming(
        kind: ReminderKind.upcomingClinicalSession,
        subjectId: 'clinical',
        startsAtUtc: end,
        commitmentTimeZoneId: 'fixed',
        route: '/clinical',
      ),
      ...schedules.clinicalConfirmation(
        subjectId: 'clinical',
        endsAtUtc: clock.nowUtc,
        nextMorningNineUtc: clock.nowUtc.add(const Duration(hours: 21)),
        throughUtc: end,
        route: '/clinical',
      ),
      ...schedules.protectedWeek(
        weekId: 'week',
        weekStartsUtc: end,
        route: '/planning',
      ),
      ...schedules.initialSelfAssessment(
        placementId: 'placement',
        placementStartsUtc: clock.nowUtc.add(const Duration(days: 7)),
        throughUtc: end,
        route: '/evaluation',
      ),
      ...schedules.interimReview(
        placementId: 'placement',
        completedHours: 41,
        thresholdHours: 50,
        nowUtc: clock.nowUtc,
        selfAssessmentComplete: false,
        preceptorAssessmentComplete: false,
        throughUtc: end,
        route: '/evaluation',
      ),
      ...schedules.finalEvaluation(
        kind: ReminderKind.finalSelfAssessment,
        requirementId: 'final-self',
        completedHours: 91,
        targetHours: 100,
        nowUtc: clock.nowUtc,
        deadlineUtc: end,
        hasFutureClinicalSessions: true,
        evaluationComplete: false,
        throughUtc: end,
        route: '/evaluation',
      ),
      ...schedules.finalEvaluation(
        kind: ReminderKind.finalPlacementReview,
        requirementId: 'final-placement',
        completedHours: 91,
        targetHours: 100,
        nowUtc: clock.nowUtc,
        deadlineUtc: end,
        hasFutureClinicalSessions: true,
        evaluationComplete: false,
        throughUtc: end,
        route: '/evaluation',
      ),
      ...schedules.weeklySummary(
        weekId: 'week',
        sundayAtConfiguredTimeUtc: end,
        route: '/summary',
      ),
      schedules.deadlineRisk(
        id: 'placement',
        detectedAtUtc: clock.nowUtc,
        route: '/placement',
      ),
      ...schedules.portableBackup(
        profileId: 'profile',
        setupAtUtc: clock.nowUtc.subtract(const Duration(days: 7)),
        lastBackupAtUtc: null,
        nowUtc: clock.nowUtc,
        route: '/backup',
      ),
      ...schedules.syncHealth(
        deviceId: 'device',
        conflictDetectedAtUtc: clock.nowUtc,
        failureStartedAtUtc: clock.nowUtc,
        oldestUnsynchronizedChangeUtc: clock.nowUtc,
        route: '/sync',
      ),
    ];
    expect(
      candidates.map((value) => value.kind).toSet(),
      ReminderKind.values.toSet(),
    );
  });

  test(
    'approaching evaluations follow either trigger and not overdue dates',
    () {
      final schedules = DefaultReminderSchedules(zones);
      final now = DateTime.utc(2026, 2, 1, 12);
      expect(
        schedules.interimReview(
          placementId: 'placement',
          completedHours: 41,
          thresholdHours: 50,
          nowUtc: now,
          selfAssessmentComplete: false,
          preceptorAssessmentComplete: true,
          throughUtc: now,
          route: '/evaluation',
        ),
        isNotEmpty,
      );
      expect(
        schedules.interimReview(
          placementId: 'placement',
          completedHours: 20,
          thresholdHours: 50,
          nowUtc: now,
          nextSessionStartsUtc: now,
          nextSessionHours: 30,
          selfAssessmentComplete: false,
          preceptorAssessmentComplete: true,
          throughUtc: now,
          route: '/evaluation',
        ),
        isNotEmpty,
      );
      expect(
        schedules.finalEvaluation(
          kind: ReminderKind.finalPlacementReview,
          requirementId: 'final-placement',
          completedHours: 50,
          targetHours: 100,
          nowUtc: now,
          deadlineUtc: now.subtract(const Duration(days: 1)),
          hasFutureClinicalSessions: false,
          evaluationComplete: false,
          throughUtc: now,
          route: '/evaluation',
        ),
        isEmpty,
      );
    },
  );

  test('default cadence anchors are exact for persistent workflows', () {
    final schedules = DefaultReminderSchedules(zones);
    final base = DateTime.utc(2026, 2, 10, 12);
    expect(
      schedules
          .clinicalConfirmation(
            subjectId: 'session',
            endsAtUtc: base,
            nextMorningNineUtc: base.add(const Duration(hours: 21)),
            throughUtc: base.add(const Duration(days: 7)),
            route: '/session',
          )
          .map((value) => value.anchorUtc),
      [
        base.add(const Duration(minutes: 30)),
        base.add(const Duration(hours: 21)),
        base.add(const Duration(hours: 21, days: 3)),
        base.add(const Duration(hours: 21, days: 6)),
      ],
    );
    expect(
      schedules
          .protectedWeek(
            weekId: 'week',
            weekStartsUtc: base,
            route: '/planning',
          )
          .map((value) => value.anchorUtc),
      [
        base.subtract(const Duration(days: 3)),
        base.subtract(const Duration(days: 1)),
      ],
    );
    expect(
      schedules
          .initialSelfAssessment(
            placementId: 'placement',
            placementStartsUtc: base,
            throughUtc: base.add(const Duration(days: 7)),
            route: '/evaluation',
          )
          .map((value) => value.anchorUtc),
      [
        base.subtract(const Duration(days: 7)),
        base.subtract(const Duration(days: 1)),
        base,
        base.add(const Duration(days: 3)),
        base.add(const Duration(days: 6)),
      ],
    );
    expect(
      schedules
          .syncHealth(
            deviceId: 'device',
            conflictDetectedAtUtc: base,
            failureStartedAtUtc: base,
            oldestUnsynchronizedChangeUtc: base,
            route: '/sync',
          )
          .map((value) => value.anchorUtc),
      [
        base,
        base.add(const Duration(hours: 1)),
        base.add(const Duration(hours: 24)),
      ],
    );
    expect(
      schedules
          .portableBackup(
            profileId: 'profile',
            setupAtUtc: base.subtract(const Duration(days: 22)),
            lastBackupAtUtc: null,
            nowUtc: base,
            route: '/backup',
          )
          .single
          .anchorUtc,
      base.add(const Duration(days: 6)),
    );
  });

  test('past anchors are filtered or rolled forward by source semantics', () {
    final now = DateTime.utc(2026, 2, 10, 12);
    final past = now.subtract(const Duration(hours: 1));
    final result = policy.build(
      nowUtc: now,
      candidates: [
        ReminderCandidate(
          kind: ReminderKind.upcomingWorkShift,
          subjectId: 'work',
          anchorUtc: past,
          title: 'Upcoming',
          route: '/work',
        ),
        ReminderCandidate(
          kind: ReminderKind.syncConflict,
          subjectId: 'conflict',
          anchorUtc: past,
          title: 'Conflict',
          route: '/sync',
          deliverWhenPastDue: true,
        ),
      ],
      deviceTimeZoneId: 'fixed',
    );
    expect(result, hasLength(1));
    expect(result.single.kind, ReminderKind.syncConflict);
    expect(result.single.scheduledForUtc, now);
  });

  test('quiet-hour start is delayed and end is immediately deliverable', () {
    final starts = DateTime.utc(2026, 2, 11, 2); // 21:00 fixed local.
    final ends = DateTime.utc(2026, 2, 11, 12); // 07:00 fixed local.
    final result = policy.build(
      nowUtc: starts.subtract(const Duration(hours: 1)),
      candidates: [
        ReminderCandidate(
          kind: ReminderKind.weeklySummary,
          subjectId: 'start',
          anchorUtc: starts,
          title: 'Start',
          route: '/summary',
        ),
        ReminderCandidate(
          kind: ReminderKind.weeklySummary,
          subjectId: 'end',
          anchorUtc: ends,
          title: 'End',
          route: '/summary',
        ),
      ],
      deviceTimeZoneId: 'fixed',
    );
    expect(result.map((value) => value.scheduledForUtc), [ends, ends]);
  });
}

final class _FakeClock {
  const _FakeClock(this.nowUtc);
  final DateTime nowUtc;
}

final class _FixedZones implements ReminderTimeZoneResolver {
  const _FixedZones(this.offset);
  final Duration offset;
  @override
  DateTime fromLocal(DateTime localWallClock, String timeZoneId) =>
      DateTime.utc(
        localWallClock.year,
        localWallClock.month,
        localWallClock.day,
        localWallClock.hour,
        localWallClock.minute,
      ).subtract(offset);
  @override
  DateTime toLocal(DateTime utc, String timeZoneId) => utc.toUtc().add(offset);
}
