import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

/// A revision-bound, complete impact preview for moving one Clinical
/// Placement aggregate to Trash.
final class ClinicalPlacementDeletionPreview {
  const ClinicalPlacementDeletionPreview({
    required this.clinicalPlacementId,
    required this.clinicalPlacementName,
    required this.clinicalPlacementState,
    required this.memberRevisions,
    required this.scheduledClinicalSessionCount,
    required this.awaitingConfirmationClinicalSessionCount,
    required this.completedClinicalSessionCount,
    required this.cancelledClinicalSessionCount,
    required this.missedClinicalSessionCount,
    required this.clinicalSessionCompletedMinutes,
    required this.historicalHoursEntryCount,
    required this.historicalCompletedMinutes,
    required this.evaluationRequirementCount,
    required this.documentedEvaluationRequirementCount,
    required this.scheduleTemplateCount,
    required this.reminderStateCount,
    required this.attachedPreceptorRelationshipCount,
    required this.unsavedSchedulingDraftCount,
    required this.clearsActivePlacementSelection,
    required this.hasUnresolvedSynchronizationConflicts,
  });

  final String clinicalPlacementId;
  final String clinicalPlacementName;
  final ClinicalPlacementState clinicalPlacementState;
  final Map<String, int> memberRevisions;
  final int scheduledClinicalSessionCount;
  final int awaitingConfirmationClinicalSessionCount;
  final int completedClinicalSessionCount;
  final int cancelledClinicalSessionCount;
  final int missedClinicalSessionCount;
  final int clinicalSessionCompletedMinutes;
  final int historicalHoursEntryCount;
  final int historicalCompletedMinutes;
  final int evaluationRequirementCount;
  final int documentedEvaluationRequirementCount;
  final int scheduleTemplateCount;
  final int reminderStateCount;
  final int attachedPreceptorRelationshipCount;
  final int unsavedSchedulingDraftCount;
  final bool clearsActivePlacementSelection;
  final bool hasUnresolvedSynchronizationConflicts;

  int get clinicalSessionCount =>
      scheduledClinicalSessionCount +
      awaitingConfirmationClinicalSessionCount +
      completedClinicalSessionCount +
      cancelledClinicalSessionCount +
      missedClinicalSessionCount;

  int get persistedDependentRecordCount =>
      clinicalSessionCount +
      historicalHoursEntryCount +
      1 + // Evaluation Plan.
      scheduleTemplateCount +
      reminderStateCount;

  bool get requiresTypedName =>
      clinicalPlacementState == ClinicalPlacementState.completed;
}

/// Persistence capability for the all-or-nothing Clinical Placement deletion
/// graph. Implementations own transaction, conflict, sync-batch, and grouped
/// Trash semantics.
abstract interface class ClinicalPlacementAggregateDeletionStore {
  Future<ClinicalPlacementDeletionPreview> previewClinicalPlacementDeletion({
    required String clinicalPlacementId,
    required int unsavedSchedulingDraftCount,
  });

  Future<void> moveClinicalPlacementAggregateToTrash({
    required ClinicalPlacementDeletionPreview preview,
    required String aggregateMutationId,
    required DateTime deletedAtUtc,
  });
}
