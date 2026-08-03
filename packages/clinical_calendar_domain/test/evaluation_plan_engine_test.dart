import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

void main() {
  const engine = EvaluationPlanEngine();

  group('Evaluation Plan configuration and generation', () {
    test('defaults all boundary requirements and 90-hour cadence', () {
      final configuration = EvaluationPlanConfiguration();
      final plan = engine.create(
        evaluationPlanId: 'evaluation-plan-1',
        configuration: configuration,
        context: _context(targetMinutes: 270 * 60),
        primaryPreceptorId: 'primary-1',
      );

      expect(
        configuration.interimReviewCadenceMinutes,
        EvaluationPlanConfiguration.defaultInterimReviewCadenceMinutes,
      );
      expect(
        plan.currentRequirements.map((item) => item.identity.kind),
        containsAll([
          EvaluationRequirementKind.initialSelfAssessment,
          EvaluationRequirementKind.finalSelfAssessment,
          EvaluationRequirementKind.finalPlacementReview,
        ]),
      );
    });

    test('rejects a nonpositive Interim Review cadence', () {
      expect(
        () => EvaluationPlanConfiguration(interimReviewCadenceMinutes: 0),
        throwsA(isA<DomainValidationException>()),
      );
    });

    test('respects boundary toggles', () {
      final plan = engine.create(
        evaluationPlanId: 'evaluation-plan-1',
        configuration: EvaluationPlanConfiguration(
          initialSelfAssessmentRequired: false,
          finalSelfAssessmentRequired: false,
          finalPlacementReviewRequired: false,
        ),
        context: _context(targetMinutes: 100 * 60),
        primaryPreceptorId: 'primary-1',
      );

      expect(
        plan.currentRequirements,
        everyElement(
          predicate<EvaluationRequirement>(
            (item) => item.thresholdMinutes != null,
          ),
        ),
      );
    });

    test(
      'generates exactly two parts at cadence multiples strictly below target',
      () {
        final plan = _plan(targetMinutes: 270 * 60);
        final interim = plan.currentRequirements
            .where((item) => item.thresholdMinutes != null)
            .toList();

        expect(interim.map((item) => item.thresholdMinutes), [
          90 * 60,
          90 * 60,
          180 * 60,
          180 * 60,
        ]);
        expect(
          interim.where((item) => item.thresholdMinutes == 270 * 60),
          isEmpty,
        );
        for (final threshold in [90 * 60, 180 * 60]) {
          expect(
            interim
                .where((item) => item.thresholdMinutes == threshold)
                .map((item) => item.identity.kind),
            containsAll([
              EvaluationRequirementKind.interimStudentReviewsPrimaryPreceptor,
              EvaluationRequirementKind.interimPrimaryPreceptorReviewsStudent,
            ]),
          );
        }
      },
    );
  });

  group('deterministic requirement state', () {
    test('Initial is Approaching for seven days and Due on Start Date', () {
      final requirement = _ofKind(
        _plan(),
        EvaluationRequirementKind.initialSelfAssessment,
      );

      expect(
        _state(requirement, _context(today: LocalDate(2026, 8, 23))),
        EvaluationRequirementState.notDue,
      );
      expect(
        _state(requirement, _context(today: LocalDate(2026, 8, 24))),
        EvaluationRequirementState.approaching,
      );
      expect(
        _state(requirement, _context(today: LocalDate(2026, 8, 31))),
        EvaluationRequirementState.due,
      );
    });

    test('Interim uses exact ten-hour boundary and next Session crossing', () {
      final requirement = _interimAt(_plan(), 90 * 60);

      expect(
        _state(requirement, _context(completedMinutes: 80 * 60 - 1)),
        EvaluationRequirementState.notDue,
      );
      expect(
        _state(requirement, _context(completedMinutes: 80 * 60)),
        EvaluationRequirementState.approaching,
      );
      expect(
        _state(
          requirement,
          _context(
            completedMinutes: 70 * 60,
            futureScheduledSessionMinutes: [20 * 60],
          ),
        ),
        EvaluationRequirementState.approaching,
      );
      expect(
        _state(requirement, _context(completedMinutes: 90 * 60)),
        EvaluationRequirementState.due,
      );
    });

    test(
      'finals approach by hours or deadline but require target and no future Sessions',
      () {
        final requirement = _ofKind(
          _plan(),
          EvaluationRequirementKind.finalSelfAssessment,
        );

        expect(
          _state(requirement, _context(completedMinutes: 260 * 60)),
          EvaluationRequirementState.approaching,
        );
        expect(
          _state(requirement, _context(today: LocalDate(2026, 9, 23))),
          EvaluationRequirementState.approaching,
        );
        expect(
          _state(
            requirement,
            _context(
              completedMinutes: 270 * 60,
              futureScheduledSessionMinutes: [60],
            ),
          ),
          EvaluationRequirementState.approaching,
        );
        expect(
          _state(requirement, _context(completedMinutes: 270 * 60)),
          EvaluationRequirementState.due,
        );
      },
    );

    test('an overdue deadline without target does not make finals Due', () {
      final requirement = _ofKind(
        _plan(),
        EvaluationRequirementKind.finalPlacementReview,
      );

      expect(
        _state(
          requirement,
          _context(completedMinutes: 100 * 60, today: LocalDate(2026, 10, 1)),
        ),
        EvaluationRequirementState.approaching,
      );
    });
  });

  group('documentation', () {
    test('defaults to Medatrax and validates date, location, and note', () {
      final plan = _plan();
      final identity = _interimAt(plan, 90 * 60).identity;
      final documented = engine.documentRequirement(
        plan: plan,
        identity: identity,
        documentation: EvaluationDocumentation(
          dateDocumented: LocalDate(2026, 8, 15),
          referenceOrNote: 'Confirmation 42',
        ),
        asOfDate: LocalDate(2026, 8, 15),
      );
      final record = documented.requirements.singleWhere(
        (item) => item.identity == identity,
      );

      expect(record.documentation!.location, 'Medatrax');
      expect(record.documentation!.referenceOrNote, 'Confirmation 42');
      expect(
        () => engine.documentRequirement(
          plan: plan,
          identity: identity,
          documentation: EvaluationDocumentation(
            dateDocumented: LocalDate(2026, 8, 16),
          ),
          asOfDate: LocalDate(2026, 8, 15),
        ),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () => EvaluationDocumentation(
          dateDocumented: LocalDate(2026, 8, 15),
          location: ' ',
        ),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () => EvaluationDocumentation(
          dateDocumented: LocalDate(2026, 8, 15),
          location: 'Medatrax\u0000',
        ),
        throwsA(isA<DomainValidationException>()),
      );
    });

    test('an undocumented requirement cannot become historical', () {
      final requirement = _ofKind(
        _plan(),
        EvaluationRequirementKind.initialSelfAssessment,
      );

      expect(
        requirement.retainAsHistory,
        throwsA(isA<DomainValidationException>()),
      );
    });

    test('early documentation always wins after corrected hours', () {
      final original = _plan();
      final requirement = _interimAt(original, 90 * 60);
      final documented = engine.documentRequirement(
        plan: original,
        identity: requirement.identity,
        documentation: EvaluationDocumentation(
          dateDocumented: LocalDate(2026, 8, 15),
        ),
        asOfDate: LocalDate(2026, 8, 15),
      );
      final corrected = documented.requirements.singleWhere(
        (item) => item.identity == requirement.identity,
      );

      expect(
        _state(corrected, _context(completedMinutes: 20 * 60)),
        EvaluationRequirementState.documented,
      );
    });
  });
}

EvaluationPlan _plan({int targetMinutes = 270 * 60}) =>
    const EvaluationPlanEngine().create(
      evaluationPlanId: 'evaluation-plan-1',
      configuration: EvaluationPlanConfiguration(),
      context: _context(targetMinutes: targetMinutes),
      primaryPreceptorId: 'primary-1',
    );

EvaluationPlanContext _context({
  int completedMinutes = 0,
  int targetMinutes = 270 * 60,
  LocalDate? today,
  List<int> futureScheduledSessionMinutes = const [],
}) => EvaluationPlanContext(
  completedMinutes: completedMinutes,
  targetMinutes: targetMinutes,
  startDate: LocalDate(2026, 8, 31),
  completionDeadline: LocalDate(2026, 9, 30),
  today: today ?? LocalDate(2026, 8, 1),
  futureScheduledSessionMinutes: futureScheduledSessionMinutes,
);

EvaluationRequirement _ofKind(
  EvaluationPlan plan,
  EvaluationRequirementKind kind,
) => plan.currentRequirements.singleWhere((item) => item.identity.kind == kind);

EvaluationRequirement _interimAt(EvaluationPlan plan, int thresholdMinutes) =>
    plan.currentRequirements.firstWhere(
      (item) => item.thresholdMinutes == thresholdMinutes,
    );

EvaluationRequirementState _state(
  EvaluationRequirement requirement,
  EvaluationPlanContext context,
) => const EvaluationPlanEngine()
    .evaluate(
      EvaluationPlan.restore(
        id: requirement.identity.evaluationPlanId,
        configuration: EvaluationPlanConfiguration(),
        requirements: [requirement],
      ),
      context,
    )
    .requirements
    .single
    .state;
