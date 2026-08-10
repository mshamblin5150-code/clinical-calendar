import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';

const placementTestStudentId = '10000000-0000-4000-8000-000000000001';

final class PlacementProgressHarness {
  factory PlacementProgressHarness.graphiteConcept() =>
      PlacementProgressHarness(
        familyName: 'Acceptance Family Medicine',
        familyTargetHours: 90,
        seedHistoricalHours: false,
        scheduledSessionCount: 2,
        scheduledSessionHours: 8,
        secondPlacementName: 'Internal Medicine',
        splitSessionsBetweenPlacements: true,
        selectSecondPlacement: true,
        requireInitialSelfAssessments: true,
        secondPlacementStartDate: LocalDate(2026, 8, 1),
        firstSessionDate: LocalDate(2026, 8, 8),
      );

  PlacementProgressHarness({
    bool completed = false,
    String familyName = 'Family Medicine',
    int familyTargetHours = 270,
    bool seedHistoricalHours = true,
    int scheduledSessionCount = 9,
    int scheduledSessionHours = 12,
    String secondPlacementName = 'Pediatrics',
    bool splitSessionsBetweenPlacements = false,
    bool selectSecondPlacement = false,
    bool requireInitialSelfAssessments = false,
    LocalDate? secondPlacementStartDate,
    LocalDate? firstSessionDate,
  }) {
    _seed(
      completed: completed,
      familyName: familyName,
      familyTargetHours: familyTargetHours,
      seedHistoricalHours: seedHistoricalHours,
      scheduledSessionCount: scheduledSessionCount,
      scheduledSessionHours: scheduledSessionHours,
      secondPlacementName: secondPlacementName,
      splitSessionsBetweenPlacements: splitSessionsBetweenPlacements,
      selectSecondPlacement: selectSecondPlacement,
      requireInitialSelfAssessments: requireInitialSelfAssessments,
      secondPlacementStartDate:
          secondPlacementStartDate ?? LocalDate(2026, 9, 1),
      firstSessionDate: firstSessionDate ?? LocalDate(2026, 8, 20),
    );
    final placementService = PlacementApplicationService(
      repositories: registry,
      clock: const _Clock(),
      identifiers: _Identifiers(),
      studentId: placementTestStudentId,
    );
    controller = PlacementProgressController(
      service: placementService,
      studentId: placementTestStudentId,
    );
    attentionController = EvaluationAttentionController(
      service: EvaluationAttentionApplicationService(
        placements: PlacementEvaluationGateway(placementService),
        attentionSource: LocalAttentionRepositorySource(registry),
        clock: const _Clock(),
        studentId: placementTestStudentId,
      ),
    );
  }

  final PlacementTestRepositories repositories = PlacementTestRepositories();
  late final PlacementTestRegistry registry = PlacementTestRegistry(
    repositories,
  );
  late final PlacementProgressController controller;
  late final EvaluationAttentionController attentionController;

  void _seed({
    required bool completed,
    required String familyName,
    required int familyTargetHours,
    required bool seedHistoricalHours,
    required int scheduledSessionCount,
    required int scheduledSessionHours,
    required String secondPlacementName,
    required bool splitSessionsBetweenPlacements,
    required bool selectSecondPlacement,
    required bool requireInitialSelfAssessments,
    required LocalDate secondPlacementStartDate,
    required LocalDate firstSessionDate,
  }) {
    final smith = Preceptor(id: _smithId, name: 'Dr. Smith');
    final nguyen = Preceptor(id: placementTestNguyenId, name: 'Dr. Nguyen');
    repositories.preceptors
      ..seed(smith)
      ..seed(nguyen);
    final familyPlan = _plan(
      _familyPlanId,
      _smithId,
      familyTargetHours * 60,
      requireInitialSelfAssessment: requireInitialSelfAssessments,
    );
    final pediatricsPlan = _plan(
      _pediatricsPlanId,
      placementTestNguyenId,
      90 * 60,
      requireInitialSelfAssessment: requireInitialSelfAssessments,
    );
    repositories.evaluationPlans
      ..seed(familyPlan)
      ..seed(pediatricsPlan);
    repositories.clinicalPlacements
      ..seed(
        ClinicalPlacement.restore(
          id: placementTestFamilyId,
          name: familyName,
          targetHours: TargetHours.fromWholeHours(familyTargetHours),
          startDate: LocalDate(2026, 8, 1),
          completionDeadline: LocalDate(2026, 12, 31),
          attachedPreceptorIds: const [_smithId, placementTestNguyenId],
          primaryPreceptorId: _smithId,
          evaluationPlanId: _familyPlanId,
          state: completed
              ? ClinicalPlacementState.completed
              : ClinicalPlacementState.active,
        ),
      )
      ..seed(
        ClinicalPlacement.create(
          id: _pediatricsId,
          name: secondPlacementName,
          targetHours: TargetHours.fromWholeHours(90),
          startDate: secondPlacementStartDate,
          completionDeadline: LocalDate(2027, 1, 31),
          attachedPreceptorIds: const [placementTestNguyenId],
          primaryPreceptorId: placementTestNguyenId,
          evaluationPlanId: _pediatricsPlanId,
        ),
      );
    if (seedHistoricalHours) {
      repositories.historicalHoursEntries
        ..seed(
          HistoricalHoursEntry(
            id: _historySmithId,
            clinicalPlacementId: placementTestFamilyId,
            completedMinutes: 90 * 60,
            effectiveDate: LocalDate(2026, 8, 2),
            preceptorId: _smithId,
          ),
        )
        ..seed(
          HistoricalHoursEntry(
            id: _historyUnattributedId,
            clinicalPlacementId: placementTestFamilyId,
            completedMinutes: 36 * 60,
            effectiveDate: LocalDate(2026, 8, 3),
          ),
        );
    }
    for (var index = 0; index < scheduledSessionCount; index++) {
      final secondPlacementSession =
          splitSessionsBetweenPlacements && index.isOdd;
      final date =
          (secondPlacementSession ? LocalDate(2026, 9, 20) : firstSessionDate)
              .addDays(index);
      repositories.clinicalSessions.seed(
        ClinicalSession.restore(
          id: '50000000-0000-4000-8000-${index.toString().padLeft(12, '0')}',
          clinicalPlacementId: secondPlacementSession
              ? _pediatricsId
              : placementTestFamilyId,
          preceptorId: index.isEven ? _smithId : placementTestNguyenId,
          plannedInterval: _interval(date, scheduledSessionHours),
          state: ClinicalSessionState.scheduled,
        ),
      );
    }
    repositories.activePlacementSelection.seed(
      selectSecondPlacement ? _pediatricsId : placementTestFamilyId,
    );
  }
}

EvaluationPlan _plan(
  String id,
  String primary,
  int targetMinutes, {
  required bool requireInitialSelfAssessment,
}) {
  const engine = EvaluationPlanEngine();
  return engine.create(
    evaluationPlanId: id,
    configuration: EvaluationPlanConfiguration(
      initialSelfAssessmentRequired: requireInitialSelfAssessment,
      interimReviewCadenceMinutes: targetMinutes + 60,
      finalSelfAssessmentRequired: false,
      finalPlacementReviewRequired: false,
    ),
    context: EvaluationPlanContext(
      completedMinutes: 0,
      targetMinutes: targetMinutes,
      startDate: LocalDate(2026, 8, 1),
      completionDeadline: LocalDate(2027, 1, 31),
      today: LocalDate(2026, 8, 10),
    ),
    primaryPreceptorId: primary,
  );
}

ZonedInterval _interval(LocalDate date, int hours) => ZonedInterval(
  startDate: date,
  startTime: LocalTime(7, 0),
  endTime: LocalTime(7 + hours, 0),
  timeZone: TimeZoneId('UTC'),
  startOffset: UtcOffset.utc,
  endOffset: UtcOffset.utc,
);

const placementTestFamilyId = '30000000-0000-4000-8000-000000000001';
const _pediatricsId = '30000000-0000-4000-8000-000000000002';
const _smithId = '30000000-0000-4000-8000-000000000003';
const placementTestNguyenId = '30000000-0000-4000-8000-000000000004';
const _familyPlanId = '30000000-0000-4000-8000-000000000005';
const _pediatricsPlanId = '30000000-0000-4000-8000-000000000006';
const _historySmithId = '30000000-0000-4000-8000-000000000007';
const _historyUnattributedId = '30000000-0000-4000-8000-000000000008';

final class _Clock implements Clock {
  const _Clock();
  @override
  DateTime nowUtc() => DateTime.utc(2026, 8, 10, 12);
}

final class _Identifiers implements IdentifierGenerator {
  int _next = 100;
  @override
  String nextIdentifier() =>
      '90000000-0000-4000-8000-${(_next++).toString().padLeft(12, '0')}';
}

final class PlacementTestRegistry implements RepositoryRegistry {
  const PlacementTestRegistry(this.repositories);
  final PlacementTestRepositories repositories;

  @override
  Future<void> initialize() async {}

  @override
  Future<R> read<R>(
    R Function(LocalReadRepositories repositories) callback,
  ) async => callback(repositories);

  @override
  Future<R> mutate<R>(
    R Function(LocalWriteRepositories repositories) callback,
  ) async => callback(repositories);
}

final class PlacementTestRepositories implements LocalWriteRepositories {
  PlacementTestRepositories() {
    workShifts = PlacementTestMemoryRepository((value) => value.id);
    clinicalSessions = PlacementTestMemoryRepository((value) => value.id);
    protectedDays = PlacementTestMemoryRepository((value) => value.id);
    scheduleTemplates = PlacementTestMemoryRepository((value) => value.id);
    preceptors = PlacementTestMemoryRepository((value) => value.id);
    clinicalPlacements = PlacementTestMemoryRepository((value) => value.id);
    historicalHoursEntries = PlacementTestMemoryRepository((value) => value.id);
    evaluationPlans = PlacementTestMemoryRepository((value) => value.id);
    activePlacementSelection = PlacementTestSelectionRepository();
  }

  @override
  late final PlacementTestMemoryRepository<WorkShift> workShifts;
  @override
  late final PlacementTestMemoryRepository<ClinicalSession> clinicalSessions;
  @override
  late final PlacementTestMemoryRepository<ProtectedDay> protectedDays;
  @override
  late final PlacementTestMemoryRepository<ScheduleTemplate> scheduleTemplates;
  @override
  late final PlacementTestMemoryRepository<Preceptor> preceptors;
  @override
  late final PlacementTestMemoryRepository<ClinicalPlacement>
  clinicalPlacements;
  @override
  late final PlacementTestMemoryRepository<HistoricalHoursEntry>
  historicalHoursEntries;
  @override
  late final PlacementTestMemoryRepository<EvaluationPlan> evaluationPlans;
  @override
  late final PlacementTestSelectionRepository activePlacementSelection;
  @override
  final OutboxMaintenanceRepository outbox = _Outbox();
  @override
  final SyncCursorRepository syncCursors = _SyncCursors();
}

final class PlacementTestMemoryRepository<T> implements MutableRepository<T> {
  PlacementTestMemoryRepository(this.idOf);
  final String Function(T) idOf;
  final Map<String, StoredDomainRecord<T>> records = {};

  void seed(T value) {
    final now = DateTime.utc(2026, 8, 1);
    records[idOf(value)] = StoredDomainRecord(
      value: value,
      studentId: placementTestStudentId,
      revision: 1,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
  }

  @override
  StoredDomainRecord<T>? find({
    required String studentId,
    required String id,
    bool includeDeleted = false,
  }) => records[id];

  @override
  List<StoredDomainRecord<T>> list({
    required String studentId,
    bool includeDeleted = false,
  }) => records.values.toList();

  @override
  MutationReceipt<T> put({
    required String studentId,
    required T value,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    final current = records[idOf(value)];
    if ((current?.revision ?? 0) != expectedRevision) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'revision mismatch',
      );
    }
    final record = StoredDomainRecord<T>(
      value: value,
      studentId: studentId,
      revision: expectedRevision + 1,
      createdAtUtc: current?.createdAtUtc ?? mutation.occurredAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
    );
    records[idOf(value)] = record;
    return MutationReceipt(record: record, replayed: false);
  }

  @override
  MutationReceipt<T> tombstone({
    required String studentId,
    required String id,
    required int expectedRevision,
    required MutationToken mutation,
  }) => throw UnimplementedError();
}

final class PlacementTestSelectionRepository
    implements ActivePlacementSelectionRepository {
  StoredDomainRecord<String?>? record;

  void seed(String value) {
    final now = DateTime.utc(2026, 8, 1);
    record = StoredDomainRecord(
      value: value,
      studentId: placementTestStudentId,
      revision: 1,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
  }

  @override
  StoredDomainRecord<String?>? find({required String studentId}) => record;

  @override
  MutationReceipt<String?> put({
    required String studentId,
    required String? clinicalPlacementId,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    record = StoredDomainRecord(
      value: clinicalPlacementId,
      studentId: studentId,
      revision: expectedRevision + 1,
      createdAtUtc: record?.createdAtUtc ?? mutation.occurredAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
    );
    return MutationReceipt(record: record!, replayed: false);
  }
}

final class _Outbox implements OutboxMaintenanceRepository {
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
    int limit = 100,
  }) => <OutboxOperation>[];
  @override
  void recordFailedAttempt({
    required String studentId,
    required String operationId,
    required DateTime attemptedAtUtc,
    required DateTime nextAttemptAtUtc,
    required String failureCode,
  }) {}
}

final class _SyncCursors implements SyncCursorRepository {
  @override
  SyncCursor? find({required String studentId, required String remoteScope}) =>
      null;
  @override
  void put(SyncCursor cursor) {}
}
