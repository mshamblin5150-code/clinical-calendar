import '../commitments/clinical_session.dart';
import '../domain_validation.dart';
import '../time/local_date.dart';
import 'historical_hours_entry.dart';
import 'placement_completion_evidence.dart';
import 'target_hours.dart';

enum ClinicalPlacementState { active, readyToComplete, completed }

/// A program requirement that persists independently of its Preceptors.
final class ClinicalPlacement {
  factory ClinicalPlacement.create({
    required String id,
    required String name,
    required TargetHours targetHours,
    required LocalDate startDate,
    required LocalDate completionDeadline,
    required Iterable<String> attachedPreceptorIds,
    required String primaryPreceptorId,
    required String evaluationPlanId,
  }) => ClinicalPlacement._validated(
    id: id,
    name: name,
    targetHours: targetHours,
    startDate: startDate,
    completionDeadline: completionDeadline,
    attachedPreceptorIds: attachedPreceptorIds,
    primaryPreceptorId: primaryPreceptorId,
    evaluationPlanId: evaluationPlanId,
    state: ClinicalPlacementState.active,
  );

  factory ClinicalPlacement.restore({
    required String id,
    required String name,
    required TargetHours targetHours,
    required LocalDate startDate,
    required LocalDate completionDeadline,
    required Iterable<String> attachedPreceptorIds,
    required String primaryPreceptorId,
    required String evaluationPlanId,
    required ClinicalPlacementState state,
  }) => ClinicalPlacement._validated(
    id: id,
    name: name,
    targetHours: targetHours,
    startDate: startDate,
    completionDeadline: completionDeadline,
    attachedPreceptorIds: attachedPreceptorIds,
    primaryPreceptorId: primaryPreceptorId,
    evaluationPlanId: evaluationPlanId,
    state: state,
  );

  factory ClinicalPlacement._validated({
    required String id,
    required String name,
    required TargetHours targetHours,
    required LocalDate startDate,
    required LocalDate completionDeadline,
    required Iterable<String> attachedPreceptorIds,
    required String primaryPreceptorId,
    required String evaluationPlanId,
    required ClinicalPlacementState state,
  }) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty || normalizedName.length > 160) {
      throw const DomainValidationException(
        'Clinical Placement name must contain between 1 and 160 characters.',
      );
    }
    if (completionDeadline.isBefore(startDate)) {
      throw const DomainValidationException(
        'Completion Deadline cannot be before Start Date.',
      );
    }
    final normalizedPreceptorIds = attachedPreceptorIds
        .map((value) => requireIdentifier(value, 'Preceptor id'))
        .toSet();
    final normalizedPrimary = requireIdentifier(
      primaryPreceptorId,
      'Primary Preceptor id',
    );
    if (!normalizedPreceptorIds.contains(normalizedPrimary)) {
      throw const DomainValidationException(
        'Primary Preceptor must be attached to the Clinical Placement.',
      );
    }
    return ClinicalPlacement._(
      id: requireIdentifier(id, 'Clinical Placement id'),
      name: normalizedName,
      targetHours: targetHours,
      startDate: startDate,
      completionDeadline: completionDeadline,
      attachedPreceptorIds: Set.unmodifiable(normalizedPreceptorIds),
      primaryPreceptorId: normalizedPrimary,
      evaluationPlanId: requireIdentifier(
        evaluationPlanId,
        'Evaluation Plan id',
      ),
      state: state,
    );
  }

  const ClinicalPlacement._({
    required this.id,
    required this.name,
    required this.targetHours,
    required this.startDate,
    required this.completionDeadline,
    required this.attachedPreceptorIds,
    required this.primaryPreceptorId,
    required this.evaluationPlanId,
    required this.state,
  });

  final String id;
  final String name;
  final TargetHours targetHours;
  final LocalDate startDate;
  final LocalDate completionDeadline;
  final Set<String> attachedPreceptorIds;
  final String primaryPreceptorId;
  final String evaluationPlanId;
  final ClinicalPlacementState state;

  ClinicalPlacement changePrimaryPreceptor(String preceptorId) {
    _requireEditable();
    final normalized = requireIdentifier(preceptorId, 'Primary Preceptor id');
    if (!attachedPreceptorIds.contains(normalized)) {
      throw const DomainValidationException(
        'Primary Preceptor must be attached to the Clinical Placement.',
      );
    }
    return _copy(primaryPreceptorId: normalized);
  }

  ClinicalPlacement attachPreceptor(String preceptorId) {
    _requireEditable();
    final normalized = requireIdentifier(preceptorId, 'Preceptor id');
    return _copy(attachedPreceptorIds: {...attachedPreceptorIds, normalized});
  }

  ClinicalPlacement detachPreceptor(
    String preceptorId,
    PreceptorReferenceSummary references,
  ) {
    _requireEditable();
    final normalized = requireIdentifier(preceptorId, 'Preceptor id');
    if (!attachedPreceptorIds.contains(normalized)) {
      throw const DomainValidationException(
        'Preceptor is not attached to the Clinical Placement.',
      );
    }
    if (normalized == primaryPreceptorId) {
      throw const DomainValidationException(
        'Primary Preceptor cannot be detached until another is Primary.',
      );
    }
    if (references.hasReferences) {
      throw const DomainValidationException(
        'A referenced Preceptor cannot be detached from the Clinical Placement.',
      );
    }
    return _copy(
      attachedPreceptorIds: attachedPreceptorIds
          .where((id) => id != normalized)
          .toSet(),
    );
  }

  void validateClinicalSession(ClinicalSession session) {
    if (session.clinicalPlacementId != id) {
      throw const DomainValidationException(
        'Clinical Session belongs to a different Clinical Placement.',
      );
    }
    if (!attachedPreceptorIds.contains(session.preceptorId)) {
      throw const DomainValidationException(
        'Clinical Session Preceptor is not attached to the Clinical Placement.',
      );
    }
    _validateIntervalDates(
      session.plannedInterval.startDate,
      session.plannedInterval.endDate,
    );
    final actual = session.actualInterval;
    if (actual != null) {
      _validateIntervalDates(actual.startDate, actual.endDate);
    }
  }

  void validateHistoricalHoursEntry(HistoricalHoursEntry entry) {
    if (entry.clinicalPlacementId != id) {
      throw const DomainValidationException(
        'Historical Hours Entry belongs to a different Clinical Placement.',
      );
    }
    final preceptorId = entry.preceptorId;
    if (preceptorId != null && !attachedPreceptorIds.contains(preceptorId)) {
      throw const DomainValidationException(
        'Historical Hours Entry Preceptor is not attached to the '
        'Clinical Placement.',
      );
    }
  }

  ClinicalPlacement changeWindow({
    required LocalDate startDate,
    required LocalDate completionDeadline,
    required Iterable<ClinicalSession> existingSessions,
  }) {
    _requireEditable();
    if (completionDeadline.isBefore(startDate)) {
      throw const DomainValidationException(
        'Completion Deadline cannot be before Start Date.',
      );
    }
    for (final session in existingSessions) {
      if (session.clinicalPlacementId != id ||
          session.plannedInterval.startDate.isBefore(startDate) ||
          session.plannedInterval.endDate.isAfter(completionDeadline)) {
        throw const DomainValidationException(
          'A Clinical Session falls outside the proposed placement window.',
        );
      }
    }
    return _copy(
      startDate: startDate,
      completionDeadline: completionDeadline,
      state: ClinicalPlacementState.active,
    );
  }

  ClinicalPlacement changeTargetHours(TargetHours targetHours) {
    _requireEditable();
    return _copy(
      targetHours: targetHours,
      state: ClinicalPlacementState.active,
    );
  }

  ClinicalPlacement evaluateReadiness(PlacementCompletionEvidence evidence) {
    _requireEditable();
    return _copy(
      state: evidence.satisfies(targetHours)
          ? ClinicalPlacementState.readyToComplete
          : ClinicalPlacementState.active,
    );
  }

  ClinicalPlacement complete() {
    if (state != ClinicalPlacementState.readyToComplete) {
      throw const DomainValidationException(
        'Only a Ready-to-Complete Clinical Placement can be completed.',
      );
    }
    return _copy(state: ClinicalPlacementState.completed);
  }

  ClinicalPlacement reopen() {
    if (state != ClinicalPlacementState.completed) {
      throw const DomainValidationException(
        'Only a Completed Placement can be reopened.',
      );
    }
    return _copy(state: ClinicalPlacementState.active);
  }

  bool isEligibleForPermanentDeletion(PlacementContentSummary content) =>
      state == ClinicalPlacementState.active && content.isEmpty;

  void requireEligibleForPermanentDeletion(PlacementContentSummary content) {
    if (!isEligibleForPermanentDeletion(content)) {
      throw const DomainValidationException(
        'Only an empty mistaken Clinical Placement may be permanently deleted.',
      );
    }
  }

  void _validateIntervalDates(LocalDate intervalStart, LocalDate intervalEnd) {
    if (intervalStart.isBefore(startDate) ||
        intervalEnd.isAfter(completionDeadline)) {
      throw const DomainValidationException(
        'Clinical Session falls outside the Clinical Placement window.',
      );
    }
  }

  void _requireEditable() {
    if (state == ClinicalPlacementState.completed) {
      throw const DomainValidationException(
        'Completed Placements reject ordinary edits until reopened.',
      );
    }
  }

  ClinicalPlacement _copy({
    String? name,
    TargetHours? targetHours,
    LocalDate? startDate,
    LocalDate? completionDeadline,
    Set<String>? attachedPreceptorIds,
    String? primaryPreceptorId,
    String? evaluationPlanId,
    ClinicalPlacementState? state,
  }) => ClinicalPlacement._(
    id: id,
    name: name ?? this.name,
    targetHours: targetHours ?? this.targetHours,
    startDate: startDate ?? this.startDate,
    completionDeadline: completionDeadline ?? this.completionDeadline,
    attachedPreceptorIds: Set.unmodifiable(
      attachedPreceptorIds ?? this.attachedPreceptorIds,
    ),
    primaryPreceptorId: primaryPreceptorId ?? this.primaryPreceptorId,
    evaluationPlanId: evaluationPlanId ?? this.evaluationPlanId,
    state: state ?? this.state,
  );
}
