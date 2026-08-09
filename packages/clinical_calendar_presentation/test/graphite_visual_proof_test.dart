import 'dart:io';
import 'dart:math' as math;
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
    expect(find.byKey(const Key('calendar-today-label')), findsOneWidget);

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

    expect(find.bySemanticsLabel('Graphite calendar mark'), findsOneWidget);

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
      greaterThanOrEqualTo(.9288),
      reason: 'mean channel similarity was ${comparison.meanChannelSimilarity}',
    );
    expect(
      comparison.closePixelRatio,
      greaterThanOrEqualTo(.8181),
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
    expect(comparison.meanChannelSimilarity, lessThan(.9288));
    expect(comparison.closePixelRatio, lessThan(.8181));
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
          accent: Theme.of(context).colorScheme.primary,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
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
                        CustomPaint(
                          painter: _PlacementWheelPainter(
                            progress: progress,
                            accent: accent,
                          ),
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
                _PlacementDependency(
                  scheduled: true,
                  accent: accent,
                  label: detail.split('\n')[1],
                ),
                const SizedBox(height: 5),
                _PlacementDependency(
                  scheduled: false,
                  accent: accent,
                  label: detail.split('\n')[2],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

final class _PlacementWheelPainter extends CustomPainter {
  const _PlacementWheelPainter({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 7;
    canvas.drawCircle(
      center,
      radius + 4,
      Paint()
        ..color = const Color(0xFF1A1E21)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF4A5054)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    canvas.drawCircle(
      center,
      radius - 5,
      Paint()
        ..color = const Color(0xFF252A2E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5708,
        6.2832 * progress,
        false,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_PlacementWheelPainter oldDelegate) =>
      progress != oldDelegate.progress || accent != oldDelegate.accent;
}

final class _PlacementDependency extends StatelessWidget {
  const _PlacementDependency({
    required this.scheduled,
    required this.accent,
    required this.label,
  });

  final bool scheduled;
  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox.square(
        dimension: 21,
        child: scheduled
            ? Icon(
                Icons.schedule_outlined,
                size: 20,
                color: context.clinicalColors.secondaryText,
              )
            : CustomPaint(painter: _DashedRingPainter(color: accent)),
      ),
      const SizedBox(width: 8),
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );
}

final class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 10; index++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        index * .6283,
        .31,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter oldDelegate) =>
      color != oldDelegate.color;
}

final class _InsightProof extends StatelessWidget {
  const _InsightProof();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: context.clinicalColors.workMachinery,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(child: _ProofTitle('INTERNAL MEDICINE')),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: SizedBox.square(
            dimension: 136,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _DetailedWheelPainter(
                    accent: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '0 hr\n',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 26,
                          ),
                        ),
                        TextSpan(
                          text: 'completed',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 13,
                          ),
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
        const SizedBox(height: 0),
        const _InsightDependency(
          icon: Icons.gps_fixed,
          label: 'Target',
          value: '90 hr',
        ),
        const _InsightDependency(
          icon: Icons.check_circle_outline,
          label: 'Completed',
          value: '0 hr',
        ),
        const _InsightDependency(
          icon: Icons.schedule_outlined,
          label: 'Scheduled',
          value: '8 hr',
        ),
        const _InsightDependency(
          icon: Icons.radio_button_unchecked,
          label: 'Unscheduled',
          value: '82 hr',
          dashed: true,
        ),
        const _InsightDependency(
          icon: Icons.keyboard_double_arrow_up,
          label: 'Over-Target',
          value: '0 hr',
        ),
        const SizedBox(height: 4),
        const Divider(),
        Text(
          'Additional pace required',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          '21 hr 16 min / week',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'TAP WHEEL TO VIEW NEXT PLACEMENT',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 18),
        Text(
          'SHOW PRECEPTOR BREAKDOWN',
          style: TextStyle(color: context.clinicalColors.scheduled),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: context.clinicalColors.secondaryText,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(child: _ProofTitle('NEEDS ATTENTION')),
            Text('ON  •  5', style: TextStyle(color: Color(0xFFFF8D86))),
          ],
        ),
        const SizedBox(height: 8),
        const _AttentionProofItem(
          icon: Icons.report_gmailerrorred_outlined,
          title: 'CLINICAL SESSION NEEDS CONFIRMATION',
          detail: 'Confirm the actual times and supervisor',
        ),
        const _AttentionProofItem(
          icon: Icons.assignment_outlined,
          title: 'INITIAL SELF-ASSESSMENT',
          detail: 'Acceptance Family Medicine',
          trailing: 'Due',
        ),
        const _AttentionProofItem(
          icon: Icons.assignment_outlined,
          title: 'INITIAL SELF-ASSESSMENT',
          detail: 'Internal Medicine',
          trailing: 'Due',
        ),
        const _AttentionProofItem(
          icon: Icons.report_gmailerrorred_outlined,
          title: 'PLANNING INCOMPLETE',
          detail: 'Choose one empty Protected Day',
        ),
      ],
    ),
  );
}

final class _DetailedWheelPainter extends CustomPainter {
  const _DetailedWheelPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final tickRadius = size.shortestSide / 2 - 6;
    final tickPaint = Paint()
      ..color = const Color(0xFF9BA3A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var index = 0; index < 60; index++) {
      final angle = index * .10472 - 1.5708;
      final outer = Offset(
        center.dx + tickRadius * math.cos(angle),
        center.dy + tickRadius * math.sin(angle),
      );
      final innerRadius = tickRadius - (index % 5 == 0 ? 5 : 3);
      final inner = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }
    canvas.drawCircle(
      center,
      tickRadius - 10,
      Paint()
        ..color = const Color(0xFF4A5054)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      center,
      tickRadius - 14,
      Paint()
        ..color = accent.withValues(alpha: .18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_DetailedWheelPainter oldDelegate) =>
      accent != oldDelegate.accent;
}

final class _InsightDependency extends StatelessWidget {
  const _InsightDependency({
    required this.icon,
    required this.label,
    required this.value,
    this.dashed = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool dashed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox.square(
          dimension: 19,
          child: dashed
              ? CustomPaint(
                  painter: _DashedRingPainter(
                    color: context.clinicalColors.secondaryText,
                  ),
                )
              : Icon(
                  icon,
                  size: 18,
                  color: context.clinicalColors.secondaryText,
                ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(value),
      ],
    ),
  );
}

final class _AttentionProofItem extends StatelessWidget {
  const _AttentionProofItem({
    required this.icon,
    required this.title,
    required this.detail,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 68),
    padding: const EdgeInsets.symmetric(vertical: 7),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: context.clinicalColors.insetBorder.withValues(alpha: .38),
        ),
      ),
    ),
    child: Row(
      children: [
        Icon(icon, size: 38, color: context.clinicalColors.urgent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.clinicalColors.urgent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Text(
            trailing!,
            style: TextStyle(color: context.clinicalColors.urgent),
          ),
        ],
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

void _noop() {}

void _ignoreDestination(ClinicalCalendarDestination _) {}
