import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

void main() {
  const engine = EvaluationPlanEngine();

  group('Evaluation Plan impact preview and edits', () {
    test('cadence edit previews impact and preserves documented history', () {
      var plan = _plan();
      final documentedIdentity = _interim(
        plan,
        90 * 60,
        EvaluationRequirementKind.interimStudentReviewsPrimaryPreceptor,
      ).identity;
      plan = _document(plan, documentedIdentity);

      final preview = engine.previewEdit(
        currentPlan: plan,
        proposedConfiguration: EvaluationPlanConfiguration(
          interimReviewCadenceMinutes: 60 * 60,
        ),
        proposedContext: _context(completedMinutes: 130 * 60),
        proposedPrimaryPreceptorId: 'primary-1',
      );
      final edited = engine.applyEdit(preview);

      expect(preview.description, isNotEmpty);
      expect(
        preview.preservedDocumentedRequirementIdentities,
        contains(documentedIdentity),
      );
      final historical = edited.requirements.singleWhere(
        (item) => item.identity == documentedIdentity,
      );
      expect(historical.isCurrentlyRequired, isFalse);
      expect(historical.isDocumented, isTrue);
      expect(
        edited.currentRequirements
            .where((item) => item.thresholdMinutes != null)
            .map((item) => item.thresholdMinutes),
        [
          60 * 60,
          60 * 60,
          120 * 60,
          120 * 60,
          180 * 60,
          180 * 60,
          240 * 60,
          240 * 60,
        ],
      );
    });

    test('newly introduced thresholds already passed are Due', () {
      final preview = engine.previewEdit(
        currentPlan: _plan(),
        proposedConfiguration: EvaluationPlanConfiguration(
          interimReviewCadenceMinutes: 60 * 60,
        ),
        proposedContext: _context(completedMinutes: 130 * 60),
        proposedPrimaryPreceptorId: 'primary-1',
      );
      final evaluation = engine.evaluate(
        engine.applyEdit(preview),
        _context(completedMinutes: 130 * 60),
      );

      expect(
        evaluation.requirements
            .where(
              (item) =>
                  item.requirement.thresholdMinutes == 60 * 60 ||
                  item.requirement.thresholdMinutes == 120 * 60,
            )
            .map((item) => item.state),
        everyElement(EvaluationRequirementState.due),
      );
    });

    test('toggle removal retains documented boundary record only', () {
      var plan = _plan();
      final initial = plan.currentRequirements.singleWhere(
        (item) =>
            item.identity.kind ==
            EvaluationRequirementKind.initialSelfAssessment,
      );
      plan = _document(plan, initial.identity);
      final preview = engine.previewEdit(
        currentPlan: plan,
        proposedConfiguration: EvaluationPlanConfiguration(
          initialSelfAssessmentRequired: false,
          finalSelfAssessmentRequired: false,
        ),
        proposedContext: _context(),
        proposedPrimaryPreceptorId: 'primary-1',
      );
      final edited = engine.applyEdit(preview);

      expect(
        edited.requirements
            .singleWhere((item) => item.identity == initial.identity)
            .isCurrentlyRequired,
        isFalse,
      );
      expect(
        edited.requirements.where(
          (item) =>
              item.identity.kind ==
              EvaluationRequirementKind.finalSelfAssessment,
        ),
        isEmpty,
      );
    });

    test(
      'Primary change preserves documented Preceptor and updates future parts',
      () {
        var plan = _plan();
        final documentedIdentity = _interim(
          plan,
          90 * 60,
          EvaluationRequirementKind.interimStudentReviewsPrimaryPreceptor,
        ).identity;
        plan = _document(plan, documentedIdentity);

        final edited = engine.applyEdit(
          engine.previewEdit(
            currentPlan: plan,
            proposedConfiguration: plan.configuration,
            proposedContext: _context(),
            proposedPrimaryPreceptorId: 'primary-2',
          ),
        );

        expect(
          edited.requirements
              .singleWhere((item) => item.identity == documentedIdentity)
              .primaryPreceptorId,
          'primary-1',
        );
        expect(
          edited.currentRequirements.where((item) => !item.isDocumented),
          everyElement(
            predicate<EvaluationRequirement>(
              (item) =>
                  item.thresholdMinutes == null ||
                  item.primaryPreceptorId == 'primary-2',
            ),
          ),
        );
      },
    );
  });

  group('Ready-to-Complete Evaluation gating', () {
    test(
      'requires every currently required item and ignores documented history',
      () {
        var plan = _plan(
          configuration: EvaluationPlanConfiguration(
            initialSelfAssessmentRequired: false,
            interimReviewCadenceMinutes: 1000 * 60,
            finalPlacementReviewRequired: false,
          ),
        );
        final finalIdentity = plan.currentRequirements.single.identity;
        expect(plan.allCurrentlyRequiredDocumented, isFalse);

        plan = _document(plan, finalIdentity);
        final removed = engine.applyEdit(
          engine.previewEdit(
            currentPlan: plan,
            proposedConfiguration: EvaluationPlanConfiguration(
              initialSelfAssessmentRequired: false,
              interimReviewCadenceMinutes: 1000 * 60,
              finalSelfAssessmentRequired: false,
              finalPlacementReviewRequired: false,
            ),
            proposedContext: _context(),
            proposedPrimaryPreceptorId: 'primary-1',
          ),
        );
        final evaluation = engine.evaluate(removed, _context());
        final evidence = PlacementCompletionEvidence(
          completedMinutes: 270 * 60,
          allRequiredEvaluationsDocumented:
              evaluation.allCurrentlyRequiredDocumented,
          awaitingConfirmationSessionCount: 0,
          scheduledFutureSessionCount: 0,
        );

        expect(removed.requirements.single.isCurrentlyRequired, isFalse);
        expect(evaluation.allCurrentlyRequiredDocumented, isTrue);
        expect(evidence.satisfies(TargetHours.fromWholeHours(270)), isTrue);
      },
    );
  });
}

EvaluationPlan _plan({EvaluationPlanConfiguration? configuration}) =>
    const EvaluationPlanEngine().create(
      evaluationPlanId: 'evaluation-plan-1',
      configuration: configuration ?? EvaluationPlanConfiguration(),
      context: _context(),
      primaryPreceptorId: 'primary-1',
    );

EvaluationPlanContext _context({int completedMinutes = 0}) =>
    EvaluationPlanContext(
      completedMinutes: completedMinutes,
      targetMinutes: 270 * 60,
      startDate: LocalDate(2026, 8, 1),
      completionDeadline: LocalDate(2026, 12, 1),
      today: LocalDate(2026, 8, 1),
    );

EvaluationRequirement _interim(
  EvaluationPlan plan,
  int threshold,
  EvaluationRequirementKind kind,
) => plan.currentRequirements.singleWhere(
  (item) => item.thresholdMinutes == threshold && item.identity.kind == kind,
);

EvaluationPlan _document(
  EvaluationPlan plan,
  EvaluationRequirementIdentity identity,
) => const EvaluationPlanEngine().documentRequirement(
  plan: plan,
  identity: identity,
  documentation: EvaluationDocumentation(dateDocumented: LocalDate(2026, 8, 1)),
  asOfDate: LocalDate(2026, 8, 1),
);
