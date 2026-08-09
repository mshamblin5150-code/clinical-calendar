import 'dart:io';

import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/proof_fonts.dart';

const _studentId = '00000000-0000-4000-8000-000000000133';
final _today = LocalDate(2026, 8, 5);

void main() {
  setUpAll(prepareProofEnvironment);

  testWidgets('Federation Classic landscape matches its approved composition', (
    tester,
  ) async {
    await _pumpProof(tester, const Size(1586, 992));

    expect(find.text('MY PLACEMENTS'), findsOneWidget);
    expect(find.text('AUGUST 2026'), findsOneWidget);
    expect(find.text('PLANNING'), findsOneWidget);
    expect(find.text('NEEDS ATTENTION'), findsOneWidget);
    final title = tester.getRect(
      find.byKey(const Key('calendar-period-title')),
    );
    final switcher = tester.getRect(
      find.byKey(const Key('calendar-period-switcher')),
    );
    expect(title.center.dx, closeTo(774, 3));
    expect(title.center.dy, closeTo(141, 3));
    expect(switcher.left, closeTo(593, 5));
    expect(switcher.top, closeTo(158, 3));
    expect(
      find.byKey(const Key('calendar-day-2026-09-12')),
      findsOneWidget,
      reason: 'The approved concept shows seven complete Calendar rows.',
    );
    expect(find.text('SUNDAY'), findsNothing);
    for (final (index, expectedCenter) in const [
      (0, 227.0),
      (1, 510.0),
      (2, 790.0),
      (3, 1068.0),
      (4, 1314.0),
    ]) {
      expect(
        tester
            .getRect(find.byKey(Key('federation-classic-navigation-$index')))
            .center
            .dx,
        closeTo(expectedCenter, 3),
      );
    }
    final todayControl = find.byKey(
      const Key('federation-classic-navigation-0'),
    );
    final todayIcon = tester.getRect(
      find.descendant(
        of: todayControl,
        matching: find.byIcon(Icons.today_outlined),
      ),
    );
    final todayLabel = tester.getRect(
      find.descendant(of: todayControl, matching: find.text('TODAY')),
    );
    expect(todayIcon.bottom, lessThan(todayLabel.top));

    await expectLater(
      find.byKey(const Key('federation-classic-proof')),
      matchesGoldenFile(
        'goldens/federation_classic_v6/federation_classic_landscape_1586x992.png',
      ),
    );
  });

  testWidgets('Federation Classic portrait is an intentional tablet console', (
    tester,
  ) async {
    await _pumpProof(tester, const Size(900, 1440));

    await expectLater(
      find.byKey(const Key('federation-classic-proof')),
      matchesGoldenFile(
        'goldens/federation_classic_v6/federation_classic_portrait_900x1440.png',
      ),
    );
  });

  testWidgets('Federation Classic remains legible at 200 percent text scale', (
    tester,
  ) async {
    await _pumpProof(
      tester,
      const Size(900, 1440),
      textScaler: const TextScaler.linear(2),
    );
    final navigation = tester.getRect(
      find.byKey(const Key('federation-classic-bottom-navigation')),
    );
    final calendar = tester.getRect(
      find.byKey(const Key('federation-classic-calendar-bay')),
    );
    expect(navigation.right, lessThan(calendar.left));
    expect(navigation.bottom, lessThanOrEqualTo(1440));
    expect(
      find.byKey(const Key('federation-classic-portrait-scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('federation-classic-calendar-horizontal-scroll')),
      findsOneWidget,
    );
    expect(find.byTooltip('Open menu'), findsOneWidget);
    expect(find.byTooltip('Add schedule'), findsOneWidget);

    await expectLater(
      find.byKey(const Key('federation-classic-proof')),
      matchesGoldenFile(
        'goldens/federation_classic_v6/'
        'federation_classic_portrait_200_percent_900x1440.png',
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
      'packages/clinical_calendar_presentation/$federationClassicFrameAsset',
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
    for (final asset in const [
      federationClassicFrameAsset,
      federationClassicRailNineSliceAsset,
    ]) {
      await precacheImage(
        AssetImage(asset, package: 'clinical_calendar_presentation'),
        preloadKey.currentContext!,
      );
    }
  });
  await tester.pump();
  expect(tester.takeException(), isNull);
  const themeBundle = FederationClassicThemeBundle();
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
      backgroundColor: FederationClassicColors.scheduled,
      child: Text(
        'AB',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
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
          key: const Key('federation-classic-proof'),
          child: Stack(
            children: [
              Positioned.fill(
                child: themeBundle.shellRenderer.build(
                  slots: slots,
                  environmentName: 'FEDERATION CLASSIC',
                  onOpenMenu: _noop,
                  onOpenDestination: _ignoreDestination,
                  onOpenAttention: _noop,
                  onAddSchedule: _noop,
                ),
              ),
              if (size.width > size.height) const _AndroidStatusBarProof(),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  for (final ownerKey in const [
    Key('federation-classic-portrait-scroll'),
    Key('federation-classic-calendar-horizontal-scroll'),
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

final class _AndroidStatusBarProof extends StatelessWidget {
  const _AndroidStatusBarProof();

  @override
  Widget build(BuildContext context) => const Positioned(
    left: 14,
    top: 8,
    right: 14,
    height: 22,
    child: IgnorePointer(
      child: Row(
        children: [
          Text(
            '6:10',
            style: TextStyle(
              fontFamily: 'ProofRoboto',
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 28),
          Text(
            'Wed, Aug 5',
            style: TextStyle(
              fontFamily: 'ProofRoboto',
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          Spacer(),
          Icon(Icons.wifi, size: 14, color: Colors.white),
          SizedBox(width: 5),
          Icon(Icons.battery_full, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text(
            '100%',
            style: TextStyle(
              fontFamily: 'ProofRoboto',
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
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
    if (key ==
        'packages/clinical_calendar_presentation/$federationClassicFrameAsset') {
      return ByteData.sublistView(
        Uint8List.fromList(await frameFile.readAsBytes()),
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
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(child: _SectionTitle('MY PLACEMENTS')),
            Icon(
              Icons.settings_outlined,
              size: 22,
              color: FederationClassicColors.workAccent,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const _PlacementCard(
        name: 'Acceptance\nFamily Medicine',
        accent: FederationClassicColors.workAccent,
        completed: '0 hr',
        scheduled: '8 hr',
      ),
      const SizedBox(height: 12),
      const _PlacementCard(
        name: 'Internal Medicine',
        accent: FederationClassicColors.clinical,
        completed: '0 hr',
        scheduled: '8 hr',
      ),
      const Spacer(),
      Text(
        'TAP A PLACEMENT FOR DETAILS',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: FederationClassicColors.workAccent,
          letterSpacing: 1.1,
        ),
      ),
    ],
  );
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
      color: FederationClassicColors.canvas.withValues(alpha: .68),
      border: Border.all(color: accent.withValues(alpha: .8)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                border: Border.all(color: accent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.medical_services_outlined, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(height: 1.25),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _MetricLine('$completed / 90 hr completed', accent),
        _MetricLine('$scheduled scheduled', FederationClassicColors.scheduled),
        const _MetricLine(
          '82 hr unscheduled',
          FederationClassicColors.unscheduled,
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
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 14),
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
      const Row(
        children: [
          _SectionTitle('PLANNING'),
          SizedBox(width: 12),
          Expanded(child: _AccentRule(FederationClassicColors.workAccent)),
        ],
      ),
      const SizedBox(height: 5),
      Text(
        'Build the monthly plan in this in-flow region.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 7),
      const Row(
        children: [
          Expanded(
            child: _ProofAction(
              icon: Icons.add,
              label: 'ADD SCHEDULE',
              filled: true,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _ProofAction(
              icon: Icons.warning_amber_outlined,
              label: 'PLANNING INCOMPLETE',
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _ProofAction(
              icon: Icons.keyboard_arrow_up,
              label: 'COLLAPSE',
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            border: Border.all(color: FederationClassicColors.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: _PlanningStep('1', 'TYPE & TIME')),
              const SizedBox(height: 3),
              Text(
                '0 selected dates',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 3),
              const Row(
                children: [
                  Expanded(
                    child: _ChoiceChip(
                      'WORK SHIFT',
                      FederationClassicColors.workAccent,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _ChoiceChip(
                      'CLINICAL SESSION',
                      FederationClassicColors.clinical,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _ChoiceChip(
                      'PROTECTED DAY',
                      FederationClassicColors.protectedDayAccent,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Row(
                children: [
                  Expanded(
                    child: _FieldProof(
                      label: 'SCHEDULE TEMPLATE',
                      value: 'ENTER TIMES MANUALLY',
                    ),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 120,
                    child: _FieldProof(label: 'START', value: '08:00'),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 120,
                    child: _FieldProof(label: 'END', value: '17:00'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

final class _ProofAction extends StatelessWidget {
  const _ProofAction({
    required this.icon,
    required this.label,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    decoration: BoxDecoration(
      color: filled ? FederationClassicColors.scheduled : Colors.transparent,
      border: Border.all(color: FederationClassicColors.outline),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: filled ? Colors.black : null),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.fade,
            style: TextStyle(color: filled ? Colors.black : null),
          ),
        ),
      ],
    ),
  );
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
        foregroundColor: FederationClassicColors.clinical,
        child: Text(number),
      ),
      const SizedBox(width: 7),
      Text(
        label,
        style: const TextStyle(color: FederationClassicColors.clinical),
      ),
    ],
  );
}

final class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall),
  );
}

final class _FieldProof extends StatelessWidget {
  const _FieldProof({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: FederationClassicColors.surfaceHigh,
      border: Border.all(color: FederationClassicColors.outline),
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
      const Row(
        children: [
          _SectionTitle(
            'INTERNAL MEDICINE',
            color: FederationClassicColors.clinical,
          ),
          SizedBox(width: 10),
          Expanded(child: _AccentRule(FederationClassicColors.clinical)),
        ],
      ),
      const SizedBox(height: 32),
      const Row(
        children: [
          SizedBox.square(
            dimension: 142,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: .09,
                  strokeWidth: 17,
                  color: FederationClassicColors.clinical,
                  backgroundColor: FederationClassicColors.surfaceHigh,
                ),
                Center(
                  child: Text('0 hr\ncompleted', textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                _MetricLine(
                  'Target                 90 hr',
                  FederationClassicColors.text,
                ),
                _MetricLine(
                  'Completed            0 hr',
                  FederationClassicColors.completed,
                ),
                _MetricLine(
                  'Scheduled             8 hr',
                  FederationClassicColors.scheduled,
                ),
                _MetricLine(
                  'Unscheduled       82 hr',
                  FederationClassicColors.unscheduled,
                ),
                _MetricLine(
                  'Over-Target          0 hr',
                  FederationClassicColors.workAccent,
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Text(
        'Additional pace required - 21 hr 16 min / week',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 7),
      const _StatusStrip(
        'TAP WHEEL TO VIEW NEXT PLACEMENT',
        FederationClassicColors.scheduled,
      ),
      const SizedBox(height: 4),
      const _StatusStrip(
        'SHOW PRECEPTOR BREAKDOWN',
        FederationClassicColors.clinical,
      ),
      const SizedBox(height: 34),
      const Row(
        children: [
          _SectionTitle('NEEDS ATTENTION'),
          SizedBox(width: 10),
          Expanded(child: _AccentRule(FederationClassicColors.workAccent)),
        ],
      ),
      const Text(
        'ON - 5',
        style: TextStyle(color: FederationClassicColors.scheduled),
      ),
      const SizedBox(height: 5),
      const _AttentionCard(
        icon: Icons.assignment_late_outlined,
        title: 'Clinical Session needs confirmation',
        subtitle: 'Confirm the actual times and supervisors.',
      ),
      const _AttentionCard(
        icon: Icons.fact_check_outlined,
        title: 'INITIAL SELF-ASSESSMENT',
        subtitle: 'Acceptance Family Medicine - Due',
      ),
      const _AttentionCard(
        icon: Icons.fact_check_outlined,
        title: 'INITIAL SELF-ASSESSMENT',
        subtitle: 'Internal Medicine - Due',
      ),
      const _AttentionCard(
        icon: Icons.warning_amber_outlined,
        title: 'Planning Incomplete',
        subtitle: 'Choose one empty Protected Day',
      ),
      const Spacer(),
      const Row(
        children: [
          Text(
            'OPEN ATTENTION CENTER',
            style: TextStyle(color: FederationClassicColors.scheduled),
          ),
          SizedBox(width: 10),
          Expanded(child: _AccentRule(FederationClassicColors.scheduled)),
        ],
      ),
    ],
  );
}

final class _AccentRule extends StatelessWidget {
  const _AccentRule(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 10,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

final class _StatusStrip extends StatelessWidget {
  const _StatusStrip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 27,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    alignment: Alignment.centerLeft,
    color: color,
    child: Text(
      label,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
    ),
  );
}

final class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 5),
    constraints: BoxConstraints(
      minHeight: subtitle == null
          ? 48
          : title.startsWith('Clinical Session')
          ? 84
          : 62,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      border: Border.all(
        color: FederationClassicColors.outline.withValues(alpha: .35),
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    foregroundDecoration: const BoxDecoration(
      border: Border(
        left: BorderSide(color: FederationClassicColors.urgent, width: 3),
      ),
    ),
    child: Row(
      children: [
        Icon(icon, color: FederationClassicColors.clinical, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontSize: 13),
              ),
              if (subtitle case final subtitle?) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
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
      _MetricLine('42 / 90 hr completed', FederationClassicColors.completed),
      _MetricLine('24 hr scheduled', FederationClassicColors.scheduled),
      _MetricLine('24 hr unscheduled', FederationClassicColors.unscheduled),
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
  const _SectionTitle(
    this.label, {
    this.color = FederationClassicColors.workAccent,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      color: color,
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
      id: 'protected-19',
      kind: CalendarEntryKind.protectedDay,
      startDate: LocalDate(2026, 8, 19),
      endDate: LocalDate(2026, 8, 19),
      title: 'Protected Day',
      statusLabel: 'Protected',
    ),
    for (final day in [6, 17, 27])
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
    for (final day in [5, 13, 24])
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

void _noop() {}

void _ignoreDestination(ClinicalCalendarDestination _) {}
