import 'dart:io';
import 'dart:math' as math;

import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/proof_fonts.dart';

const _studentId = '00000000-0000-4000-8000-000000000137';
final _today = LocalDate(2026, 8, 6);

void main() {
  setUpAll(_loadProofFonts);

  testWidgets('Field Archive landscape matches its approved composition', (
    tester,
  ) async {
    await _pumpProof(tester, const Size(1536, 1024));

    await expectLater(
      find.byKey(const Key('heritage-field-notes-proof')),
      matchesGoldenFile(
        'goldens/heritage_field_notes/heritage_field_notes_landscape_1536x1024.png',
      ),
    );
  });

  testWidgets('Field Archive portrait is an intentional tablet console', (
    tester,
  ) async {
    await _pumpProof(tester, const Size(900, 1440));

    await expectLater(
      find.byKey(const Key('heritage-field-notes-proof')),
      matchesGoldenFile(
        'goldens/heritage_field_notes/heritage_field_notes_portrait_900x1440.png',
      ),
    );
  });

  testWidgets('Field Archive remains legible at 200 percent text scale', (
    tester,
  ) async {
    await _pumpProof(
      tester,
      const Size(900, 1440),
      textScaler: const TextScaler.linear(2),
    );
    final navigation = tester.getRect(
      find.byKey(const Key('heritage-field-notes-bottom-navigation')),
    );
    expect(navigation.top, greaterThan(1300));
    expect(navigation.bottom, lessThanOrEqualTo(1440));
    expect(
      find.byKey(const Key('heritage-field-notes-portrait-scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('heritage-field-notes-calendar-horizontal-scroll')),
      findsOneWidget,
    );
    expect(find.byTooltip('Open menu'), findsOneWidget);
    expect(find.byTooltip('Add schedule'), findsWidgets);

    await expectLater(
      find.byKey(const Key('heritage-field-notes-proof')),
      matchesGoldenFile(
        'goldens/heritage_field_notes/'
        'heritage_field_notes_portrait_200_percent_900x1440.png',
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
      'packages/clinical_calendar_presentation/$heritageFieldNotesFrameAsset',
    ),
    brandFile: _findWorkspaceFile(
      'packages/clinical_calendar_presentation/$heritageFieldNotesAxionDeltaAsset',
    ),
    chassisFile: _findWorkspaceFile(
      'packages/clinical_calendar_presentation/$heritageFieldNotesMaterialChassisAsset',
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
        heritageFieldNotesFrameAsset,
        package: 'clinical_calendar_presentation',
      ),
      preloadKey.currentContext!,
    );
    await precacheImage(
      const AssetImage(
        heritageFieldNotesAxionDeltaAsset,
        package: 'clinical_calendar_presentation',
      ),
      preloadKey.currentContext!,
    );
    await precacheImage(
      const AssetImage(
        heritageFieldNotesMaterialChassisAsset,
        package: 'clinical_calendar_presentation',
      ),
      preloadKey.currentContext!,
    );
  });
  await tester.pump();
  expect(tester.takeException(), isNull);
  const themeBundle = HeritageFieldNotesThemeBundle();
  final proofTheme = themeBundle.standardPresentation.createThemeData();
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
          key: const Key('heritage-field-notes-proof'),
          child: themeBundle.shellRenderer.build(
            slots: slots,
            environmentName: 'CC-2026-08',
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
    Key('heritage-field-notes-portrait-scroll'),
    Key('heritage-field-notes-calendar-horizontal-scroll'),
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
    required this.brandFile,
    required this.chassisFile,
  });

  final File frameFile;
  final File brandFile;
  final File chassisFile;

  @override
  Future<ByteData> load(String key) async {
    if (key ==
        'packages/clinical_calendar_presentation/$heritageFieldNotesFrameAsset') {
      return ByteData.sublistView(
        Uint8List.fromList(await frameFile.readAsBytes()),
      );
    }
    if (key ==
        'packages/clinical_calendar_presentation/$heritageFieldNotesAxionDeltaAsset') {
      return ByteData.sublistView(
        Uint8List.fromList(await brandFile.readAsBytes()),
      );
    }
    if (key ==
        'packages/clinical_calendar_presentation/$heritageFieldNotesMaterialChassisAsset') {
      return ByteData.sublistView(
        Uint8List.fromList(await chassisFile.readAsBytes()),
      );
    }
    return rootBundle.load(key);
  }
}

Future<void> _loadProofFonts() async {
  await prepareProofEnvironment();
  var root = Directory.current.absolute;
  File? fieldArchive;
  while (root.parent.path != root.path) {
    final fieldArchiveCandidate = File(
      '${root.path}${Platform.pathSeparator}packages'
      '${Platform.pathSeparator}clinical_calendar_presentation'
      '${Platform.pathSeparator}assets${Platform.pathSeparator}'
      'heritage_field_notes_fonts${Platform.pathSeparator}'
      'RobotoCondensed-Variable.ttf',
    );
    if (fieldArchiveCandidate.existsSync()) {
      fieldArchive = fieldArchiveCandidate;
    }
    if (fieldArchive != null) break;
    root = root.parent;
  }
  if (fieldArchive == null) {
    throw StateError('Field Archive proof font was not found.');
  }
  await _loadFont('FieldArchiveCondensed', fieldArchive);
}

Future<void> _loadFont(String family, File file) async {
  final bytes = Uint8List.fromList(await file.readAsBytes());
  await (FontLoader(
    family,
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

final class _PlacementsProof extends StatelessWidget {
  const _PlacementsProof();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _SectionTitle('MY PLACEMENTS'),
      const SizedBox(height: 12),
      const _PlacementCard(
        name: 'ACCEPTANCE FAMILY MEDICINE',
        accent: HeritageFieldNotesColors.clinical,
        completed: '0 hr',
        scheduled: '8 hr',
        unscheduled: '82 hr',
      ),
      const SizedBox(height: 12),
      const _PlacementCard(
        name: 'INTERNAL MEDICINE',
        accent: HeritageFieldNotesColors.clinical,
        completed: '0 hr',
        scheduled: '8 hr',
        unscheduled: '82 hr',
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
    height: 290,
    padding: const EdgeInsets.fromLTRB(24, 18, 16, 16),
    decoration: BoxDecoration(
      color: HeritageFieldNotesColors.surfaceRaised,
      border: Border.all(color: HeritageFieldNotesColors.insetBorder),
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [
        BoxShadow(
          color: Color(0x242B2117),
          blurRadius: 5,
          offset: Offset(1, 2),
        ),
      ],
    ),
    foregroundDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: accent, width: 7)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            name,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              letterSpacing: .5,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '$completed / 90 hr completed',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Spacer(),
        Center(
          child: SizedBox.square(
            dimension: 110,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: completed == '0 hr' ? 0 : .47,
                  strokeWidth: 9,
                  color: accent,
                  backgroundColor: HeritageFieldNotesColors.control,
                ),
                Center(
                  child: Text(
                    completed == '0 hr' ? '0%' : '47%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        _MetricLine(
          '$scheduled scheduled',
          HeritageFieldNotesColors.scheduled,
          icon: Icons.schedule,
        ),
        _MetricLine(
          '$unscheduled unscheduled',
          HeritageFieldNotesColors.unscheduled,
          icon: Icons.circle_outlined,
        ),
      ],
    ),
  );
}

final class _MetricLine extends StatelessWidget {
  const _MetricLine(this.label, this.color, {this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Row(
      children: [
        Icon(icon ?? Icons.circle_outlined, color: color, size: 20),
        const SizedBox(width: 9),
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
    final enlargedText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (enlargedText) ...[
              const Expanded(child: _SectionTitle('PLANNING')),
              IconButton(
                tooltip: 'Add schedule',
                onPressed: _noop,
                icon: const Icon(Icons.add),
              ),
              IconButton(
                tooltip: 'Planning incomplete',
                onPressed: _noop,
                icon: const Icon(Icons.warning_amber_outlined),
              ),
            ] else ...[
              const _SectionTitle('PLANNING'),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  'Build the monthly plan in this in-flow region.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const _PlanningAction(
                label: 'ADD SCHEDULE',
                width: 108,
                tooltip: 'Add schedule',
                color: HeritageFieldNotesColors.clinical,
              ),
              const SizedBox(width: 8),
              const _PlanningAction(
                label: 'PLANNING INCOMPLETE',
                width: 150,
                urgent: true,
              ),
              const SizedBox(width: 8),
              const _PlanningAction(
                label: 'COLLAPSE',
                width: 96,
                color: Color(0xFF6B4B22),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        if (enlargedText)
          const SizedBox(
            height: 92,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PlanningStep('1', 'TYPE & TIME'),
                  SizedBox(width: 18),
                  _ChoiceChip(
                    'WORK SHIFT',
                    HeritageFieldNotesColors.workMachinery,
                  ),
                  SizedBox(width: 8),
                  _ChoiceChip(
                    'CLINICAL SESSION',
                    HeritageFieldNotesColors.clinical,
                  ),
                  SizedBox(width: 8),
                  _ChoiceChip(
                    'PROTECTED DAY',
                    HeritageFieldNotesColors.protectedDayAccent,
                  ),
                ],
              ),
            ),
          )
        else
          const Row(
            children: [
              _PlanningStep('1', 'TYPE & TIME'),
              SizedBox(width: 18),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChoiceChip(
                      'WORK SHIFT',
                      HeritageFieldNotesColors.workMachinery,
                    ),
                    _ChoiceChip(
                      'CLINICAL SESSION',
                      HeritageFieldNotesColors.clinical,
                    ),
                    _ChoiceChip(
                      'PROTECTED DAY',
                      HeritageFieldNotesColors.protectedDayAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: _FieldProof(
                label: 'SCHEDULE TEMPLATE',
                value: 'ENTER TIMES MANUALLY',
              ),
            ),
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
  Widget build(BuildContext context) => Container(
    width: MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 260 : 180,
    padding: const EdgeInsets.only(right: 18),
    decoration: const BoxDecoration(
      border: Border(
        right: BorderSide(color: HeritageFieldNotesColors.insetBorder),
      ),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: HeritageFieldNotesColors.clinical,
          foregroundColor: Colors.white,
          child: Text(number),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            Text(
              '0 selected dates',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    ),
  );
}

final class _PlanningAction extends StatelessWidget {
  const _PlanningAction({
    required this.label,
    required this.width,
    this.tooltip,
    this.urgent = false,
    this.color,
  });

  final String label;
  final double width;
  final String? tooltip;
  final bool urgent;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: width,
      height: 38,
      child: OutlinedButton(
        onPressed: _noop,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          foregroundColor: urgent
              ? HeritageFieldNotesColors.urgent
              : color ?? HeritageFieldNotesColors.primaryText,
          side: BorderSide(
            color: urgent
                ? HeritageFieldNotesColors.urgent
                : color ?? HeritageFieldNotesColors.insetBorder,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

final class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final selected = label == 'CLINICAL SESSION';
    final foreground = selected ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? color : color.withValues(alpha: .08),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ArchiveChoiceMark(label: label, color: foreground),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

final class _ArchiveChoiceMark extends StatelessWidget {
  const _ArchiveChoiceMark({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => switch (label) {
    'WORK SHIFT' => SizedBox.square(
      dimension: 22,
      child: CustomPaint(painter: _ProofWorkStripePainter(color)),
    ),
    'PROTECTED DAY' => Icon(Icons.shield, color: color, size: 22),
    _ => Icon(Icons.add, color: color, size: 22),
  };
}

final class _ProofWorkStripePainter extends CustomPainter {
  const _ProofWorkStripePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(2, size.height * .72),
      Offset(size.width * .56, 3),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * .42, size.height - 3),
      Offset(size.width - 2, size.height * .28),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProofWorkStripePainter oldDelegate) =>
      oldDelegate.color != color;
}

final class _FieldProof extends StatelessWidget {
  const _FieldProof({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: HeritageFieldNotesColors.control,
      border: Border.all(color: HeritageFieldNotesColors.insetBorder),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
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
      const _SectionTitle('INTERNAL MEDICINE'),
      const SizedBox(height: 14),
      Center(
        child: SizedBox.square(
          dimension: 126,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const CustomPaint(painter: _ArchiveProgressDialPainter()),
              Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '0 hr\n',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: HeritageFieldNotesColors.clinical,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      TextSpan(
                        text: 'completed',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      const _MetricLine(
        'Target                 90 hr',
        HeritageFieldNotesColors.primaryText,
        icon: Icons.gps_fixed,
      ),
      const _MetricLine(
        'Completed            0 hr',
        HeritageFieldNotesColors.completed,
        icon: Icons.check_circle_outline,
      ),
      const _MetricLine(
        'Scheduled             8 hr',
        HeritageFieldNotesColors.scheduled,
        icon: Icons.schedule,
      ),
      const _MetricLine(
        'Unscheduled       82 hr',
        HeritageFieldNotesColors.unscheduled,
        icon: Icons.circle_outlined,
      ),
      const _MetricLine(
        'Over-Target          0 hr',
        HeritageFieldNotesColors.primaryText,
        icon: Icons.keyboard_double_arrow_up,
      ),
      const SizedBox(height: 10),
      const Divider(),
      const SizedBox(height: 8),
      Text(
        'Additional pace required',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Text(
        '21 hr 16 min / week',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: HeritageFieldNotesColors.clinical,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'TAP WHEEL TO VIEW NEXT PLACEMENT',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: HeritageFieldNotesColors.clinical,
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: _noop,
          style: TextButton.styleFrom(
            foregroundColor: HeritageFieldNotesColors.scheduled,
          ),
          child: const Text('SHOW PRECEPTOR BREAKDOWN'),
        ),
      ),
      const SizedBox(height: 6),
      const Divider(),
      const SizedBox(height: 10),
      Row(
        children: [
          Container(
            width: 6,
            height: 28,
            color: HeritageFieldNotesColors.insetBorder,
          ),
          const SizedBox(width: 10),
          Text(
            'NEEDS ATTENTION',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: .8,
            ),
          ),
          const Spacer(),
          Text(
            '5',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: HeritageFieldNotesColors.urgent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      const _AttentionCard(
        icon: Icons.assignment_late_outlined,
        title: 'CLINICAL SESSION NEEDS CONFIRMATION',
        subtitle: 'Confirm the actual times and supervisor',
      ),
      const _AttentionCard(
        icon: Icons.fact_check_outlined,
        title: 'INITIAL SELF-ASSESSMENT',
        subtitle: 'Acceptance Family Medicine',
        trailing: 'Due',
      ),
      const _AttentionCard(
        icon: Icons.fact_check_outlined,
        title: 'INITIAL SELF-ASSESSMENT',
        subtitle: 'Internal Medicine',
        trailing: 'Due',
      ),
      const _AttentionCard(
        icon: Icons.warning_amber_outlined,
        title: 'PLANNING INCOMPLETE',
        subtitle: 'Choose one empty Protected Day',
      ),
    ],
  );
}

final class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
    decoration: BoxDecoration(
      border: Border(
        left: const BorderSide(
          color: HeritageFieldNotesColors.urgent,
          width: 3,
        ),
        bottom: BorderSide(
          color: HeritageFieldNotesColors.insetBorder.withValues(alpha: .35),
        ),
      ),
    ),
    child: Row(
      children: [
        Icon(icon, color: HeritageFieldNotesColors.urgent, size: 24),
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
                  color: HeritageFieldNotesColors.urgent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: HeritageFieldNotesColors.urgent,
              fontWeight: FontWeight.w700,
            ),
          ),
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
      _MetricLine('42 / 90 hr completed', HeritageFieldNotesColors.completed),
      _MetricLine('24 hr scheduled', HeritageFieldNotesColors.scheduled),
      _MetricLine('24 hr unscheduled', HeritageFieldNotesColors.unscheduled),
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
      color: HeritageFieldNotesColors.primaryText,
      letterSpacing: 1.7,
      fontWeight: FontWeight.w700,
    ),
  );
}

final class _ArchiveProgressDialPainter extends CustomPainter {
  const _ArchiveProgressDialPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 5;
    final paint = Paint()
      ..color = HeritageFieldNotesColors.primaryText
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const marks = 56;
    for (var index = 0; index < marks; index++) {
      final angle = index * math.pi * 2 / marks;
      final outside = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final inside = Offset(
        center.dx + math.cos(angle) * (radius - 2),
        center.dy + math.sin(angle) * (radius - 2),
      );
      canvas.drawLine(inside, outside, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArchiveProgressDialPainter oldDelegate) =>
      false;
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
    for (final day in [4, 7, 11, 14, 17, 21, 25, 28])
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
    for (final day in [3, 10, 13, 20, 24, 27])
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
