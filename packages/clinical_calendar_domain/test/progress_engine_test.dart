import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

void main() {
  const engine = ClinicalPlacementProgressEngine();

  group('Clinical Placement progress ledger', () {
    final cases =
        <
          ({
            String name,
            int target,
            List<ClinicalSession> sessions,
            List<HistoricalHoursEntry> history,
            int completed,
            int scheduled,
            int awaiting,
            int historical,
            int remaining,
            int unscheduled,
            int overTarget,
          })
        >[
          (
            name: 'uses corrected actual minutes instead of planned minutes',
            target: 600,
            sessions: [
              _session(
                id: 'corrected',
                state: ClinicalSessionState.completed,
                plannedStart: '0800',
                plannedEnd: '1200',
                actualStart: '0817',
                actualEnd: '1153',
              ),
            ],
            history: const [],
            completed: 216,
            scheduled: 0,
            awaiting: 0,
            historical: 0,
            remaining: 384,
            unscheduled: 384,
            overTarget: 0,
          ),
          (
            name: 'excludes cancelled and missed sessions',
            target: 600,
            sessions: [
              _session(id: 'cancelled', state: ClinicalSessionState.cancelled),
              _session(id: 'missed', state: ClinicalSessionState.missed),
            ],
            history: const [],
            completed: 0,
            scheduled: 0,
            awaiting: 0,
            historical: 0,
            remaining: 600,
            unscheduled: 600,
            overTarget: 0,
          ),
          (
            name: 'separates Scheduled and Awaiting Confirmation exact minutes',
            target: 900,
            sessions: [
              _session(id: 'future', state: ClinicalSessionState.scheduled),
              _session(
                id: 'past',
                state: ClinicalSessionState.awaitingConfirmation,
                plannedStart: '1305',
                plannedEnd: '1542',
              ),
            ],
            history: const [],
            completed: 0,
            scheduled: 377,
            awaiting: 157,
            historical: 0,
            remaining: 900,
            unscheduled: 523,
            overTarget: 0,
          ),
          (
            name: 'counts Historical Hours without scheduling them',
            target: 600,
            sessions: const [],
            history: [_history(id: 'prior', minutes: 375)],
            completed: 375,
            scheduled: 0,
            awaiting: 0,
            historical: 375,
            remaining: 225,
            unscheduled: 225,
            overTarget: 0,
          ),
          (
            name:
                'floors Remaining and Unscheduled while preserving Over-Target',
            target: 240,
            sessions: [
              _session(
                id: 'long-day',
                state: ClinicalSessionState.completed,
                actualStart: '0800',
                actualEnd: '1300',
              ),
              _session(
                id: 'extra-scheduled',
                state: ClinicalSessionState.scheduled,
              ),
            ],
            history: const [],
            completed: 300,
            scheduled: 220,
            awaiting: 0,
            historical: 0,
            remaining: 0,
            unscheduled: 0,
            overTarget: 60,
          ),
        ];

    for (final testCase in cases) {
      test(testCase.name, () {
        final progress = engine.derivePlacement(
          placement: _placement(targetMinutes: testCase.target),
          sessions: testCase.sessions,
          historicalHoursEntries: testCase.history,
          today: LocalDate(2026, 8, 1),
        );

        expect(progress.completedMinutes, testCase.completed);
        expect(progress.scheduledMinutes, testCase.scheduled);
        expect(progress.awaitingConfirmationMinutes, testCase.awaiting);
        expect(progress.historicalMinutes, testCase.historical);
        expect(progress.remainingMinutes, testCase.remaining);
        expect(progress.unscheduledMinutes, testCase.unscheduled);
        expect(progress.overTargetMinutes, testCase.overTarget);
      });
    }

    test('reconciles multiple Preceptors and an Unattributed bucket', () {
      final progress = engine.derivePlacement(
        placement: _placement(targetMinutes: 1200),
        sessions: [
          _session(
            id: 'p1-completed',
            state: ClinicalSessionState.completed,
            preceptorId: 'preceptor-1',
          ),
          _session(
            id: 'p2-scheduled',
            state: ClinicalSessionState.scheduled,
            preceptorId: 'preceptor-2',
          ),
          _session(
            id: 'p2-awaiting',
            state: ClinicalSessionState.awaitingConfirmation,
            preceptorId: 'preceptor-2',
          ),
        ],
        historicalHoursEntries: [
          _history(id: 'p2-history', minutes: 75, preceptorId: 'preceptor-2'),
          _history(id: 'unattributed', minutes: 45),
        ],
        today: LocalDate(2026, 8, 1),
      );

      expect(progress.preceptorProgress['preceptor-1']!.completedMinutes, 220);
      expect(progress.preceptorProgress['preceptor-2']!.completedMinutes, 75);
      expect(progress.preceptorProgress['preceptor-2']!.scheduledMinutes, 440);
      expect(
        progress.preceptorProgress['preceptor-2']!.awaitingConfirmationMinutes,
        220,
      );
      expect(progress.unattributedProgress.completedMinutes, 45);
      expect(progress.unattributedProgress.historicalMinutes, 45);
      expect(
        progress.preceptorProgress.values.fold<int>(
          progress.unattributedProgress.completedMinutes,
          (sum, bucket) => sum + bucket.completedMinutes,
        ),
        progress.completedMinutes,
      );
      expect(
        progress.preceptorProgress.values.fold<int>(
          0,
          (sum, bucket) => sum + bucket.scheduledMinutes,
        ),
        progress.scheduledMinutes,
      );
    });

    test('rejects duplicate source records instead of double-counting', () {
      final duplicate = _session(
        id: 'duplicate',
        state: ClinicalSessionState.scheduled,
      );

      expect(
        () => engine.derivePlacement(
          placement: _placement(targetMinutes: 600),
          sessions: [duplicate, duplicate],
          historicalHoursEntries: const [],
          today: LocalDate(2026, 8, 1),
        ),
        throwsA(isA<DomainValidationException>()),
      );
    });
  });

  group('completion forecast', () {
    test('uses the chronologically scheduled target-crossing date', () {
      final progress = engine.derivePlacement(
        placement: _placement(targetMinutes: 300),
        sessions: [
          _session(
            id: 'completed',
            state: ClinicalSessionState.completed,
            actualStart: '0800',
            actualEnd: '1000',
          ),
          _session(
            id: 'later',
            state: ClinicalSessionState.scheduled,
            date: LocalDate(2026, 8, 20),
          ),
          _session(
            id: 'crossing',
            state: ClinicalSessionState.scheduled,
            date: LocalDate(2026, 8, 10),
            plannedStart: '0800',
            plannedEnd: '1100',
          ),
        ],
        historicalHoursEntries: const [],
        today: LocalDate(2026, 8, 1),
      );

      expect(progress.projectedCompletionDate, LocalDate(2026, 8, 10));
      expect(progress.requiredWeeklyPace, isNull);
    });

    test('uses the actual target-crossing date after completion', () {
      final progress = engine.derivePlacement(
        placement: _placement(targetMinutes: 300),
        sessions: [
          _session(
            id: 'second',
            state: ClinicalSessionState.completed,
            date: LocalDate(2026, 8, 8),
          ),
        ],
        historicalHoursEntries: [
          _history(id: 'first', minutes: 100, date: LocalDate(2026, 8, 2)),
        ],
        today: LocalDate(2026, 8, 9),
      );

      expect(progress.projectedCompletionDate, LocalDate(2026, 8, 8));
      expect(progress.overTargetMinutes, 20);
    });

    test('returns exact required weekly pace when target is not scheduled', () {
      final progress = engine.derivePlacement(
        placement: _placement(
          targetMinutes: 600,
          completionDeadline: LocalDate(2026, 8, 14),
        ),
        sessions: const [],
        historicalHoursEntries: [_history(id: 'prior', minutes: 180)],
        today: LocalDate(2026, 8, 1),
      );

      expect(progress.projectedCompletionDate, isNull);
      expect(progress.requiredWeeklyPace!.requiredMinutes, 420);
      expect(progress.requiredWeeklyPace!.availableDays, 14);
      expect(progress.requiredWeeklyPace!.averageMinutesPerWeek, 210);
    });
  });

  group('Total Progress', () {
    test(
      'aggregates all placements into one eight-segment percentage model',
      () {
        final first = engine.derivePlacement(
          placement: _placement(id: 'first', targetMinutes: 600),
          sessions: const [],
          historicalHoursEntries: [
            _history(id: 'first-history', placementId: 'first', minutes: 150),
          ],
          today: LocalDate(2026, 8, 1),
        );
        final second = engine.derivePlacement(
          placement: _placement(id: 'second', targetMinutes: 600),
          sessions: const [],
          historicalHoursEntries: [
            _history(id: 'second-history', placementId: 'second', minutes: 60),
          ],
          today: LocalDate(2026, 8, 1),
        );

        final total = engine.deriveTotal([first, second]);

        expect(total.completedMinutes, 210);
        expect(total.targetMinutes, 1200);
        expect(total.completedPercentage, 18);
        expect(total.segmentFillPercentages, [100, 44, 0, 0, 0, 0, 0, 0]);
        expect(total.segmentFillPercentages, hasLength(8));
      },
    );

    test('caps aggregate progress and every segment at 100 percent', () {
      final overTarget = engine.derivePlacement(
        placement: _placement(targetMinutes: 60),
        sessions: const [],
        historicalHoursEntries: [_history(id: 'over', minutes: 90)],
        today: LocalDate(2026, 8, 1),
      );

      final total = engine.deriveTotal([overTarget]);

      expect(total.completedPercentage, 100);
      expect(total.segmentFillPercentages, everyElement(100));
    });

    test(
      'returns an empty zero model and TargetHours rejects zero targets',
      () {
        expect(engine.deriveTotal(const []), isA<TotalProgress>());
        final empty = engine.deriveTotal(const []);
        expect(empty.completedPercentage, 0);
        expect(empty.segmentFillPercentages, everyElement(0));
        expect(
          () => TargetHours.fromMinutes(0),
          throwsA(isA<DomainValidationException>()),
        );
      },
    );
  });
}

ClinicalPlacement _placement({
  String id = 'placement-1',
  required int targetMinutes,
  LocalDate? completionDeadline,
}) => ClinicalPlacement.create(
  id: id,
  name: 'Family Medicine',
  targetHours: TargetHours.fromMinutes(targetMinutes),
  startDate: LocalDate(2026, 8, 1),
  completionDeadline: completionDeadline ?? LocalDate(2026, 8, 31),
  attachedPreceptorIds: const ['preceptor-1', 'preceptor-2'],
  primaryPreceptorId: 'preceptor-1',
  evaluationPlanId: 'evaluation-plan-1',
);

ClinicalSession _session({
  required String id,
  required ClinicalSessionState state,
  String placementId = 'placement-1',
  String preceptorId = 'preceptor-1',
  LocalDate? date,
  String plannedStart = '0800',
  String plannedEnd = '1140',
  String? actualStart,
  String? actualEnd,
}) {
  final sessionDate = date ?? LocalDate(2026, 8, 5);
  return ClinicalSession.restore(
    id: id,
    clinicalPlacementId: placementId,
    preceptorId: preceptorId,
    plannedInterval: _interval(sessionDate, plannedStart, plannedEnd),
    state: state,
    actualInterval: state == ClinicalSessionState.completed
        ? _interval(
            sessionDate,
            actualStart ?? plannedStart,
            actualEnd ?? plannedEnd,
          )
        : null,
  );
}

HistoricalHoursEntry _history({
  required String id,
  required int minutes,
  String placementId = 'placement-1',
  String? preceptorId,
  LocalDate? date,
}) => HistoricalHoursEntry(
  id: id,
  clinicalPlacementId: placementId,
  completedMinutes: minutes,
  effectiveDate: date ?? LocalDate(2026, 8, 1),
  preceptorId: preceptorId,
);

ZonedInterval _interval(LocalDate date, String start, String end) =>
    ZonedInterval(
      startDate: date,
      startTime: LocalTime.parseMilitary(start),
      endTime: LocalTime.parseMilitary(end),
      timeZone: TimeZoneId('America/New_York'),
      startOffset: UtcOffset.inMinutes(-240),
      endOffset: UtcOffset.inMinutes(-240),
    );
