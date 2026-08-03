import '../domain_validation.dart';
import '../time/local_date.dart';
import 'evaluation_plan.dart';

/// Exact current placement facts used to derive Evaluation requirement state.
final class EvaluationPlanContext {
  factory EvaluationPlanContext({
    required int completedMinutes,
    required int targetMinutes,
    required LocalDate startDate,
    required LocalDate completionDeadline,
    required LocalDate today,
    Iterable<int> futureScheduledSessionMinutes = const <int>[],
  }) {
    if (completedMinutes < 0 || targetMinutes <= 0) {
      throw const DomainValidationException(
        'Evaluation Plan requires nonnegative Completed Hours and positive '
        'Target Hours.',
      );
    }
    if (completionDeadline.isBefore(startDate)) {
      throw const DomainValidationException(
        'Completion Deadline cannot be before Start Date.',
      );
    }
    final scheduledMinutes = futureScheduledSessionMinutes.toList(
      growable: false,
    );
    if (scheduledMinutes.any((minutes) => minutes <= 0)) {
      throw const DomainValidationException(
        'Future Scheduled Session minutes must be greater than zero.',
      );
    }
    return EvaluationPlanContext._(
      completedMinutes: completedMinutes,
      targetMinutes: targetMinutes,
      startDate: startDate,
      completionDeadline: completionDeadline,
      today: today,
      futureScheduledSessionMinutes: List.unmodifiable(scheduledMinutes),
    );
  }

  const EvaluationPlanContext._({
    required this.completedMinutes,
    required this.targetMinutes,
    required this.startDate,
    required this.completionDeadline,
    required this.today,
    required this.futureScheduledSessionMinutes,
  });

  final int completedMinutes;
  final int targetMinutes;
  final LocalDate startDate;
  final LocalDate completionDeadline;
  final LocalDate today;

  /// Ordered future Scheduled Sessions; the first is the next Session.
  final List<int> futureScheduledSessionMinutes;
}

final class EvaluatedEvaluationRequirement {
  const EvaluatedEvaluationRequirement(this.requirement, this.state);

  final EvaluationRequirement requirement;
  final EvaluationRequirementState state;
}

/// A deterministic snapshot suitable for checklist and completion gating.
final class EvaluationPlanEvaluation {
  const EvaluationPlanEvaluation._(this.requirements);

  final List<EvaluatedEvaluationRequirement> requirements;

  bool get allCurrentlyRequiredDocumented => requirements
      .where((item) => item.requirement.isCurrentlyRequired)
      .every((item) => item.state == EvaluationRequirementState.documented);
}

/// Explicit description that must exist before an Evaluation Plan edit applies.
final class EvaluationPlanEditPreview {
  const EvaluationPlanEditPreview._({
    required this.description,
    required this.addedRequirementIdentities,
    required this.removedUndocumentedRequirementIdentities,
    required this.preservedDocumentedRequirementIdentities,
    required this.proposedPlan,
  });

  final String description;
  final List<EvaluationRequirementIdentity> addedRequirementIdentities;
  final List<EvaluationRequirementIdentity>
  removedUndocumentedRequirementIdentities;
  final List<EvaluationRequirementIdentity>
  preservedDocumentedRequirementIdentities;
  final EvaluationPlan proposedPlan;
}

/// Pure Evaluation Plan generation, editing, documentation, and state engine.
final class EvaluationPlanEngine {
  const EvaluationPlanEngine();

  EvaluationPlan create({
    required String evaluationPlanId,
    required EvaluationPlanConfiguration configuration,
    required EvaluationPlanContext context,
    required String primaryPreceptorId,
  }) {
    final normalizedPlanId = requireIdentifier(
      evaluationPlanId,
      'Evaluation Plan id',
    );
    final normalizedPrimary = requireIdentifier(
      primaryPreceptorId,
      'Primary Preceptor id',
    );
    return EvaluationPlan.restore(
      id: normalizedPlanId,
      configuration: configuration,
      requirements: _generateCurrentRequirements(
        evaluationPlanId: normalizedPlanId,
        configuration: configuration,
        targetMinutes: context.targetMinutes,
        primaryPreceptorId: normalizedPrimary,
      ),
    );
  }

  EvaluationPlanEvaluation evaluate(
    EvaluationPlan plan,
    EvaluationPlanContext context,
  ) => EvaluationPlanEvaluation._(
    List.unmodifiable(
      plan.requirements.map(
        (requirement) => EvaluatedEvaluationRequirement(
          requirement,
          _stateFor(requirement, context),
        ),
      ),
    ),
  );

  EvaluationPlan documentRequirement({
    required EvaluationPlan plan,
    required EvaluationRequirementIdentity identity,
    required EvaluationDocumentation documentation,
    required LocalDate asOfDate,
  }) {
    var matched = false;
    final updated = plan.requirements
        .map((requirement) {
          if (requirement.identity != identity) return requirement;
          matched = true;
          return requirement.document(documentation, asOfDate: asOfDate);
        })
        .toList(growable: false);
    if (!matched) {
      throw const DomainValidationException(
        'Evaluation requirement does not belong to this Evaluation Plan.',
      );
    }
    return EvaluationPlan.restore(
      id: plan.id,
      configuration: plan.configuration,
      requirements: updated,
    );
  }

  EvaluationPlanEditPreview previewEdit({
    required EvaluationPlan currentPlan,
    required EvaluationPlanConfiguration proposedConfiguration,
    required EvaluationPlanContext proposedContext,
    required String proposedPrimaryPreceptorId,
  }) {
    final desired = _generateCurrentRequirements(
      evaluationPlanId: currentPlan.id,
      configuration: proposedConfiguration,
      targetMinutes: proposedContext.targetMinutes,
      primaryPreceptorId: requireIdentifier(
        proposedPrimaryPreceptorId,
        'Primary Preceptor id',
      ),
    );
    final desiredByIdentity = {
      for (final requirement in desired) requirement.identity: requirement,
    };
    final currentByIdentity = {
      for (final requirement in currentPlan.currentRequirements)
        requirement.identity: requirement,
    };
    final documentedByIdentity = {
      for (final requirement in currentPlan.requirements)
        if (requirement.isDocumented) requirement.identity: requirement,
    };

    final merged = <EvaluationRequirement>[];
    for (final desiredRequirement in desired) {
      final documented = documentedByIdentity[desiredRequirement.identity];
      merged.add(documented?.requireCurrently() ?? desiredRequirement);
    }
    for (final documented in documentedByIdentity.values) {
      if (!desiredByIdentity.containsKey(documented.identity)) {
        merged.add(documented.retainAsHistory());
      }
    }
    _sortRequirements(merged);

    final added = desiredByIdentity.keys
        .where((identity) => !currentByIdentity.containsKey(identity))
        .toList(growable: false);
    final removed = currentByIdentity.values
        .where(
          (requirement) =>
              !requirement.isDocumented &&
              !desiredByIdentity.containsKey(requirement.identity),
        )
        .map((requirement) => requirement.identity)
        .toList(growable: false);
    final preserved = documentedByIdentity.keys.toList(growable: false);
    final description =
        'This edit adds ${added.length} current requirement(s), removes '
        '${removed.length} undocumented requirement(s), and preserves '
        '${preserved.length} documented requirement(s) as history.';

    return EvaluationPlanEditPreview._(
      description: description,
      addedRequirementIdentities: List.unmodifiable(added),
      removedUndocumentedRequirementIdentities: List.unmodifiable(removed),
      preservedDocumentedRequirementIdentities: List.unmodifiable(preserved),
      proposedPlan: EvaluationPlan.restore(
        id: currentPlan.id,
        configuration: proposedConfiguration,
        requirements: merged,
      ),
    );
  }

  EvaluationPlan applyEdit(EvaluationPlanEditPreview preview) =>
      preview.proposedPlan;
}

List<EvaluationRequirement> _generateCurrentRequirements({
  required String evaluationPlanId,
  required EvaluationPlanConfiguration configuration,
  required int targetMinutes,
  required String primaryPreceptorId,
}) {
  final requirements = <EvaluationRequirement>[];
  if (configuration.initialSelfAssessmentRequired) {
    requirements.add(
      _requirement(
        evaluationPlanId,
        EvaluationRequirementKind.initialSelfAssessment,
      ),
    );
  }
  var threshold = configuration.interimReviewCadenceMinutes;
  while (threshold < targetMinutes) {
    requirements
      ..add(
        _requirement(
          evaluationPlanId,
          EvaluationRequirementKind.interimStudentReviewsPrimaryPreceptor,
          thresholdMinutes: threshold,
          primaryPreceptorId: primaryPreceptorId,
        ),
      )
      ..add(
        _requirement(
          evaluationPlanId,
          EvaluationRequirementKind.interimPrimaryPreceptorReviewsStudent,
          thresholdMinutes: threshold,
          primaryPreceptorId: primaryPreceptorId,
        ),
      );
    threshold += configuration.interimReviewCadenceMinutes;
  }
  if (configuration.finalSelfAssessmentRequired) {
    requirements.add(
      _requirement(
        evaluationPlanId,
        EvaluationRequirementKind.finalSelfAssessment,
      ),
    );
  }
  if (configuration.finalPlacementReviewRequired) {
    requirements.add(
      _requirement(
        evaluationPlanId,
        EvaluationRequirementKind.finalPlacementReview,
      ),
    );
  }
  _sortRequirements(requirements);
  return requirements;
}

EvaluationRequirement _requirement(
  String evaluationPlanId,
  EvaluationRequirementKind kind, {
  int? thresholdMinutes,
  String? primaryPreceptorId,
}) => EvaluationRequirement.restore(
  identity: EvaluationRequirementIdentity(
    evaluationPlanId: evaluationPlanId,
    kind: kind,
    thresholdMinutes: thresholdMinutes,
  ),
  isCurrentlyRequired: true,
  primaryPreceptorId: primaryPreceptorId,
);

EvaluationRequirementState _stateFor(
  EvaluationRequirement requirement,
  EvaluationPlanContext context,
) {
  if (requirement.isDocumented) return EvaluationRequirementState.documented;
  if (!requirement.isCurrentlyRequired) {
    throw const DomainValidationException(
      'Undocumented historical Evaluation requirements are invalid.',
    );
  }
  switch (requirement.identity.kind) {
    case EvaluationRequirementKind.initialSelfAssessment:
      if (!context.today.isBefore(context.startDate)) {
        return EvaluationRequirementState.due;
      }
      return !context.today.isBefore(context.startDate.addDays(-7))
          ? EvaluationRequirementState.approaching
          : EvaluationRequirementState.notDue;
    case EvaluationRequirementKind.interimStudentReviewsPrimaryPreceptor ||
        EvaluationRequirementKind.interimPrimaryPreceptorReviewsStudent:
      final threshold = requirement.thresholdMinutes!;
      if (context.completedMinutes >= threshold) {
        return EvaluationRequirementState.due;
      }
      final withinTenHours = threshold - context.completedMinutes <= 10 * 60;
      final nextScheduledCrosses =
          context.futureScheduledSessionMinutes.isNotEmpty &&
          context.completedMinutes +
                  context.futureScheduledSessionMinutes.first >=
              threshold;
      return withinTenHours || nextScheduledCrosses
          ? EvaluationRequirementState.approaching
          : EvaluationRequirementState.notDue;
    case EvaluationRequirementKind.finalSelfAssessment ||
        EvaluationRequirementKind.finalPlacementReview:
      final targetMet = context.completedMinutes >= context.targetMinutes;
      if (targetMet && context.futureScheduledSessionMinutes.isEmpty) {
        return EvaluationRequirementState.due;
      }
      final withinTenHours =
          context.targetMinutes - context.completedMinutes <= 10 * 60;
      final withinSevenDays = !context.today.isBefore(
        context.completionDeadline.addDays(-7),
      );
      return withinTenHours || withinSevenDays
          ? EvaluationRequirementState.approaching
          : EvaluationRequirementState.notDue;
  }
}

void _sortRequirements(List<EvaluationRequirement> requirements) {
  requirements.sort((left, right) {
    final leftThreshold =
        left.thresholdMinutes ?? _boundaryOrder(left.identity.kind);
    final rightThreshold =
        right.thresholdMinutes ?? _boundaryOrder(right.identity.kind);
    final thresholdComparison = leftThreshold.compareTo(rightThreshold);
    return thresholdComparison != 0
        ? thresholdComparison
        : left.identity.kind.index.compareTo(right.identity.kind.index);
  });
}

int _boundaryOrder(EvaluationRequirementKind kind) => switch (kind) {
  EvaluationRequirementKind.initialSelfAssessment => -1,
  EvaluationRequirementKind.finalSelfAssessment ||
  EvaluationRequirementKind.finalPlacementReview => 0x7fffffffffffffff,
  EvaluationRequirementKind.interimStudentReviewsPrimaryPreceptor ||
  EvaluationRequirementKind.interimPrimaryPreceptorReviewsStudent =>
    throw StateError('Interim Review order requires a threshold.'),
};
