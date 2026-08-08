import 'dart:io';

import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _studentId = '00000000-0000-4000-8000-000000000239';
final _today = LocalDate(2026, 8, 5);

void main() {
  setUpAll(_loadProofFonts);

  testWidgets('Federation 2399 landscape matches its approved composition', (
    tester,
  ) async {
    await _pumpProof(tester, const Size(1536, 1024));

    await expectLater(
      find.byKey(const Key('federation-2399-proof')),
      matchesGoldenFile(
        'goldens/federation_2399/federation_2399_landscape_1536x1024.png',
      ),
    );
  });

  testWidgets('Federation 2399 portrait is an intentional tablet console', (
    tester,
  ) async {
    await _pumpProof(tester, const Size(900, 1440));

    await expectLater(
      find.byKey(const Key('federation-2399-proof')),
      matchesGoldenFile(
        'goldens/federation_2399/federation_2399_portrait_900x1440.png',
      ),
    );
  });
}

Future<void> _pumpProof(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final proofAssets = _ProofAssetBundle(
    frameFile: _findWorkspaceFile(
      'packages/clinical_calendar_presentation/$federation2399FrameAsset',
    ),
  );
  final preloadKey = GlobalKey();
  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: proofAssets,
      child: MaterialApp(home: SizedBox(key: preloadKey)),
    ),
  );
  await tester.runAsync(
    () => precacheImage(
      const AssetImage(
        federation2399FrameAsset,
        package: 'clinical_calendar_presentation',
      ),
      preloadKey.currentContext!,
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
  const themeBundle = Federation2399ThemeBundle();
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
        home: RepaintBoundary(
          key: const Key('federation-2399-proof'),
          child: themeBundle.shellRenderer.build(
            slots: slots,
            environmentName: 'FEDERATION 2399',
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
  _ProofAssetBundle({required this.frameFile});

  final File frameFile;

  @override
  Future<ByteData> load(String key) async {
    if (key ==
        'packages/clinical_calendar_presentation/$federation2399FrameAsset') {
      return ByteData.sublistView(
        Uint8List.fromList(await frameFile.readAsBytes()),
      );
    }
    return rootBundle.load(key);
  }
}

Future<void> _loadProofFonts() async {
  var root = Directory.current.absolute;
  File? roboto;
  File? materialIcons;
  while (root.parent.path != root.path) {
    final fontDirectory = Directory(
      '${root.path}${Platform.pathSeparator}.tooling${Platform.pathSeparator}'
      'flutter${Platform.pathSeparator}bin${Platform.pathSeparator}cache'
      '${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
      'material_fonts',
    );
    final candidateRoboto = File(
      '${fontDirectory.path}${Platform.pathSeparator}roboto-regular.ttf',
    );
    final candidateIcons = File(
      '${fontDirectory.path}${Platform.pathSeparator}'
      'materialicons-regular.otf',
    );
    if (candidateRoboto.existsSync() && candidateIcons.existsSync()) {
      roboto = candidateRoboto;
      materialIcons = candidateIcons;
      break;
    }
    root = root.parent;
  }
  if (roboto == null || materialIcons == null) {
    throw StateError('Bundled Flutter proof fonts were not found.');
  }
  await _loadFont('ProofRoboto', roboto);
  await _loadFont('MaterialIcons', materialIcons);
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
        name: 'ACCEPTANCE\nFAMILY MEDICINE',
        accent: Federation2399Colors.clinical,
        completed: '0 hr',
        scheduled: '8 hr',
      ),
      const SizedBox(height: 12),
      const _PlacementCard(
        name: 'INTERNAL MEDICINE',
        accent: Federation2399Colors.workMachinery,
        completed: '42 hr',
        scheduled: '24 hr',
      ),
      const Spacer(),
      Text(
        'TAP A PLACEMENT FOR DETAILS',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Federation2399Colors.workMachinery,
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
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Federation2399Colors.canvas.withValues(alpha: .68),
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
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.1,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _MetricLine('$completed / 90 hr completed', accent),
        _MetricLine('$scheduled scheduled', Federation2399Colors.scheduled),
        const _MetricLine(
          '48 hr unscheduled',
          Federation2399Colors.unscheduled,
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

final class _PlanningProof extends StatelessWidget {
  const _PlanningProof();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Expanded(child: _SectionTitle('PLANNING')),
          OutlinedButton.icon(
            onPressed: _noop,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('ADD SCHEDULE'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _noop,
            icon: const Icon(Icons.warning_amber_outlined, size: 18),
            label: const Text('PLANNING INCOMPLETE'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Build the monthly plan in this in-flow region.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      const Row(
        children: [
          _PlanningStep('1', 'TYPE & TIME'),
          SizedBox(width: 18),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChoiceChip('WORK SHIFT', Federation2399Colors.workMachinery),
                _ChoiceChip('CLINICAL SESSION', Federation2399Colors.clinical),
                _ChoiceChip(
                  'PROTECTED DAY',
                  Federation2399Colors.protectedDayAccent,
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
        foregroundColor: Federation2399Colors.clinical,
        child: Text(number),
      ),
      const SizedBox(width: 7),
      Text(label, style: const TextStyle(color: Federation2399Colors.clinical)),
    ],
  );
}

final class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
      color: Federation2399Colors.control,
      border: Border.all(color: Federation2399Colors.insetBorder),
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
      const _SectionTitle('INTERNAL MEDICINE'),
      const SizedBox(height: 14),
      Center(
        child: SizedBox.square(
          dimension: 126,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const CircularProgressIndicator(
                value: .47,
                strokeWidth: 15,
                color: Federation2399Colors.clinical,
                backgroundColor: Federation2399Colors.control,
              ),
              Center(
                child: Text(
                  '42 hr\ncompleted',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      const _MetricLine(
        'Target                 90 hr',
        Federation2399Colors.primaryText,
      ),
      const _MetricLine(
        'Completed          42 hr',
        Federation2399Colors.completed,
      ),
      const _MetricLine(
        'Scheduled           24 hr',
        Federation2399Colors.scheduled,
      ),
      const _MetricLine(
        'Unscheduled       24 hr',
        Federation2399Colors.unscheduled,
      ),
      const SizedBox(height: 18),
      const Divider(),
      const SizedBox(height: 10),
      const _SectionTitle('NEEDS ATTENTION'),
      const SizedBox(height: 8),
      const _AttentionCard(
        icon: Icons.assignment_late_outlined,
        title: 'CLINICAL SESSION\nNEEDS CONFIRMATION',
      ),
      const _AttentionCard(
        icon: Icons.fact_check_outlined,
        title: 'INITIAL SELF-ASSESSMENT',
      ),
      const _AttentionCard(
        icon: Icons.warning_amber_outlined,
        title: 'PLANNING INCOMPLETE',
      ),
    ],
  );
}

final class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      border: Border(
        left: const BorderSide(color: Federation2399Colors.urgent, width: 3),
        bottom: BorderSide(
          color: Federation2399Colors.insetBorder.withValues(alpha: .35),
        ),
      ),
    ),
    child: Row(
      children: [
        Icon(icon, color: Federation2399Colors.clinical, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.labelSmall),
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
      _MetricLine('42 / 90 hr completed', Federation2399Colors.completed),
      _MetricLine('24 hr scheduled', Federation2399Colors.scheduled),
      _MetricLine('24 hr unscheduled', Federation2399Colors.unscheduled),
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
      color: Federation2399Colors.clinical,
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
