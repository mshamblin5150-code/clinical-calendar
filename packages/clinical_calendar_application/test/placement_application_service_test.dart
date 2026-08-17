import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

const _studentId = '10000000-0000-4000-8000-000000000001';

void main() {
  late _FakeRegistry registry;
  late _SequenceIdentifiers identifiers;
  late PlacementApplicationService service;

  setUp(() {
    registry = _FakeRegistry();
    identifiers = _SequenceIdentifiers();
    service = PlacementApplicationService(
      repositories: registry,
      clock: _FixedClock(DateTime.utc(2026, 8, 10, 12)),
      identifiers: identifiers,
      studentId: _studentId,
    );
  });

  test(
    'creates Placement, Plan, active selection, and distinct outboxes',
    () async {
      final preceptor = await service.createPreceptor(name: 'Dr. Rivera');
      final before = registry.repositories.outboxOperations.length;

      final snapshot = await service.createPlacement(
        CreatePlacementRequest(
          name: 'Family Medicine',
          targetHours: TargetHours.fromWholeHours(270),
          startDate: LocalDate(2026, 8, 1),
          completionDeadline: LocalDate(2026, 12, 31),
          primaryPreceptorId: preceptor.id,
          evaluationPlanConfiguration: EvaluationPlanConfiguration(),
        ),
      );

      expect(snapshot.placement.name, 'Family Medicine');
      expect(
        registry.repositories.activePlacementSelection
            .find(studentId: _studentId)!
            .value,
        snapshot.placement.id,
      );
      final aggregateOutboxes = registry.repositories.outboxOperations.sublist(
        before,
      );
      expect(aggregateOutboxes, hasLength(3));
      expect(
        aggregateOutboxes.map((item) => item.entityType),
        containsAll(['clinical_placement', 'evaluation_plan', 'settings']),
      );
      expect(
        aggregateOutboxes.map((item) => item.mutation.operationId).toSet(),
        hasLength(3),
      );
      expect(
        (await service.activePlacement())!.placement.id,
        snapshot.placement.id,
      );
      expect(snapshot.placementRevision, 1);
      expect(snapshot.evaluationPlanRevision, 1);
      expect(snapshot.attachedPreceptors.single.preceptor.name, 'Dr. Rivera');
      expect(snapshot.attachedPreceptors.single.isPrimary, isTrue);
    },
  );

  test('lists placements stably and derives shared Total Progress', () async {
    final preceptor = await service.createPreceptor(name: 'Dr. Rivera');
    Future<PlacementSnapshot> create(String name, LocalDate start) =>
        service.createPlacement(
          CreatePlacementRequest(
            name: name,
            targetHours: TargetHours.fromMinutes(60),
            startDate: start,
            completionDeadline: LocalDate(2026, 12, 31),
            primaryPreceptorId: preceptor.id,
            evaluationPlanConfiguration: EvaluationPlanConfiguration(
              initialSelfAssessmentRequired: false,
              interimReviewCadenceMinutes: 120,
              finalSelfAssessmentRequired: false,
              finalPlacementReviewRequired: false,
            ),
          ),
        );

    final later = await create('Pediatrics', LocalDate(2026, 9, 1));
    final earlier = await create('Family Medicine', LocalDate(2026, 8, 1));
    await service.addHistoricalHours(
      clinicalPlacementId: earlier.placement.id,
      completedMinutes: 30,
      effectiveDate: LocalDate(2026, 8, 2),
    );

    final listed = await service.placements();
    expect(listed.map((item) => item.placement.name), [
      'Family Medicine',
      'Pediatrics',
    ]);
    expect(
      (await service.activePlacement())!.placement.id,
      earlier.placement.id,
    );
    final total = await service.totalProgress();
    expect(total.targetMinutes, 120);
    expect(total.completedMinutes, 30);
    expect(total.completedPercentage, 25);
    expect(total.segmentFillPercentages, hasLength(8));
    expect(later.progress.completedMinutes, 0);
  });

  test(
    'snapshot exposes scheduled future sessions in chronological order',
    () async {
      final created = await _createSimplePlacement(service);
      final later = ClinicalSession.schedule(
        id: identifiers.nextIdentifier(),
        clinicalPlacementId: created.placement.id,
        preceptorId: created.placement.primaryPreceptorId,
        plannedInterval: _interval(LocalDate(2026, 8, 22), 8, 4),
        asOfUtc: DateTime.utc(2026, 8, 10, 12),
      );
      final earlier = ClinicalSession.schedule(
        id: identifiers.nextIdentifier(),
        clinicalPlacementId: created.placement.id,
        preceptorId: created.placement.primaryPreceptorId,
        plannedInterval: _interval(LocalDate(2026, 8, 20), 8, 4),
        asOfUtc: DateTime.utc(2026, 8, 10, 12),
      );
      registry.repositories.seedClinicalSession(later);
      registry.repositories.seedClinicalSession(earlier);

      final snapshot = (await service.activePlacement())!;

      expect(snapshot.scheduledFutureSessionCount, 2);
      expect(snapshot.scheduledFutureSessions, [earlier, later]);
    },
  );

  test(
    'aggregate failure rolls back records, selection, and outboxes',
    () async {
      final preceptor = await service.createPreceptor(name: 'Dr. Rivera');
      final outboxCount = registry.repositories.outboxOperations.length;
      registry.repositories.failNextEvaluationPlanPut = true;

      await expectLater(
        service.createPlacement(
          CreatePlacementRequest(
            name: 'Family Medicine',
            targetHours: TargetHours.fromWholeHours(1),
            startDate: LocalDate(2026, 8, 1),
            completionDeadline: LocalDate(2026, 8, 31),
            primaryPreceptorId: preceptor.id,
            evaluationPlanConfiguration: EvaluationPlanConfiguration(),
          ),
        ),
        throwsStateError,
      );

      expect(
        registry.repositories.clinicalPlacements.list(studentId: _studentId),
        isEmpty,
      );
      expect(
        registry.repositories.activePlacementSelection.find(
          studentId: _studentId,
        ),
        isNull,
      );
      expect(registry.repositories.outboxOperations, hasLength(outboxCount));
    },
  );

  test(
    'impact preview blocks invalid window and rejects stale confirmation',
    () async {
      final created = await _createSimplePlacement(service);
      final session = ClinicalSession.schedule(
        id: identifiers.nextIdentifier(),
        clinicalPlacementId: created.placement.id,
        preceptorId: created.placement.primaryPreceptorId,
        plannedInterval: _interval(LocalDate(2026, 8, 20), 8, 12),
        asOfUtc: DateTime.utc(2026, 8, 10, 12),
      );
      registry.repositories.seedClinicalSession(session);

      final blocked = await service.previewEdit(
        clinicalPlacementId: created.placement.id,
        request: EditPlacementRequest(
          name: 'Family Medicine',
          targetHours: TargetHours.fromWholeHours(2),
          startDate: LocalDate(2026, 8, 1),
          completionDeadline: LocalDate(2026, 8, 15),
          evaluationPlanConfiguration: EvaluationPlanConfiguration(
            interimReviewCadenceMinutes: 60,
          ),
        ),
      );
      expect(blocked.canConfirm, isFalse);
      expect(blocked.outOfWindowClinicalSessionIds, [session.id]);

      final valid = await service.previewEdit(
        clinicalPlacementId: created.placement.id,
        request: EditPlacementRequest(
          name: 'Family Medicine Updated',
          targetHours: TargetHours.fromWholeHours(2),
          startDate: LocalDate(2026, 8, 1),
          completionDeadline: LocalDate(2026, 8, 31),
          evaluationPlanConfiguration: EvaluationPlanConfiguration(
            interimReviewCadenceMinutes: 60,
          ),
        ),
      );
      registry.repositories.seedHistoricalHours(
        HistoricalHoursEntry(
          id: identifiers.nextIdentifier(),
          clinicalPlacementId: created.placement.id,
          completedMinutes: 15,
          effectiveDate: LocalDate(2026, 8, 5),
        ),
      );
      await expectLater(
        service.confirmEdit(valid),
        throwsA(
          isA<RepositoryException>().having(
            (error) => error.kind,
            'kind',
            RepositoryFailureKind.concurrentModification,
          ),
        ),
      );

      final fresh = await service.previewEdit(
        clinicalPlacementId: created.placement.id,
        request: EditPlacementRequest(
          name: 'Family Medicine Updated',
          targetHours: TargetHours.fromWholeHours(2),
          startDate: LocalDate(2026, 8, 1),
          completionDeadline: LocalDate(2026, 8, 31),
          evaluationPlanConfiguration: EvaluationPlanConfiguration(
            interimReviewCadenceMinutes: 60,
          ),
        ),
      );
      final saved = await service.confirmEdit(fresh);
      expect(saved.placement.name, 'Family Medicine Updated');
      expect(saved.progress.targetMinutes, 120);
      expect(
        fresh.evaluationPlanImpact!.addedRequirementIdentities,
        hasLength(4),
      );
    },
  );

  test(
    'attributed and Unattributed history derive progress and lifecycle',
    () async {
      final created = await _createSimplePlacement(
        service,
        targetMinutes: 60,
        noEvaluations: true,
      );
      final preceptorId = created.placement.primaryPreceptorId;

      await service.addHistoricalHours(
        clinicalPlacementId: created.placement.id,
        completedMinutes: 30,
        effectiveDate: LocalDate(2026, 8, 2),
        preceptorId: preceptorId,
      );
      final ready = await service.addHistoricalHours(
        clinicalPlacementId: created.placement.id,
        completedMinutes: 45,
        effectiveDate: LocalDate(2026, 8, 3),
      );

      expect(ready.progress.completedMinutes, 75);
      expect(ready.progress.remainingMinutes, 0);
      expect(ready.progress.unscheduledMinutes, 0);
      expect(ready.progress.overTargetMinutes, 15);
      expect(
        ready.progress.preceptorProgress[preceptorId]!.historicalMinutes,
        30,
      );
      expect(ready.progress.unattributedProgress.historicalMinutes, 45);
      expect(ready.derivedState, ClinicalPlacementState.readyToComplete);

      final revision = registry.repositories.placementRevision(
        created.placement.id,
      );
      final completed = await service.completePlacement(
        clinicalPlacementId: created.placement.id,
        expectedPlacementRevision: revision,
      );
      expect(completed.placement.state, ClinicalPlacementState.completed);
      await expectLater(
        service.addHistoricalHours(
          clinicalPlacementId: created.placement.id,
          completedMinutes: 1,
          effectiveDate: LocalDate(2026, 8, 4),
        ),
        throwsA(isA<DomainValidationException>()),
      );

      final reopened = await service.reopenPlacement(
        clinicalPlacementId: created.placement.id,
        expectedPlacementRevision: registry.repositories.placementRevision(
          created.placement.id,
        ),
      );
      expect(reopened.placement.state, ClinicalPlacementState.active);
      expect(reopened.progress.completedMinutes, 75);
    },
  );

  test(
    'documentation clears attention and preserves settled metadata',
    () async {
      final created = await _createSimplePlacement(service, targetMinutes: 60);
      expect(
        created.evaluationAttention.single.state,
        EvaluationRequirementState.due,
      );
      final plan = registry.repositories.evaluationPlans.find(
        studentId: _studentId,
        id: created.placement.evaluationPlanId,
      )!;
      final requirement = plan.value.currentRequirements.single;

      final documented = await service.documentEvaluationRequirement(
        clinicalPlacementId: created.placement.id,
        identity: requirement.identity,
        documentation: EvaluationDocumentation(
          dateDocumented: LocalDate(2026, 8, 9),
          referenceOrNote: 'Medatrax confirmation 42',
        ),
        expectedEvaluationPlanRevision: plan.revision,
      );

      expect(documented.evaluationAttention, isEmpty);
      final item = documented.evaluation.requirements.single;
      expect(item.state, EvaluationRequirementState.documented);
      expect(item.requirement.documentation!.location, 'Medatrax');
      expect(
        item.requirement.documentation!.referenceOrNote,
        'Medatrax confirmation 42',
      );
    },
  );

  test(
    'Primary change preserves documented review history and detach rules',
    () async {
      final original = await service.createPreceptor(name: 'Dr. Original');
      final replacement = await service.createPreceptor(
        name: 'Dr. Replacement',
      );
      final temporary = await service.createPreceptor(name: 'Dr. Temporary');
      final created = await service.createPlacement(
        CreatePlacementRequest(
          name: 'Family Medicine',
          targetHours: TargetHours.fromMinutes(120),
          startDate: LocalDate(2026, 8, 1),
          completionDeadline: LocalDate(2026, 8, 31),
          primaryPreceptorId: original.id,
          evaluationPlanConfiguration: EvaluationPlanConfiguration(
            initialSelfAssessmentRequired: false,
            interimReviewCadenceMinutes: 60,
            finalSelfAssessmentRequired: false,
            finalPlacementReviewRequired: false,
          ),
        ),
      );
      var placementRevision = registry.repositories.placementRevision(
        created.placement.id,
      );
      await service.attachPreceptor(
        clinicalPlacementId: created.placement.id,
        preceptorId: replacement.id,
        expectedPlacementRevision: placementRevision,
      );
      placementRevision = registry.repositories.placementRevision(
        created.placement.id,
      );
      await service.attachPreceptor(
        clinicalPlacementId: created.placement.id,
        preceptorId: temporary.id,
        expectedPlacementRevision: placementRevision,
      );
      final planBefore = registry.repositories.evaluationPlans.find(
        studentId: _studentId,
        id: created.placement.evaluationPlanId,
      )!;
      final documentedIdentity = planBefore.value.requirements.first.identity;
      await service.documentEvaluationRequirement(
        clinicalPlacementId: created.placement.id,
        identity: documentedIdentity,
        documentation: EvaluationDocumentation(
          dateDocumented: LocalDate(2026, 8, 9),
        ),
        expectedEvaluationPlanRevision: planBefore.revision,
      );

      placementRevision = registry.repositories.placementRevision(
        created.placement.id,
      );
      final planRevision = registry.repositories.evaluationPlans
          .find(studentId: _studentId, id: created.placement.evaluationPlanId)!
          .revision;
      final changed = await service.makePrimaryPreceptor(
        clinicalPlacementId: created.placement.id,
        preceptorId: replacement.id,
        expectedPlacementRevision: placementRevision,
        expectedEvaluationPlanRevision: planRevision,
      );
      expect(changed.placement.primaryPreceptorId, replacement.id);
      final requirements = registry.repositories.evaluationPlans
          .find(studentId: _studentId, id: created.placement.evaluationPlanId)!
          .value
          .requirements;
      expect(
        requirements
            .singleWhere((item) => item.identity == documentedIdentity)
            .primaryPreceptorId,
        original.id,
      );
      expect(
        requirements
            .singleWhere((item) => item.identity != documentedIdentity)
            .primaryPreceptorId,
        replacement.id,
      );

      final detached = await service.detachPreceptor(
        clinicalPlacementId: created.placement.id,
        preceptorId: temporary.id,
        expectedPlacementRevision: registry.repositories.placementRevision(
          created.placement.id,
        ),
      );
      expect(
        detached.placement.attachedPreceptorIds,
        isNot(contains(temporary.id)),
      );
      await expectLater(
        service.detachPreceptor(
          clinicalPlacementId: created.placement.id,
          preceptorId: original.id,
          expectedPlacementRevision: registry.repositories.placementRevision(
            created.placement.id,
          ),
        ),
        throwsA(isA<DomainValidationException>()),
      );
    },
  );
}

Future<PlacementSnapshot> _createSimplePlacement(
  PlacementApplicationService service, {
  int targetMinutes = 120,
  bool noEvaluations = false,
}) async {
  final preceptor = await service.createPreceptor(name: 'Dr. Rivera');
  return service.createPlacement(
    CreatePlacementRequest(
      name: 'Family Medicine',
      targetHours: TargetHours.fromMinutes(targetMinutes),
      startDate: LocalDate(2026, 8, 1),
      completionDeadline: LocalDate(2026, 8, 31),
      primaryPreceptorId: preceptor.id,
      evaluationPlanConfiguration: EvaluationPlanConfiguration(
        initialSelfAssessmentRequired: !noEvaluations,
        interimReviewCadenceMinutes: targetMinutes + 60,
        finalSelfAssessmentRequired: false,
        finalPlacementReviewRequired: false,
      ),
    ),
  );
}

ZonedInterval _interval(LocalDate date, int startHour, int endHour) =>
    ZonedInterval(
      startDate: date,
      startTime: LocalTime(startHour, 0),
      endTime: LocalTime(endHour, 0),
      timeZone: TimeZoneId('UTC'),
      startOffset: UtcOffset.utc,
      endOffset: UtcOffset.utc,
    );

final class _FixedClock implements Clock {
  const _FixedClock(this.value);
  final DateTime value;

  @override
  DateTime nowUtc() => value;
}

final class _SequenceIdentifiers implements IdentifierGenerator {
  int _next = 1;

  @override
  String nextIdentifier() {
    final suffix = (_next++).toString().padLeft(12, '0');
    return '20000000-0000-4000-8000-$suffix';
  }
}

final class _FakeRegistry implements RepositoryRegistry {
  _FakeRepositories repositories = _FakeRepositories();

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
    final before = repositories.copy();
    try {
      return callback(repositories);
    } on Object {
      repositories = before;
      rethrow;
    }
  }
}

final class _FakeRepositories implements LocalWriteRepositories {
  _FakeRepositories() {
    workShifts = _MemoryRepository('work_shift', (value) => value.id, this);
    clinicalSessions = _MemoryRepository(
      'clinical_session',
      (value) => value.id,
      this,
    );
    protectedDays = _MemoryRepository(
      'protected_day',
      (value) => value.id,
      this,
    );
    scheduleTemplates = _MemoryRepository(
      'schedule_template',
      (value) => value.id,
      this,
    );
    preceptors = _MemoryRepository('preceptor', (value) => value.id, this);
    clinicalPlacements = _MemoryRepository(
      'clinical_placement',
      (value) => value.id,
      this,
    );
    historicalHoursEntries = _MemoryRepository(
      'historical_hours_entry',
      (value) => value.id,
      this,
    );
    evaluationPlans = _MemoryRepository(
      'evaluation_plan',
      (value) => value.id,
      this,
      beforePut: () {
        if (failNextEvaluationPlanPut) {
          failNextEvaluationPlanPut = false;
          throw StateError('injected Evaluation Plan failure');
        }
      },
    );
    activePlacementSelection = _FakeSelectionRepository(this);
  }

  @override
  late final _MemoryRepository<WorkShift> workShifts;
  @override
  late final _MemoryRepository<ClinicalSession> clinicalSessions;
  @override
  late final _MemoryRepository<ProtectedDay> protectedDays;
  @override
  late final _MemoryRepository<ScheduleTemplate> scheduleTemplates;
  @override
  late final _MemoryRepository<Preceptor> preceptors;
  @override
  late final _MemoryRepository<ClinicalPlacement> clinicalPlacements;
  @override
  late final _MemoryRepository<HistoricalHoursEntry> historicalHoursEntries;
  @override
  late final _MemoryRepository<EvaluationPlan> evaluationPlans;
  @override
  late final _FakeSelectionRepository activePlacementSelection;
  final List<OutboxOperation> outboxOperations = [];
  @override
  final _FakeOutbox outbox = _FakeOutbox();
  @override
  final _FakeSyncCursors syncCursors = _FakeSyncCursors();
  bool failNextEvaluationPlanPut = false;

  _FakeRepositories copy() {
    final result = _FakeRepositories();
    result.workShifts.copyRecordsFrom(workShifts);
    result.clinicalSessions.copyRecordsFrom(clinicalSessions);
    result.protectedDays.copyRecordsFrom(protectedDays);
    result.scheduleTemplates.copyRecordsFrom(scheduleTemplates);
    result.preceptors.copyRecordsFrom(preceptors);
    result.clinicalPlacements.copyRecordsFrom(clinicalPlacements);
    result.historicalHoursEntries.copyRecordsFrom(historicalHoursEntries);
    result.evaluationPlans.copyRecordsFrom(evaluationPlans);
    result.activePlacementSelection.copyRecordFrom(activePlacementSelection);
    result.outboxOperations.addAll(outboxOperations);
    result.failNextEvaluationPlanPut = failNextEvaluationPlanPut;
    return result;
  }

  void recordMutation(
    String entityType,
    String entityId,
    int baseRevision,
    MutationToken mutation,
  ) {
    outboxOperations.add(
      OutboxOperation(
        mutation: mutation,
        studentId: _studentId,
        entityType: entityType,
        entityId: entityId,
        type: OutboxOperationType.upsert,
        baseRevision: baseRevision,
        payloadJson: '{}',
      ),
    );
  }

  void seedClinicalSession(ClinicalSession value) =>
      clinicalSessions.seed(value);

  void seedHistoricalHours(HistoricalHoursEntry value) =>
      historicalHoursEntries.seed(value);

  int placementRevision(String id) =>
      clinicalPlacements.find(studentId: _studentId, id: id)!.revision;
}

final class _MemoryRepository<T> implements MutableRepository<T> {
  _MemoryRepository(this.entityType, this.idOf, this.owner, {this.beforePut});

  final String entityType;
  final String Function(T) idOf;
  final _FakeRepositories owner;
  final void Function()? beforePut;
  final Map<String, StoredDomainRecord<T>> _records = {};

  @override
  StoredDomainRecord<T>? find({
    required String studentId,
    required String id,
    bool includeDeleted = false,
  }) {
    final record = _records[id];
    return !includeDeleted && record?.isDeleted == true ? null : record;
  }

  @override
  List<StoredDomainRecord<T>> list({
    required String studentId,
    bool includeDeleted = false,
  }) => _records.values
      .where((record) => includeDeleted || !record.isDeleted)
      .toList(growable: false);

  @override
  MutationReceipt<T> put({
    required String studentId,
    required T value,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    beforePut?.call();
    final id = idOf(value);
    final current = _records[id];
    final revision = current?.revision ?? 0;
    if (revision != expectedRevision) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'revision mismatch',
      );
    }
    final record = StoredDomainRecord<T>(
      value: value,
      studentId: studentId,
      revision: revision + 1,
      createdAtUtc: current?.createdAtUtc ?? mutation.occurredAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
    );
    _records[id] = record;
    owner.recordMutation(entityType, id, revision, mutation);
    return MutationReceipt(record: record, replayed: false);
  }

  @override
  MutationReceipt<T> tombstone({
    required String studentId,
    required String id,
    required int expectedRevision,
    required MutationToken mutation,
  }) => throw UnimplementedError();

  void seed(T value) {
    final now = DateTime.utc(2026, 8, 10, 12);
    final current = _records[idOf(value)];
    _records[idOf(value)] = StoredDomainRecord<T>(
      value: value,
      studentId: _studentId,
      revision: (current?.revision ?? 0) + 1,
      createdAtUtc: current?.createdAtUtc ?? now,
      updatedAtUtc: now,
    );
  }

  void copyRecordsFrom(_MemoryRepository<T> source) {
    _records.addAll(source._records);
  }
}

final class _FakeSelectionRepository
    implements ActivePlacementSelectionRepository {
  _FakeSelectionRepository(this.owner);
  final _FakeRepositories owner;
  StoredDomainRecord<String?>? _record;

  @override
  StoredDomainRecord<String?>? find({required String studentId}) => _record;

  @override
  MutationReceipt<String?> put({
    required String studentId,
    required String? clinicalPlacementId,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    final revision = _record?.revision ?? 0;
    if (revision != expectedRevision) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'revision mismatch',
      );
    }
    _record = StoredDomainRecord<String?>(
      value: clinicalPlacementId,
      studentId: studentId,
      revision: revision + 1,
      createdAtUtc: _record?.createdAtUtc ?? mutation.occurredAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
    );
    owner.recordMutation('settings', studentId, revision, mutation);
    return MutationReceipt(record: _record!, replayed: false);
  }

  void copyRecordFrom(_FakeSelectionRepository source) {
    _record = source._record;
  }
}

final class _FakeOutbox implements OutboxMaintenanceRepository {
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
    OutboxRetryEligibility retryEligibility = OutboxRetryEligibility.due,
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

final class _FakeSyncCursors implements SyncCursorRepository {
  @override
  SyncCursor? find({required String studentId, required String remoteScope}) =>
      null;

  @override
  void put(SyncCursor cursor) {}
}
