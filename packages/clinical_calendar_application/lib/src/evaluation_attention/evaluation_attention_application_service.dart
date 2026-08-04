import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import '../placements/placement_application_service.dart';
import '../placements/placement_models.dart';
import '../ports.dart';
import '../repositories.dart';
import 'evaluation_attention_models.dart';

abstract interface class EvaluationPlacementGateway {
  Future<List<PlacementSnapshot>> placements();
  Future<PlacementSnapshot?> activePlacement();
  Future<PlacementEditImpactPreview> previewEdit({
    required String clinicalPlacementId,
    required EditPlacementRequest request,
  });
  Future<PlacementSnapshot> confirmEdit(PlacementEditImpactPreview preview);
  Future<PlacementSnapshot> documentEvaluationRequirement({
    required String clinicalPlacementId,
    required EvaluationRequirementIdentity identity,
    required EvaluationDocumentation documentation,
    required int expectedEvaluationPlanRevision,
  });
}

final class PlacementEvaluationGateway implements EvaluationPlacementGateway {
  const PlacementEvaluationGateway(this.service);

  final PlacementApplicationService service;

  @override
  Future<PlacementSnapshot?> activePlacement() => service.activePlacement();

  @override
  Future<PlacementSnapshot> confirmEdit(PlacementEditImpactPreview preview) =>
      service.confirmEdit(preview);

  @override
  Future<PlacementSnapshot> documentEvaluationRequirement({
    required String clinicalPlacementId,
    required EvaluationRequirementIdentity identity,
    required EvaluationDocumentation documentation,
    required int expectedEvaluationPlanRevision,
  }) => service.documentEvaluationRequirement(
    clinicalPlacementId: clinicalPlacementId,
    identity: identity,
    documentation: documentation,
    expectedEvaluationPlanRevision: expectedEvaluationPlanRevision,
  );

  @override
  Future<List<PlacementSnapshot>> placements() => service.placements();

  @override
  Future<PlacementEditImpactPreview> previewEdit({
    required String clinicalPlacementId,
    required EditPlacementRequest request,
  }) => service.previewEdit(
    clinicalPlacementId: clinicalPlacementId,
    request: request,
  );
}

abstract interface class AttentionRepositorySource {
  Future<AttentionRepositorySnapshot> load({
    required String studentId,
    required DateTime nowUtc,
  });
}

final class LocalAttentionRepositorySource
    implements AttentionRepositorySource {
  const LocalAttentionRepositorySource(this.repositories);

  final RepositoryRegistry repositories;

  @override
  Future<AttentionRepositorySnapshot> load({
    required String studentId,
    required DateTime nowUtc,
  }) => repositories.read((repositories) {
    final awaiting = repositories.clinicalSessions
        .list(studentId: studentId)
        .map((record) => record.value.refreshStatus(nowUtc))
        .where(
          (session) =>
              session.state == ClinicalSessionState.awaitingConfirmation,
        )
        .toList(growable: false);
    final protectedDates = repositories.protectedDays
        .list(studentId: studentId)
        .map((record) => record.value.date)
        .toSet();
    var weekStartsOn = DateTime.sunday;
    if (repositories case final SupportLocalReadRepositories support) {
      weekStartsOn =
          support.studentSettings.find(studentId: studentId)?.value.weekStart ??
          weekStartsOn;
    }
    final pending = repositories.outbox.pending(
      studentId: studentId,
      asOfUtc: nowUtc,
      limit: 1000,
    );
    pending.sort(
      (left, right) =>
          left.mutation.occurredAtUtc.compareTo(right.mutation.occurredAtUtc),
    );
    return AttentionRepositorySnapshot(
      awaitingConfirmationSessions: awaiting,
      protectedDates: Set.unmodifiable(protectedDates),
      weekStartsOn: weekStartsOn,
      pendingSynchronizationCount: pending.length,
      oldestPendingSynchronizationAtUtc: pending.isEmpty
          ? null
          : pending.first.mutation.occurredAtUtc,
    );
  });
}

final class EvaluationAttentionApplicationService {
  EvaluationAttentionApplicationService({
    required this.placements,
    required this.attentionSource,
    required this.clock,
    required String studentId,
  }) : studentId = requireIdentifier(studentId, 'Student id');

  final EvaluationPlacementGateway placements;
  final AttentionRepositorySource attentionSource;
  final Clock clock;
  final String studentId;

  Future<EvaluationAttentionSnapshot> load({
    AttentionExternalState externalState = const AttentionExternalState(),
  }) async {
    final now = _now();
    final placementValues = await placements.placements();
    final active = await placements.activePlacement();
    final repository = await attentionSource.load(
      studentId: studentId,
      nowUtc: now,
    );
    return EvaluationAttentionSnapshot(
      placements: List.unmodifiable(placementValues),
      activePlacementId: active?.placement.id,
      attentionItems: List.unmodifiable(
        _deriveAttention(placementValues, repository, externalState, now),
      ),
    );
  }

  Future<PlacementEditImpactPreview> previewConfiguration({
    required PlacementSnapshot placement,
    required EvaluationPlanConfiguration configuration,
  }) => placements.previewEdit(
    clinicalPlacementId: placement.placement.id,
    request: EditPlacementRequest(
      name: placement.placement.name,
      targetHours: placement.placement.targetHours,
      startDate: placement.placement.startDate,
      completionDeadline: placement.placement.completionDeadline,
      evaluationPlanConfiguration: configuration,
    ),
  );

  Future<PlacementSnapshot> confirmConfiguration(
    PlacementEditImpactPreview preview,
  ) => placements.confirmEdit(preview);

  Future<PlacementSnapshot> documentRequirement({
    required PlacementSnapshot placement,
    required EvaluationRequirementIdentity identity,
    required EvaluationDocumentation documentation,
  }) => placements.documentEvaluationRequirement(
    clinicalPlacementId: placement.placement.id,
    identity: identity,
    documentation: documentation,
    expectedEvaluationPlanRevision: placement.evaluationPlanRevision,
  );

  DateTime _now() {
    final value = clock.nowUtc();
    if (!value.isUtc) throw StateError('Clock must return UTC.');
    return value;
  }
}

List<AttentionItem> _deriveAttention(
  List<PlacementSnapshot> placements,
  AttentionRepositorySnapshot repository,
  AttentionExternalState external,
  DateTime nowUtc,
) {
  final items = <AttentionItem>[
    for (final session in repository.awaitingConfirmationSessions)
      AttentionItem(
        id: 'confirmation:${session.id}',
        kind: AttentionKind.confirmation,
        urgency: AttentionUrgency.due,
        destination: AttentionDestination.confirmClinicalSession,
        title: 'Clinical Session needs confirmation',
        detail: 'Confirm the actual times and supervising Preceptor.',
        clinicalPlacementId: session.clinicalPlacementId,
        clinicalSessionId: session.id,
      ),
  ];
  final today = LocalDate(nowUtc.year, nowUtc.month, nowUtc.day);
  final week = CalendarWeekConfiguration(weekStartsOn: repository.weekStartsOn);
  final currentWeek = week.weekContaining(today);
  final nextWeek = week.weekContaining(currentWeek.end.addDays(1));
  for (final candidate in [currentWeek, nextWeek]) {
    if (!repository.protectedDates.any(candidate.contains)) {
      final current = candidate.contains(today);
      items.add(
        AttentionItem(
          id: 'protected-day:${candidate.start}',
          kind: AttentionKind.protectedDayPlanning,
          urgency: current
              ? AttentionUrgency.due
              : AttentionUrgency.approaching,
          destination: AttentionDestination.planProtectedDay,
          title: current
              ? 'Planning Incomplete'
              : 'Plan next week’s Protected Day',
          detail:
              'Choose one empty Protected Day for ${candidate.start}–${candidate.end}.',
          suggestedDate: candidate.start,
        ),
      );
    }
  }
  for (final placement in placements) {
    for (final evaluated in placement.evaluation.requirements) {
      if (!evaluated.requirement.isCurrentlyRequired ||
          (evaluated.state != EvaluationRequirementState.approaching &&
              evaluated.state != EvaluationRequirementState.due)) {
        continue;
      }
      items.add(
        AttentionItem(
          id: 'evaluation:${evaluated.requirement.identity.stableValue}',
          kind: AttentionKind.evaluation,
          urgency: evaluated.state == EvaluationRequirementState.due
              ? AttentionUrgency.due
              : AttentionUrgency.approaching,
          destination: AttentionDestination.documentEvaluation,
          title: _requirementTitle(evaluated.requirement.identity),
          detail:
              '${placement.placement.name} · ${_stateLabel(evaluated.state)}',
          clinicalPlacementId: placement.placement.id,
          evaluationRequirementIdentity: evaluated.requirement.identity,
        ),
      );
    }
    final pace = placement.progress.requiredWeeklyPace;
    if (pace != null && pace.isDeadlinePassed && pace.requiredMinutes > 0) {
      items.add(
        AttentionItem(
          id: 'deadline:${placement.placement.id}',
          kind: AttentionKind.deadline,
          urgency: AttentionUrgency.urgent,
          destination: AttentionDestination.manageClinicalPlacement,
          title: 'Completion Deadline needs attention',
          detail:
              '${placement.placement.name} still has '
              '${pace.requiredMinutes} unscheduled minutes.',
          clinicalPlacementId: placement.placement.id,
        ),
      );
    }
  }
  if (external.backup == BackupAttentionState.missing ||
      external.backup == BackupAttentionState.overdue) {
    items.add(
      AttentionItem(
        id: 'backup',
        kind: AttentionKind.backup,
        urgency: external.backup == BackupAttentionState.overdue
            ? AttentionUrgency.due
            : AttentionUrgency.approaching,
        destination: AttentionDestination.createPortableBackup,
        title: external.backup == BackupAttentionState.overdue
            ? 'Portable backup is overdue'
            : 'Create your first portable backup',
        detail:
            'Create an encrypted portable backup and keep its passphrase separate.',
      ),
    );
  }
  final oldest = repository.oldestPendingSynchronizationAtUtc;
  final pendingForADay =
      oldest != null && nowUtc.difference(oldest) >= const Duration(hours: 24);
  if (external.synchronization == SynchronizationAttentionState.conflict ||
      external.synchronization == SynchronizationAttentionState.failed ||
      pendingForADay) {
    final conflict =
        external.synchronization == SynchronizationAttentionState.conflict;
    items.add(
      AttentionItem(
        id: 'synchronization',
        kind: AttentionKind.synchronization,
        urgency: conflict ? AttentionUrgency.urgent : AttentionUrgency.due,
        destination: AttentionDestination.resolveSynchronization,
        title: conflict
            ? 'Sync Conflict Needs Attention'
            : 'Synchronization needs attention',
        detail:
            '${repository.pendingSynchronizationCount} local change(s) are waiting.',
      ),
    );
  }
  items.sort((left, right) {
    final urgency = right.urgency.index.compareTo(left.urgency.index);
    return urgency != 0 ? urgency : left.id.compareTo(right.id);
  });
  return items;
}

String _requirementTitle(
  EvaluationRequirementIdentity identity,
) => switch (identity.kind) {
  EvaluationRequirementKind.initialSelfAssessment => 'Initial Self-Assessment',
  EvaluationRequirementKind.interimStudentReviewsPrimaryPreceptor =>
    'Interim Review · Student reviews Primary Preceptor',
  EvaluationRequirementKind.interimPrimaryPreceptorReviewsStudent =>
    'Interim Review · Primary Preceptor reviews Student',
  EvaluationRequirementKind.finalSelfAssessment => 'Final Self-Assessment',
  EvaluationRequirementKind.finalPlacementReview => 'Final Placement Review',
};

String _stateLabel(EvaluationRequirementState state) => switch (state) {
  EvaluationRequirementState.notDue => 'Not Due',
  EvaluationRequirementState.approaching => 'Approaching',
  EvaluationRequirementState.due => 'Due',
  EvaluationRequirementState.documented => 'Documented',
};
