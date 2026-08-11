import 'dart:io';
import 'dart:ui' as ui;

import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:clinical_calendar_presentation/src/canonical_delta_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'support/keyboard_focus.dart';
import 'support/proof_fonts.dart';
import 'support/placement_progress_harness.dart';

const _studentId = '00000000-0000-4000-8000-000000000128';
final _today = LocalDate(2026, 8, 6);

void main() {
  setUpAll(prepareProofEnvironment);

  testWidgets('Graphite landscape is the approved precision instrument', (
    tester,
  ) async {
    var addAssignmentInvocations = 0;
    await _pumpProof(
      tester,
      const Size(1536, 1024),
      onAddAssignment: () => addAssignmentInvocations++,
    );

    expect(find.byKey(const Key('graphite-landscape-rails')), findsOneWidget);
    expect(find.byKey(const Key('calendar-today-label')), findsOneWidget);
    final placementHousing = find.byKey(
      const Key('graphite-placement-housing'),
    );
    expect(placementHousing, findsOneWidget);
    expect(
      find.descendant(
        of: placementHousing,
        matching: find.byType(GraphiteNineSliceFrame),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: placementHousing,
        matching: find.byKey(const Key('graphite-live-placement-card')),
      ),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const Key('graphite-live-attention-rail')),
      findsOneWidget,
    );

    final planningBay = tester.getRect(
      find.byKey(const Key('graphite-planning-bay')),
    );
    final endField = tester.getRect(
      find.byKey(const Key('graphite-planning-field-END')),
    );
    expect(
      planningBay.right - endField.right,
      greaterThanOrEqualTo(48),
      reason: 'The END field must clear the planning bay chrome.',
    );

    expect(find.bySemanticsLabel('Open menu'), findsOneWidget);
    expect(
      find.byKey(const Key('graphite-assignment-control-housing')),
      findsOneWidget,
    );

    await expectLater(
      find.byKey(const Key('graphite-proof')),
      matchesGoldenFile('goldens/graphite/graphite_landscape_1536x1024.png'),
    );
    await tester.tap(find.byKey(const Key('add-academic-assignment')));
    expect(addAssignmentInvocations, 1);
  });

  testWidgets(
    'Graphite expanded Preceptors remain clipped above Needs Attention',
    (tester) async {
      await _pumpProof(tester, const Size(1536, 1024));
      final placementHousing = find.byKey(
        const Key('graphite-placement-progress-housing'),
      );
      final attentionHousing = find.byKey(
        const Key('graphite-attention-housing'),
      );
      final collapsedPlacement = tester.getRect(placementHousing);
      final collapsedAttention = tester.getRect(attentionHousing);

      await tester.tap(find.byKey(const Key('toggle-preceptor-breakdown')));
      await tester.pumpAndSettle();

      expect(find.byType(PreceptorProgressBreakdown), findsOneWidget);
      expect(tester.getRect(placementHousing), collapsedPlacement);
      expect(tester.getRect(attentionHousing), collapsedAttention);
      expect(collapsedPlacement.bottom, lessThan(collapsedAttention.top));
      expect(
        find.descendant(
          of: placementHousing,
          matching: find.byKey(const Key('graphite-placement-progress-clip')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: attentionHousing,
          matching: find.byKey(const Key('graphite-attention-clip')),
        ),
        findsOneWidget,
      );
      await tester.drag(
        find
            .descendant(of: placementHousing, matching: find.byType(Scrollable))
            .first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await focusWithKeyboard(
        tester,
        find.byKey(const Key('toggle-preceptor-breakdown')),
      );
      expect(FocusManager.instance.primaryFocus, isNotNull);
      await expectLater(
        find.byKey(const Key('graphite-proof')),
        matchesGoldenFile(
          'goldens/graphite/'
          'graphite_landscape_preceptors_expanded_1536x1024.png',
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Graphite landscape directly matches the approved concept', (
    tester,
  ) async {
    await _pumpProof(tester, const Size(1536, 1024));

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('graphite-proof')),
    );
    final runtimeBytes = await tester.runAsync(() async {
      final runtimeImage = await boundary.toImage(pixelRatio: .25);
      final bytes = await runtimeImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      runtimeImage.dispose();
      return bytes;
    });
    final concept = _loadApprovedConceptComparison();

    final comparison = _compareConcept(
      concept.getBytes(order: img.ChannelOrder.rgba),
      runtimeBytes!.buffer.asUint8List(),
    );
    expect(
      comparison.meanChannelSimilarity,
      greaterThanOrEqualTo(.925),
      reason: 'mean channel similarity was ${comparison.meanChannelSimilarity}',
    );
    expect(
      comparison.closePixelRatio,
      greaterThanOrEqualTo(.805),
      reason: 'close-pixel ratio was ${comparison.closePixelRatio}',
    );
  });

  test('direct concept gate rejects the superseded v2 landscape', () {
    final rejectedFile = _findWorkspaceFile(
      'docs/themes/acceptance/proofs/graphite-v2/'
      'runtime-landscape-1536x1024.png',
    );
    final rejectedSource = img.decodePng(rejectedFile.readAsBytesSync());
    expect(rejectedSource, isNotNull);
    final rejected = img.copyResize(
      rejectedSource!,
      width: 384,
      height: 256,
      interpolation: img.Interpolation.average,
    );
    final comparison = _compareConcept(
      _loadApprovedConceptComparison().getBytes(order: img.ChannelOrder.rgba),
      rejected.getBytes(order: img.ChannelOrder.rgba),
    );
    expect(comparison.closePixelRatio, lessThan(.805));
  });

  testWidgets('Graphite portrait is an intentional ordered recomposition', (
    tester,
  ) async {
    await _pumpProof(tester, const Size(900, 1440));

    await expectLater(
      find.byKey(const Key('graphite-proof')),
      matchesGoldenFile('goldens/graphite/graphite_portrait_900x1440.png'),
    );
  });

  testWidgets('Graphite remains operable at 200 percent text scale', (
    tester,
  ) async {
    var addScheduleInvocations = 0;
    var profileInvocations = 0;
    var menuInvocations = 0;
    await _pumpProof(
      tester,
      const Size(900, 1440),
      textScaler: const TextScaler.linear(2),
      onAddSchedule: () => addScheduleInvocations++,
      onOpenProfile: () => profileInvocations++,
      onOpenMenu: () => menuInvocations++,
    );
    expect(find.byKey(const Key('graphite-portrait-scroll')), findsOneWidget);
    expect(
      find.byKey(const Key('graphite-calendar-horizontal-scroll')),
      findsOneWidget,
    );
    expect(find.byTooltip('Open menu'), findsOneWidget);
    expect(find.byTooltip('Add schedule'), findsOneWidget);
    final menuAction = tester.getRect(find.byTooltip('Open menu'));
    final addAction = tester.getRect(find.byTooltip('Add schedule'));
    final profileAction = tester.getRect(find.byTooltip('Open profile'));
    final navigation = tester.getRect(
      find.byKey(const Key('graphite-bottom-navigation')),
    );
    for (final action in [addAction, profileAction, menuAction]) {
      expect(action.left, greaterThanOrEqualTo(0));
      expect(action.right, lessThanOrEqualTo(900));
      expect(action.top, greaterThanOrEqualTo(0));
      expect(action.bottom, lessThanOrEqualTo(1440));
    }
    await tester.tap(find.byTooltip('Add schedule'));
    await tester.tap(find.byTooltip('Open profile'));
    await tester.tap(find.byTooltip('Open menu'));
    expect(addScheduleInvocations, 1);
    expect(profileInvocations, 1);
    expect(menuInvocations, 1);
    await tester.pump();
    expect(navigation.top, greaterThan(1300));
    expect(navigation.bottom, lessThanOrEqualTo(1440));

    await expectLater(
      find.byKey(const Key('graphite-proof')),
      matchesGoldenFile(
        'goldens/graphite/graphite_portrait_200_percent_900x1440.png',
      ),
    );
  });

  testWidgets(
    'Graphite Clinical Placements uses its destination-wide machinery',
    (tester) async {
      final harness = PlacementProgressHarness(
        familyName: 'Acceptance Family Medicine',
      );
      await harness.controller.load();
      await _pumpDestinationProof(
        tester,
        destination: ClinicalCalendarDestination.clinicalPlacements,
        child: PlacementManagementSurface(
          controller: harness.controller,
          studentId: placementTestStudentId,
        ),
      );

      expect(
        find.byKey(const Key('graphite-destination-crown')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('graphite-destination-bay')), findsOneWidget);
      expect(
        find.byKey(const Key('placement-management-surface')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('add-placement-action')), findsOneWidget);
      expect(find.byType(GraphiteNineSliceFrame), findsNothing);
      expect(find.byType(VariantFNineSliceFrame), findsNothing);
      await expectLater(
        find.byKey(const Key('graphite-destination-proof')),
        matchesGoldenFile(
          'goldens/graphite/'
          'graphite_destination_clinical_placements_1536x1024.png',
        ),
      );
    },
  );
}

img.Image _loadApprovedConceptComparison() {
  final conceptFile = _findWorkspaceFile(
    'docs/concepts/themes/graphite/calendar-dashboard-concept-v1.png',
  );
  final conceptSource = img.decodePng(conceptFile.readAsBytesSync());
  if (conceptSource == null) {
    throw StateError('The approved Graphite concept is not a valid PNG.');
  }
  return img.copyResize(
    conceptSource,
    width: 384,
    height: 256,
    interpolation: img.Interpolation.average,
  );
}

({double meanChannelSimilarity, double closePixelRatio}) _compareConcept(
  Uint8List concept,
  Uint8List runtime,
) {
  assert(concept.length == runtime.length);
  var totalChannelError = 0;
  var closePixels = 0;
  final pixelCount = runtime.length ~/ 4;
  for (var offset = 0; offset < runtime.length; offset += 4) {
    final redError = (concept[offset] - runtime[offset]).abs();
    final greenError = (concept[offset + 1] - runtime[offset + 1]).abs();
    final blueError = (concept[offset + 2] - runtime[offset + 2]).abs();
    totalChannelError += redError + greenError + blueError;
    if (redError <= 32 && greenError <= 32 && blueError <= 32) {
      closePixels++;
    }
  }
  return (
    meanChannelSimilarity: 1 - totalChannelError / (pixelCount * 3 * 255),
    closePixelRatio: closePixels / pixelCount,
  );
}

Future<void> _pumpProof(
  WidgetTester tester,
  Size size, {
  TextScaler textScaler = TextScaler.noScaling,
  VoidCallback onAddSchedule = _noop,
  VoidCallback onOpenProfile = _noop,
  VoidCallback onOpenMenu = _noop,
  VoidCallback onAddAssignment = _noop,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final proofAssets = _ProofAssetBundle(
    frameFile: _findWorkspaceFile(
      'packages/clinical_calendar_presentation/$graphiteFrameAsset',
    ),
    deltaFile: _findWorkspaceFile(
      'packages/clinical_calendar_presentation/$canonicalDeltaMarkAsset',
    ),
  );
  final preloadKey = GlobalKey();
  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: proofAssets,
      child: MaterialApp(home: SizedBox(key: preloadKey)),
    ),
  );
  await tester.runAsync(() async {
    await Future.wait([
      precacheImage(
        const AssetImage(
          graphiteFrameAsset,
          package: 'clinical_calendar_presentation',
        ),
        preloadKey.currentContext!,
      ),
      precacheImage(
        const AssetImage(
          canonicalDeltaMarkAsset,
          package: 'clinical_calendar_presentation',
        ),
        preloadKey.currentContext!,
      ),
    ]);
  });
  await tester.pump();
  expect(tester.takeException(), isNull);

  const themeBundle = GraphiteThemeBundle();
  final baseTheme = themeBundle.standardPresentation.createThemeData();
  final proofTheme = baseTheme.copyWith(
    textTheme: baseTheme.textTheme.apply(fontFamily: 'ProofRoboto'),
    primaryTextTheme: baseTheme.primaryTextTheme.apply(
      fontFamily: 'ProofRoboto',
    ),
  );
  final placementHarness = PlacementProgressHarness.graphiteConcept();
  await placementHarness.controller.load();
  await placementHarness.attentionController.load();
  expect(
    placementHarness.attentionController.error,
    isNull,
    reason: 'The production attention fixture must load successfully.',
  );
  final slots = ResponsiveShellSlots(
    centralContent: AcademicAssignmentCalendarWorkspace(
      themeId: graphiteThemeId,
      onAddAssignment: onAddAssignment,
      calendar: CalendarPeriodView(
        dataSource: _ProofCalendarDataSource(),
        studentId: _studentId,
        today: _today,
        initialAnchor: _today,
      ),
    ),
    planningRegion: const _PlanningProof(),
    placementDock: PlacementDock(
      controller: placementHarness.controller,
      studentId: placementTestStudentId,
    ),
    insightRail: GraphiteInsightRailSlots(
      placementProgress: PlacementProgressRail(
        controller: placementHarness.controller,
        studentId: placementTestStudentId,
      ),
      attention: AttentionRail(
        controller: placementHarness.attentionController,
        onOpenAction: (_) {},
        onOpenAll: _noop,
      ),
    ),
    mobilePlacementSummary: const _ProofPanel(
      title: 'PLACEMENT STATUS',
      lines: ['42 / 90 hr completed', '24 hr scheduled', '24 hr unscheduled'],
    ),
    mobileAttention: const _ProofPanel(
      title: 'NEEDS ATTENTION',
      lines: ['Session needs confirmation', 'Planning incomplete'],
      urgentFrom: 0,
    ),
    profileAvatar: Tooltip(
      message: 'Open profile',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpenProfile,
        child: const CircleAvatar(
          radius: 18,
          child: Icon(Icons.person_outline, size: 20),
        ),
      ),
    ),
  );

  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: proofAssets,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: proofTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: RepaintBoundary(
          key: const Key('graphite-proof'),
          child: themeBundle.shellRenderer.build(
            slots: slots,
            environmentName: 'GRAPHITE',
            onOpenMenu: onOpenMenu,
            onOpenDestination: _ignoreDestination,
            onOpenAttention: _noop,
            onAddSchedule: onAddSchedule,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  for (final ownerKey in const [
    Key('graphite-portrait-scroll'),
    Key('graphite-calendar-horizontal-scroll'),
  ]) {
    final scrollable = find.descendant(
      of: find.byKey(ownerKey),
      matching: find.byType(Scrollable),
    );
    if (scrollable.evaluate().isNotEmpty) {
      tester.state<ScrollableState>(scrollable.first).position.jumpTo(0);
    }
  }
  await tester.pump();
  expect(tester.takeException(), isNull);
}

Future<void> _pumpDestinationProof(
  WidgetTester tester, {
  required ClinicalCalendarDestination destination,
  required Widget child,
}) async {
  await tester.binding.setSurfaceSize(const Size(1536, 1024));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  const themeBundle = GraphiteThemeBundle();
  final baseTheme = themeBundle.standardPresentation.createThemeData();
  final proofTheme = baseTheme.copyWith(
    textTheme: baseTheme.textTheme.apply(fontFamily: 'ProofRoboto'),
    primaryTextTheme: baseTheme.primaryTextTheme.apply(
      fontFamily: 'ProofRoboto',
    ),
  );
  final proofAssets = _ProofAssetBundle(
    frameFile: _findWorkspaceFile(
      'packages/clinical_calendar_presentation/$graphiteFrameAsset',
    ),
    deltaFile: _findWorkspaceFile(
      'packages/clinical_calendar_presentation/$canonicalDeltaMarkAsset',
    ),
  );
  final preloadKey = GlobalKey();
  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: proofAssets,
      child: MaterialApp(home: SizedBox(key: preloadKey)),
    ),
  );
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage(
        canonicalDeltaMarkAsset,
        package: 'clinical_calendar_presentation',
      ),
      preloadKey.currentContext!,
    );
  });
  await tester.pump();
  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: proofAssets,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: proofTheme,
        home: RepaintBoundary(
          key: const Key('graphite-destination-proof'),
          child: themeBundle.shellRenderer.buildDestination(
            destination: destination,
            entry: DestinationEntry.applicationMenu,
            onExit: _noop,
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

final class _PlanningProof extends StatelessWidget {
  const _PlanningProof();

  @override
  Widget build(BuildContext context) {
    final enlargedText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (enlargedText)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _ProofTitle('PLANNING'),
              OutlinedButton(
                onPressed: _noop,
                child: const Text('ADD SCHEDULE'),
              ),
              OutlinedButton(
                onPressed: _noop,
                child: const Text('PLANNING INCOMPLETE'),
              ),
            ],
          )
        else
          Row(
            children: [
              const Expanded(
                child: Row(
                  children: [
                    _ProofTitle('PLANNING'),
                    SizedBox(width: 18),
                    Text('Build the monthly plan in this in-flow region.'),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: _noop,
                child: const Text('ADD SCHEDULE'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _noop,
                child: const Text('PLANNING INCOMPLETE'),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: context.clinicalColors.insetBorder),
              borderRadius: BorderRadius.circular(7),
              color: context.clinicalColors.canvas,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _PlanningChoice(
                      icon: Icons.looks_one_outlined,
                      label: 'TYPE & TIME',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _PlanningChoice(
                      icon: Icons.work_outline,
                      label: 'WORK SHIFT',
                      color: context.clinicalColors.workMachinery,
                    ),
                    const SizedBox(width: 12),
                    _PlanningChoice(
                      icon: Icons.medical_services_outlined,
                      label: 'CLINICAL SESSION',
                      color: context.clinicalColors.clinical,
                    ),
                    const SizedBox(width: 12),
                    _PlanningChoice(
                      icon: Icons.shield_outlined,
                      label: 'PROTECTED DAY',
                      color: context.clinicalColors.protectedDayAccent,
                    ),
                  ],
                ),
                const Spacer(),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: .96,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _PlanningField('SCHEDULE TEMPLATE', 'MANUAL'),
                        ),
                        SizedBox(width: 12),
                        Expanded(child: _PlanningField('START', '08:00')),
                        SizedBox(width: 12),
                        Expanded(child: _PlanningField('END', '16:00')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _PlanningChoice extends StatelessWidget {
  const _PlanningChoice({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}

final class _PlanningField extends StatelessWidget {
  const _PlanningField(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('graphite-planning-field-$label'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      border: Border.all(color: context.clinicalColors.insetBorder),
      color: context.clinicalColors.structureRaised,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(value),
      ],
    ),
  );
}

final class _ProofTitle extends StatelessWidget {
  const _ProofTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      letterSpacing: 1.2,
      fontWeight: FontWeight.w700,
    ),
  );
}

final class _ProofPanel extends StatelessWidget {
  const _ProofPanel({
    required this.title,
    required this.lines,
    this.urgentFrom,
  });

  final String title;
  final List<String> lines;
  final int? urgentFrom;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < lines.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              lines[index],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: urgentFrom != null && index >= urgentFrom!
                    ? context.clinicalColors.urgent
                    : null,
              ),
            ),
          ),
      ],
    ),
  );
}

final class _ProofCalendarDataSource implements CalendarDataSource {
  @override
  Future<CalendarSnapshot> load({
    required String studentId,
    required LocalDate firstDate,
    required LocalDate lastDate,
  }) async => CalendarSnapshot([
    for (final day in [1, 5, 12, 19, 26])
      CalendarEntry(
        id: 'protected-$day',
        kind: CalendarEntryKind.protectedDay,
        startDate: LocalDate(2026, 8, day),
        endDate: LocalDate(2026, 8, day),
        title: 'Protected Day',
        statusLabel: 'Protected',
      ),
    for (final day in [4, 7, 11, 14, 18, 21, 25, 28])
      CalendarEntry(
        id: 'work-$day',
        kind: CalendarEntryKind.workShift,
        startDate: LocalDate(2026, 8, day),
        endDate: LocalDate(2026, 8, day),
        startTime: LocalTime(7, 0),
        endTime: LocalTime(15, 0),
        title: 'Work Shift',
        statusLabel: 'Scheduled',
      ),
    for (final day in [3, 6, 10, 13, 17, 20, 24, 27])
      CalendarEntry(
        id: 'clinical-$day',
        kind: CalendarEntryKind.clinicalSession,
        startDate: LocalDate(2026, 8, day),
        endDate: LocalDate(2026, 8, day),
        startTime: LocalTime(8, 0),
        endTime: LocalTime(16, 0),
        title: 'Clinical Session',
        assignment: 'Internal Medicine · Jordan Lee',
        statusLabel: day == 5 ? 'Awaiting Confirmation' : 'Scheduled',
      ),
  ]);
}

File _findWorkspaceFile(String relativePath) {
  var root = Directory.current.absolute;
  final normalized = relativePath.replaceAll('/', Platform.pathSeparator);
  while (root.parent.path != root.path) {
    final candidate = File('${root.path}${Platform.pathSeparator}$normalized');
    if (candidate.existsSync()) return candidate;
    root = root.parent;
  }
  throw StateError('Proof dependency was not found: $relativePath');
}

final class _ProofAssetBundle extends CachingAssetBundle {
  _ProofAssetBundle({required this.frameFile, required this.deltaFile});

  final File frameFile;
  final File deltaFile;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'packages/clinical_calendar_presentation/$graphiteFrameAsset') {
      return ByteData.sublistView(await frameFile.readAsBytes());
    }
    if (key ==
        'packages/clinical_calendar_presentation/$canonicalDeltaMarkAsset') {
      return ByteData.sublistView(await deltaFile.readAsBytes());
    }
    return rootBundle.load(key);
  }
}

void _noop() {}

void _ignoreDestination(ClinicalCalendarDestination _) {}
