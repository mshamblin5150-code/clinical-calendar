import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import '../ports.dart';
import '../repositories.dart';
import 'placement_models.dart';

final class PlacementApplicationService {
  factory PlacementApplicationService({
    required RepositoryRegistry repositories,
    required Clock clock,
    required IdentifierGenerator identifiers,
    required String studentId,
    ClinicalPlacementProgressEngine progressEngine =
        const ClinicalPlacementProgressEngine(),
    EvaluationPlanEngine evaluationPlanEngine = const EvaluationPlanEngine(),
  }) => PlacementApplicationService._(
    repositories,
    clock,
    identifiers,
    requireIdentifier(studentId, 'Student id'),
    progressEngine,
    evaluationPlanEngine,
  );

  const PlacementApplicationService._(
    this._repositories,
    this._clock,
    this._identifiers,
    this._studentId,
    this._progressEngine,
    this._evaluationPlanEngine,
  );

  final RepositoryRegistry _repositories;
  final Clock _clock;
  final IdentifierGenerator _identifiers;
  final String _studentId;
  final ClinicalPlacementProgressEngine _progressEngine;
  final EvaluationPlanEngine _evaluationPlanEngine;

  Future<PlacementSnapshot> createPlacement(
    CreatePlacementRequest request,
  ) async {
    final occurredAt = _now();
    final placementId = _identifiers.nextIdentifier();
    final evaluationPlanId = _identifiers.nextIdentifier();
    return _repositories.mutate((repositories) {
      _requireRecord(
        repositories.preceptors.find(
          studentId: _studentId,
          id: request.primaryPreceptorId,
        ),
        'Primary Preceptor',
      );
      final placement = ClinicalPlacement.create(
        id: placementId,
        name: request.name,
        targetHours: request.targetHours,
        startDate: request.startDate,
        completionDeadline: request.completionDeadline,
        attachedPreceptorIds: [request.primaryPreceptorId],
        primaryPreceptorId: request.primaryPreceptorId,
        evaluationPlanId: evaluationPlanId,
      );
      final context = EvaluationPlanContext(
        completedMinutes: 0,
        targetMinutes: request.targetHours.minutes,
        startDate: request.startDate,
        completionDeadline: request.completionDeadline,
        today: _today(occurredAt),
      );
      final plan = _evaluationPlanEngine.create(
        evaluationPlanId: evaluationPlanId,
        configuration: request.evaluationPlanConfiguration,
        context: context,
        primaryPreceptorId: request.primaryPreceptorId,
      );

      // SQLCipher resolves a new plan's inverse placement association from
      // the placement outbox written earlier in this same transaction.
      repositories.clinicalPlacements.put(
        studentId: _studentId,
        value: placement,
        expectedRevision: 0,
        mutation: _mutation(occurredAt),
      );
      repositories.evaluationPlans.put(
        studentId: _studentId,
        value: plan,
        expectedRevision: 0,
        mutation: _mutation(occurredAt),
      );
      final active = repositories.activePlacementSelection.find(
        studentId: _studentId,
      );
      repositories.activePlacementSelection.put(
        studentId: _studentId,
        clinicalPlacementId: placement.id,
        expectedRevision: active?.revision ?? 0,
        mutation: _mutation(occurredAt),
      );
      return _snapshot(repositories, placement.id, occurredAt);
    });
  }

  Future<PlacementEditImpactPreview> previewEdit({
    required String clinicalPlacementId,
    required EditPlacementRequest request,
  }) async {
    final asOf = _now();
    return _repositories.read((repositories) {
      final placementRecord = _placement(repositories, clinicalPlacementId);
      final current = placementRecord.value;
      _requireUnlocked(current);
      final planRecord = _plan(repositories, current.evaluationPlanId);
      final sessions = _sessionRecords(repositories, current.id);
      final history = _historyRecords(repositories, current.id);
      final currentProgress = _progressEngine.derivePlacement(
        placement: current,
        sessions: sessions.map((record) => record.value),
        historicalHoursEntries: history.map((record) => record.value),
        today: _today(asOf),
      );
      final blockers =
          sessions
              .where(
                (record) => _outsideWindow(
                  record.value,
                  request.startDate,
                  request.completionDeadline,
                ),
              )
              .map((record) => record.value.id)
              .toList(growable: false)
            ..sort();

      ClinicalPlacement? proposedPlacement;
      ClinicalPlacementProgress? proposedProgress;
      EvaluationPlanEditPreview? planImpact;
      EvaluationPlan? proposedPlan;
      if (blockers.isEmpty) {
        var changed = current.changeTargetHours(request.targetHours);
        changed = changed.changeWindow(
          startDate: request.startDate,
          completionDeadline: request.completionDeadline,
          existingSessions: sessions.map((record) => record.value),
        );
        proposedPlacement = ClinicalPlacement.restore(
          id: changed.id,
          name: request.name,
          targetHours: changed.targetHours,
          startDate: changed.startDate,
          completionDeadline: changed.completionDeadline,
          attachedPreceptorIds: changed.attachedPreceptorIds,
          primaryPreceptorId: changed.primaryPreceptorId,
          evaluationPlanId: changed.evaluationPlanId,
          state: changed.state,
        );
        proposedProgress = _progressEngine.derivePlacement(
          placement: proposedPlacement,
          sessions: sessions.map((record) => record.value),
          historicalHoursEntries: history.map((record) => record.value),
          today: _today(asOf),
        );
        planImpact = _evaluationPlanEngine.previewEdit(
          currentPlan: planRecord.value,
          proposedConfiguration: request.evaluationPlanConfiguration,
          proposedContext: _evaluationContext(
            proposedPlacement,
            proposedProgress,
            sessions.map((record) => record.value),
            asOf,
          ),
          proposedPrimaryPreceptorId: proposedPlacement.primaryPreceptorId,
        );
        proposedPlan = _evaluationPlanEngine.applyEdit(planImpact);
      }

      return PlacementEditImpactPreview.internal(
        clinicalPlacementId: current.id,
        expectedPlacementRevision: placementRecord.revision,
        expectedEvaluationPlanRevision: planRecord.revision,
        sourceRevisions: _sourceRevisions(sessions, history),
        outOfWindowClinicalSessionIds: List.unmodifiable(blockers),
        currentProgress: currentProgress,
        proposedProgress: proposedProgress,
        evaluationPlanImpact: planImpact,
        proposedPlacement: proposedPlacement,
        proposedEvaluationPlan: proposedPlan,
      );
    });
  }

  Future<PlacementSnapshot> confirmEdit(
    PlacementEditImpactPreview preview,
  ) async {
    if (!preview.canConfirm ||
        preview.proposedPlacement == null ||
        preview.proposedEvaluationPlan == null) {
      throw const DomainValidationException(
        'A blocked Clinical Placement impact preview cannot be confirmed.',
      );
    }
    final occurredAt = _now();
    return _repositories.mutate((repositories) {
      final placementRecord = _placement(
        repositories,
        preview.clinicalPlacementId,
      );
      final planRecord = _plan(
        repositories,
        placementRecord.value.evaluationPlanId,
      );
      final sessions = _sessionRecords(repositories, placementRecord.value.id);
      final history = _historyRecords(repositories, placementRecord.value.id);
      if (placementRecord.revision != preview.expectedPlacementRevision ||
          planRecord.revision != preview.expectedEvaluationPlanRevision ||
          !_sameRevisions(
            preview.sourceRevisions,
            _sourceRevisions(sessions, history),
          )) {
        throw const RepositoryException(
          RepositoryFailureKind.concurrentModification,
          'The Clinical Placement changed after its impact preview.',
        );
      }
      _requireUnlocked(placementRecord.value);
      // Re-run the window invariant against the transaction's exact records.
      preview.proposedPlacement!.changeWindow(
        startDate: preview.proposedPlacement!.startDate,
        completionDeadline: preview.proposedPlacement!.completionDeadline,
        existingSessions: sessions.map((record) => record.value),
      );
      repositories.clinicalPlacements.put(
        studentId: _studentId,
        value: preview.proposedPlacement!,
        expectedRevision: placementRecord.revision,
        mutation: _mutation(occurredAt),
      );
      repositories.evaluationPlans.put(
        studentId: _studentId,
        value: preview.proposedEvaluationPlan!,
        expectedRevision: planRecord.revision,
        mutation: _mutation(occurredAt),
      );
      return _snapshot(repositories, placementRecord.value.id, occurredAt);
    });
  }

  Future<Preceptor> createPreceptor({
    required String name,
    String? organizationOrSite,
    String? phone,
    String? email,
    String? schedulingNotes,
  }) async {
    final occurredAt = _now();
    final value = Preceptor(
      id: _identifiers.nextIdentifier(),
      name: name,
      organizationOrSite: organizationOrSite,
      phone: phone,
      email: email,
      schedulingNotes: schedulingNotes,
    );
    return _repositories.mutate((repositories) {
      repositories.preceptors.put(
        studentId: _studentId,
        value: value,
        expectedRevision: 0,
        mutation: _mutation(occurredAt),
      );
      return value;
    });
  }

  Future<Preceptor> editPreceptor({
    required String preceptorId,
    required int expectedRevision,
    required String name,
    String? organizationOrSite,
    String? phone,
    String? email,
    String? schedulingNotes,
  }) async {
    final occurredAt = _now();
    return _repositories.mutate((repositories) {
      final current = _requireRecord(
        repositories.preceptors.find(studentId: _studentId, id: preceptorId),
        'Preceptor',
      );
      if (current.revision != expectedRevision) {
        throw const RepositoryException(
          RepositoryFailureKind.concurrentModification,
          'The Preceptor changed before the edit was saved.',
        );
      }
      final value = Preceptor(
        id: current.value.id,
        name: name,
        organizationOrSite: organizationOrSite,
        phone: phone,
        email: email,
        schedulingNotes: schedulingNotes,
      );
      repositories.preceptors.put(
        studentId: _studentId,
        value: value,
        expectedRevision: current.revision,
        mutation: _mutation(occurredAt),
      );
      return value;
    });
  }

  Future<PlacementSnapshot> attachPreceptor({
    required String clinicalPlacementId,
    required String preceptorId,
    required int expectedPlacementRevision,
  }) => _changePlacementOnly(
    clinicalPlacementId: clinicalPlacementId,
    expectedPlacementRevision: expectedPlacementRevision,
    transform: (repositories, placement) {
      _requireRecord(
        repositories.preceptors.find(studentId: _studentId, id: preceptorId),
        'Preceptor',
      );
      return placement.attachPreceptor(preceptorId);
    },
  );

  Future<PlacementSnapshot> detachPreceptor({
    required String clinicalPlacementId,
    required String preceptorId,
    required int expectedPlacementRevision,
  }) => _changePlacementOnly(
    clinicalPlacementId: clinicalPlacementId,
    expectedPlacementRevision: expectedPlacementRevision,
    transform: (repositories, placement) {
      final plan = _plan(repositories, placement.evaluationPlanId).value;
      final references = PreceptorReferenceSummary(
        clinicalSessionCount: _sessionRecords(
          repositories,
          placement.id,
        ).where((record) => record.value.preceptorId == preceptorId).length,
        historicalHoursEntryCount: _historyRecords(
          repositories,
          placement.id,
        ).where((record) => record.value.preceptorId == preceptorId).length,
        evaluationRecordCount: plan.requirements
            .where(
              (requirement) => requirement.primaryPreceptorId == preceptorId,
            )
            .length,
      );
      return placement.detachPreceptor(preceptorId, references);
    },
  );

  Future<PlacementSnapshot> makePrimaryPreceptor({
    required String clinicalPlacementId,
    required String preceptorId,
    required int expectedPlacementRevision,
    required int expectedEvaluationPlanRevision,
  }) async {
    final occurredAt = _now();
    return _repositories.mutate((repositories) {
      final placementRecord = _placement(repositories, clinicalPlacementId);
      final planRecord = _plan(
        repositories,
        placementRecord.value.evaluationPlanId,
      );
      _requireExpected(placementRecord.revision, expectedPlacementRevision);
      _requireExpected(planRecord.revision, expectedEvaluationPlanRevision);
      final placement = placementRecord.value.changePrimaryPreceptor(
        preceptorId,
      );
      final sessions = _sessionRecords(repositories, placement.id);
      final progress = _progressEngine.derivePlacement(
        placement: placement,
        sessions: sessions.map((record) => record.value),
        historicalHoursEntries: _historyRecords(
          repositories,
          placement.id,
        ).map((record) => record.value),
        today: _today(occurredAt),
      );
      final planPreview = _evaluationPlanEngine.previewEdit(
        currentPlan: planRecord.value,
        proposedConfiguration: planRecord.value.configuration,
        proposedContext: _evaluationContext(
          placement,
          progress,
          sessions.map((record) => record.value),
          occurredAt,
        ),
        proposedPrimaryPreceptorId: preceptorId,
      );
      repositories.clinicalPlacements.put(
        studentId: _studentId,
        value: placement,
        expectedRevision: placementRecord.revision,
        mutation: _mutation(occurredAt),
      );
      repositories.evaluationPlans.put(
        studentId: _studentId,
        value: _evaluationPlanEngine.applyEdit(planPreview),
        expectedRevision: planRecord.revision,
        mutation: _mutation(occurredAt),
      );
      return _snapshot(repositories, placement.id, occurredAt);
    });
  }

  Future<PlacementSnapshot> addHistoricalHours({
    required String clinicalPlacementId,
    required int completedMinutes,
    required LocalDate effectiveDate,
    String? preceptorId,
    String? note,
  }) async {
    final occurredAt = _now();
    final entryId = _identifiers.nextIdentifier();
    return _repositories.mutate((repositories) {
      final placementRecord = _placement(repositories, clinicalPlacementId);
      _requireUnlocked(placementRecord.value);
      if (preceptorId != null) {
        _requireRecord(
          repositories.preceptors.find(studentId: _studentId, id: preceptorId),
          'Preceptor',
        );
      }
      final entry = HistoricalHoursEntry(
        id: entryId,
        clinicalPlacementId: placementRecord.value.id,
        completedMinutes: completedMinutes,
        effectiveDate: effectiveDate,
        preceptorId: preceptorId,
        note: note,
      );
      placementRecord.value.validateHistoricalHoursEntry(entry);
      repositories.historicalHoursEntries.put(
        studentId: _studentId,
        value: entry,
        expectedRevision: 0,
        mutation: _mutation(occurredAt),
      );
      _persistDerivedReadiness(repositories, placementRecord, occurredAt);
      return _snapshot(repositories, placementRecord.value.id, occurredAt);
    });
  }

  Future<PlacementSnapshot> documentEvaluationRequirement({
    required String clinicalPlacementId,
    required EvaluationRequirementIdentity identity,
    required EvaluationDocumentation documentation,
    required int expectedEvaluationPlanRevision,
  }) async {
    final occurredAt = _now();
    return _repositories.mutate((repositories) {
      final placementRecord = _placement(repositories, clinicalPlacementId);
      _requireUnlocked(placementRecord.value);
      final planRecord = _plan(
        repositories,
        placementRecord.value.evaluationPlanId,
      );
      _requireExpected(planRecord.revision, expectedEvaluationPlanRevision);
      final plan = _evaluationPlanEngine.documentRequirement(
        plan: planRecord.value,
        identity: identity,
        documentation: documentation,
        asOfDate: _today(occurredAt),
      );
      repositories.evaluationPlans.put(
        studentId: _studentId,
        value: plan,
        expectedRevision: planRecord.revision,
        mutation: _mutation(occurredAt),
      );
      _persistDerivedReadiness(repositories, placementRecord, occurredAt);
      return _snapshot(repositories, placementRecord.value.id, occurredAt);
    });
  }

  Future<PlacementSnapshot> completePlacement({
    required String clinicalPlacementId,
    required int expectedPlacementRevision,
  }) async {
    final occurredAt = _now();
    return _repositories.mutate((repositories) {
      final record = _placement(repositories, clinicalPlacementId);
      _requireExpected(record.revision, expectedPlacementRevision);
      final snapshot = _snapshot(repositories, record.value.id, occurredAt);
      final ready = record.value.evaluateReadiness(
        _completionEvidence(snapshot),
      );
      final completed = ready.complete();
      repositories.clinicalPlacements.put(
        studentId: _studentId,
        value: completed,
        expectedRevision: record.revision,
        mutation: _mutation(occurredAt),
      );
      return _snapshot(repositories, record.value.id, occurredAt);
    });
  }

  Future<PlacementSnapshot> reopenPlacement({
    required String clinicalPlacementId,
    required int expectedPlacementRevision,
  }) async {
    final occurredAt = _now();
    return _repositories.mutate((repositories) {
      final record = _placement(repositories, clinicalPlacementId);
      _requireExpected(record.revision, expectedPlacementRevision);
      final reopened = record.value.reopen();
      repositories.clinicalPlacements.put(
        studentId: _studentId,
        value: reopened,
        expectedRevision: record.revision,
        mutation: _mutation(occurredAt),
      );
      final active = repositories.activePlacementSelection.find(
        studentId: _studentId,
      );
      repositories.activePlacementSelection.put(
        studentId: _studentId,
        clinicalPlacementId: reopened.id,
        expectedRevision: active?.revision ?? 0,
        mutation: _mutation(occurredAt),
      );
      return _snapshot(repositories, record.value.id, occurredAt);
    });
  }

  Future<void> selectActivePlacement(String? clinicalPlacementId) async {
    final occurredAt = _now();
    await _repositories.mutate((repositories) {
      if (clinicalPlacementId != null) {
        _placement(repositories, clinicalPlacementId);
      }
      final current = repositories.activePlacementSelection.find(
        studentId: _studentId,
      );
      repositories.activePlacementSelection.put(
        studentId: _studentId,
        clinicalPlacementId: clinicalPlacementId,
        expectedRevision: current?.revision ?? 0,
        mutation: _mutation(occurredAt),
      );
    });
  }

  Future<PlacementSnapshot?> activePlacement() {
    final asOf = _now();
    return _repositories.read((repositories) {
      final selected = repositories.activePlacementSelection.find(
        studentId: _studentId,
      );
      final id = selected?.value;
      return id == null ? null : _snapshot(repositories, id, asOf);
    });
  }

  Future<PlacementSnapshot> placement(String clinicalPlacementId) {
    final asOf = _now();
    return _repositories.read(
      (repositories) => _snapshot(repositories, clinicalPlacementId, asOf),
    );
  }

  Future<List<PlacementSnapshot>> placements() {
    final asOf = _now();
    return _repositories.read((repositories) {
      final records =
          repositories.clinicalPlacements.list(studentId: _studentId)..sort((
            left,
            right,
          ) {
            final date = left.value.startDate.compareTo(right.value.startDate);
            if (date != 0) return date;
            final name = left.value.name.compareTo(right.value.name);
            return name != 0 ? name : left.value.id.compareTo(right.value.id);
          });
      return List.unmodifiable(
        records.map((record) => _snapshot(repositories, record.value.id, asOf)),
      );
    });
  }

  Future<TotalProgress> totalProgress() async => _progressEngine.deriveTotal(
    (await placements()).map((snapshot) => snapshot.progress),
  );

  Future<PlacementSnapshot> _changePlacementOnly({
    required String clinicalPlacementId,
    required int expectedPlacementRevision,
    required ClinicalPlacement Function(
      LocalWriteRepositories repositories,
      ClinicalPlacement placement,
    )
    transform,
  }) async {
    final occurredAt = _now();
    return _repositories.mutate((repositories) {
      final record = _placement(repositories, clinicalPlacementId);
      _requireExpected(record.revision, expectedPlacementRevision);
      final changed = transform(repositories, record.value);
      repositories.clinicalPlacements.put(
        studentId: _studentId,
        value: changed,
        expectedRevision: record.revision,
        mutation: _mutation(occurredAt),
      );
      return _snapshot(repositories, changed.id, occurredAt);
    });
  }

  void _persistDerivedReadiness(
    LocalWriteRepositories repositories,
    StoredDomainRecord<ClinicalPlacement> record,
    DateTime occurredAt,
  ) {
    final snapshot = _snapshot(repositories, record.value.id, occurredAt);
    final evaluated = record.value.evaluateReadiness(
      _completionEvidence(snapshot),
    );
    if (evaluated.state != record.value.state) {
      repositories.clinicalPlacements.put(
        studentId: _studentId,
        value: evaluated,
        expectedRevision: record.revision,
        mutation: _mutation(occurredAt),
      );
    }
  }

  PlacementSnapshot _snapshot(
    LocalReadRepositories repositories,
    String placementId,
    DateTime asOf,
  ) {
    final placementRecord = _placement(repositories, placementId);
    final placement = placementRecord.value;
    final sessionRecords = _sessionRecords(repositories, placement.id);
    final sessions = sessionRecords
        .map((record) => record.value.refreshStatus(asOf))
        .toList(growable: false);
    final history = _historyRecords(
      repositories,
      placement.id,
    ).map((record) => record.value).toList(growable: false);
    final progress = _progressEngine.derivePlacement(
      placement: placement,
      sessions: sessions,
      historicalHoursEntries: history,
      today: _today(asOf),
    );
    final planRecord = _plan(repositories, placement.evaluationPlanId);
    final plan = planRecord.value;
    final evaluation = _evaluationPlanEngine.evaluate(
      plan,
      _evaluationContext(placement, progress, sessions, asOf),
    );
    final awaiting = sessions
        .where(
          (session) =>
              session.state == ClinicalSessionState.awaitingConfirmation,
        )
        .length;
    final scheduledSessions =
        sessions
            .where((session) => session.state == ClinicalSessionState.scheduled)
            .toList(growable: false)
          ..sort(
            (left, right) => left.plannedInterval.startInstantUtc.compareTo(
              right.plannedInterval.startInstantUtc,
            ),
          );
    final scheduled = scheduledSessions.length;
    final evidence = PlacementCompletionEvidence(
      completedMinutes: progress.completedMinutes,
      allRequiredEvaluationsDocumented:
          evaluation.allCurrentlyRequiredDocumented,
      awaitingConfirmationSessionCount: awaiting,
      scheduledFutureSessionCount: scheduled,
    );
    final derivedState = placement.state == ClinicalPlacementState.completed
        ? ClinicalPlacementState.completed
        : placement.evaluateReadiness(evidence).state;
    return PlacementSnapshot(
      placement: placement,
      placementRevision: placementRecord.revision,
      evaluationPlanRevision: planRecord.revision,
      evaluationPlanConfiguration: plan.configuration,
      attachedPreceptors: List.unmodifiable(
        placement.attachedPreceptorIds.map((id) {
          final record = _requireRecord(
            repositories.preceptors.find(studentId: _studentId, id: id),
            'Preceptor',
          );
          return PlacementPreceptorSnapshot(
            preceptor: record.value,
            revision: record.revision,
            isPrimary: id == placement.primaryPreceptorId,
          );
        }).toList()..sort((left, right) {
          if (left.isPrimary != right.isPrimary) {
            return left.isPrimary ? -1 : 1;
          }
          final name = left.preceptor.name.compareTo(right.preceptor.name);
          return name != 0
              ? name
              : left.preceptor.id.compareTo(right.preceptor.id);
        }),
      ),
      progress: progress,
      evaluation: evaluation,
      derivedState: derivedState,
      awaitingConfirmationSessionCount: awaiting,
      scheduledFutureSessionCount: scheduled,
      scheduledFutureSessions: List.unmodifiable(scheduledSessions),
    );
  }

  EvaluationPlanContext _evaluationContext(
    ClinicalPlacement placement,
    ClinicalPlacementProgress progress,
    Iterable<ClinicalSession> sessions,
    DateTime asOf,
  ) {
    final future =
        sessions
            .where((session) => session.state == ClinicalSessionState.scheduled)
            .toList(growable: false)
          ..sort(
            (left, right) => left.plannedInterval.startInstantUtc.compareTo(
              right.plannedInterval.startInstantUtc,
            ),
          );
    return EvaluationPlanContext(
      completedMinutes: progress.completedMinutes,
      targetMinutes: placement.targetHours.minutes,
      startDate: placement.startDate,
      completionDeadline: placement.completionDeadline,
      today: _today(asOf),
      futureScheduledSessionMinutes: future.map(
        (session) => session.plannedMinutes,
      ),
    );
  }

  PlacementCompletionEvidence _completionEvidence(PlacementSnapshot snapshot) =>
      PlacementCompletionEvidence(
        completedMinutes: snapshot.progress.completedMinutes,
        allRequiredEvaluationsDocumented:
            snapshot.evaluation.allCurrentlyRequiredDocumented,
        awaitingConfirmationSessionCount:
            snapshot.awaitingConfirmationSessionCount,
        scheduledFutureSessionCount: snapshot.scheduledFutureSessionCount,
      );

  StoredDomainRecord<ClinicalPlacement> _placement(
    LocalReadRepositories repositories,
    String id,
  ) => _requireRecord(
    repositories.clinicalPlacements.find(studentId: _studentId, id: id),
    'Clinical Placement',
  );

  StoredDomainRecord<EvaluationPlan> _plan(
    LocalReadRepositories repositories,
    String id,
  ) => _requireRecord(
    repositories.evaluationPlans.find(studentId: _studentId, id: id),
    'Evaluation Plan',
  );

  List<StoredDomainRecord<ClinicalSession>> _sessionRecords(
    LocalReadRepositories repositories,
    String placementId,
  ) => repositories.clinicalSessions
      .list(studentId: _studentId)
      .where((record) => record.value.clinicalPlacementId == placementId)
      .toList(growable: false);

  List<StoredDomainRecord<HistoricalHoursEntry>> _historyRecords(
    LocalReadRepositories repositories,
    String placementId,
  ) => repositories.historicalHoursEntries
      .list(studentId: _studentId)
      .where((record) => record.value.clinicalPlacementId == placementId)
      .toList(growable: false);

  Map<String, int> _sourceRevisions(
    Iterable<StoredDomainRecord<ClinicalSession>> sessions,
    Iterable<StoredDomainRecord<HistoricalHoursEntry>> history,
  ) => Map.unmodifiable({
    for (final record in sessions)
      'clinical-session:${record.value.id}': record.revision,
    for (final record in history)
      'historical-hours:${record.value.id}': record.revision,
  });

  MutationToken _mutation(DateTime occurredAt) => MutationToken(
    operationId: _identifiers.nextIdentifier(),
    idempotencyKey: _identifiers.nextIdentifier(),
    occurredAtUtc: occurredAt,
  );

  DateTime _now() {
    final value = _clock.nowUtc();
    if (!value.isUtc) {
      throw StateError('Clock.nowUtc() must return UTC.');
    }
    return value;
  }
}

StoredDomainRecord<T> _requireRecord<T>(
  StoredDomainRecord<T>? record,
  String label,
) {
  if (record == null) {
    throw RepositoryException(
      RepositoryFailureKind.notFound,
      '$label was not found.',
    );
  }
  return record;
}

void _requireExpected(int actual, int expected) {
  if (actual != expected) {
    throw const RepositoryException(
      RepositoryFailureKind.concurrentModification,
      'The record changed before the operation was saved.',
    );
  }
}

void _requireUnlocked(ClinicalPlacement placement) {
  if (placement.state == ClinicalPlacementState.completed) {
    throw const DomainValidationException(
      'Completed Placements reject ordinary edits until reopened.',
    );
  }
}

bool _outsideWindow(
  ClinicalSession session,
  LocalDate start,
  LocalDate deadline,
) {
  final planned = session.plannedInterval;
  if (planned.startDate.isBefore(start) || planned.endDate.isAfter(deadline)) {
    return true;
  }
  final actual = session.actualInterval;
  return actual != null &&
      (actual.startDate.isBefore(start) || actual.endDate.isAfter(deadline));
}

bool _sameRevisions(Map<String, int> left, Map<String, int> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}

LocalDate _today(DateTime utc) => LocalDate(utc.year, utc.month, utc.day);
