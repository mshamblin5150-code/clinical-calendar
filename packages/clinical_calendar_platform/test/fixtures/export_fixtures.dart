import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

final fixtureTime = DateTime.utc(2026, 8, 3, 16);
final fixtureToday = LocalDate(2026, 8, 3);
final fixtureZone = TimeZoneId('America/New_York');
final fixtureOffset = UtcOffset.inMinutes(-240);

PlacementExportSnapshot placementExportFixture({
  String name = 'Family Medicine - Clinique José',
  int targetMinutes = 270 * 60,
  bool includeRecords = true,
  bool overTarget = false,
}) {
  final primary = Preceptor(id: fixtureId(2), name: 'José Álvarez');
  final alternate = Preceptor(id: fixtureId(3), name: 'Zoë Müller');
  final target = overTarget ? 60 : targetMinutes;
  final placement = ClinicalPlacement.create(
    id: fixtureId(1),
    name: name,
    targetHours: TargetHours.fromMinutes(target),
    startDate: LocalDate(2026, 8, 1),
    completionDeadline: LocalDate(2026, 12, 31),
    attachedPreceptorIds: [primary.id, alternate.id],
    primaryPreceptorId: primary.id,
    evaluationPlanId: fixtureId(4),
  );
  final sessions = <ClinicalSession>[
    if (includeRecords)
      ClinicalSession.restore(
        id: fixtureId(5),
        clinicalPlacementId: placement.id,
        preceptorId: primary.id,
        plannedInterval: fixtureInterval(2, 8, 0, 16, 0),
        state: ClinicalSessionState.completed,
        actualInterval: fixtureInterval(
          2,
          8,
          17,
          overTarget ? 10 : 15,
          overTarget ? 17 : 53,
        ),
      ),
    if (includeRecords && !overTarget)
      ClinicalSession.schedule(
        id: fixtureId(6),
        clinicalPlacementId: placement.id,
        preceptorId: alternate.id,
        plannedInterval: fixtureInterval(12, 9, 0, 17, 0),
        asOfUtc: fixtureTime,
      ),
  ];
  final history = <HistoricalHoursEntry>[
    if (includeRecords && !overTarget)
      HistoricalHoursEntry(
        id: fixtureId(7),
        clinicalPlacementId: placement.id,
        completedMinutes: 125,
        effectiveDate: LocalDate(2026, 8, 1),
        preceptorId: alternate.id,
        note: 'Imported, checked by María',
      ),
    if (includeRecords && !overTarget)
      HistoricalHoursEntry(
        id: fixtureId(8),
        clinicalPlacementId: placement.id,
        completedMinutes: 47,
        effectiveDate: LocalDate(2026, 8, 1),
        note: 'Unattributed before adoption',
      ),
  ];
  final progress = const ClinicalPlacementProgressEngine().derivePlacement(
    placement: placement,
    sessions: sessions,
    historicalHoursEntries: history,
    today: fixtureToday,
  );
  final context = EvaluationPlanContext(
    completedMinutes: progress.completedMinutes,
    targetMinutes: target,
    startDate: placement.startDate,
    completionDeadline: placement.completionDeadline,
    today: fixtureToday,
    futureScheduledSessionMinutes: [
      for (final session in sessions)
        if (session.state == ClinicalSessionState.scheduled)
          session.plannedMinutes,
    ],
  );
  final plan = const EvaluationPlanEngine().create(
    evaluationPlanId: placement.evaluationPlanId,
    configuration: EvaluationPlanConfiguration(
      interimReviewCadenceMinutes: 90 * 60,
    ),
    context: context,
    primaryPreceptorId: primary.id,
  );
  final evaluation = const EvaluationPlanEngine().evaluate(plan, context);
  final placementSnapshot = PlacementSnapshot(
    placement: placement,
    placementRevision: 1,
    evaluationPlanRevision: 1,
    evaluationPlanConfiguration: plan.configuration,
    attachedPreceptors: [
      PlacementPreceptorSnapshot(
        preceptor: primary,
        revision: 1,
        isPrimary: true,
      ),
      PlacementPreceptorSnapshot(
        preceptor: alternate,
        revision: 1,
        isPrimary: false,
      ),
    ],
    progress: progress,
    evaluation: evaluation,
    derivedState: ClinicalPlacementState.active,
    awaitingConfirmationSessionCount: sessions
        .where(
          (session) =>
              session.state == ClinicalSessionState.awaitingConfirmation,
        )
        .length,
    scheduledFutureSessionCount: sessions
        .where((session) => session.state == ClinicalSessionState.scheduled)
        .length,
  );
  return PlacementExportSnapshot(
    generatedAtUtc: fixtureTime,
    placement: placementSnapshot,
    sessions: [for (final session in sessions) fixtureRecord(session)],
    historicalHours: [for (final entry in history) fixtureRecord(entry)],
    evaluationPlan: fixtureRecord(plan),
  );
}

StoredDomainRecord<T> fixtureRecord<T>(T value) => StoredDomainRecord(
  value: value,
  studentId: fixtureId(100),
  revision: 1,
  createdAtUtc: fixtureTime,
  updatedAtUtc: fixtureTime,
);

ZonedInterval fixtureInterval(
  int day,
  int startHour,
  int startMinute,
  int endHour,
  int endMinute,
) => ZonedInterval(
  startDate: LocalDate(2026, 8, day),
  startTime: LocalTime(startHour, startMinute),
  endTime: LocalTime(endHour, endMinute),
  timeZone: fixtureZone,
  startOffset: fixtureOffset,
  endOffset: fixtureOffset,
);

String fixtureId(int value) =>
    '00000000-0000-4000-8000-${value.toRadixString(16).padLeft(12, '0')}';
