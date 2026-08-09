import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/src/evaluation_attention/attention_surfaces.dart';
import 'package:clinical_calendar_presentation/src/evaluation_attention/evaluation_attention_controller.dart';
import 'package:clinical_calendar_presentation/src/evaluation_attention/evaluation_plan_surface.dart';
import 'package:clinical_calendar_presentation/src/graphite_theme.dart';
import 'package:clinical_calendar_presentation/src/graphite_instrument_scope.dart';
import 'package:clinical_calendar_presentation/src/theme_contract.dart';
import 'package:clinical_calendar_presentation/src/variant_f_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Graphite live Attention rail uses concept hierarchy', (
    tester,
  ) async {
    var openedAll = 0;
    final harness = _Harness(withEveryAttentionFamily: true);
    await harness.controller.load();
    await _pump(
      tester,
      GraphiteInstrumentScope(
        child: AttentionRail(
          controller: harness.controller,
          onOpenAction: (_) {},
          onOpenAll: () => openedAll++,
        ),
      ),
      const Size(380, 620),
      graphite: true,
    );

    expect(
      find.byKey(const Key('graphite-live-attention-rail')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('graphite-live-attention-item')), findsWidgets);
    expect(find.text('NEEDS ATTENTION'), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-attention-center-action')));
    expect(openedAll, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'checklist shows every state and documents with Medatrax default',
    (tester) async {
      final harness = _Harness();
      await harness.controller.load();
      final dueIdentity = harness.gateway.dueIdentity;
      final beforeCount = harness.controller.attentionItems.length;

      await _pump(
        tester,
        EvaluationPlanSurface(controller: harness.controller),
        const Size(390, 844),
      );

      for (final label in ['Not Due', 'Approaching', 'Due', 'Documented']) {
        expect(find.text(label), findsWidgets);
      }
      final dueRow = find.byKey(
        Key('evaluation-requirement-${dueIdentity.stableValue}'),
      );
      final documentAction = find.descendant(
        of: dueRow,
        matching: find.widgetWithText(OutlinedButton, 'Document evaluation'),
      );
      await tester.ensureVisible(documentAction);
      await tester.pumpAndSettle();
      await tester.tap(documentAction);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('evaluation-documentation-location')),
            )
            .controller!
            .text,
        'Medatrax',
      );
      expect(
        find.text('External record reference (no patient information)'),
        findsOneWidget,
      );
      tester
              .widget<TextField>(
                find.byKey(const Key('evaluation-documented-date')),
              )
              .controller!
              .text =
          '08-03-2026';
      await tester.enterText(
        find.byKey(const Key('evaluation-external-reference')),
        'Patient Jane Doe clinical note',
      );
      await tester.tap(
        find.byKey(const Key('save-evaluation-documentation-action')),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Do not enter patient information'),
        findsOneWidget,
      );
      expect(harness.gateway.lastDocumentation, isNull);
      await tester.enterText(
        find.byKey(const Key('evaluation-external-reference')),
        'MEDATRAX-2026-0042',
      );
      await tester.tap(
        find.byKey(const Key('save-evaluation-documentation-action')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(
            Key('evaluation-requirement-${dueIdentity.stableValue}'),
          ),
          matching: find.text('Documented'),
        ),
        findsOneWidget,
      );
      expect(harness.gateway.lastDocumentation!.location, 'Medatrax');
      expect(
        harness.gateway.lastDocumentation!.referenceOrNote,
        'MEDATRAX-2026-0042',
      );
      expect(harness.controller.attentionItems.length, beforeCount - 1);
      expect(
        harness.controller.attentionItems.any(
          (item) => item.evaluationRequirementIdentity == dueIdentity,
        ),
        isFalse,
      );
    },
  );

  testWidgets('configuration requires impact preview before save', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.controller.load();
    final finalPlacementIdentity = harness.gateway.finalPlacementIdentity;
    await _pump(
      tester,
      EvaluationPlanSurface(controller: harness.controller),
      const Size(768, 1024),
    );

    await tester.tap(find.byKey(const Key('final-placement-review-required')));
    await tester.tap(find.byKey(const Key('preview-evaluation-plan-action')));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Evaluation Plan changes'), findsOneWidget);
    expect(find.textContaining('removes 1 undocumented'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-evaluation-plan-action')));
    await tester.pumpAndSettle();

    expect(harness.gateway.configuration.finalPlacementReviewRequired, isFalse);
    expect(
      find.byKey(
        Key('evaluation-requirement-${finalPlacementIdentity.stableValue}'),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'attention actions expose exact workflow and fit phone viewports',
    (tester) async {
      final harness = _Harness(withEveryAttentionFamily: true);
      await harness.controller.load();
      AttentionItem? opened;
      for (final size in const [
        Size(320, 568),
        Size(390, 844),
        Size(932, 430),
      ]) {
        await _pump(
          tester,
          AttentionCenterSurface(
            controller: harness.controller,
            notificationMode: true,
            onOpenAction: (item) => opened = item,
          ),
          size,
        );
        expect(
          find.byKey(const Key('notification-center-surface')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: 'overflow at $size');
      }
      final first = harness.controller.attentionItems.first;
      await tester.tap(find.byKey(Key('attention-item-${first.id}')));
      await tester.pump();
      expect(opened, same(first));
      expect(
        harness.controller.attentionItems
            .map((item) => item.destination)
            .toSet(),
        containsAll([
          AttentionDestination.confirmClinicalSession,
          AttentionDestination.planProtectedDay,
          AttentionDestination.documentEvaluation,
          AttentionDestination.createPortableBackup,
          AttentionDestination.resolveSynchronization,
        ]),
      );
    },
  );

  testWidgets('Graphite attention renders its bundle-owned status marks', (
    tester,
  ) async {
    final harness = _Harness(withEveryAttentionFamily: true);
    await harness.controller.load();
    await _pump(
      tester,
      AttentionCenterSurface(
        controller: harness.controller,
        notificationMode: false,
        onOpenAction: (_) {},
      ),
      const Size(390, 844),
      graphite: true,
    );

    expect(find.byKey(const Key('theme-mark-scheduledProgress')), findsWidgets);
    expect(find.byKey(const Key('theme-mark-urgent')), findsWidgets);
  });

  testWidgets('Evaluation Plan surface fits compact phone landscapes', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.controller.load();
    for (final size in const [Size(320, 568), Size(844, 390), Size(932, 430)]) {
      await _pump(
        tester,
        EvaluationPlanSurface(controller: harness.controller),
        size,
      );
      expect(find.byKey(const Key('evaluation-plan-surface')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'overflow at $size');
    }
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child,
  Size size, {
  bool graphite = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ClinicalCalendarSemanticMarkScope(
      marks: graphite
          ? const GraphiteThemeBundle().marks
          : const VariantFThemeBundle().marks,
      child: MaterialApp(
        theme: graphite ? buildGraphiteTheme() : buildVariantFTheme(),
        home: Scaffold(body: SafeArea(child: child)),
      ),
    ),
  );
  await tester.pump();
}

final class _Harness {
  _Harness({bool withEveryAttentionFamily = false})
    : gateway = _Gateway(),
      source = _Source(withEveryAttentionFamily: withEveryAttentionFamily) {
    controller = EvaluationAttentionController(
      service: EvaluationAttentionApplicationService(
        placements: gateway,
        attentionSource: source,
        clock: const _Clock(),
        studentId: _studentId,
      ),
      externalState: withEveryAttentionFamily
          ? const AttentionExternalState(
              backup: BackupAttentionState.overdue,
              synchronization: SynchronizationAttentionState.conflict,
            )
          : const AttentionExternalState(
              backup: BackupAttentionState.current,
              synchronization: SynchronizationAttentionState.healthy,
            ),
    );
  }

  final _Gateway gateway;
  final _Source source;
  late final EvaluationAttentionController controller;
}

final class _Gateway implements EvaluationPlacementGateway {
  _Gateway() {
    placement = ClinicalPlacement.create(
      id: _placementId,
      name: 'Family Medicine',
      targetHours: TargetHours.fromWholeHours(270),
      startDate: LocalDate(2026, 7, 1),
      completionDeadline: LocalDate(2026, 12, 31),
      attachedPreceptorIds: const [_preceptorId],
      primaryPreceptorId: _preceptorId,
      evaluationPlanId: _planId,
    );
    configuration = EvaluationPlanConfiguration();
    context = EvaluationPlanContext(
      completedMinutes: 100 * 60,
      targetMinutes: 270 * 60,
      startDate: placement.startDate,
      completionDeadline: placement.completionDeadline,
      today: LocalDate(2026, 8, 3),
      futureScheduledSessionMinutes: const [85 * 60],
    );
    plan = const EvaluationPlanEngine().create(
      evaluationPlanId: _planId,
      configuration: configuration,
      context: context,
      primaryPreceptorId: _preceptorId,
    );
    final initial = plan.requirements.firstWhere(
      (requirement) =>
          requirement.identity.kind ==
          EvaluationRequirementKind.initialSelfAssessment,
    );
    plan = const EvaluationPlanEngine().documentRequirement(
      plan: plan,
      identity: initial.identity,
      documentation: EvaluationDocumentation(
        dateDocumented: LocalDate(2026, 7, 1),
      ),
      asOfDate: LocalDate(2026, 8, 3),
    );
  }

  late final ClinicalPlacement placement;
  late EvaluationPlanConfiguration configuration;
  late EvaluationPlanContext context;
  late EvaluationPlan plan;
  int revision = 1;
  EvaluationDocumentation? lastDocumentation;

  EvaluationRequirementIdentity get dueIdentity => plan.requirements
      .firstWhere(
        (requirement) =>
            requirement.identity.kind ==
                EvaluationRequirementKind
                    .interimStudentReviewsPrimaryPreceptor &&
            requirement.thresholdMinutes == 90 * 60,
      )
      .identity;

  EvaluationRequirementIdentity get finalPlacementIdentity => plan.requirements
      .firstWhere(
        (requirement) =>
            requirement.identity.kind ==
            EvaluationRequirementKind.finalPlacementReview,
      )
      .identity;

  PlacementSnapshot get snapshot {
    final history = HistoricalHoursEntry(
      id: _historyId,
      clinicalPlacementId: _placementId,
      completedMinutes: 100 * 60,
      effectiveDate: LocalDate(2026, 8, 1),
      preceptorId: _preceptorId,
    );
    final progress = const ClinicalPlacementProgressEngine().derivePlacement(
      placement: placement,
      sessions: const [],
      historicalHoursEntries: [history],
      today: LocalDate(2026, 8, 3),
    );
    return PlacementSnapshot(
      placement: placement,
      placementRevision: 1,
      evaluationPlanRevision: revision,
      evaluationPlanConfiguration: configuration,
      attachedPreceptors: [
        PlacementPreceptorSnapshot(
          preceptor: Preceptor(id: _preceptorId, name: 'Dr. Smith'),
          revision: 1,
          isPrimary: true,
        ),
      ],
      progress: progress,
      evaluation: const EvaluationPlanEngine().evaluate(plan, context),
      derivedState: ClinicalPlacementState.active,
      awaitingConfirmationSessionCount: 0,
      scheduledFutureSessionCount: 1,
    );
  }

  @override
  Future<PlacementSnapshot?> activePlacement() async => snapshot;

  @override
  Future<PlacementSnapshot> confirmEdit(
    PlacementEditImpactPreview preview,
  ) async {
    configuration = preview.proposedEvaluationPlan!.configuration;
    plan = preview.proposedEvaluationPlan!;
    revision++;
    return snapshot;
  }

  @override
  Future<PlacementSnapshot> documentEvaluationRequirement({
    required String clinicalPlacementId,
    required EvaluationRequirementIdentity identity,
    required EvaluationDocumentation documentation,
    required int expectedEvaluationPlanRevision,
  }) async {
    expect(expectedEvaluationPlanRevision, revision);
    lastDocumentation = documentation;
    plan = const EvaluationPlanEngine().documentRequirement(
      plan: plan,
      identity: identity,
      documentation: documentation,
      asOfDate: LocalDate(2026, 8, 3),
    );
    revision++;
    return snapshot;
  }

  @override
  Future<List<PlacementSnapshot>> placements() async => [snapshot];

  @override
  Future<PlacementEditImpactPreview> previewEdit({
    required String clinicalPlacementId,
    required EditPlacementRequest request,
  }) async {
    final impact = const EvaluationPlanEngine().previewEdit(
      currentPlan: plan,
      proposedConfiguration: request.evaluationPlanConfiguration,
      proposedContext: context,
      proposedPrimaryPreceptorId: _preceptorId,
    );
    return PlacementEditImpactPreview.internal(
      clinicalPlacementId: clinicalPlacementId,
      expectedPlacementRevision: 1,
      expectedEvaluationPlanRevision: revision,
      sourceRevisions: const {},
      outOfWindowClinicalSessionIds: const [],
      currentProgress: snapshot.progress,
      proposedProgress: snapshot.progress,
      evaluationPlanImpact: impact,
      proposedPlacement: placement,
      proposedEvaluationPlan: impact.proposedPlan,
    );
  }
}

final class _Source implements AttentionRepositorySource {
  _Source({required this.withEveryAttentionFamily});

  final bool withEveryAttentionFamily;

  @override
  Future<AttentionRepositorySnapshot> load({
    required String studentId,
    required DateTime nowUtc,
  }) async => AttentionRepositorySnapshot(
    awaitingConfirmationSessions: withEveryAttentionFamily
        ? [_awaitingSession()]
        : const [],
    protectedDates: withEveryAttentionFamily
        ? const {}
        : {LocalDate(2026, 8, 2), LocalDate(2026, 8, 9)},
    weekStartsOn: DateTime.sunday,
    pendingSynchronizationCount: withEveryAttentionFamily ? 2 : 0,
    oldestPendingSynchronizationAtUtc: withEveryAttentionFamily
        ? DateTime.utc(2026, 8, 1)
        : null,
  );
}

final class _Clock implements Clock {
  const _Clock();

  @override
  DateTime nowUtc() => DateTime.utc(2026, 8, 3, 16);
}

ClinicalSession _awaitingSession() => ClinicalSession.restore(
  id: _sessionId,
  clinicalPlacementId: _placementId,
  preceptorId: _preceptorId,
  plannedInterval: ZonedInterval(
    startDate: LocalDate(2026, 8, 2),
    startTime: LocalTime.parseMilitary('0800'),
    endTime: LocalTime.parseMilitary('1600'),
    timeZone: TimeZoneId('America/New_York'),
    startOffset: UtcOffset.inMinutes(-240),
    endOffset: UtcOffset.inMinutes(-240),
  ),
  state: ClinicalSessionState.awaitingConfirmation,
);

const _studentId = '00000000-0000-4000-8000-000000000001';
const _placementId = '00000000-0000-4000-8000-000000000002';
const _planId = '00000000-0000-4000-8000-000000000003';
const _preceptorId = '00000000-0000-4000-8000-000000000004';
const _sessionId = '00000000-0000-4000-8000-000000000005';
const _historyId = '00000000-0000-4000-8000-000000000006';
