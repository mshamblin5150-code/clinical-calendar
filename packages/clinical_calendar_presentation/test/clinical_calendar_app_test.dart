import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const studentId = '00000000-0000-4000-8000-000000000001';
const _appSessionId = '40000000-0000-4000-8000-000000000001';

void main() {
  const requiredViewports = <Size>[
    Size(320, 568),
    Size(390, 844),
    Size(844, 390),
    Size(768, 1024),
    Size(932, 430),
    Size(1024, 768),
    Size(1440, 900),
  ];

  for (final viewport in requiredViewports) {
    testWidgets(
      'shell fits ${viewport.width.toInt()}x${viewport.height.toInt()}',
      (tester) async {
        await _pumpAt(tester, viewport);

        final desktop = viewport.width >= 960 && viewport.height >= 600;
        expect(
          find.byKey(Key(desktop ? 'command-bar' : 'compact-header')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('bottom-navigation')),
          desktop ? findsNothing : findsOneWidget,
        );
        expect(find.byKey(const Key('central-content')), findsOneWidget);
        expect(find.byType(CalendarPeriodView), findsOneWidget);
        expect(find.byKey(const Key('planning-region')), findsOneWidget);
        expect(
          find.byKey(const Key('placement-dock')),
          desktop ? findsOneWidget : findsNothing,
        );
        expect(
          find.byKey(const Key('insight-rail')),
          desktop ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(PlacementDock),
          desktop ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(PlacementMobileSummary),
          desktop ? findsNothing : findsOneWidget,
        );
        expect(
          find.byKey(const Key('attention-rail')),
          desktop ? findsOneWidget : findsNothing,
        );

        await tester.ensureVisible(
          find.byKey(const Key('primary-planning-action')),
        );
        await tester.pumpAndSettle();
        final actionRect = tester.getRect(
          find.byKey(const Key('primary-planning-action')),
        );
        expect(actionRect.left, greaterThanOrEqualTo(0));
        expect(actionRect.right, lessThanOrEqualTo(viewport.width));
        expect(actionRect.height, greaterThanOrEqualTo(44));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('mobile Settings exposes the complete application menu', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('application-menu')), findsOneWidget);
    for (final destination in applicationMenuDestinations) {
      expect(
        find.descendant(
          of: find.byKey(const Key('application-menu')),
          matching: find.text(destination.label),
        ),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu entry uses Back and returns to the application menu', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1024, 768));

    await tester.tap(find.byKey(const Key('desktop-menu-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('back-action')), findsOneWidget);
    expect(find.byKey(const Key('close-action')), findsNothing);
    expect(
      find.byKey(const Key('notification-center-surface')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('back-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('application-menu')), findsOneWidget);
  });

  testWidgets('direct Help entry uses Close', (tester) async {
    await _pumpAt(tester, const Size(1024, 768));

    await tester.tap(find.byKey(const Key('desktop-help-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('close-action')), findsOneWidget);
    expect(find.byKey(const Key('back-action')), findsNothing);
    expect(find.text('WORKFLOW GUIDE'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('VARIANT F CALENDAR STATES'),
      500,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('support-help-surface')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('VARIANT F CALENDAR STATES'), findsOneWidget);
  });

  testWidgets('profile avatar is a 44 pixel direct Student Profile entry', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1024, 768));

    final avatar = find.byKey(const Key('student-profile-avatar-action'));
    expect(avatar, findsOneWidget);
    expect(tester.getSize(avatar), const Size(44, 44));

    await tester.tap(avatar);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('student-profile-surface')), findsOneWidget);
    expect(find.byKey(const Key('close-action')), findsOneWidget);
  });

  testWidgets('menu routes Clinical Placements to its management surface', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1024, 768));

    await tester.tap(find.byKey(const Key('desktop-menu-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clinical Placements'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('placement-management-surface')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('back-action')), findsOneWidget);
  });

  testWidgets('menu routes Settings to the settings and templates surface', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1024, 768));

    await tester.tap(find.byKey(const Key('desktop-menu-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-templates-surface')), findsOneWidget);
    expect(find.byKey(const Key('back-action')), findsOneWidget);
  });

  testWidgets('calendar selection feeds staged tray and both reset seams', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));

    await tester.tap(
      find.byKey(const Key('calendar-day-2026-01-02')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('selected-date-count')));
    expect(find.text('1 selected date'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('planning-incomplete-action')),
    );
    await tester.tap(find.byKey(const Key('planning-incomplete-action')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('batch-type-protectedDay')))
          .selected,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('primary-planning-action')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const Key('batch-type-clinicalSession')),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('calendar item opens contextual lifecycle surface', (
    tester,
  ) async {
    final repositories = _Repositories(seedLifecycle: true);
    await _pumpAt(
      tester,
      const Size(1024, 768),
      dependencies: _dependencies(repositories: repositories),
    );

    await tester.tap(find.byKey(Key('compact-clinicalSession-$_appSessionId')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('commitment-lifecycle-surface')),
      findsOneWidget,
    );
    expect(find.text('CLINICAL SESSION DETAILS'), findsOneWidget);
    expect(find.textContaining('Family Medicine'), findsWidgets);
  });

  testWidgets(
    'Planning Incomplete attention preserves its date and resets the tray',
    (tester) async {
      await _pumpAt(tester, const Size(390, 844));

      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('notification-center-surface')),
        findsOneWidget,
      );
      final center = tester.widget<AttentionCenterSurface>(
        find.byType(AttentionCenterSurface),
      );
      expect(
        center.controller.error,
        isNull,
        reason: '${center.controller.error}',
      );

      await tester.tap(find.text('Planning Incomplete'));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarPeriodView), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('selected-date-count')));
      expect(find.text('1 selected date'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const Key('batch-type-protectedDay')),
            )
            .selected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('evaluation attention opens its selected contextual plan route', (
    tester,
  ) async {
    final repositories = _Repositories(seedLifecycle: true);
    await _pumpAt(
      tester,
      const Size(1024, 768),
      dependencies: _dependencies(repositories: repositories),
    );

    await tester.tap(find.byKey(const Key('desktop-menu-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    final center = tester.widget<AttentionCenterSurface>(
      find.byType(AttentionCenterSurface),
    );
    expect(
      center.controller.error,
      isNull,
      reason: '${center.controller.error}',
    );
    final evaluationAttention = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
            'attention-item-evaluation:',
          ),
    );
    expect(evaluationAttention, findsWidgets);
    await tester.tap(evaluationAttention.first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('contextual-route-surface')), findsOneWidget);
    expect(find.byKey(const Key('evaluation-plan-surface')), findsOneWidget);
    expect(find.text('Evaluation Plan'), findsWidgets);
    expect(find.text('Family Medicine'), findsWidgets);
    expect(find.byKey(const Key('contextual-back-action')), findsOneWidget);

    await tester.tap(find.byKey(const Key('contextual-back-action')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('notification-center-surface')),
      findsOneWidget,
    );
  });

  testWidgets('synchronization attention exposes an honest Sync Now route', (
    tester,
  ) async {
    final repositories = _Repositories(seedSynchronization: true);
    await _pumpAt(
      tester,
      const Size(390, 844),
      dependencies: _dependencies(repositories: repositories),
    );

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Synchronization needs attention'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('contextual-route-surface')), findsOneWidget);
    expect(
      find.byKey(const Key('synchronization-attention-surface')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('sync-now-action')));
    await tester.pumpAndSettle();
    expect(
      find.text('Synchronization is offline. Local changes remain queued.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('contextual-back-action')), findsOneWidget);
  });

  test('theme Help registry supplies a safe unknown-theme fallback', () {
    final guide = ThemeHelpGuideRegistry.standard().resolve('future-theme');

    expect(guide, isA<GenericThemeHelpGuide>());
    expect(guide.themeId, 'future-theme');
    expect(guide.calendarStates, isNotEmpty);
  });

  testWidgets('Variant F exposes semantic colors and shallow metrics', (
    tester,
  ) async {
    late ClinicalCalendarColors colors;
    late ClinicalCalendarMetrics metrics;
    await tester.pumpWidget(
      MaterialApp(
        theme: const VariantFVisualTheme().createThemeData(),
        home: Builder(
          builder: (context) {
            colors = context.clinicalColors;
            metrics = context.clinicalMetrics;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(colors.clinical, VariantFColors.primary);
    expect(colors.work, VariantFColors.work);
    expect(colors.protectedDay, VariantFColors.protectedDay);
    expect(colors.scheduled, VariantFColors.scheduled);
    expect(colors.urgent, VariantFColors.urgent);
    expect(metrics.cornerRadius, lessThanOrEqualTo(4));
    expect(metrics.minimumTouchTarget, 44);
  });
}

Future<void> _pumpAt(
  WidgetTester tester,
  Size size, {
  ApplicationDependencies? dependencies,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ClinicalCalendarApp(
      dependencies: dependencies ?? _dependencies(),
      environmentName: 'test',
      studentId: studentId,
    ),
  );
  await tester.pumpAndSettle();
}

ApplicationDependencies _dependencies({_Repositories? repositories}) =>
    ApplicationDependencies(
      repositories: repositories ?? _Repositories(),
      clock: _Clock(),
      identifiers: _Identifiers(),
      synchronization: _Synchronization(),
      notifications: _Notifications(),
      secureStorage: _SecureStorage(),
      files: _Files(),
    );

final class _Repositories implements RepositoryRegistry {
  _Repositories({bool seedLifecycle = false, bool seedSynchronization = false})
    : repositories = _ReadRepositories(
        seedLifecycle: seedLifecycle,
        seedSynchronization: seedSynchronization,
      );

  final _ReadRepositories repositories;

  @override
  Future<void> initialize() async {}

  @override
  Future<R> read<R>(
    R Function(LocalReadRepositories repositories) callback,
  ) async => callback(repositories);

  @override
  Future<R> mutate<R>(
    R Function(LocalWriteRepositories repositories) callback,
  ) async => throw UnimplementedError();
}

final class _ReadRepositories implements SupportLocalReadRepositories {
  _ReadRepositories({
    required bool seedLifecycle,
    required bool seedSynchronization,
  }) : _workShifts = _EmptyReadRepository(),
       _clinicalSessions = seedLifecycle
           ? _StaticReadRepository([_sessionRecord()], (value) => value.id)
           : _EmptyReadRepository(),
       _protectedDays = _EmptyReadRepository(),
       _scheduleTemplates = _EmptyReadRepository(),
       _preceptors = seedLifecycle
           ? _StaticReadRepository([_preceptorRecord()], (value) => value.id)
           : _EmptyReadRepository(),
       _clinicalPlacements = seedLifecycle
           ? _StaticReadRepository([_placementRecord()], (value) => value.id)
           : _EmptyReadRepository(),
       _evaluationPlans = seedLifecycle
           ? _StaticReadRepository([
               _evaluationPlanRecord(),
             ], (value) => value.id)
           : _EmptyReadRepository(),
       _outbox = seedSynchronization ? _PendingOutbox() : const _EmptyOutbox();

  final ReadRepository<WorkShift> _workShifts;
  final ReadRepository<ClinicalSession> _clinicalSessions;
  final ReadRepository<ProtectedDay> _protectedDays;
  final ReadRepository<ScheduleTemplate> _scheduleTemplates;
  final ReadRepository<Preceptor> _preceptors;
  final ReadRepository<ClinicalPlacement> _clinicalPlacements;
  final OutboxReadRepository _outbox;
  final _EmptyReadRepository<HistoricalHoursEntry> _historicalHoursEntries =
      _EmptyReadRepository();
  final ReadRepository<EvaluationPlan> _evaluationPlans;

  @override
  ReadRepository<WorkShift> get workShifts => _workShifts;

  @override
  ReadRepository<ClinicalSession> get clinicalSessions => _clinicalSessions;

  @override
  ReadRepository<ProtectedDay> get protectedDays => _protectedDays;

  @override
  ReadRepository<ScheduleTemplate> get scheduleTemplates => _scheduleTemplates;

  @override
  ReadRepository<Preceptor> get preceptors => _preceptors;

  @override
  ReadRepository<ClinicalPlacement> get clinicalPlacements =>
      _clinicalPlacements;

  @override
  ReadRepository<HistoricalHoursEntry> get historicalHoursEntries =>
      _historicalHoursEntries;

  @override
  ReadRepository<EvaluationPlan> get evaluationPlans => _evaluationPlans;

  @override
  OutboxReadRepository get outbox => _outbox;

  @override
  SyncCursorReadRepository get syncCursors => const _EmptySyncCursors();

  @override
  ActivePlacementSelectionReadRepository get activePlacementSelection =>
      const _EmptyActivePlacement();

  @override
  StudentProfileReadRepository get studentProfile => const _ProfileRead();

  @override
  StudentSettingsReadRepository get studentSettings => const _SettingsRead();
}

final class _EmptyReadRepository<T> implements ReadRepository<T> {
  @override
  StoredDomainRecord<T>? find({
    required String studentId,
    required String id,
    bool includeDeleted = false,
  }) => null;

  @override
  List<StoredDomainRecord<T>> list({
    required String studentId,
    bool includeDeleted = false,
  }) => <StoredDomainRecord<T>>[];
}

final class _StaticReadRepository<T> implements ReadRepository<T> {
  _StaticReadRepository(Iterable<StoredDomainRecord<T>> records, this.idOf)
    : records = List.unmodifiable(records);

  final List<StoredDomainRecord<T>> records;
  final String Function(T value) idOf;

  @override
  StoredDomainRecord<T>? find({
    required String studentId,
    required String id,
    bool includeDeleted = false,
  }) {
    for (final record in records) {
      if (record.studentId == studentId && idOf(record.value) == id) {
        return record;
      }
    }
    return null;
  }

  @override
  List<StoredDomainRecord<T>> list({
    required String studentId,
    bool includeDeleted = false,
  }) => records
      .where((record) => record.studentId == studentId)
      .toList(growable: false);
}

StoredDomainRecord<ClinicalSession> _sessionRecord() => StoredDomainRecord(
  value: ClinicalSession.schedule(
    id: _appSessionId,
    clinicalPlacementId: '20000000-0000-4000-8000-000000000001',
    preceptorId: '30000000-0000-4000-8000-000000000001',
    plannedInterval: ZonedInterval(
      startDate: LocalDate(2026, 1, 1),
      startTime: LocalTime(13, 0),
      endTime: LocalTime(16, 0),
      timeZone: TimeZoneId('UTC'),
      startOffset: UtcOffset.utc,
      endOffset: UtcOffset.utc,
    ),
    asOfUtc: DateTime.utc(2026, 1, 1, 12),
  ),
  studentId: studentId,
  revision: 1,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

StoredDomainRecord<ClinicalPlacement> _placementRecord() => StoredDomainRecord(
  value: ClinicalPlacement.create(
    id: '20000000-0000-4000-8000-000000000001',
    name: 'Family Medicine',
    targetHours: TargetHours.fromWholeHours(270),
    startDate: LocalDate(2026, 1, 1),
    completionDeadline: LocalDate(2026, 12, 31),
    attachedPreceptorIds: const ['30000000-0000-4000-8000-000000000001'],
    primaryPreceptorId: '30000000-0000-4000-8000-000000000001',
    evaluationPlanId: '70000000-0000-4000-8000-000000000001',
  ),
  studentId: studentId,
  revision: 1,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

StoredDomainRecord<EvaluationPlan> _evaluationPlanRecord() {
  final plan = const EvaluationPlanEngine().create(
    evaluationPlanId: '70000000-0000-4000-8000-000000000001',
    configuration: EvaluationPlanConfiguration(),
    context: EvaluationPlanContext(
      completedMinutes: 0,
      targetMinutes: 270 * 60,
      startDate: LocalDate(2026, 1, 1),
      completionDeadline: LocalDate(2026, 12, 31),
      today: LocalDate(2026, 1, 1),
      futureScheduledSessionMinutes: const [3 * 60],
    ),
    primaryPreceptorId: '30000000-0000-4000-8000-000000000001',
  );
  return StoredDomainRecord(
    value: plan,
    studentId: studentId,
    revision: 1,
    createdAtUtc: DateTime.utc(2026),
    updatedAtUtc: DateTime.utc(2026),
  );
}

StoredDomainRecord<Preceptor> _preceptorRecord() => StoredDomainRecord(
  value: Preceptor(
    id: '30000000-0000-4000-8000-000000000001',
    name: 'Dr. Rivera',
  ),
  studentId: studentId,
  revision: 1,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

final class _ProfileRead implements StudentProfileReadRepository {
  const _ProfileRead();

  @override
  StoredDomainRecord<StudentProfile>? find({required String studentId}) =>
      StoredDomainRecord(
        value: StudentProfile(id: studentId, displayName: 'Test Student'),
        studentId: studentId,
        revision: 0,
        createdAtUtc: DateTime.utc(2026),
        updatedAtUtc: DateTime.utc(2026),
      );
}

final class _SettingsRead implements StudentSettingsReadRepository {
  const _SettingsRead();

  @override
  StoredDomainRecord<StudentSettings>? find({required String studentId}) =>
      null;
}

final class _EmptyActivePlacement
    implements ActivePlacementSelectionReadRepository {
  const _EmptyActivePlacement();

  @override
  StoredDomainRecord<String?>? find({required String studentId}) => null;
}

final class _EmptyOutbox implements OutboxReadRepository {
  const _EmptyOutbox();

  @override
  List<OutboxOperation> pending({
    required String studentId,
    required DateTime asOfUtc,
    int limit = 100,
  }) => <OutboxOperation>[];
}

final class _PendingOutbox implements OutboxReadRepository {
  @override
  List<OutboxOperation> pending({
    required String studentId,
    required DateTime asOfUtc,
    int limit = 100,
  }) => [
    OutboxOperation(
      mutation: MutationToken(
        operationId: '80000000-0000-4000-8000-000000000001',
        idempotencyKey: '80000000-0000-4000-8000-000000000002',
        occurredAtUtc: DateTime.utc(2025, 12, 30),
      ),
      studentId: studentId,
      entityType: 'work_shift',
      entityId: '80000000-0000-4000-8000-000000000003',
      type: OutboxOperationType.upsert,
      baseRevision: 0,
      payloadJson: '{}',
    ),
  ];
}

final class _EmptySyncCursors implements SyncCursorReadRepository {
  const _EmptySyncCursors();

  @override
  SyncCursor? find({required String studentId, required String remoteScope}) =>
      null;
}

final class _Clock implements Clock {
  @override
  DateTime nowUtc() => DateTime.utc(2026);
}

final class _Identifiers implements IdentifierGenerator {
  @override
  String nextIdentifier() => 'test';
}

final class _Synchronization implements SynchronizationService {
  @override
  Future<SynchronizationResult> synchronize() async =>
      const SynchronizationResult(SynchronizationDisposition.offline);
}

final class _Notifications implements NotificationService {
  @override
  Future<void> reconcileScheduledNotifications() async {}
}

final class _SecureStorage implements SecureStorage {
  @override
  Future<void> delete(String key) async {}

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}
}

final class _Files implements FileService {
  @override
  Future<List<int>> read(Uri location) async => [];

  @override
  Future<void> write(Uri location, List<int> bytes) async {}
}
