import '../domain_validation.dart';
import '../time/local_date.dart';

/// The configurable Evaluation Plan attached to one Clinical Placement.
final class EvaluationPlanConfiguration {
  factory EvaluationPlanConfiguration({
    bool initialSelfAssessmentRequired = true,
    int interimReviewCadenceMinutes = defaultInterimReviewCadenceMinutes,
    bool finalSelfAssessmentRequired = true,
    bool finalPlacementReviewRequired = true,
  }) {
    if (interimReviewCadenceMinutes <= 0) {
      throw const DomainValidationException(
        'Interim Review cadence must be greater than zero.',
      );
    }
    return EvaluationPlanConfiguration._(
      initialSelfAssessmentRequired: initialSelfAssessmentRequired,
      interimReviewCadenceMinutes: interimReviewCadenceMinutes,
      finalSelfAssessmentRequired: finalSelfAssessmentRequired,
      finalPlacementReviewRequired: finalPlacementReviewRequired,
    );
  }

  const EvaluationPlanConfiguration._({
    required this.initialSelfAssessmentRequired,
    required this.interimReviewCadenceMinutes,
    required this.finalSelfAssessmentRequired,
    required this.finalPlacementReviewRequired,
  });

  static const int defaultInterimReviewCadenceMinutes = 90 * 60;

  final bool initialSelfAssessmentRequired;
  final int interimReviewCadenceMinutes;
  final bool finalSelfAssessmentRequired;
  final bool finalPlacementReviewRequired;

  @override
  bool operator ==(Object other) =>
      other is EvaluationPlanConfiguration &&
      initialSelfAssessmentRequired == other.initialSelfAssessmentRequired &&
      interimReviewCadenceMinutes == other.interimReviewCadenceMinutes &&
      finalSelfAssessmentRequired == other.finalSelfAssessmentRequired &&
      finalPlacementReviewRequired == other.finalPlacementReviewRequired;

  @override
  int get hashCode => Object.hash(
    initialSelfAssessmentRequired,
    interimReviewCadenceMinutes,
    finalSelfAssessmentRequired,
    finalPlacementReviewRequired,
  );
}

enum EvaluationRequirementKind {
  initialSelfAssessment,
  interimStudentReviewsPrimaryPreceptor,
  interimPrimaryPreceptorReviewsStudent,
  finalSelfAssessment,
  finalPlacementReview,
}

enum EvaluationRequirementState { notDue, approaching, due, documented }

/// Semantic identity that remains stable across plan and Primary edits.
///
/// The Primary Preceptor is intentionally not part of an Interim identity:
/// it is historical detail on the requirement itself.
final class EvaluationRequirementIdentity {
  factory EvaluationRequirementIdentity({
    required String evaluationPlanId,
    required EvaluationRequirementKind kind,
    int? thresholdMinutes,
  }) {
    final isInterim = _isInterimKind(kind);
    if (isInterim != (thresholdMinutes != null) ||
        (thresholdMinutes != null && thresholdMinutes <= 0)) {
      throw const DomainValidationException(
        'Only Interim Review identities require a positive threshold.',
      );
    }
    return EvaluationRequirementIdentity._(
      requireIdentifier(evaluationPlanId, 'Evaluation Plan id'),
      kind,
      thresholdMinutes,
    );
  }

  const EvaluationRequirementIdentity._(
    this.evaluationPlanId,
    this.kind,
    this.thresholdMinutes,
  );

  final String evaluationPlanId;
  final EvaluationRequirementKind kind;
  final int? thresholdMinutes;

  String get stableValue {
    final threshold = thresholdMinutes;
    return threshold == null
        ? '$evaluationPlanId:${kind.name}'
        : '$evaluationPlanId:${kind.name}:$threshold';
  }

  @override
  bool operator ==(Object other) =>
      other is EvaluationRequirementIdentity &&
      evaluationPlanId == other.evaluationPlanId &&
      kind == other.kind &&
      thresholdMinutes == other.thresholdMinutes;

  @override
  int get hashCode => Object.hash(evaluationPlanId, kind, thresholdMinutes);

  @override
  String toString() => stableValue;
}

/// Evidence that an Evaluation Plan requirement was documented elsewhere.
final class EvaluationDocumentation {
  factory EvaluationDocumentation({
    required LocalDate dateDocumented,
    String location = defaultLocation,
    String? referenceOrNote,
  }) {
    final normalizedLocation = location.trim();
    if (normalizedLocation.isEmpty || normalizedLocation.length > 160) {
      throw const DomainValidationException(
        'Evaluation documentation location must contain between 1 and 160 '
        'characters.',
      );
    }
    if (normalizedLocation.codeUnits.any(
      (unit) => unit < 0x20 || unit == 0x7f,
    )) {
      throw const DomainValidationException(
        'Evaluation documentation location contains control characters.',
      );
    }
    final normalizedNote = _normalizeOptionalText(
      referenceOrNote,
      'Evaluation documentation reference or note',
      1000,
    );
    return EvaluationDocumentation._(
      dateDocumented,
      normalizedLocation,
      normalizedNote,
    );
  }

  const EvaluationDocumentation._(
    this.dateDocumented,
    this.location,
    this.referenceOrNote,
  );

  static const String defaultLocation = 'Medatrax';

  final LocalDate dateDocumented;
  final String location;
  final String? referenceOrNote;
}

/// A generated requirement or a preserved documented historical record.
final class EvaluationRequirement {
  factory EvaluationRequirement.restore({
    required EvaluationRequirementIdentity identity,
    required bool isCurrentlyRequired,
    String? primaryPreceptorId,
    EvaluationDocumentation? documentation,
  }) {
    final interim = _isInterimKind(identity.kind);
    final normalizedPreceptorId = primaryPreceptorId == null
        ? null
        : requireIdentifier(primaryPreceptorId, 'Primary Preceptor id');
    if (interim != (normalizedPreceptorId != null)) {
      throw const DomainValidationException(
        'Interim Review requirements require a Primary Preceptor.',
      );
    }
    if (!isCurrentlyRequired && documentation == null) {
      throw const DomainValidationException(
        'Only documented requirements may be retained as history.',
      );
    }
    return EvaluationRequirement._(
      identity: identity,
      isCurrentlyRequired: isCurrentlyRequired,
      primaryPreceptorId: normalizedPreceptorId,
      documentation: documentation,
    );
  }

  const EvaluationRequirement._({
    required this.identity,
    required this.isCurrentlyRequired,
    required this.primaryPreceptorId,
    required this.documentation,
  });

  final EvaluationRequirementIdentity identity;
  final bool isCurrentlyRequired;
  final String? primaryPreceptorId;
  final EvaluationDocumentation? documentation;

  int? get thresholdMinutes => identity.thresholdMinutes;
  bool get isDocumented => documentation != null;

  EvaluationRequirement document(
    EvaluationDocumentation evidence, {
    required LocalDate asOfDate,
  }) {
    if (evidence.dateDocumented.isAfter(asOfDate)) {
      throw const DomainValidationException(
        'Evaluation documentation date cannot be in the future.',
      );
    }
    return EvaluationRequirement._(
      identity: identity,
      isCurrentlyRequired: isCurrentlyRequired,
      primaryPreceptorId: primaryPreceptorId,
      documentation: evidence,
    );
  }

  EvaluationRequirement retainAsHistory() {
    if (!isDocumented) {
      throw const DomainValidationException(
        'Only documented Evaluation requirements may be retained as history.',
      );
    }
    return EvaluationRequirement._(
      identity: identity,
      isCurrentlyRequired: false,
      primaryPreceptorId: primaryPreceptorId,
      documentation: documentation,
    );
  }

  EvaluationRequirement requireCurrently() => EvaluationRequirement._(
    identity: identity,
    isCurrentlyRequired: true,
    primaryPreceptorId: primaryPreceptorId,
    documentation: documentation,
  );
}

/// Stored Evaluation Plan configuration and requirement history.
final class EvaluationPlan {
  factory EvaluationPlan.restore({
    required String id,
    required EvaluationPlanConfiguration configuration,
    required Iterable<EvaluationRequirement> requirements,
  }) {
    final normalizedId = requireIdentifier(id, 'Evaluation Plan id');
    final requirementList = requirements.toList(growable: false);
    final identities = <EvaluationRequirementIdentity>{};
    for (final requirement in requirementList) {
      if (requirement.identity.evaluationPlanId != normalizedId) {
        throw const DomainValidationException(
          'Evaluation requirement belongs to a different Evaluation Plan.',
        );
      }
      if (!identities.add(requirement.identity)) {
        throw const DomainValidationException(
          'Evaluation requirement identities must be unique.',
        );
      }
    }
    return EvaluationPlan._(
      normalizedId,
      configuration,
      List.unmodifiable(requirementList),
    );
  }

  const EvaluationPlan._(this.id, this.configuration, this.requirements);

  final String id;
  final EvaluationPlanConfiguration configuration;
  final List<EvaluationRequirement> requirements;

  Iterable<EvaluationRequirement> get currentRequirements =>
      requirements.where((requirement) => requirement.isCurrentlyRequired);

  bool get allCurrentlyRequiredDocumented =>
      currentRequirements.every((requirement) => requirement.isDocumented);
}

bool _isInterimKind(EvaluationRequirementKind kind) =>
    kind == EvaluationRequirementKind.interimStudentReviewsPrimaryPreceptor ||
    kind == EvaluationRequirementKind.interimPrimaryPreceptorReviewsStudent;

String? _normalizeOptionalText(String? value, String fieldName, int maxLength) {
  if (value == null) return null;
  final normalized = value.trim();
  if (normalized.isEmpty) return null;
  if (normalized.length > maxLength) {
    throw DomainValidationException(
      '$fieldName cannot exceed $maxLength characters.',
    );
  }
  if (normalized.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)) {
    throw DomainValidationException('$fieldName contains control characters.');
  }
  return normalized;
}
