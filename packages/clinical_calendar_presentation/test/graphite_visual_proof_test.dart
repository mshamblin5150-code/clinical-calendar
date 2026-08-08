import 'dart:io';

import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _studentId = '00000000-0000-4000-8000-000000000128';
final _today = LocalDate(2026, 8, 6);

void main() {
  setUpAll(_loadProofFonts);

  testWidgets('Graphite landscape is the approved precision instrument', (
    tester,
  ) async {
    await _pumpProof(tester, const Size(1536, 1024));

    await expectLater(
      find.byKey(const Key('graphite-proof')),
      matchesGoldenFile('goldens/graphite/graphite_landscape_1536x1024.png'),
    );
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
    await _pumpProof(
      tester,
      const Size(900, 1440),
      textScaler: const TextScaler.linear(2),
    );
    expect(find.byKey(const Key('graphite-portrait-scroll')), findsOneWidget);
    expect(
      find.byKey(const Key('graphite-calendar-horizontal-scroll')),
      findsOneWidget,
    );
    expect(find.byTooltip('Open menu'), findsOneWidget);
    expect(find.byTooltip('Add schedule'), findsOneWidget);
    final menuAction = tester.getRect(find.byTooltip('Open menu'));
    final navigation = tester.getRect(
      find.byKey(const Key('graphite-bottom-navigation')),
    );
    expect(menuAction.top, greaterThanOrEqualTo(0));
    expect(menuAction.bottom, lessThanOrEqualTo(1440));
    expect(navigation.top, greaterThan(1300));
    expect(navigation.bottom, lessThanOrEqualTo(1440));

    await expectLater(
      find.byKey(const Key('graphite-proof')),
      matchesGoldenFile(
        'goldens/graphite/graphite_portrait_200_percent_900x1440.png',
      ),
    );
  });
}

Future<void> _pumpProof(
  WidgetTester tester,
  Size size, {
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final proofAssets = _ProofAssetBundle(
    frameFile: _findWorkspaceFile(
      'packages/clinical_calendar_presentation/$graphiteFrameAsset',
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
        graphiteFrameAsset,
        package: 'clinical_calendar_presentation',
      ),
      preloadKey.currentContext!,
    );
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
  final slots = ResponsiveShellSlots(
    centralContent: CalendarPeriodView(
      dataSource: _ProofCalendarDataSource(),
      studentId: _studentId,
      today: _today,
      initialAnchor: _today,
    ),
    planningRegion: const _PlanningProof(),
    placementDock: const _PlacementsProof(),
    insightRail: const _InsightProof(),
    mobilePlacementSummary: const _ProofPanel(
      title: 'PLACEMENT STATUS',
      lines: ['42 / 90 hr completed', '24 hr scheduled', '24 hr unscheduled'],
    ),
    mobileAttention: const _ProofPanel(
      title: 'NEEDS ATTENTION',
      lines: ['Session needs confirmation', 'Planning incomplete'],
      urgentFrom: 0,
    ),
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
          key: const Key('graphite-proof'),
          child: themeBundle.shellRenderer.build(
            slots: slots,
            environmentName: 'GRAPHITE',
            onOpenMenu: _noop,
            onOpenDestination: _ignoreDestination,
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

final class _PlacementsProof extends StatelessWidget {
  const _PlacementsProof();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ProofTitle('MY PLACEMENTS'),
        const SizedBox(height: 12),
        _PlacementCard(
          name: 'ACCEPTANCE FAMILY MEDICINE',
          progress: 0,
          accent: context.clinicalColors.clinical,
          detail: '0 hr / 90 hr completed\n8 hr scheduled\n82 hr unscheduled',
        ),
        const SizedBox(height: 12),
        _PlacementCard(
          name: 'INTERNAL MEDICINE',
          progress: .47,
          accent: context.clinicalColors.workMachinery,
          detail: '42 hr / 90 hr completed\n24 hr scheduled\n24 hr unscheduled',
        ),
      ],
    ),
  );
}

final class _PlacementCard extends StatelessWidget {
  const _PlacementCard({
    required this.name,
    required this.progress,
    required this.accent,
    required this.detail,
  });

  final String name;
  final double progress;
  final Color accent;
  final String detail;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border(left: BorderSide(color: accent, width: 4)),
      color: context.clinicalColors.structureRaised,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 14),
        Center(
          child: SizedBox.square(
            dimension: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 9,
                  color: accent,
                  backgroundColor: context.clinicalColors.insetBorder,
                ),
                Center(child: Text('${(progress * 100).round()}%')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          detail,
          style: Theme.of(context).textTheme.bodySmall,
          strutStyle: const StrutStyle(height: 1.35),
        ),
      ],
    ),
  );
}

final class _InsightProof extends StatelessWidget {
  const _InsightProof();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ProofTitle('INTERNAL MEDICINE'),
        const SizedBox(height: 10),
        Center(
          child: SizedBox.square(
            dimension: 116,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: .47,
                  strokeWidth: 11,
                  color: context.clinicalColors.clinical,
                  backgroundColor: context.clinicalColors.insetBorder,
                ),
                const Center(
                  child: Text('42 hr\ncompleted', textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Target                                      90 hr'),
        const Text('Scheduled                               24 hr'),
        const Text('Unscheduled                           24 hr'),
        const SizedBox(height: 12),
        const Divider(),
        Text(
          'Additional pace required',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          '21 hr 16 min / week',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: context.clinicalColors.clinical,
          ),
        ),
        const SizedBox(height: 10),
        const Divider(),
        const _ProofTitle('NEEDS ATTENTION  •  5'),
        const SizedBox(height: 8),
        for (final label in const [
          'Clinical Session needs confirmation',
          'Initial Self-Assessment — Due',
          'Initial Self-Assessment — Internal Medicine',
          'Planning incomplete',
          'Interim Review threshold approaching',
        ])
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: context.clinicalColors.urgent,
                  width: 3,
                ),
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.clinicalColors.urgent,
              ),
            ),
          ),
      ],
    ),
  );
}

final class _PlanningProof extends StatelessWidget {
  const _PlanningProof();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Expanded(child: _ProofTitle('PLANNING')),
          OutlinedButton(onPressed: _noop, child: const Text('ADD SCHEDULE')),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _noop,
            child: const Text('PLANNING INCOMPLETE'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      const Text('Build the monthly plan in this in-flow region.'),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          const Chip(label: Text('1  TYPE & TIME')),
          Chip(
            avatar: Icon(
              Icons.work_outline,
              color: context.clinicalColors.workMachinery,
            ),
            label: const Text('WORK SHIFT'),
          ),
          Chip(
            avatar: Icon(
              Icons.medical_services_outlined,
              color: context.clinicalColors.clinical,
            ),
            label: const Text('CLINICAL SESSION'),
          ),
          Chip(
            avatar: Icon(
              Icons.shield_outlined,
              color: context.clinicalColors.protectedDayAccent,
            ),
            label: const Text('PROTECTED DAY'),
          ),
        ],
      ),
      const Spacer(),
      const Row(
        children: [
          Expanded(child: _PlanningField('SCHEDULE TEMPLATE', 'MANUAL')),
          SizedBox(width: 8),
          Expanded(child: _PlanningField('START', '08:00')),
          SizedBox(width: 8),
          Expanded(child: _PlanningField('END', '16:00')),
        ],
      ),
    ],
  );
}

final class _PlanningField extends StatelessWidget {
  const _PlanningField(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
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
    for (final day in [1, 5, 8, 12, 15, 19, 22, 26, 29])
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
  _ProofAssetBundle({required this.frameFile});

  final File frameFile;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'packages/clinical_calendar_presentation/$graphiteFrameAsset') {
      return ByteData.sublistView(await frameFile.readAsBytes());
    }
    return rootBundle.load(key);
  }
}

Future<void> _loadProofFonts() async {
  var root = Directory.current.absolute;
  while (root.parent.path != root.path) {
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}.tooling${Platform.pathSeparator}'
      'flutter${Platform.pathSeparator}bin${Platform.pathSeparator}cache'
      '${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
      'material_fonts',
    );
    final roboto = File(
      '${directory.path}${Platform.pathSeparator}roboto-regular.ttf',
    );
    final icons = File(
      '${directory.path}${Platform.pathSeparator}materialicons-regular.otf',
    );
    if (roboto.existsSync() && icons.existsSync()) {
      await _loadFont('ProofRoboto', roboto);
      await _loadFont('MaterialIcons', icons);
      return;
    }
    root = root.parent;
  }
  throw StateError('Bundled Flutter proof fonts were not found.');
}

Future<void> _loadFont(String family, File file) async {
  final bytes = await file.readAsBytes();
  await (FontLoader(
    family,
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

void _noop() {}

void _ignoreDestination(ClinicalCalendarDestination _) {}
