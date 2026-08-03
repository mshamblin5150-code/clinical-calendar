import '../domain_validation.dart';
import 'target_hours.dart';

/// Read-only output supplied by the progress and Evaluation Plan engines when
/// determining a Clinical Placement's lifecycle state.
final class PlacementCompletionEvidence {
  factory PlacementCompletionEvidence({
    required int completedMinutes,
    required bool allRequiredEvaluationsDocumented,
    required int awaitingConfirmationSessionCount,
    required int scheduledFutureSessionCount,
  }) {
    if (completedMinutes < 0 ||
        awaitingConfirmationSessionCount < 0 ||
        scheduledFutureSessionCount < 0) {
      throw const DomainValidationException(
        'Placement completion evidence counts cannot be negative.',
      );
    }
    return PlacementCompletionEvidence._(
      completedMinutes: completedMinutes,
      allRequiredEvaluationsDocumented: allRequiredEvaluationsDocumented,
      awaitingConfirmationSessionCount: awaitingConfirmationSessionCount,
      scheduledFutureSessionCount: scheduledFutureSessionCount,
    );
  }

  const PlacementCompletionEvidence._({
    required this.completedMinutes,
    required this.allRequiredEvaluationsDocumented,
    required this.awaitingConfirmationSessionCount,
    required this.scheduledFutureSessionCount,
  });

  final int completedMinutes;
  final bool allRequiredEvaluationsDocumented;
  final int awaitingConfirmationSessionCount;
  final int scheduledFutureSessionCount;

  bool satisfies(TargetHours targetHours) =>
      completedMinutes >= targetHours.minutes &&
      allRequiredEvaluationsDocumented &&
      awaitingConfirmationSessionCount == 0 &&
      scheduledFutureSessionCount == 0;
}

/// References that prevent a Preceptor from being detached from a placement.
final class PreceptorReferenceSummary {
  factory PreceptorReferenceSummary({
    required int clinicalSessionCount,
    required int historicalHoursEntryCount,
    required int evaluationRecordCount,
  }) {
    if (clinicalSessionCount < 0 ||
        historicalHoursEntryCount < 0 ||
        evaluationRecordCount < 0) {
      throw const DomainValidationException(
        'Preceptor reference counts cannot be negative.',
      );
    }
    return PreceptorReferenceSummary._(
      clinicalSessionCount,
      historicalHoursEntryCount,
      evaluationRecordCount,
    );
  }

  const PreceptorReferenceSummary._(
    this.clinicalSessionCount,
    this.historicalHoursEntryCount,
    this.evaluationRecordCount,
  );

  final int clinicalSessionCount;
  final int historicalHoursEntryCount;
  final int evaluationRecordCount;

  bool get hasReferences =>
      clinicalSessionCount > 0 ||
      historicalHoursEntryCount > 0 ||
      evaluationRecordCount > 0;
}

/// Records that prevent permanent deletion of a Clinical Placement.
final class PlacementContentSummary {
  factory PlacementContentSummary({
    required int clinicalSessionCount,
    required int historicalHoursEntryCount,
    required int evaluationRecordCount,
  }) {
    if (clinicalSessionCount < 0 ||
        historicalHoursEntryCount < 0 ||
        evaluationRecordCount < 0) {
      throw const DomainValidationException(
        'Clinical Placement content counts cannot be negative.',
      );
    }
    return PlacementContentSummary._(
      clinicalSessionCount,
      historicalHoursEntryCount,
      evaluationRecordCount,
    );
  }

  const PlacementContentSummary._(
    this.clinicalSessionCount,
    this.historicalHoursEntryCount,
    this.evaluationRecordCount,
  );

  final int clinicalSessionCount;
  final int historicalHoursEntryCount;
  final int evaluationRecordCount;

  bool get isEmpty =>
      clinicalSessionCount == 0 &&
      historicalHoursEntryCount == 0 &&
      evaluationRecordCount == 0;
}
