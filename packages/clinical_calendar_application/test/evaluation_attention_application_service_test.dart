import 'package:clinical_calendar_application/src/evaluation_attention/evaluation_attention_application_service.dart';
import 'package:clinical_calendar_application/src/evaluation_attention/evaluation_attention_models.dart';
import 'package:clinical_calendar_application/src/placements/placement_models.dart';
import 'package:clinical_calendar_application/src/ports.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'derives every actionable attention family with exact destinations',
    () async {
      final placement = _placementSnapshot();
      final source = _AttentionSource(
        AttentionRepositorySnapshot(
          awaitingConfirmationSessions: [_awaitingSession()],
          protectedDates: const {},
          weekStartsOn: DateTime.sunday,
          pendingSynchronizationCount: 2,
          oldestPendingSynchronizationAtUtc: DateTime.utc(2026, 8, 1),
        ),
      );
      final service = EvaluationAttentionApplicationService(
        placements: _PlacementGateway(placement),
        attentionSource: source,
        clock: const _Clock(),
        studentId: _studentId,
      );

      final snapshot = await service.load(
        externalState: const AttentionExternalState(
          backup: BackupAttentionState.overdue,
          synchronization: SynchronizationAttentionState.conflict,
        ),
      );

      expect(
        snapshot.attentionItems.map((item) => item.kind).toSet(),
        containsAll(AttentionKind.values),
      );
      final confirmation = snapshot.attentionItems.singleWhere(
        (item) => item.kind == AttentionKind.confirmation,
      );
      expect(confirmation.clinicalSessionId, _sessionId);
      expect(
        confirmation.destination,
        AttentionDestination.confirmClinicalSession,
      );
      final evaluation = snapshot.attentionItems.firstWhere(
        (item) => item.kind == AttentionKind.evaluation,
      );
      expect(evaluation.clinicalPlacementId, _placementId);
      expect(evaluation.evaluationRequirementIdentity, isNotNull);
      expect(
        snapshot.attentionItems.where(
          (item) => item.kind == AttentionKind.protectedDayPlanning,
        ),
        hasLength(2),
      );
      expect(snapshot.attentionItems.first.urgency, AttentionUrgency.urgent);
    },
  );

  test(
    'configuration preview preserves placement fields and changes only plan',
    () async {
      final placement = _placementSnapshot();
      final gateway = _PlacementGateway(placement);
      final service = EvaluationAttentionApplicationService(
        placements: gateway,
        attentionSource: _AttentionSource(_emptyAttention()),
        clock: const _Clock(),
        studentId: _studentId,
      );
      final proposed = EvaluationPlanConfiguration(
        initialSelfAssessmentRequired: false,
        interimReviewCadenceMinutes: 60 * 60,
        finalSelfAssessmentRequired: true,
        finalPlacementReviewRequired: false,
      );

      await service.previewConfiguration(
        placement: placement,
        configuration: proposed,
      );

      expect(gateway.previewRequest!.name, placement.placement.name);
      expect(
        gateway.previewRequest!.targetHours,
        placement.placement.targetHours,
      );
      expect(gateway.previewRequest!.startDate, placement.placement.startDate);
      expect(
        gateway.previewRequest!.completionDeadline,
        placement.placement.completionDeadline,
      );
      expect(gateway.previewRequest!.evaluationPlanConfiguration, proposed);
    },
  );

  test(
    'documentation delegates identity, metadata, and optimistic revision',
    () async {
      final placement = _placementSnapshot();
      final gateway = _PlacementGateway(placement);
      final service = EvaluationAttentionApplicationService(
        placements: gateway,
        attentionSource: _AttentionSource(_emptyAttention()),
        clock: const _Clock(),
        studentId: _studentId,
      );
      final requirement = placement.evaluation.requirements.first.requirement;
      final documentation = EvaluationDocumentation(
        dateDocumented: LocalDate(2026, 8, 3),
        referenceOrNote: 'Recorded in school portal',
      );

      await service.documentRequirement(
        placement: placement,
        identity: requirement.identity,
        documentation: documentation,
      );

      expect(gateway.documentedIdentity, requirement.identity);
      expect(gateway.documentation!.location, 'Medatrax');
      expect(gateway.expectedRevision, placement.evaluationPlanRevision);
    },
  );
}

const _studentId = '00000000-0000-4000-8000-000000000001';
const _placementId = '00000000-0000-4000-8000-000000000002';
const _planId = '00000000-0000-4000-8000-000000000003';
const _preceptorId = '00000000-0000-4000-8000-000000000004';
const _sessionId = '00000000-0000-4000-8000-000000000005';

final class _Clock implements Clock {
  const _Clock();

  @override
  DateTime nowUtc() => DateTime.utc(2026, 8, 3, 16);
}

final class _AttentionSource implements AttentionRepositorySource {
  const _AttentionSource(this.snapshot);

  final AttentionRepositorySnapshot snapshot;

  @override
  Future<AttentionRepositorySnapshot> load({
    required String studentId,
    required DateTime nowUtc,
  }) async => snapshot;
}

final class _PlacementGateway implements EvaluationPlacementGateway {
  _PlacementGateway(this.snapshot);

  PlacementSnapshot snapshot;
  EditPlacementRequest? previewRequest;
  EvaluationRequirementIdentity? documentedIdentity;
  EvaluationDocumentation? documentation;
  int? expectedRevision;

  @override
  Future<PlacementSnapshot?> activePlacement() async => snapshot;

  @override
  Future<PlacementSnapshot> confirmEdit(
    PlacementEditImpactPreview preview,
  ) async => snapshot;

  @override
  Future<PlacementSnapshot> documentEvaluationRequirement({
    required String clinicalPlacementId,
    required EvaluationRequirementIdentity identity,
    required EvaluationDocumentation documentation,
    required int expectedEvaluationPlanRevision,
  }) async {
    documentedIdentity = identity;
    this.documentation = documentation;
    expectedRevision = expectedEvaluationPlanRevision;
    return snapshot;
  }

  @override
  Future<List<PlacementSnapshot>> placements() async => [snapshot];

  @override
  Future<PlacementEditImpactPreview> previewEdit({
    required String clinicalPlacementId,
    required EditPlacementRequest request,
  }) async {
    previewRequest = request;
    return PlacementEditImpactPreview.internal(
      clinicalPlacementId: clinicalPlacementId,
      expectedPlacementRevision: snapshot.placementRevision,
      expectedEvaluationPlanRevision: snapshot.evaluationPlanRevision,
      sourceRevisions: const {},
      outOfWindowClinicalSessionIds: const [],
      currentProgress: snapshot.progress,
      proposedProgress: snapshot.progress,
      evaluationPlanImpact: null,
      proposedPlacement: snapshot.placement,
      proposedEvaluationPlan: null,
    );
  }
}

PlacementSnapshot _placementSnapshot() {
  final placement = ClinicalPlacement.create(
    id: _placementId,
    name: 'Family Medicine',
    targetHours: TargetHours.fromWholeHours(180),
    startDate: LocalDate(2026, 7, 1),
    completionDeadline: LocalDate(2026, 8, 2),
    attachedPreceptorIds: const [_preceptorId],
    primaryPreceptorId: _preceptorId,
    evaluationPlanId: _planId,
  );
  final history = HistoricalHoursEntry(
    id: '00000000-0000-4000-8000-000000000006',
    clinicalPlacementId: _placementId,
    completedMinutes: 90 * 60,
    effectiveDate: LocalDate(2026, 8, 1),
    preceptorId: _preceptorId,
  );
  final progress = const ClinicalPlacementProgressEngine().derivePlacement(
    placement: placement,
    sessions: const [],
    historicalHoursEntries: [history],
    today: LocalDate(2026, 8, 3),
  );
  final configuration = EvaluationPlanConfiguration();
  final context = EvaluationPlanContext(
    completedMinutes: progress.completedMinutes,
    targetMinutes: progress.targetMinutes,
    startDate: placement.startDate,
    completionDeadline: placement.completionDeadline,
    today: LocalDate(2026, 8, 3),
  );
  final plan = const EvaluationPlanEngine().create(
    evaluationPlanId: _planId,
    configuration: configuration,
    context: context,
    primaryPreceptorId: _preceptorId,
  );
  return PlacementSnapshot(
    placement: placement,
    placementRevision: 1,
    evaluationPlanRevision: 2,
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
    scheduledFutureSessionCount: 0,
  );
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

AttentionRepositorySnapshot _emptyAttention() =>
    const AttentionRepositorySnapshot(
      awaitingConfirmationSessions: [],
      protectedDates: {},
      weekStartsOn: DateTime.sunday,
      pendingSynchronizationCount: 0,
      oldestPendingSynchronizationAtUtc: null,
    );
