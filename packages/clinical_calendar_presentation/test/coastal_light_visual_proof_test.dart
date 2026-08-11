import 'dart:io';

import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/proof_fonts.dart';

const _studentId = '00000000-0000-4000-8000-000000000136';
final _today = LocalDate(2026, 8, 6);

void main() {
  setUpAll(prepareProofEnvironment);

  testWidgets('Coastal Light landscape matches its approved composition', (
    tester,
  ) async {
    await _pumpProof(tester, const Size(1586, 992));

    await expectLater(
      find.byKey(const Key('coastal-calm-proof')),
      matchesGoldenFile(
        'goldens/coastal_light/coastal_light_landscape_1586x992.png',
      ),
    );
  });

  testWidgets('Coastal Light landscape obeys normative concept geometry', (
    tester,
  ) async {
    await _pumpProof(tester, const Size(1586, 992));

    final placements = tester.getRect(
      find.byKey(const Key('coastal-calm-placement-bay')),
    );
    final calendar = tester.getRect(
      find.byKey(const Key('coastal-calm-calendar-bay')),
    );
    final planning = tester.getRect(
      find.byKey(const Key('coastal-calm-planning-bay')),
    );
    final insight = tester.getRect(
      find.byKey(const Key('coastal-calm-insight-bay')),
    );
    final navigation = tester.getRect(
      find.byKey(const Key('coastal-calm-bottom-navigation')),
    );

    expect(placements.width / 1586, closeTo(.205, .006));
    expect(calendar.width / 1586, closeTo(.519, .006));
    expect(insight.width / 1586, closeTo(.227, .006));
    expect(calendar.height / 992, closeTo(.54, .006));
    expect(planning.height / 992, closeTo(.263, .006));
    expect(navigation.height / 992, closeTo(.076, .006));
    expect(
      find.byKey(const Key('coastal-light-axion-delta')),
      findsOneWidget,
      reason: 'The Coastal crown carries the approved Axion brand mark.',
    );
    expect(find.text('AUGUST 2026'), findsOneWidget);
    for (final label in const ['MONTH', 'WEEK', 'AGENDA', 'SUN', 'SAT']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('SUNDAY'), findsNothing);

    final calendarViewport = tester.getRect(find.byType(CalendarPeriodView));
    final calendarLegend = tester.getRect(
      find.byKey(const Key('coastal-calm-calendar-legend-line')),
    );
    expect(
      calendarLegend.top,
      greaterThanOrEqualTo(calendarViewport.bottom),
      reason:
          'Clinical, Work, and Protected belong on their own line below Calendar.',
    );

    final visibleEntries = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> && key.value.startsWith('month-entry-');
    });
    expect(
      visibleEntries,
      findsNWidgets(19),
      reason: 'The concept month is a populated planning surface.',
    );
  });

  testWidgets('Coastal Light crown exposes shared destination controls', (
    tester,
  ) async {
    final opened = <ClinicalCalendarDestination>[];
    await _pumpProof(
      tester,
      const Size(1586, 992),
      onOpenDestination: opened.add,
    );

    for (final key in const [
      Key('coastal-light-add-placement-action'),
      Key('coastal-light-help-action'),
      Key('coastal-light-profile-action'),
    ]) {
      expect(find.byKey(key).hitTestable(), findsOneWidget);
    }

    await tester.tap(
      find.byKey(const Key('coastal-light-add-placement-action')),
    );
    await tester.tap(find.byKey(const Key('coastal-light-help-action')));
    await tester.tap(find.byKey(const Key('coastal-light-profile-action')));
    expect(opened, [
      ClinicalCalendarDestination.clinicalPlacements,
      ClinicalCalendarDestination.help,
    ]);
  });

  testWidgets('Coastal Light owns destination crown and housing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1586, 992));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const themeBundle = CoastalLightThemeBundle();
    await tester.pumpWidget(
      MaterialApp(
        theme: themeBundle.standardPresentation.createThemeData(),
        home: themeBundle.shellRenderer.buildDestination(
          destination: ClinicalCalendarDestination.clinicalPlacements,
          entry: DestinationEntry.direct,
          onExit: _noop,
          child: const ShellPanel(
            label: 'Clinical Placements',
            child: Text('Fictional placement content'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('coastal-light-destination-shell')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('coastal-light-destination-crown')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('coastal-light-destination-housing')),
      findsOneWidget,
    );
    expect(find.byType(AdditiveThemeDestinationSurface), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Coastal Light portrait is an intentional tablet console', (
    tester,
  ) async {
    await _pumpProof(tester, const Size(900, 1440));

    await expectLater(
      find.byKey(const Key('coastal-calm-proof')),
      matchesGoldenFile(
        'goldens/coastal_light/coastal_light_portrait_900x1440.png',
      ),
    );
  });

  testWidgets('Coastal Light remains legible at 200 percent text scale', (
    tester,
  ) async {
    await _pumpProof(
      tester,
      const Size(900, 1440),
      textScaler: const TextScaler.linear(2),
    );
    final navigation = tester.getRect(
      find.byKey(const Key('coastal-calm-bottom-navigation')),
    );
    expect(navigation.top, greaterThan(1300));
    expect(navigation.bottom, lessThanOrEqualTo(1440));
    expect(
      find.byKey(const Key('coastal-calm-bottom-navigation')).hitTestable(),
      findsOneWidget,
      reason: 'The enlarged content viewport must not paint over navigation.',
    );
    expect(
      find.byKey(const Key('coastal-calm-portrait-scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('coastal-calm-calendar-horizontal-scroll')),
      findsOneWidget,
    );
    expect(find.byTooltip('Open menu').hitTestable(), findsOneWidget);
    expect(find.byTooltip('Add schedule').hitTestable(), findsOneWidget);
    expect(
      find.byKey(const Key('coastal-calm-navigation-4')).hitTestable(),
      findsOneWidget,
      reason: 'Settings must remain reachable at 200 percent text scale.',
    );

    await expectLater(
      find.byKey(const Key('coastal-calm-proof')),
      matchesGoldenFile(
        'goldens/coastal_light/'
        'coastal_light_portrait_200_percent_900x1440.png',
      ),
    );
  });
}

Future<void> _pumpProof(
  WidgetTester tester,
  Size size, {
  TextScaler textScaler = TextScaler.noScaling,
  ValueChanged<ClinicalCalendarDestination> onOpenDestination =
      _ignoreDestination,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final proofAssets = _ProofAssetBundle(
    frameFile: _findWorkspaceFile(
      'packages/clinical_calendar_presentation/$coastalLightFrameAsset',
    ),
    chassisFile: _findWorkspaceFile(
      'packages/clinical_calendar_presentation/'
      '$coastalLightLandscapeChassisAsset',
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
        coastalLightFrameAsset,
        package: 'clinical_calendar_presentation',
      ),
      preloadKey.currentContext!,
    );
    await precacheImage(
      const AssetImage(
        coastalLightLandscapeChassisAsset,
        package: 'clinical_calendar_presentation',
      ),
      preloadKey.currentContext!,
    );
  });
  await tester.pump();
  expect(tester.takeException(), isNull);
  const themeBundle = CoastalLightThemeBundle();
  final baseTheme = themeBundle.standardPresentation.createThemeData();
  final proofTheme = baseTheme.copyWith(
    textTheme: baseTheme.textTheme.apply(fontFamily: 'ProofRoboto'),
    primaryTextTheme: baseTheme.primaryTextTheme.apply(
      fontFamily: 'ProofRoboto',
    ),
  );
  final source = _ProofCalendarDataSource();
  final slots = ResponsiveShellSlots(
    centralContent: AcademicAssignmentCalendarWorkspace(
      themeId: coastalCalmThemeId,
      onAddAssignment: _noop,
      calendar: CalendarPeriodView(
        dataSource: source,
        studentId: _studentId,
        today: _today,
        initialAnchor: _today,
      ),
    ),
    planningRegion: const _PlanningProof(),
    placementDock: const _PlacementsProof(),
    insightRail: const _InsightProof(),
    mobilePlacementSummary: const _PlacementSummaryProof(),
    mobileAttention: const _AttentionSummaryProof(),
    profileAvatar: const CircleAvatar(
      radius: 18,
      child: Icon(Icons.person_outline, size: 20),
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
          key: const Key('coastal-calm-proof'),
          child: themeBundle.shellRenderer.build(
            slots: slots,
            environmentName: 'COASTAL LIGHT',
            onOpenMenu: _noop,
            onOpenDestination: onOpenDestination,
            onOpenAttention: _noop,
            onAddSchedule: _noop,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  for (final ownerKey in const [
    Key('coastal-calm-portrait-scroll'),
    Key('coastal-calm-calendar-horizontal-scroll'),
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
  _ProofAssetBundle({required this.frameFile, required this.chassisFile});

  final File frameFile;
  final File chassisFile;

  @override
  Future<ByteData> load(String key) async {
    if (key ==
        'packages/clinical_calendar_presentation/$coastalLightFrameAsset') {
      return ByteData.sublistView(
        Uint8List.fromList(await frameFile.readAsBytes()),
      );
    }
    if (key ==
        'packages/clinical_calendar_presentation/'
            '$coastalLightLandscapeChassisAsset') {
      return ByteData.sublistView(
        Uint8List.fromList(await chassisFile.readAsBytes()),
      );
    }
    return rootBundle.load(key);
  }
}

final class _PlacementsProof extends StatelessWidget {
  const _PlacementsProof();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('MY PLACEMENTS'),
        const SizedBox(height: 20),
        const Expanded(
          flex: 47,
          child: _PlacementCard(
            name: 'ACCEPTANCE FAMILY MEDICINE',
            accent: CoastalLightColors.clinical,
            completed: '0 hr',
            scheduled: '8 hr',
          ),
        ),
        const SizedBox(height: 18),
        const Expanded(
          flex: 53,
          child: _PlacementCard(
            name: 'INTERNAL MEDICINE',
            accent: CoastalLightColors.workMachinery,
            completed: '0 hr',
            scheduled: '8 hr',
          ),
        ),
      ],
    );
  }
}

final class _PlacementCard extends StatelessWidget {
  const _PlacementCard({
    required this.name,
    required this.accent,
    required this.completed,
    required this.scheduled,
  });

  final String name;
  final Color accent;
  final String completed;
  final String scheduled;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: CoastalLightColors.surface.withValues(alpha: .88),
      border: Border.all(
        color: CoastalLightColors.insetBorder.withValues(alpha: .3),
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: CoastalLightColors.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text('$completed / 90 hr completed'),
        const SizedBox(height: 14),
        Center(
          child: SizedBox.square(
            dimension: 86,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: completed == '0 hr' ? 0 : .47,
                  strokeWidth: 9,
                  color: accent,
                  backgroundColor: CoastalLightColors.control,
                ),
                Center(
                  child: Text(
                    completed == '0 hr' ? '0%' : '47%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: CoastalLightColors.clinical,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 38),
        _PlacementMetricLine(
          icon: Icons.calendar_month_outlined,
          label: '$scheduled scheduled',
          color: CoastalLightColors.workMachinery,
        ),
        const _PlacementMetricLine(
          icon: Icons.pending_outlined,
          label: '82 hr unscheduled',
          color: CoastalLightColors.scheduled,
        ),
      ],
    ),
  );
}

final class _MetricLine extends StatelessWidget {
  const _MetricLine(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

final class _PlacementMetricLine extends StatelessWidget {
  const _PlacementMetricLine({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 11),
    child: Row(
      children: [
        Icon(icon, size: 23, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

final class _PlanningProof extends StatelessWidget {
  const _PlanningProof();

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
      return ListView(
        children: [
          const _SectionTitle('PLANNING'),
          const SizedBox(height: 12),
          Text(
            'Build the monthly plan in this in-flow region.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          const _PlanningStep('1', 'TYPE & TIME'),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 230,
                child: _ChoiceChip(
                  'CLINICAL SESSION',
                  CoastalLightColors.clinical,
                ),
              ),
              SizedBox(
                width: 190,
                child: _ChoiceChip(
                  'WORK SHIFT',
                  CoastalLightColors.workMachinery,
                ),
              ),
              SizedBox(
                width: 210,
                child: _ChoiceChip(
                  'PROTECTED DAY',
                  CoastalLightColors.protectedDayAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _FieldProof(
            label: 'SCHEDULE TEMPLATE',
            value: 'ENTER TIMES MANUALLY',
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle('PLANNING')),
            SizedBox(
              width: 145,
              height: 42,
              child: FilledButton(
                onPressed: _noop,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  textStyle: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                child: const Text('ADD SCHEDULE'),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 175,
              height: 42,
              child: TextButton(
                onPressed: _noop,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: CoastalLightColors.urgent,
                  textStyle: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                child: const Text('PLANNING INCOMPLETE'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 102,
              height: 42,
              child: OutlinedButton(
                onPressed: _noop,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: Theme.of(context).textTheme.labelSmall,
                ),
                child: const FittedBox(child: Text('COLLAPSE')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Build the monthly plan in this in-flow region.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        const SizedBox(
          height: 72,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PlanningStep('1', 'TYPE & TIME'),
                    SizedBox(height: 6),
                    Padding(
                      padding: EdgeInsets.only(left: 31),
                      child: Text('0 selected dates'),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _ChoiceChip(
                  'CLINICAL SESSION',
                  CoastalLightColors.clinical,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _ChoiceChip(
                  'WORK SHIFT',
                  CoastalLightColors.workMachinery,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _ChoiceChip(
                  'PROTECTED DAY',
                  CoastalLightColors.protectedDayAccent,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            SizedBox(
              width: 245,
              child: _FieldProof(
                label: 'SCHEDULE TEMPLATE',
                value: 'ENTER TIMES MANUALLY',
              ),
            ),
            const Spacer(),
            const SizedBox(width: 10),
            const SizedBox(
              width: 120,
              child: _FieldProof(label: 'START', value: '08:00'),
            ),
            const SizedBox(width: 10),
            const SizedBox(
              width: 120,
              child: _FieldProof(label: 'END', value: '16:00'),
            ),
          ],
        ),
      ],
    );
  }
}

final class _PlanningStep extends StatelessWidget {
  const _PlanningStep(this.number, this.label);

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 12,
        backgroundColor: Colors.transparent,
        foregroundColor: CoastalLightColors.clinical,
        child: Text(number),
      ),
      const SizedBox(width: 7),
      Text(label, style: const TextStyle(color: CoastalLightColors.clinical)),
    ],
  );
}

final class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = switch (label) {
      'CLINICAL SESSION' => Icons.medical_services_outlined,
      'WORK SHIFT' => Icons.work_outline,
      _ => Icons.shield_outlined,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

final class _FieldProof extends StatelessWidget {
  const _FieldProof({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: CoastalLightColors.control,
      border: Border.all(color: CoastalLightColors.insetBorder),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}

final class _InsightProof extends StatelessWidget {
  const _InsightProof();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        flex: 63,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionTitle('INTERNAL MEDICINE'),
              const SizedBox(height: 20),
              Center(
                child: SizedBox.square(
                  dimension: 122,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const CircularProgressIndicator(
                        value: 0,
                        strokeWidth: 12,
                        color: CoastalLightColors.clinical,
                        backgroundColor: CoastalLightColors.control,
                      ),
                      const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '0',
                                  style: TextStyle(
                                    color: CoastalLightColors.primaryText,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'hr',
                                  style: TextStyle(
                                    color: CoastalLightColors.primaryText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'completed',
                              style: TextStyle(
                                color: CoastalLightColors.primaryText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const _ProgressMetricLine(
                icon: Icons.gps_fixed,
                label: 'Target',
                value: '90 hr',
              ),
              const _ProgressMetricLine(
                icon: Icons.check_circle_outline,
                label: 'Completed',
                value: '0 hr',
              ),
              const _ProgressMetricLine(
                icon: Icons.calendar_month_outlined,
                label: 'Scheduled',
                value: '8 hr',
              ),
              const _ProgressMetricLine(
                icon: Icons.pending_outlined,
                label: 'Unscheduled',
                value: '82 hr',
              ),
              const _ProgressMetricLine(
                icon: Icons.flag_outlined,
                label: 'Over-Target',
                value: '0 hr',
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: CoastalLightColors.control,
                  border: Border.all(
                    color: CoastalLightColors.insetBorder.withValues(
                      alpha: .35,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.speed_outlined,
                      size: 30,
                      color: CoastalLightColors.workMachinery,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Additional pace required\n21 hr 16 min / week',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(
                    Icons.explore_outlined,
                    size: 20,
                    color: CoastalLightColors.workMachinery,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'TAP WHEEL TO VIEW NEXT PLACEMENT',
                    style: TextStyle(
                      color: CoastalLightColors.workMachinery,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 20,
                    color: CoastalLightColors.workMachinery,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'SHOW PRECEPTOR BREAKDOWN',
                    style: TextStyle(
                      color: CoastalLightColors.workMachinery,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Expanded(
        flex: 37,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: CoastalLightColors.surface.withValues(alpha: .9),
            border: Border.all(
              color: CoastalLightColors.urgent.withValues(alpha: .45),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'NEEDS ATTENTION',
                      style: TextStyle(
                        color: CoastalLightColors.urgent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                  Text(
                    'ON · 5',
                    style: TextStyle(
                      color: CoastalLightColors.urgent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              _AttentionCard(
                icon: Icons.warning_rounded,
                title: 'CLINICAL SESSION NEEDS CONFIRMATION',
                description: 'Confirm the actual times and preceptor',
                urgent: true,
              ),
              _AttentionCard(
                icon: Icons.warning_rounded,
                title: 'INITIAL SELF-ASSESSMENT',
                description: 'Acceptance Family Medicine',
                due: true,
                urgent: true,
              ),
              _AttentionCard(
                icon: Icons.warning_rounded,
                title: 'INITIAL SELF-ASSESSMENT',
                description: 'Internal Medicine',
                due: true,
                urgent: true,
              ),
              _AttentionCard(
                icon: Icons.warning_rounded,
                title: 'PLANNING INCOMPLETE',
                description: 'Choose one empty Protected Day',
                urgent: true,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

final class _ProgressMetricLine extends StatelessWidget {
  const _ProgressMetricLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(icon, size: 21, color: CoastalLightColors.workMachinery),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

final class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.icon,
    required this.title,
    this.description,
    this.due = false,
    this.urgent = false,
  });

  final IconData icon;
  final String title;
  final String? description;
  final bool due;
  final bool urgent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
    decoration: BoxDecoration(
      border: Border(
        left: BorderSide(
          color: urgent ? CoastalLightColors.urgent : Colors.transparent,
          width: 3,
        ),
        bottom: BorderSide(
          color: CoastalLightColors.insetBorder.withValues(alpha: .35),
        ),
      ),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          color: urgent
              ? CoastalLightColors.urgent
              : CoastalLightColors.clinical,
          size: urgent ? 28 : 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (description != null)
                Text(
                  description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
            ],
          ),
        ),
        if (due)
          const Text(
            'Due',
            style: TextStyle(
              color: CoastalLightColors.urgent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          )
        else if (!urgent)
          const Icon(Icons.chevron_right, size: 18),
      ],
    ),
  );
}

final class _PlacementSummaryProof extends StatelessWidget {
  const _PlacementSummaryProof();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _SectionTitle('PLACEMENT STATUS'),
      SizedBox(height: 10),
      _MetricLine('42 / 90 hr completed', CoastalLightColors.completed),
      _MetricLine('24 hr scheduled', CoastalLightColors.scheduled),
      _MetricLine('24 hr unscheduled', CoastalLightColors.unscheduled),
    ],
  );
}

final class _AttentionSummaryProof extends StatelessWidget {
  const _AttentionSummaryProof();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _SectionTitle('NEEDS ATTENTION'),
      SizedBox(height: 8),
      _AttentionCard(
        icon: Icons.assignment_late_outlined,
        title: 'SESSION NEEDS CONFIRMATION',
      ),
      _AttentionCard(
        icon: Icons.warning_amber_outlined,
        title: 'PLANNING INCOMPLETE',
      ),
    ],
  );
}

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      color: CoastalLightColors.clinical,
      letterSpacing: 1.7,
      fontWeight: FontWeight.w700,
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
    CalendarEntry(
      id: 'assignment-11',
      kind: CalendarEntryKind.academicAssignment,
      startDate: LocalDate(2026, 8, 11),
      endDate: LocalDate(2026, 8, 11),
      title: 'SOAP Note Reflection',
      course: 'NURS 642',
      statusLabel: 'Pending',
    ),
    for (final day in [7, 17, 27])
      CalendarEntry(
        id: 'protected-$day',
        kind: CalendarEntryKind.protectedDay,
        startDate: LocalDate(2026, 8, day),
        endDate: LocalDate(2026, 8, day),
        title: 'Protected Day',
        statusLabel: 'Protected',
      ),
    for (final day in [3, 4, 10, 13, 19, 24, 28])
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
    for (final day in [5, 6, 12, 14, 18, 21, 25, 26])
      CalendarEntry(
        id: 'clinical-$day',
        kind: CalendarEntryKind.clinicalSession,
        startDate: LocalDate(2026, 8, day),
        endDate: LocalDate(2026, 8, day),
        startTime: LocalTime(8, 0),
        endTime: LocalTime(16, 0),
        title: 'Clinical Session',
        assignment: 'Internal Medicine · Jordan Lee',
        statusLabel: day == 6 ? 'Awaiting Confirmation' : 'Scheduled',
      ),
  ]);
}

void _noop() {}

void _ignoreDestination(ClinicalCalendarDestination _) {}
