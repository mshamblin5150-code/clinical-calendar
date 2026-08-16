import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

/// Canonical read model used by placement management, progress, evaluation,
/// and scheduling-default consumers.
final class PlacementSnapshot {
  const PlacementSnapshot({
    required this.placement,
    required this.placementRevision,
    required this.evaluationPlanRevision,
    required this.evaluationPlanConfiguration,
    required this.attachedPreceptors,
    required this.progress,
    required this.evaluation,
    required this.derivedState,
    required this.awaitingConfirmationSessionCount,
    required this.scheduledFutureSessionCount,
    this.scheduledFutureSessions = const [],
  });

  final ClinicalPlacement placement;
  final int placementRevision;
  final int evaluationPlanRevision;
  final EvaluationPlanConfiguration evaluationPlanConfiguration;
  final List<PlacementPreceptorSnapshot> attachedPreceptors;
  final ClinicalPlacementProgress progress;
  final EvaluationPlanEvaluation evaluation;
  final ClinicalPlacementState derivedState;
  final int awaitingConfirmationSessionCount;
  final int scheduledFutureSessionCount;
  final List<ClinicalSession> scheduledFutureSessions;

  bool get isReadyToComplete =>
      derivedState == ClinicalPlacementState.readyToComplete;

  List<EvaluatedEvaluationRequirement> get evaluationAttention => evaluation
      .requirements
      .where(
        (item) =>
            item.requirement.isCurrentlyRequired &&
            (item.state == EvaluationRequirementState.approaching ||
                item.state == EvaluationRequirementState.due),
      )
      .toList(growable: false);
}

final class PlacementPreceptorSnapshot {
  const PlacementPreceptorSnapshot({
    required this.preceptor,
    required this.revision,
    required this.isPrimary,
  });

  final Preceptor preceptor;
  final int revision;
  final bool isPrimary;
}

final class CreatePlacementRequest {
  const CreatePlacementRequest({
    required this.name,
    required this.targetHours,
    required this.startDate,
    required this.completionDeadline,
    required this.primaryPreceptorId,
    required this.evaluationPlanConfiguration,
  });

  final String name;
  final TargetHours targetHours;
  final LocalDate startDate;
  final LocalDate completionDeadline;
  final String primaryPreceptorId;
  final EvaluationPlanConfiguration evaluationPlanConfiguration;
}

final class EditPlacementRequest {
  const EditPlacementRequest({
    required this.name,
    required this.targetHours,
    required this.startDate,
    required this.completionDeadline,
    required this.evaluationPlanConfiguration,
  });

  final String name;
  final TargetHours targetHours;
  final LocalDate startDate;
  final LocalDate completionDeadline;
  final EvaluationPlanConfiguration evaluationPlanConfiguration;
}

/// A revision-bound impact description. It is deliberately created only by
/// the placement service's preview operation and must be supplied unchanged to
/// the confirmed save.
final class PlacementEditImpactPreview {
  const PlacementEditImpactPreview.internal({
    required this.clinicalPlacementId,
    required this.expectedPlacementRevision,
    required this.expectedEvaluationPlanRevision,
    required this.sourceRevisions,
    required this.outOfWindowClinicalSessionIds,
    required this.currentProgress,
    required this.proposedProgress,
    required this.evaluationPlanImpact,
    required this.proposedPlacement,
    required this.proposedEvaluationPlan,
  });

  final String clinicalPlacementId;
  final int expectedPlacementRevision;
  final int expectedEvaluationPlanRevision;
  final Map<String, int> sourceRevisions;
  final List<String> outOfWindowClinicalSessionIds;
  final ClinicalPlacementProgress currentProgress;
  final ClinicalPlacementProgress? proposedProgress;
  final EvaluationPlanEditPreview? evaluationPlanImpact;
  final ClinicalPlacement? proposedPlacement;
  final EvaluationPlan? proposedEvaluationPlan;

  bool get canConfirm => outOfWindowClinicalSessionIds.isEmpty;
}
