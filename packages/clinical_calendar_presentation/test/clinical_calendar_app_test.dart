import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const studentId = '00000000-0000-4000-8000-000000000001';

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

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ClinicalCalendarApp(
      dependencies: _dependencies(),
      environmentName: 'test',
      studentId: studentId,
    ),
  );
  await tester.pumpAndSettle();
}

ApplicationDependencies _dependencies() => ApplicationDependencies(
  repositories: _Repositories(),
  clock: _Clock(),
  identifiers: _Identifiers(),
  synchronization: _Synchronization(),
  notifications: _Notifications(),
  secureStorage: _SecureStorage(),
  files: _Files(),
);

final class _Repositories implements RepositoryRegistry {
  final _ReadRepositories repositories = _ReadRepositories();

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
  final _EmptyReadRepository<WorkShift> _workShifts = _EmptyReadRepository();
  final _EmptyReadRepository<ClinicalSession> _clinicalSessions =
      _EmptyReadRepository();
  final _EmptyReadRepository<ProtectedDay> _protectedDays =
      _EmptyReadRepository();
  final _EmptyReadRepository<ScheduleTemplate> _scheduleTemplates =
      _EmptyReadRepository();
  final _EmptyReadRepository<Preceptor> _preceptors = _EmptyReadRepository();
  final _EmptyReadRepository<ClinicalPlacement> _clinicalPlacements =
      _EmptyReadRepository();
  final _EmptyReadRepository<HistoricalHoursEntry> _historicalHoursEntries =
      _EmptyReadRepository();
  final _EmptyReadRepository<EvaluationPlan> _evaluationPlans =
      _EmptyReadRepository();

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
  OutboxReadRepository get outbox => const _EmptyOutbox();

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
  }) => const [];
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
