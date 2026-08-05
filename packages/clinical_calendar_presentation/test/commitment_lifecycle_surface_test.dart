import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _studentId = '10000000-0000-4000-8000-000000000001';
const _placementId = '20000000-0000-4000-8000-000000000001';
const _primaryId = '30000000-0000-4000-8000-000000000001';
const _alternateId = '30000000-0000-4000-8000-000000000002';
const _pastSessionId = '40000000-0000-4000-8000-000000000001';
const _futureSessionId = '40000000-0000-4000-8000-000000000002';
const _workShiftId = '50000000-0000-4000-8000-000000000001';
const _protectedDayId = '60000000-0000-4000-8000-000000000001';

void main() {
  testWidgets(
    'elapsed Scheduled Session opens Awaiting and confirms corrected ledger',
    (tester) async {
      final harness = _Harness();
      await harness.controller.open(
        kind: CommitmentLifecycleKind.clinicalSession,
        id: _pastSessionId,
      );
      await _pump(tester, harness.surface(), const Size(768, 900));

      expect(find.text('Awaiting Confirmation'), findsOneWidget);
      expect(find.byKey(const Key('confirm-session-action')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('lifecycle-start-field')),
        '0817',
      );
      await tester.enterText(
        find.byKey(const Key('lifecycle-end-field')),
        '15:53',
      );
      await tester.tap(find.byKey(const Key('lifecycle-preceptor-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dr. Nguyen').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-session-action')));
      await tester.pumpAndSettle();

      final saved = harness.repositories.clinicalSessions
          .find(studentId: _studentId, id: _pastSessionId)!
          .value;
      expect(saved.state, ClinicalSessionState.completed);
      expect(saved.completedMinutes, 456);
      expect(saved.preceptorId, _alternateId);
      expect(find.text('Completed'), findsOneWidget);
      expect(harness.changed, 1);
    },
  );

  testWidgets('invalid move names Schedule Conflict and preserves original', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.controller.open(
      kind: CommitmentLifecycleKind.clinicalSession,
      id: _pastSessionId,
    );
    await _pump(tester, harness.surface(), const Size(768, 900));

    tester
            .widget<TextField>(find.byKey(const Key('lifecycle-date-field')))
            .controller!
            .text =
        '08-12-2026';
    await tester.enterText(
      find.byKey(const Key('lifecycle-start-field')),
      '1000',
    );
    await tester.enterText(
      find.byKey(const Key('lifecycle-end-field')),
      '1300',
    );
    await tester.tap(find.byKey(const Key('save-lifecycle-times-action')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Schedule Conflict on 08-12-2026'),
      findsOneWidget,
    );
    expect(
      find.textContaining('original entry was not changed'),
      findsOneWidget,
    );
    expect(
      harness.repositories.clinicalSessions
          .find(studentId: _studentId, id: _pastSessionId)!
          .value
          .plannedInterval
          .startDate,
      LocalDate(2026, 8, 8),
    );
    expect(harness.changed, 0);
  });

  testWidgets('Awaiting supports Missed and future Scheduled supports Cancel', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.controller.open(
      kind: CommitmentLifecycleKind.clinicalSession,
      id: _pastSessionId,
    );
    await _pump(tester, harness.surface(), const Size(640, 780));
    await tester.tap(find.byKey(const Key('missed-session-action')));
    await tester.pumpAndSettle();
    expect(
      harness.repositories.clinicalSessions
          .find(studentId: _studentId, id: _pastSessionId)!
          .value
          .state,
      ClinicalSessionState.missed,
    );

    await harness.controller.open(
      kind: CommitmentLifecycleKind.clinicalSession,
      id: _futureSessionId,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cancel-session-action')));
    await tester.pumpAndSettle();
    expect(
      harness.repositories.clinicalSessions
          .find(studentId: _studentId, id: _futureSessionId)!
          .value
          .state,
      ClinicalSessionState.cancelled,
    );
  });

  testWidgets('permanent delete explains erroneous semantics and confirms', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.controller.open(
      kind: CommitmentLifecycleKind.workShift,
      id: _workShiftId,
    );
    await _pump(tester, harness.surface(), const Size(640, 720));

    await tester.tap(find.byKey(const Key('delete-erroneous-entry-action')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('does not replace Cancel Session'),
      findsOneWidget,
    );
    expect(
      harness.repositories.workShifts.find(
        studentId: _studentId,
        id: _workShiftId,
      ),
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('confirm-permanent-delete-action')));
    await tester.pumpAndSettle();

    expect(
      harness.repositories.workShifts.find(
        studentId: _studentId,
        id: _workShiftId,
      ),
      isNull,
    );
    expect(harness.controller.snapshot, isNull);
  });

  testWidgets(
    'Protected Day rejects occupied move then removal recalculates planning',
    (tester) async {
      final harness = _Harness();
      await harness.controller.open(
        kind: CommitmentLifecycleKind.protectedDay,
        id: _protectedDayId,
      );
      final before = harness.controller.missingProtectedDayWeeks!;
      await _pump(tester, harness.surface(), const Size(640, 760));

      tester
              .widget<TextField>(find.byKey(const Key('lifecycle-date-field')))
              .controller!
              .text =
          '08-11-2026';
      await tester.tap(find.byKey(const Key('move-protected-day-action')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Protected Day on 08-11-2026'),
        findsOneWidget,
      );
      expect(
        harness.repositories.protectedDays
            .find(studentId: _studentId, id: _protectedDayId)!
            .value
            .date,
        LocalDate(2026, 8, 9),
      );

      tester
              .widget<TextField>(find.byKey(const Key('lifecycle-date-field')))
              .controller!
              .text =
          '08-13-2026';
      await tester.tap(find.byKey(const Key('move-protected-day-action')));
      await tester.pumpAndSettle();
      expect(
        harness.repositories.protectedDays
            .find(studentId: _studentId, id: _protectedDayId)!
            .value
            .date,
        LocalDate(2026, 8, 13),
      );
      await tester.tap(find.byKey(const Key('remove-protected-day-action')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Planning Incomplete'), findsWidgets);
      await tester.tap(
        find.byKey(const Key('confirm-remove-protected-day-action')),
      );
      await tester.pumpAndSettle();

      expect(
        harness.repositories.protectedDays.find(
          studentId: _studentId,
          id: _protectedDayId,
        ),
        isNull,
      );
      expect(harness.controller.missingProtectedDayWeeks, before + 1);
    },
  );

  testWidgets('lifecycle surface fits the required responsive matrix', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.controller.open(
      kind: CommitmentLifecycleKind.clinicalSession,
      id: _pastSessionId,
    );
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
      await _pump(tester, harness.surface(), size);
      expect(tester.takeException(), isNull, reason: 'overflow at $size');
      expect(
        find.byKey(const Key('commitment-lifecycle-surface')),
        findsOneWidget,
      );
    }
  });

  test('flexible times accept military and twelve-hour input', () {
    expect(parseFlexibleCommitmentTime('0817'), LocalTime(8, 17));
    expect(parseFlexibleCommitmentTime('8:17 AM'), LocalTime(8, 17));
    expect(parseFlexibleCommitmentTime('3:53 pm'), LocalTime(15, 53));
  });
}

Future<void> _pump(WidgetTester tester, Widget child, Size size) async {
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
  _Harness() {
    _seed();
    controller = CommitmentLifecycleController(
      service: SchedulingApplicationService(
        registry,
        const _Clock(),
        _Identifiers(),
      ),
      studentId: _studentId,
      onChanged: () => changed++,
    );
  }

  final _Repositories repositories = _Repositories();
  late final _Registry registry = _Registry(repositories);
  late final CommitmentLifecycleController controller;
  int changed = 0;

  Widget surface() => SizedBox.expand(
    child: CommitmentLifecycleSurface(
      controller: controller,
      studentId: _studentId,
    ),
  );

  void _seed() {
    repositories.preceptors
      ..seed(Preceptor(id: _primaryId, name: 'Dr. Smith'))
      ..seed(Preceptor(id: _alternateId, name: 'Dr. Nguyen'));
    repositories.clinicalPlacements.seed(
      ClinicalPlacement.create(
        id: _placementId,
        name: 'Family Medicine',
        targetHours: TargetHours.fromWholeHours(270),
        startDate: LocalDate(2026, 8, 1),
        completionDeadline: LocalDate(2026, 12, 31),
        attachedPreceptorIds: const [_primaryId, _alternateId],
        primaryPreceptorId: _primaryId,
        evaluationPlanId: '70000000-0000-4000-8000-000000000001',
      ),
    );
    repositories.clinicalSessions
      ..seed(
        ClinicalSession.restore(
          id: _pastSessionId,
          clinicalPlacementId: _placementId,
          preceptorId: _primaryId,
          plannedInterval: _interval(8, 8, 0, 16, 0),
          state: ClinicalSessionState.scheduled,
        ),
      )
      ..seed(
        ClinicalSession.restore(
          id: _futureSessionId,
          clinicalPlacementId: _placementId,
          preceptorId: _primaryId,
          plannedInterval: _interval(20, 8, 0, 16, 0),
          state: ClinicalSessionState.scheduled,
        ),
      );
    repositories.workShifts
      ..seed(
        WorkShift(
          id: _workShiftId,
          plannedInterval: _interval(12, 9, 0, 12, 0),
        ),
      )
      ..seed(
        WorkShift(
          id: '50000000-0000-4000-8000-000000000002',
          plannedInterval: _interval(11, 8, 0, 12, 0),
        ),
      );
    repositories.protectedDays.seed(
      ProtectedDay(id: _protectedDayId, date: LocalDate(2026, 8, 9)),
    );
  }
}

ZonedInterval _interval(
  int day,
  int startHour,
  int startMinute,
  int endHour,
  int endMinute,
) => ZonedInterval(
  startDate: LocalDate(2026, 8, day),
  startTime: LocalTime(startHour, startMinute),
  endTime: LocalTime(endHour, endMinute),
  timeZone: TimeZoneId('UTC'),
  startOffset: UtcOffset.utc,
  endOffset: UtcOffset.utc,
);

final class _Clock implements Clock {
  const _Clock();
  @override
  DateTime nowUtc() => DateTime.utc(2026, 8, 10, 12);
}

final class _Identifiers implements IdentifierGenerator {
  int _next = 1;
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
  }) {
    final record = records[id];
    return record != null && (includeDeleted || !record.isDeleted)
        ? record
        : null;
  }

  @override
  List<StoredDomainRecord<T>> list({
    required String studentId,
    bool includeDeleted = false,
  }) => records.values
      .where((record) => includeDeleted || !record.isDeleted)
      .toList(growable: false);

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
  }) {
    final current = records[id]!;
    final record = StoredDomainRecord<T>(
      value: current.value,
      studentId: studentId,
      revision: expectedRevision + 1,
      createdAtUtc: current.createdAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
      deletedAtUtc: mutation.occurredAtUtc,
    );
    records[id] = record;
    return MutationReceipt(record: record, replayed: false);
  }
}

final class _SelectionRepository implements ActivePlacementSelectionRepository {
  @override
  StoredDomainRecord<String?>? find({required String studentId}) => null;

  @override
  MutationReceipt<String?> put({
    required String studentId,
    required String? clinicalPlacementId,
    required int expectedRevision,
    required MutationToken mutation,
  }) => throw UnimplementedError();
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
