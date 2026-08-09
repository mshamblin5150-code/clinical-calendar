import 'dart:io';
import 'dart:ui' as ui;

import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'support/proof_fonts.dart';

const _studentId = '00000000-0000-4000-8000-000000000128';
final _today = LocalDate(2026, 8, 6);

void main() {
  setUpAll(prepareProofEnvironment);

  testWidgets('Graphite landscape is the approved precision instrument', (
    tester,
  ) async {
    await _pumpProof(tester, const Size(1536, 1024));

    expect(find.byKey(const Key('graphite-landscape-rails')), findsOneWidget);

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

    final delta = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('graphite-command-crown')),
        matching: find.byType(Image),
      ),
    );
    expect(
      delta.color,
      isNull,
      reason: 'Preserve the supplied metallic delta.',
    );

    await expectLater(
      find.byKey(const Key('graphite-proof')),
      matchesGoldenFile('goldens/graphite/graphite_landscape_1536x1024.png'),
    );
  });

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
      greaterThanOrEqualTo(.93),
      reason: 'mean channel similarity was ${comparison.meanChannelSimilarity}',
    );
    expect(
      comparison.closePixelRatio,
      greaterThanOrEqualTo(.82),
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

    expect(comparison.meanChannelSimilarity, lessThan(.93));
  });

  test(
    'Graphite delta is a transparent emblem rather than a tinted rectangle',
    () {
      final deltaFile = _findWorkspaceFile(
        'packages/clinical_calendar_presentation/$graphiteDeltaAsset',
      );
      final delta = img.decodePng(deltaFile.readAsBytesSync());
      expect(delta, isNotNull);
      var visiblePixels = 0;
      for (final pixel in delta!) {
        if (pixel.a > 0) visiblePixels++;
      }
      expect(delta.getPixel(0, 0).a, 0);
      expect(delta.getPixel(delta.width - 1, 0).a, 0);
      expect(delta.getPixel(0, delta.height - 1).a, 0);
      expect(delta.getPixel(delta.width - 1, delta.height - 1).a, 0);
      expect(visiblePixels / (delta.width * delta.height), lessThan(.45));
    },
  );

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
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final proofAssets = _ProofAssetBundle(
    frameFile: _findWorkspaceFile(
      'packages/clinical_calendar_presentation/$graphiteFrameAsset',
    ),
    deltaFile: _findWorkspaceFile(
      'packages/clinical_calendar_presentation/$graphiteDeltaAsset',
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
    await precacheImage(
      const AssetImage(
        graphiteDeltaAsset,
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

final class _PlacementsProof extends StatelessWidget {
  const _PlacementsProof();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ProofTitle('MY PLACEMENTS'),
        const SizedBox(height: 26),
        _PlacementCard(
          name: 'ACCEPTANCE FAMILY MEDICINE',
          progress: 0,
          accent: context.clinicalColors.clinical,
          detail: '0 hr / 90 hr completed\n8 hr scheduled\n82 hr unscheduled',
        ),
        const SizedBox(height: 22),
        _PlacementCard(
          name: 'INTERNAL MEDICINE',
          progress: 0,
          accent: context.clinicalColors.workMachinery,
          detail: '0 hr / 90 hr completed\n8 hr scheduled\n82 hr unscheduled',
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
  Widget build(BuildContext context) => SizedBox(
    height: 258,
    child: Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: context.clinicalColors.insetBorder.withValues(alpha: .72),
        ),
        borderRadius: BorderRadius.circular(8),
        color: context.clinicalColors.structureRaised,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            right: null,
            child: Container(width: 4, color: accent),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 7),
                Text(
                  detail.split('\n').first,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Center(
                  child: SizedBox.square(
                    dimension: 104,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          color: accent,
                          backgroundColor: const Color(0xFF44494D),
                        ),
                        Center(
                          child: Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  detail.split('\n').skip(1).join('\n'),
                  style: Theme.of(context).textTheme.bodyMedium,
                  strutStyle: const StrutStyle(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
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
            dimension: 126,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 0,
                  strokeWidth: 8,
                  color: context.clinicalColors.clinical,
                  backgroundColor: context.clinicalColors.insetBorder,
                ),
                const Center(
                  child: Text('0 hr\ncompleted', textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Target                                      90 hr'),
        const Text('Completed                                  0 hr'),
        const Text('Scheduled                                  8 hr'),
        const Text('Unscheduled                            82 hr'),
        const Text('Over-Target                                0 hr'),
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
        const SizedBox(height: 8),
        Text(
          'TAP WHEEL TO VIEW NEXT PLACEMENT',
          style: TextStyle(color: context.clinicalColors.clinical),
        ),
        const SizedBox(height: 8),
        Text(
          'SHOW PRECEPTOR BREAKDOWN',
          style: TextStyle(color: context.clinicalColors.scheduled),
        ),
        const SizedBox(height: 60),
        const Divider(),
        const _ProofTitle('NEEDS ATTENTION  •  5'),
        const SizedBox(height: 8),
        for (final label in const [
          'Clinical Session needs confirmation',
          'Initial Self-Assessment — Due',
          'Initial Self-Assessment — Internal Medicine',
          'Planning incomplete',
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
    if (key == 'packages/clinical_calendar_presentation/$graphiteDeltaAsset') {
      return ByteData.sublistView(await deltaFile.readAsBytes());
    }
    return rootBundle.load(key);
  }
}

void _noop() {}

void _ignoreDestination(ClinicalCalendarDestination _) {}
