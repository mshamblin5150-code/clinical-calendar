import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _studentId = '10000000-0000-4000-8000-000000000001';

void main() {
  testWidgets('dock, wheel, and durable selection stay synchronized', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.controller.load();
    await _pump(
      tester,
      Row(
        children: [
          SizedBox(
            width: 230,
            child: PlacementDock(
              controller: harness.controller,
              studentId: _studentId,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 270,
            child: PlacementProgressRail(
              controller: harness.controller,
              studentId: _studentId,
            ),
          ),
        ],
      ),
      size: const Size(560, 620),
    );

    expect(find.text('FAMILY MEDICINE'), findsOneWidget);
    expect(find.byKey(const Key('total-progress-segments')), findsOneWidget);
    expect(
      harness.controller.activePlacement!.placement.name,
      'Family Medicine',
    );

    await tester.tap(find.byKey(const Key('placement-progress-wheel')));
    await tester.pumpAndSettle();

    expect(harness.controller.activePlacement!.placement.name, 'Pediatrics');
    expect(
      harness.repositories.activePlacementSelection
          .find(studentId: _studentId)!
          .value,
      harness.controller.activePlacementId,
    );
    expect(find.text('PEDIATRICS'), findsOneWidget);
  });

  testWidgets('theme policy places progress wheel beside its metric ledger', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.controller.load();
    await _pump(
      tester,
      InsightRailPresentationPolicy(
        placementProgressLayout: PlacementProgressRailLayout.sideBySide,
        child: SizedBox(
          width: 420,
          child: PlacementProgressRail(
            controller: harness.controller,
            studentId: _studentId,
          ),
        ),
      ),
      size: const Size(460, 620),
    );

    final progressWheel = tester.getRect(
      find.byKey(const Key('placement-progress-wheel')),
    );
    final metricLedger = tester.getRect(
      find.byKey(const Key('placement-metric-ledger')),
    );
    expect(progressWheel.right, lessThan(metricLedger.left));
    expect(progressWheel.center.dy, closeTo(metricLedger.center.dy, 50));
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow placement dock wraps full Clinical Placement names', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.controller.load();
    await _pump(
      tester,
      SizedBox(
        width: 138,
        child: PlacementDock(
          controller: harness.controller,
          studentId: _studentId,
        ),
      ),
      size: const Size(138, 900),
    );

    final dock = find.byKey(const Key('placement-dock-surface'));
    for (final name in const ['Family Medicine', 'Pediatrics']) {
      final nameFinder = find.descendant(of: dock, matching: find.text(name));
      expect(nameFinder, findsOneWidget);
      final label = tester.widget<Text>(nameFinder);
      expect(
        label.overflow,
        isNot(TextOverflow.ellipsis),
        reason: '$name must continue onto another line instead of truncating.',
      );
      expect(
        label.maxLines,
        isNot(1),
        reason: '$name must have room to continue onto another line.',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('management list wraps full Clinical Placement names', (
    tester,
  ) async {
    final harness = _Harness(familyName: 'Acceptance Family Medicine');
    await harness.controller.load();
    await _pump(
      tester,
      PlacementManagementSurface(
        controller: harness.controller,
        studentId: _studentId,
      ),
      size: const Size(1056, 1691),
    );

    final choice = find.byKey(const Key('manage-placement-$_familyId'));
    final nameFinder = find.descendant(
      of: choice,
      matching: find.text('Acceptance Family Medicine'),
    );
    expect(nameFinder, findsOneWidget);
    final label = tester.widget<Text>(nameFinder);
    expect(label.overflow, isNot(TextOverflow.ellipsis));
    expect(label.maxLines, isNot(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'progress reconciles Preceptors, Unattributed, pace, and segments',
    (tester) async {
      final harness = _Harness();
      await harness.controller.load();
      await _pump(
        tester,
        SingleChildScrollView(
          child: PlacementMobileSummary(
            controller: harness.controller,
            studentId: _studentId,
          ),
        ),
        size: const Size(390, 844),
      );

      expect(find.text('270 hr'), findsOneWidget);
      expect(find.text('126 hr'), findsWidgets);
      expect(find.text('108 hr'), findsOneWidget);
      expect(find.text('36 hr'), findsOneWidget);
      expect(find.textContaining('Additional pace required'), findsOneWidget);
      for (var index = 0; index < 8; index++) {
        expect(
          find.byKey(Key('total-progress-segment-$index')),
          findsOneWidget,
        );
      }

      await tester.tap(find.byKey(const Key('toggle-preceptor-breakdown')));
      await tester.pump();
      expect(find.text('Dr. Smith'), findsOneWidget);
      expect(find.text('Dr. Nguyen'), findsOneWidget);
      expect(find.text('Unattributed Historical Hours'), findsOneWidget);
      expect(find.text('PRIMARY'), findsOneWidget);
    },
  );

  testWidgets('management previews blockers then confirms a valid edit', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.controller.load();
    await _pump(
      tester,
      PlacementManagementSurface(
        controller: harness.controller,
        studentId: _studentId,
      ),
      size: const Size(1024, 768),
    );

    tester
            .widget<TextField>(
              find.byKey(const Key('placement-deadline-field')),
            )
            .controller!
            .text =
        '08-15-2026';
    await tester.tap(find.byKey(const Key('preview-placement-edit-action')));
    await tester.pumpAndSettle();
    expect(find.text('SAVE BLOCKED'), findsOneWidget);
    expect(find.textContaining('fall outside'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('confirm-placement-edit-action')),
          )
          .onPressed,
      isNull,
    );

    tester
            .widget<TextField>(
              find.byKey(const Key('placement-deadline-field')),
            )
            .controller!
            .text =
        '12-31-2026';
    await tester.enterText(
      find.byKey(const Key('placement-target-field')),
      '300',
    );
    await tester.enterText(
      find.byKey(const Key('placement-name-field')),
      'Family Medicine Updated',
    );
    await tester.tap(find.byKey(const Key('preview-placement-edit-action')));
    await tester.pumpAndSettle();
    expect(find.text('IMPACT PREVIEW'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-placement-edit-action')));
    await tester.pumpAndSettle();
    expect(harness.controller.activePlacement!.progress.targetMinutes, 18000);
    expect(
      harness.controller.activePlacement!.placement.name,
      'Family Medicine Updated',
    );
    expect(harness.controller.editPreview, isNull);
  });

  testWidgets('management changes Primary and attaches a new Preceptor', (
    tester,
  ) async {
    final harness = _Harness();
    var openedEvaluations = false;
    await harness.controller.load();
    await _pump(
      tester,
      PlacementManagementSurface(
        controller: harness.controller,
        studentId: _studentId,
        onOpenEvaluations: () => openedEvaluations = true,
      ),
      size: const Size(1024, 768),
    );

    expect(find.widgetWithText(OutlinedButton, 'Set Primary'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Set Primary'));
    await tester.pumpAndSettle();
    expect(
      harness.controller.activePlacement!.placement.primaryPreceptorId,
      _nguyenId,
    );

    await tester.tap(find.byKey(const Key('add-preceptor-action')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('new-preceptor-name')),
      'Dr. Crusher',
    );
    await tester.tap(find.byKey(const Key('confirm-add-preceptor-action')));
    await tester.pumpAndSettle();
    expect(
      harness.controller.activePlacement!.attachedPreceptors,
      hasLength(3),
    );
    expect(
      harness.controller.activePlacement!.attachedPreceptors.map(
        (item) => item.preceptor.name,
      ),
      contains('Dr. Crusher'),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('placement-reviews-evaluations')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('REVIEWS & EVALUATIONS'), findsOneWidget);
    expect(
      find.text('No reviews are configured for this placement.'),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const Key('open-placement-evaluations')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-placement-evaluations')));
    expect(openedEvaluations, isTrue);
  });

  testWidgets(
    'Completed Placement locks fields and guarded Reopen restores them',
    (tester) async {
      final harness = _Harness(completed: true);
      await harness.controller.load();
      await _pump(
        tester,
        PlacementManagementSurface(
          controller: harness.controller,
          studentId: _studentId,
        ),
        size: const Size(768, 900),
      );

      expect(find.textContaining('ORDINARY EDITING LOCKED'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('placement-name-field')))
            .enabled,
        isFalse,
      );
      await tester.ensureVisible(
        find.byKey(const Key('reopen-placement-action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reopen-placement-action')));
      await tester.pumpAndSettle();
      expect(
        harness.controller.activePlacement!.placement.state,
        ClinicalPlacementState.active,
      );
      expect(find.byKey(const Key('reopen-placement-action')), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('placement-name-field')))
            .enabled,
        isTrue,
      );
    },
  );

  testWidgets('placement surfaces fit the required responsive matrix', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.controller.load();
    const sizes = [
      Size(320, 568),
      Size(390, 844),
      Size(844, 390),
      Size(768, 1024),
      Size(932, 430),
      Size(1024, 768),
      Size(1440, 900),
    ];
    for (final size in sizes) {
      await _pump(
        tester,
        PlacementManagementSurface(
          controller: harness.controller,
          studentId: _studentId,
        ),
        size: size,
      );
      expect(tester.takeException(), isNull, reason: 'overflow at $size');
      expect(
        find.byKey(const Key('placement-management-surface')),
        findsOneWidget,
      );
      final progressSurface = size.width >= 960 && size.height >= 600
          ? Row(
              children: [
                SizedBox(
                  width: 216,
                  child: PlacementDock(
                    controller: harness.controller,
                    studentId: _studentId,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 232,
                  child: PlacementProgressRail(
                    controller: harness.controller,
                    studentId: _studentId,
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: PlacementMobileSummary(
                controller: harness.controller,
                studentId: _studentId,
              ),
            );
      await _pump(tester, progressSurface, size: size);
      expect(
        tester.takeException(),
        isNull,
        reason: 'progress overflow at $size',
      );
    }
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required Size size,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildVariantFTheme(),
      home: Scaffold(body: SafeArea(child: child)),
    ),
  );
  await tester.pump();
}

final class _Harness {
  _Harness({bool completed = false, String familyName = 'Family Medicine'}) {
    _seed(completed: completed, familyName: familyName);
    controller = PlacementProgressController(
      service: PlacementApplicationService(
        repositories: registry,
        clock: const _Clock(),
        identifiers: _Identifiers(),
        studentId: _studentId,
      ),
      studentId: _studentId,
    );
  }

  final _Repositories repositories = _Repositories();
  late final _Registry registry = _Registry(repositories);
  late final PlacementProgressController controller;

  void _seed({required bool completed, required String familyName}) {
    final smith = Preceptor(id: _smithId, name: 'Dr. Smith');
    final nguyen = Preceptor(id: _nguyenId, name: 'Dr. Nguyen');
    repositories.preceptors
      ..seed(smith)
      ..seed(nguyen);
    final familyPlan = _plan(_familyPlanId, _smithId, 270 * 60);
    final pediatricsPlan = _plan(_pediatricsPlanId, _nguyenId, 90 * 60);
    repositories.evaluationPlans
      ..seed(familyPlan)
      ..seed(pediatricsPlan);
    repositories.clinicalPlacements
      ..seed(
        ClinicalPlacement.restore(
          id: _familyId,
          name: familyName,
          targetHours: TargetHours.fromWholeHours(270),
          startDate: LocalDate(2026, 8, 1),
          completionDeadline: LocalDate(2026, 12, 31),
          attachedPreceptorIds: const [_smithId, _nguyenId],
          primaryPreceptorId: _smithId,
          evaluationPlanId: _familyPlanId,
          state: completed
              ? ClinicalPlacementState.completed
              : ClinicalPlacementState.active,
        ),
      )
      ..seed(
        ClinicalPlacement.create(
          id: _pediatricsId,
          name: 'Pediatrics',
          targetHours: TargetHours.fromWholeHours(90),
          startDate: LocalDate(2026, 9, 1),
          completionDeadline: LocalDate(2027, 1, 31),
          attachedPreceptorIds: const [_nguyenId],
          primaryPreceptorId: _nguyenId,
          evaluationPlanId: _pediatricsPlanId,
        ),
      );
    repositories.historicalHoursEntries
      ..seed(
        HistoricalHoursEntry(
          id: _historySmithId,
          clinicalPlacementId: _familyId,
          completedMinutes: 90 * 60,
          effectiveDate: LocalDate(2026, 8, 2),
          preceptorId: _smithId,
        ),
      )
      ..seed(
        HistoricalHoursEntry(
          id: _historyUnattributedId,
          clinicalPlacementId: _familyId,
          completedMinutes: 36 * 60,
          effectiveDate: LocalDate(2026, 8, 3),
        ),
      );
    for (var index = 0; index < 9; index++) {
      final date = LocalDate(2026, 8, 20).addDays(index);
      repositories.clinicalSessions.seed(
        ClinicalSession.restore(
          id: '50000000-0000-4000-8000-${index.toString().padLeft(12, '0')}',
          clinicalPlacementId: _familyId,
          preceptorId: index.isEven ? _smithId : _nguyenId,
          plannedInterval: _interval(date),
          state: ClinicalSessionState.scheduled,
        ),
      );
    }
    repositories.activePlacementSelection.seed(_familyId);
  }
}

EvaluationPlan _plan(String id, String primary, int targetMinutes) {
  const engine = EvaluationPlanEngine();
  return engine.create(
    evaluationPlanId: id,
    configuration: EvaluationPlanConfiguration(
      initialSelfAssessmentRequired: false,
      interimReviewCadenceMinutes: targetMinutes + 60,
      finalSelfAssessmentRequired: false,
      finalPlacementReviewRequired: false,
    ),
    context: EvaluationPlanContext(
      completedMinutes: 0,
      targetMinutes: targetMinutes,
      startDate: LocalDate(2026, 8, 1),
      completionDeadline: LocalDate(2027, 1, 31),
      today: LocalDate(2026, 8, 10),
    ),
    primaryPreceptorId: primary,
  );
}

ZonedInterval _interval(LocalDate date) => ZonedInterval(
  startDate: date,
  startTime: LocalTime(7, 0),
  endTime: LocalTime(19, 0),
  timeZone: TimeZoneId('UTC'),
  startOffset: UtcOffset.utc,
  endOffset: UtcOffset.utc,
);

const _familyId = '30000000-0000-4000-8000-000000000001';
const _pediatricsId = '30000000-0000-4000-8000-000000000002';
const _smithId = '30000000-0000-4000-8000-000000000003';
const _nguyenId = '30000000-0000-4000-8000-000000000004';
const _familyPlanId = '30000000-0000-4000-8000-000000000005';
const _pediatricsPlanId = '30000000-0000-4000-8000-000000000006';
const _historySmithId = '30000000-0000-4000-8000-000000000007';
const _historyUnattributedId = '30000000-0000-4000-8000-000000000008';

final class _Clock implements Clock {
  const _Clock();
  @override
  DateTime nowUtc() => DateTime.utc(2026, 8, 10, 12);
}

final class _Identifiers implements IdentifierGenerator {
  int _next = 100;
  @override
  String nextIdentifier() =>
      '90000000-0000-4000-8000-${(_next++).toString().padLeft(12, '0')}';
}

final class _Registry implements RepositoryRegistry {
  const _Registry(this.repositories);
  final _Repositories repositories;

  @override
  Future<void> initialize() async {}

  @override
  Future<R> read<R>(
    R Function(LocalReadRepositories repositories) callback,
  ) async => callback(repositories);

  @override
  Future<R> mutate<R>(
    R Function(LocalWriteRepositories repositories) callback,
  ) async => callback(repositories);
}

final class _Repositories implements LocalWriteRepositories {
  _Repositories() {
    workShifts = _MemoryRepository((value) => value.id);
    clinicalSessions = _MemoryRepository((value) => value.id);
    protectedDays = _MemoryRepository((value) => value.id);
    scheduleTemplates = _MemoryRepository((value) => value.id);
    preceptors = _MemoryRepository((value) => value.id);
    clinicalPlacements = _MemoryRepository((value) => value.id);
    historicalHoursEntries = _MemoryRepository((value) => value.id);
    evaluationPlans = _MemoryRepository((value) => value.id);
    activePlacementSelection = _SelectionRepository();
  }

  @override
  late final _MemoryRepository<WorkShift> workShifts;
  @override
  late final _MemoryRepository<ClinicalSession> clinicalSessions;
  @override
  late final _MemoryRepository<ProtectedDay> protectedDays;
  @override
  late final _MemoryRepository<ScheduleTemplate> scheduleTemplates;
  @override
  late final _MemoryRepository<Preceptor> preceptors;
  @override
  late final _MemoryRepository<ClinicalPlacement> clinicalPlacements;
  @override
  late final _MemoryRepository<HistoricalHoursEntry> historicalHoursEntries;
  @override
  late final _MemoryRepository<EvaluationPlan> evaluationPlans;
  @override
  late final _SelectionRepository activePlacementSelection;
  @override
  final OutboxMaintenanceRepository outbox = _Outbox();
  @override
  final SyncCursorRepository syncCursors = _SyncCursors();
}

final class _MemoryRepository<T> implements MutableRepository<T> {
  _MemoryRepository(this.idOf);
  final String Function(T) idOf;
  final Map<String, StoredDomainRecord<T>> records = {};

  void seed(T value) {
    final now = DateTime.utc(2026, 8, 1);
    records[idOf(value)] = StoredDomainRecord(
      value: value,
      studentId: _studentId,
      revision: 1,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
  }

  @override
  StoredDomainRecord<T>? find({
    required String studentId,
    required String id,
    bool includeDeleted = false,
  }) => records[id];

  @override
  List<StoredDomainRecord<T>> list({
    required String studentId,
    bool includeDeleted = false,
  }) => records.values.toList(growable: false);

  @override
  MutationReceipt<T> put({
    required String studentId,
    required T value,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    final current = records[idOf(value)];
    if ((current?.revision ?? 0) != expectedRevision) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'revision mismatch',
      );
    }
    final record = StoredDomainRecord<T>(
      value: value,
      studentId: studentId,
      revision: expectedRevision + 1,
      createdAtUtc: current?.createdAtUtc ?? mutation.occurredAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
    );
    records[idOf(value)] = record;
    return MutationReceipt(record: record, replayed: false);
  }

  @override
  MutationReceipt<T> tombstone({
    required String studentId,
    required String id,
    required int expectedRevision,
    required MutationToken mutation,
  }) => throw UnimplementedError();
}

final class _SelectionRepository implements ActivePlacementSelectionRepository {
  StoredDomainRecord<String?>? record;

  void seed(String value) {
    final now = DateTime.utc(2026, 8, 1);
    record = StoredDomainRecord(
      value: value,
      studentId: _studentId,
      revision: 1,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
  }

  @override
  StoredDomainRecord<String?>? find({required String studentId}) => record;

  @override
  MutationReceipt<String?> put({
    required String studentId,
    required String? clinicalPlacementId,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    record = StoredDomainRecord(
      value: clinicalPlacementId,
      studentId: studentId,
      revision: expectedRevision + 1,
      createdAtUtc: record?.createdAtUtc ?? mutation.occurredAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
    );
    return MutationReceipt(record: record!, replayed: false);
  }
}

final class _Outbox implements OutboxMaintenanceRepository {
  @override
  void acknowledge({
    required String studentId,
    required String operationId,
    required int serverCursor,
    required DateTime acknowledgedAtUtc,
  }) {}
  @override
  List<OutboxOperation> pending({
    required String studentId,
    required DateTime asOfUtc,
    int limit = 100,
  }) => const [];
  @override
  void recordFailedAttempt({
    required String studentId,
    required String operationId,
    required DateTime attemptedAtUtc,
    required DateTime nextAttemptAtUtc,
    required String failureCode,
  }) {}
}

final class _SyncCursors implements SyncCursorRepository {
  @override
  SyncCursor? find({required String studentId, required String remoteScope}) =>
      null;
  @override
  void put(SyncCursor cursor) {}
}
