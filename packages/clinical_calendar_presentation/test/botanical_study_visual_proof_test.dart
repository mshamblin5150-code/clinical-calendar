import 'dart:io';

import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'support/proof_fonts.dart';

const _studentId = '00000000-0000-4000-8000-000000000239';
final _today = LocalDate(2026, 8, 6);

void main() {
  setUpAll(prepareProofEnvironment);

  test('committed landscape proof retains approved concept structure', () {
    final concept = img.decodePng(
      _findWorkspaceFile(
        'docs/concepts/themes/botanical-study/'
        'calendar-dashboard-concept-v1.png',
      ).readAsBytesSync(),
    )!;
    final runtime = img.decodePng(
      _findWorkspaceFile(
        'packages/clinical_calendar_presentation/test/goldens/'
        'botanical_study/botanical_study_landscape_1586x992.png',
      ).readAsBytesSync(),
    )!;

    expect(concept.width, 1586);
    expect(concept.height, 992);
    expect(runtime.width, concept.width);
    expect(runtime.height, concept.height);
    expect(
      _downsampledColorSimilarity(concept, runtime),
      greaterThanOrEqualTo(.94),
    );
    const regions =
        <String, ({int x, int y, int width, int height, double minimum})>{
          'crown': (x: 0, y: 0, width: 1586, height: 66, minimum: .95),
          'placements': (x: 61, y: 66, width: 307, height: 834, minimum: .94),
          'calendar': (x: 378, y: 66, width: 767, height: 561, minimum: .93),
          'planning': (x: 378, y: 638, width: 767, height: 262, minimum: .925),
          'progress': (x: 1154, y: 66, width: 401, height: 501, minimum: .95),
          'attention': (x: 1154, y: 577, width: 401, height: 323, minimum: .94),
          'navigation': (x: 0, y: 912, width: 1586, height: 80, minimum: .95),
        };
    for (final MapEntry(key: name, value: region) in regions.entries) {
      expect(
        _regionColorSimilarity(concept, runtime, region),
        greaterThanOrEqualTo(region.minimum),
        reason: '$name must match the approved concept independently',
      );
    }
  });

  testWidgets('Botanical Study landscape matches its approved composition', (
    tester,
  ) async {
    await _pumpProof(tester, const Size(1586, 992));

    await expectLater(
      find.byKey(const Key('botanical-study-proof')),
      matchesGoldenFile(
        'goldens/botanical_study/botanical_study_landscape_1586x992.png',
      ),
    );
  });

  testWidgets('Botanical Study portrait is an intentional tablet console', (
    tester,
  ) async {
    await _pumpProof(tester, const Size(900, 1440));

    await expectLater(
      find.byKey(const Key('botanical-study-proof')),
      matchesGoldenFile(
        'goldens/botanical_study/botanical_study_portrait_900x1440.png',
      ),
    );
  });

  testWidgets('Botanical Study remains legible at 200 percent text scale', (
    tester,
  ) async {
    await _pumpProof(
      tester,
      const Size(900, 1440),
      textScaler: const TextScaler.linear(2),
    );
    final navigation = tester.getRect(
      find.byKey(const Key('botanical-study-bottom-navigation')),
    );
    expect(navigation.top, greaterThan(1300));
    expect(navigation.bottom, lessThanOrEqualTo(1440));
    expect(
      find.byKey(const Key('botanical-study-portrait-scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('botanical-study-calendar-horizontal-scroll')),
      findsOneWidget,
    );
    expect(find.byTooltip('Open menu'), findsOneWidget);
    expect(find.byTooltip('Add schedule'), findsOneWidget);
    for (final (key, label) in const [
      (Key('planning-proof-add-schedule'), 'ADD SCHEDULE'),
      (Key('planning-proof-incomplete'), 'PLANNING INCOMPLETE'),
      (Key('planning-proof-collapse'), 'COLLAPSE'),
    ]) {
      final buttonRect = tester.getRect(find.byKey(key));
      final labelRect = tester.getRect(
        find.descendant(of: find.byKey(key), matching: find.text(label)),
      );
      expect(labelRect.left, greaterThanOrEqualTo(buttonRect.left));
      expect(labelRect.top, greaterThanOrEqualTo(buttonRect.top));
      expect(labelRect.right, lessThanOrEqualTo(buttonRect.right));
      expect(labelRect.bottom, lessThanOrEqualTo(buttonRect.bottom));
    }

    await expectLater(
      find.byKey(const Key('botanical-study-proof')),
      matchesGoldenFile(
        'goldens/botanical_study/'
        'botanical_study_portrait_200_percent_900x1440.png',
      ),
    );
  });

  testWidgets('Botanical Study gallery thumbnail uses its real renderer', (
    tester,
  ) async {
    await _pumpProof(
      tester,
      themeGalleryViewport,
      renderSize: const Size(1586, 992),
    );

    await expectLater(
      find.byKey(const Key('botanical-study-proof')),
      matchesGoldenFile('goldens/botanical_study_runtime_thumbnail.png'),
    );
  });
}

Future<void> _pumpProof(
  WidgetTester tester,
  Size size, {
  TextScaler textScaler = TextScaler.noScaling,
  Size? renderSize,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final proofAssets = _ProofAssetBundle(
    frameFile: _findWorkspaceFile(
      'packages/clinical_calendar_presentation/$botanicalStudyFrameAsset',
    ),
    chassisFile: _findWorkspaceFile(
      'packages/clinical_calendar_presentation/'
      '$botanicalStudyLandscapeChassisAsset',
    ),
    logoFile: _findWorkspaceFile(
      'packages/clinical_calendar_presentation/$botanicalStudyAxionLogoAsset',
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
        botanicalStudyFrameAsset,
        package: 'clinical_calendar_presentation',
      ),
      preloadKey.currentContext!,
    );
    await precacheImage(
      const AssetImage(
        botanicalStudyLandscapeChassisAsset,
        package: 'clinical_calendar_presentation',
      ),
      preloadKey.currentContext!,
    );
    await precacheImage(
      const AssetImage(
        botanicalStudyAxionLogoAsset,
        package: 'clinical_calendar_presentation',
      ),
      preloadKey.currentContext!,
    );
  });
  await tester.pump();
  expect(tester.takeException(), isNull);
  const themeBundle = BotanicalStudyThemeBundle();
  final baseTheme = themeBundle.standardPresentation.createThemeData();
  final proofTheme = baseTheme.copyWith(
    textTheme: baseTheme.textTheme.apply(fontFamily: 'ProofRoboto'),
    primaryTextTheme: baseTheme.primaryTextTheme.apply(
      fontFamily: 'ProofRoboto',
    ),
  );
  final source = _ProofCalendarDataSource();
  final slots = ResponsiveShellSlots(
    centralContent: CalendarPeriodView(
      dataSource: source,
      studentId: _studentId,
      today: _today,
      initialAnchor: _today,
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
          key: const Key('botanical-study-proof'),
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox.fromSize(
              size: renderSize ?? size,
              child: themeBundle.shellRenderer.build(
                slots: slots,
                environmentName: 'BOTANICAL STUDY',
                onOpenMenu: _noop,
                onOpenDestination: _ignoreDestination,
                onOpenAttention: _noop,
                onAddSchedule: _noop,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  for (final ownerKey in const [
    Key('botanical-study-portrait-scroll'),
    Key('botanical-study-calendar-horizontal-scroll'),
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
  _ProofAssetBundle({
    required this.frameFile,
    required this.chassisFile,
    required this.logoFile,
  });

  final File frameFile;
  final File chassisFile;
  final File logoFile;

  @override
  Future<ByteData> load(String key) async {
    if (key ==
        'packages/clinical_calendar_presentation/$botanicalStudyFrameAsset') {
      return ByteData.sublistView(
        Uint8List.fromList(await frameFile.readAsBytes()),
      );
    }
    if (key ==
        'packages/clinical_calendar_presentation/'
            '$botanicalStudyLandscapeChassisAsset') {
      return ByteData.sublistView(
        Uint8List.fromList(await chassisFile.readAsBytes()),
      );
    }
    if (key ==
        'packages/clinical_calendar_presentation/$botanicalStudyAxionLogoAsset') {
      return ByteData.sublistView(
        Uint8List.fromList(await logoFile.readAsBytes()),
      );
    }
    return rootBundle.load(key);
  }
}

final class _PlacementsProof extends StatelessWidget {
  const _PlacementsProof();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Padding(
        padding: EdgeInsets.only(left: 22),
        child: _SectionTitle('MY PLACEMENTS'),
      ),
      const SizedBox(height: 30),
      const SizedBox(
        height: 292,
        child: _PlacementCard(
          name: 'ACCEPTANCE FAMILY MEDICINE',
          accent: BotanicalStudyColors.clinical,
          completed: '0 hr',
          scheduled: '8 hr',
          unscheduled: '82 hr',
        ),
      ),
      const SizedBox(height: 25),
      const SizedBox(
        height: 292,
        child: _PlacementCard(
          name: 'INTERNAL MEDICINE',
          accent: BotanicalStudyColors.workAccent,
          completed: '0 hr',
          scheduled: '8 hr',
          unscheduled: '82 hr',
        ),
      ),
      const Spacer(),
    ],
  );
}

final class _PlacementCard extends StatelessWidget {
  const _PlacementCard({
    required this.name,
    required this.accent,
    required this.completed,
    required this.scheduled,
    required this.unscheduled,
  });

  final String name;
  final Color accent;
  final String completed;
  final String scheduled;
  final String unscheduled;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 15, 16, 14),
    decoration: BoxDecoration(
      color: BotanicalStudyColors.canvas.withValues(alpha: .42),
      border: Border(
        left: BorderSide(color: accent, width: 8),
        top: BorderSide(
          color: BotanicalStudyColors.outline.withValues(alpha: .5),
        ),
        right: BorderSide(
          color: BotanicalStudyColors.outline.withValues(alpha: .5),
        ),
        bottom: BorderSide(
          color: BotanicalStudyColors.outline.withValues(alpha: .5),
        ),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: BotanicalStudyColors.clinical,
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
        ),
        const SizedBox(height: 12),
        Text('$completed / 90 hr completed'),
        const Spacer(),
        Center(
          child: SizedBox.square(
            dimension: 98,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 0,
                  strokeWidth: 8,
                  color: accent,
                  backgroundColor: BotanicalStudyColors.outline.withValues(
                    alpha: .32,
                  ),
                ),
                Center(
                  child: Text(
                    '0%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: BotanicalStudyColors.clinical,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        const Divider(),
        _MetricLine('$scheduled scheduled', BotanicalStudyColors.scheduled),
        _MetricLine(
          '$unscheduled unscheduled',
          BotanicalStudyColors.unscheduled,
        ),
      ],
    ),
  );
}

final class _MetricLine extends StatelessWidget {
  const _MetricLine(this.label, this.color, {this.value, this.inset = 0});

  final String label;
  final Color color;
  final String? value;
  final double inset;

  IconData get _icon => switch (label) {
    final label when label.contains('Target') => Icons.track_changes_outlined,
    final label when label.startsWith('Completed') => Icons.add_box_outlined,
    final label
        when label.startsWith('Unscheduled') || label.contains('unscheduled') =>
      Icons.circle_outlined,
    final label
        when label.startsWith('Scheduled') || label.contains('scheduled') =>
      Icons.calendar_today_outlined,
    _ => Icons.circle_outlined,
  };

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: 7, left: inset, right: inset),
    child: Row(
      children: [
        Icon(_icon, color: color, size: 19),
        const SizedBox(width: 24),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        if (value case final value?)
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

final class _PlanningProof extends StatelessWidget {
  const _PlanningProof();

  @override
  Widget build(BuildContext context) {
    final enlarged = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final title = Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('PLANNING'),
          const SizedBox(height: 2),
          Text(
            'Build the monthly plan in this in-flow region.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
    final actions = Row(
      children: [
        Expanded(
          flex: 4,
          child: SizedBox(
            height: enlarged ? 72 : 34,
            child: OutlinedButton(
              key: const Key('planning-proof-add-schedule'),
              onPressed: _noop,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                backgroundColor: BotanicalStudyColors.clinical,
                foregroundColor: BotanicalStudyColors.canvas,
              ),
              child: const Text('ADD SCHEDULE', textAlign: TextAlign.center),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 6,
          child: SizedBox(
            height: enlarged ? 72 : 34,
            child: OutlinedButton(
              key: const Key('planning-proof-incomplete'),
              onPressed: _noop,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                foregroundColor: BotanicalStudyColors.urgent,
                side: const BorderSide(color: BotanicalStudyColors.urgent),
              ),
              child: const Text(
                'PLANNING INCOMPLETE',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 3,
          child: SizedBox(
            height: enlarged ? 72 : 34,
            child: OutlinedButton(
              key: const Key('planning-proof-collapse'),
              onPressed: _noop,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: const Text('COLLAPSE', textAlign: TextAlign.center),
            ),
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (enlarged) ...[
          title,
          const SizedBox(height: 10),
          actions,
        ] else
          Row(
            children: [
              Expanded(child: title),
              SizedBox(
                width: 122,
                height: 34,
                child: Transform.translate(
                  offset: const Offset(0, 3),
                  child: OutlinedButton(
                    key: const Key('planning-proof-add-schedule'),
                    onPressed: _noop,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      backgroundColor: BotanicalStudyColors.clinical,
                      foregroundColor: BotanicalStudyColors.canvas,
                    ),
                    child: const Text('ADD SCHEDULE'),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 176,
                height: 34,
                child: Transform.translate(
                  offset: const Offset(0, 3),
                  child: OutlinedButton(
                    key: const Key('planning-proof-incomplete'),
                    onPressed: _noop,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      foregroundColor: BotanicalStudyColors.urgent,
                      side: const BorderSide(
                        color: BotanicalStudyColors.urgent,
                      ),
                    ),
                    child: const Text('PLANNING INCOMPLETE'),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 80,
                height: 34,
                child: Transform.translate(
                  offset: const Offset(0, 3),
                  child: OutlinedButton(
                    key: const Key('planning-proof-collapse'),
                    onPressed: _noop,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text('COLLAPSE'),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 11),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 6, 14, 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: BotanicalStudyColors.outline.withValues(alpha: .55),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _PlanningStep('1', 'TYPE & TIME'),
                    SizedBox(width: 22),
                    Text('0 selected dates'),
                  ],
                ),
                SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ChoiceChip(
                          'CLINICAL\nSESSION',
                          BotanicalStudyColors.clinical,
                          icon: Icons.local_hospital_outlined,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _ChoiceChip(
                          'WORK SHIFT',
                          BotanicalStudyColors.workAccent,
                          icon: Icons.work_outline,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _ChoiceChip(
                          'PROTECTED DAY',
                          BotanicalStudyColors.protectedDayAccent,
                          icon: Icons.shield_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                _PlanningInputStrip(),
              ],
            ),
          ),
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
        backgroundColor: BotanicalStudyColors.clinical,
        foregroundColor: BotanicalStudyColors.canvas,
        child: Text(number),
      ),
      const SizedBox(width: 7),
      Text(label, style: const TextStyle(color: BotanicalStudyColors.clinical)),
    ],
  );
}

final class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip(this.label, this.color, {required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final enlarged = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final text = Text(
      label,
      textAlign: enlarged ? TextAlign.center : TextAlign.start,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .06),
        border: Border(
          left: BorderSide(color: color, width: 8),
          top: BorderSide(color: color),
          right: BorderSide(color: color),
          bottom: BorderSide(color: color),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: enlarged
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 44),
                const SizedBox(height: 8),
                Flexible(
                  child: FittedBox(fit: BoxFit.scaleDown, child: text),
                ),
              ],
            )
          : Row(
              children: [
                Icon(icon, color: color, size: 44),
                const SizedBox(width: 16),
                Expanded(child: text),
              ],
            ),
    );
  }
}

final class _PlanningInputStrip extends StatelessWidget {
  const _PlanningInputStrip();

  @override
  Widget build(BuildContext context) {
    const compactLabelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );
    final content = Row(
      children: [
        const Text('SCHEDULE TEMPLATE', style: compactLabelStyle),
        const SizedBox(width: 8),
        Container(
          width: 98,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: BotanicalStudyColors.surfaceRaised,
            border: Border.all(color: BotanicalStudyColors.outline),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.expand_more, size: 18),
          ),
        ),
        const SizedBox(width: 10),
        const Text('ENTER TIMES MANUALLY', style: compactLabelStyle),
        const SizedBox(width: 8),
        Switch(value: true, onChanged: _noopBool),
        const SizedBox(width: 14),
        const _PlanningTimeField(label: 'START', value: '08:00'),
        const SizedBox(width: 18),
        const _PlanningTimeField(label: 'END', value: '16:00'),
      ],
    );
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
      return SizedBox(
        height: 52,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: 1300, child: content),
        ),
      );
    }
    return SizedBox(height: 48, child: content);
  }
}

final class _PlanningTimeField extends StatelessWidget {
  const _PlanningTimeField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final enlarged = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final field = Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: BotanicalStudyColors.surfaceRaised,
        border: Border.all(color: BotanicalStudyColors.outline),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(child: Text(value)),
          const Icon(Icons.expand_more, size: 16),
        ],
      ),
    );
    if (enlarged) {
      return SizedBox(
        width: 220,
        child: Row(
          children: [
            Text(label),
            const SizedBox(width: 8),
            Expanded(child: field),
          ],
        ),
      );
    }
    return SizedBox(
      width: 122,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          const SizedBox(height: 2),
          field,
        ],
      ),
    );
  }
}

void _noopBool(bool _) {}

final class _InsightProof extends StatelessWidget {
  const _InsightProof();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: 488,
        child: Padding(
          padding: const EdgeInsets.only(left: 3, right: 51),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 27, top: 6),
                child: _SectionTitle('INTERNAL MEDICINE'),
              ),
              const SizedBox(height: 15),
              Transform.translate(
                offset: const Offset(7, 0),
                child: Center(
                  child: SizedBox.square(
                    dimension: 126,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: 0,
                          strokeWidth: 9,
                          color: BotanicalStudyColors.clinical,
                          backgroundColor: BotanicalStudyColors.outline
                              .withValues(alpha: .28),
                        ),
                        const Center(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '0',
                                  style: TextStyle(fontSize: 32),
                                ),
                                TextSpan(
                                  text: ' hr\n',
                                  style: TextStyle(fontSize: 15),
                                ),
                                TextSpan(
                                  text: 'completed',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: BotanicalStudyColors.clinical,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const _MetricLine(
                'Target',
                BotanicalStudyColors.text,
                value: '90 hr',
                inset: 28,
              ),
              const _MetricLine(
                'Completed',
                BotanicalStudyColors.completed,
                value: '0 hr',
                inset: 28,
              ),
              const _MetricLine(
                'Scheduled',
                BotanicalStudyColors.scheduled,
                value: '8 hr',
                inset: 28,
              ),
              const _MetricLine(
                'Unscheduled',
                BotanicalStudyColors.unscheduled,
                value: '82 hr',
                inset: 28,
              ),
              const _MetricLine(
                'Over-Target',
                BotanicalStudyColors.text,
                value: '0 hr',
                inset: 28,
              ),
              const Divider(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Icon(
                      Icons.speed_outlined,
                      color: BotanicalStudyColors.clinical,
                      size: 34,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Additional pace required',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Text(
                          '21 hr 16 min / week',
                          style: TextStyle(
                            color: BotanicalStudyColors.urgent,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 20),
              const Text('  ›   TAP WHEEL TO VIEW NEXT PLACEMENT'),
              const SizedBox(height: 12),
              const Text('  ♧   SHOW PRECEPTOR BREAKDOWN'),
            ],
          ),
        ),
      ),
      const Divider(height: 1),
      const SizedBox(height: 19),
      Row(
        children: [
          const SizedBox(width: 11),
          const Expanded(
            child: _SectionTitle(
              'NEEDS ATTENTION',
              color: BotanicalStudyColors.urgent,
            ),
          ),
          Text(
            'ON · 5',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: BotanicalStudyColors.urgent,
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
      const SizedBox(height: 9),
      Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .25),
          border: Border.all(
            color: BotanicalStudyColors.outline.withValues(alpha: .45),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: const Column(
          children: [
            _AttentionCard(
              height: 60,
              icon: Icons.warning_rounded,
              iconColor: BotanicalStudyColors.urgent,
              title: 'CLINICAL SESSION NEEDS CONFIRMATION',
              detail: 'Confirm the actual times and Preceptor',
            ),
            _AttentionCard(
              height: 60,
              icon: Icons.person,
              iconColor: BotanicalStudyColors.text,
              title: 'INITIAL SELF-ASSESSMENT',
              detail: 'Acceptance Family Medicine',
              trailing: 'Due',
            ),
            _AttentionCard(
              height: 60,
              icon: Icons.person,
              iconColor: BotanicalStudyColors.text,
              title: 'INITIAL SELF-ASSESSMENT',
              detail: 'Internal Medicine',
              trailing: 'Due',
            ),
            _AttentionCard(
              height: 70,
              icon: Icons.error_outline,
              iconColor: BotanicalStudyColors.urgent,
              title: 'PLANNING INCOMPLETE',
              detail: 'Choose one empty Protected Day',
              isLast: true,
            ),
          ],
        ),
      ),
    ],
  );
}

final class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.icon,
    required this.title,
    this.height,
    this.iconColor = BotanicalStudyColors.urgent,
    this.detail,
    this.trailing,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final double? height;
  final Color iconColor;
  final String? detail;
  final String? trailing;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        13,
        height == null ? 12 : 0,
        16,
        height == null ? 12 : 0,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(width: 20),
          Expanded(
            child: detail == null
                ? Text(title, style: Theme.of(context).textTheme.labelSmall)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail!,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
          ),
          if (trailing case final trailing?)
            Text(
              trailing,
              style: const TextStyle(
                color: BotanicalStudyColors.urgent,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(
                  color: BotanicalStudyColors.outline.withValues(alpha: .35),
                ),
        ),
      ),
      child: content,
    );
    return height == null
        ? decorated
        : SizedBox(height: height, child: decorated);
  }
}

final class _PlacementSummaryProof extends StatelessWidget {
  const _PlacementSummaryProof();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _SectionTitle('PLACEMENT STATUS'),
      SizedBox(height: 10),
      _MetricLine('42 / 90 hr completed', BotanicalStudyColors.completed),
      _MetricLine('24 hr scheduled', BotanicalStudyColors.scheduled),
      _MetricLine('24 hr unscheduled', BotanicalStudyColors.unscheduled),
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
  const _SectionTitle(this.label, {this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      color: color ?? BotanicalStudyColors.clinical,
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
    for (final day in [8, 15, 20, 29])
      CalendarEntry(
        id: 'protected-$day',
        kind: CalendarEntryKind.protectedDay,
        startDate: LocalDate(2026, 8, day),
        endDate: LocalDate(2026, 8, day),
        title: 'Protected Day',
        statusLabel: 'Protected',
      ),
    for (final day in [4, 6, 10, 13, 18, 22, 25, 27])
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
    for (final day in [3, 5, 7, 11, 12, 14, 17, 19, 21, 24, 26, 28])
      CalendarEntry(
        id: 'clinical-$day',
        kind: CalendarEntryKind.clinicalSession,
        startDate: LocalDate(2026, 8, day),
        endDate: LocalDate(2026, 8, day),
        startTime: LocalTime(8, 0),
        endTime: LocalTime(16, 0),
        title: 'Clinical Session',
        assignment: 'Internal Medicine - Jordan Lee',
        statusLabel: 'Scheduled',
      ),
  ]);
}

void _noop() {}

void _ignoreDestination(ClinicalCalendarDestination _) {}

double _downsampledColorSimilarity(img.Image concept, img.Image runtime) {
  final expected = img.copyResize(concept, width: 96, height: 60);
  final actual = img.copyResize(runtime, width: 96, height: 60);
  var channelError = 0.0;
  for (var y = 0; y < expected.height; y++) {
    for (var x = 0; x < expected.width; x++) {
      final left = expected.getPixel(x, y);
      final right = actual.getPixel(x, y);
      channelError += (left.r - right.r).abs();
      channelError += (left.g - right.g).abs();
      channelError += (left.b - right.b).abs();
    }
  }
  return 1 - channelError / (expected.width * expected.height * 3 * 255);
}

double _regionColorSimilarity(
  img.Image concept,
  img.Image runtime,
  ({int x, int y, int width, int height, double minimum}) region,
) {
  final expected = img.copyCrop(
    concept,
    x: region.x,
    y: region.y,
    width: region.width,
    height: region.height,
  );
  final actual = img.copyCrop(
    runtime,
    x: region.x,
    y: region.y,
    width: region.width,
    height: region.height,
  );
  return _downsampledColorSimilarity(expected, actual);
}
