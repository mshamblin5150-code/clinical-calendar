import 'dart:convert';
import 'dart:io';

import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:clinical_calendar_presentation/src/canonical_delta_mark.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/placement_progress_harness.dart';

void main() {
  const containment = VariantFThemeBundle();

  test('v2 proof manifest pins the exact runtime evidence', () async {
    final packageRoot =
        Directory.current.path.endsWith('clinical_calendar_presentation')
        ? Directory.current
        : Directory('packages/clinical_calendar_presentation');
    final repositoryRoot = packageRoot.parent.parent;
    final proofRoot = Directory(
      '${packageRoot.path}/test/baselines/containment_drone_v2',
    );
    final manifest =
        jsonDecode(
              await File(
                '${repositoryRoot.path}/docs/themes/acceptance/proofs/'
                'containment-drone-47-alpha-redesign-v2/'
                'runtime-proof-manifest.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    final proofs = (manifest['proofs'] as Map<String, dynamic>)
        .cast<String, String>();
    final containmentAssets =
        (manifest['containmentAssetSha256'] as Map<String, dynamic>)
            .cast<String, String>();

    expect(manifest['rendererId'], containmentDroneRendererId);
    expect(manifest['platform'], 'cross-host-reference');
    expect(manifest['physicalAndroidApproval'], 'pending');
    expect(
      Directory('${proofRoot.path}/reference')
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .toSet()
          .length,
      17,
    );

    final pinnedFiles = <String, File>{
      for (final name in [
        'calendar-landscape-1536x1024.png',
        'calendar-portrait-900x1440.png',
        'calendar-portrait-200-percent-900x1440.png',
      ])
        name: File('${proofRoot.path}/reference/$name'),
      'concept-vs-runtime-landscape-1536x1024.png': File(
        '${repositoryRoot.path}/docs/themes/acceptance/proofs/'
        'containment-drone-47-alpha-redesign-v2/'
        'concept-vs-runtime-landscape-1536x1024.png',
      ),
      'theme-gallery-runtime-variant-f-v2.png': File(
        '${packageRoot.path}/assets/theme_gallery_runtime/variant-f-v2.png',
      ),
    };
    for (final entry in pinnedFiles.entries) {
      expect(
        sha256.convert(await entry.value.readAsBytes()).toString(),
        proofs[entry.key],
        reason: entry.key,
      );
    }
    final chassisAsset = File(
      '${packageRoot.path}/assets/containment_drone_v2/'
      'chassis-conduit-bridge.png',
    );
    expect(
      sha256.convert(await chassisAsset.readAsBytes()).toString(),
      containmentAssets['chassis-conduit-bridge.png'],
    );
  });

  test('Containment Drone owns the approved concept renderer', () {
    expect(containment.id, variantFThemeId);
    expect(containment.metadata.displayName, 'Containment Drone 47-Alpha');
    expect(containment.shellRenderer, isA<ContainmentDroneShellRenderer>());
    expect(containment.shellRenderer.rendererId, containmentDroneRendererId);
    expect(containment.frame.assetPaths, contains(canonicalDeltaMarkAsset));
    expect(
      containment.shellRenderer.buildFrame(child: const SizedBox.shrink()),
      isA<ContainmentDroneFrame>(),
    );
  });

  test('the other six themes keep their existing renderer lanes', () {
    const renderers = <ClinicalCalendarShellRenderer>[
      GraphiteShellRenderer(),
      FederationClassicShellRenderer(),
      Federation2399ShellRenderer(),
      HeritageFieldNotesShellRenderer(),
      CoastalLightShellRenderer(),
      BotanicalStudyShellRenderer(),
    ];

    for (final renderer in renderers) {
      expect(renderer, isNot(isA<ContainmentDroneShellRenderer>()));
    }
  });

  testWidgets('landscape composition exposes the approved live regions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1536, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var menuCount = 0;
    var addCount = 0;
    var attentionCount = 0;
    final destinations = <ClinicalCalendarDestination>[];

    await tester.pumpWidget(
      _app(
        onOpenMenu: () => menuCount++,
        onAddSchedule: () => addCount++,
        onOpenAttention: () => attentionCount++,
        onOpenDestination: destinations.add,
      ),
    );

    expect(
      find.byKey(const Key('containment-drone-landscape-shell')),
      findsOneWidget,
    );
    expect(find.byType(ContainmentDroneChassis), findsOneWidget);
    expect(find.byType(CanonicalDeltaMark), findsOneWidget);
    expect(find.byKey(const Key('containment-drone-calendar-bay')), findsOne);
    expect(find.byKey(const Key('containment-drone-placement-bay')), findsOne);
    expect(find.byKey(const Key('containment-drone-planning-bay')), findsOne);
    expect(find.byKey(const Key('containment-drone-insight-bay')), findsOne);
    expect(
      find.byKey(const Key('containment-drone-bottom-navigation')),
      findsOne,
    );

    await tester.tap(find.byKey(const Key('application-menu-action')));
    await tester.tap(find.byTooltip('Open Add Schedule'));
    await tester.tap(find.byTooltip('Open Help'));
    await tester.tap(find.byTooltip('Open Notifications'));
    await tester.tap(find.byTooltip('Open Synchronization'));
    await tester.tap(find.text('ATTENTION'));

    expect(menuCount, 1);
    expect(addCount, 1);
    expect(attentionCount, 1);
    expect(destinations, [
      ClinicalCalendarDestination.help,
      ClinicalCalendarDestination.notifications,
      ClinicalCalendarDestination.synchronization,
    ]);
  });

  testWidgets(
    'portrait is an ordered scroll composition with fixed navigation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1440));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app());

      expect(
        find.byKey(const Key('containment-drone-portrait-shell')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('containment-drone-portrait-scroll')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('containment-drone-bottom-navigation')),
        findsOneWidget,
      );

      final calendarTop = tester
          .getTopLeft(find.byKey(const Key('containment-drone-calendar-bay')))
          .dy;
      final placementTop = tester
          .getTopLeft(find.byKey(const Key('containment-drone-placement-bay')))
          .dy;
      final insightTop = tester
          .getTopLeft(find.byKey(const Key('containment-drone-insight-bay')))
          .dy;
      final planningTop = tester
          .getTopLeft(find.byKey(const Key('containment-drone-planning-bay')))
          .dy;
      expect(calendarTop, lessThan(placementTop));
      expect(placementTop, lessThan(insightTop));
      expect(insightTop, lessThan(planningTop));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Containment wheel opens live placement details then shared management',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1536, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final destinations = <ClinicalCalendarDestination>[];
      final harness = PlacementProgressHarness(
        requireInitialSelfAssessments: true,
      );
      await harness.controller.load();

      await tester.pumpWidget(
        _app(
          slots: ResponsiveShellSlots(
            centralContent: const Text('Calendar'),
            planningRegion: const Text('Planning'),
            placementDock: const Text('Placements'),
            insightRail: PlacementProgressPanel(
              snapshot: harness.controller.activePlacement,
              onCycle: () {},
              touch: true,
            ),
            mobilePlacementSummary: const Text('Placements'),
            mobileAttention: const Text('Attention'),
            profileAvatar: const CircleAvatar(child: Text('AS')),
          ),
          onOpenDestination: destinations.add,
        ),
      );

      await tester.tap(find.byKey(const Key('placement-progress-wheel')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('containment-placement-details')),
        findsOneWidget,
      );
      for (final label in const [
        'Completed Hours',
        'Scheduled Hours',
        'Remaining Hours',
        'Unscheduled Hours',
        'Over-Target Hours',
        'UPCOMING CLINICAL SESSIONS',
        'EVALUATION PLAN REQUIREMENTS',
        'Initial Self-Assessment',
        'Primary · Dr. Smith',
        'Attached · Dr. Nguyen',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(
        find.byKey(
          const Key(
            'placement-upcoming-session-50000000-0000-4000-8000-000000000000',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('08-20-2026 · 7:00 AM–7:00 PM'), findsOneWidget);
      expect(find.text('Dr. Smith · UTC'), findsWidgets);
      await tester.tap(find.byKey(const Key('manage-placement-from-details')));
      await tester.pumpAndSettle();
      expect(destinations, [ClinicalCalendarDestination.clinicalPlacements]);
    },
  );

  testWidgets('destination shell is Containment-owned in both orientations', (
    tester,
  ) async {
    for (final size in const [Size(1536, 1024), Size(900, 1440)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          theme: containment.standardPresentation.createThemeData(),
          home: containment.shellRenderer.buildDestination(
            destination: ClinicalCalendarDestination.clinicalPlacements,
            entry: DestinationEntry.applicationMenu,
            onExit: _noop,
            child: const Text('Live Clinical Placements destination'),
          ),
        ),
      );

      expect(
        find.byKey(const Key('containment-drone-destination-shell')),
        findsOneWidget,
      );
      expect(find.byType(ContainmentDroneChassis), findsOneWidget);
      expect(find.text('Live Clinical Placements destination'), findsOne);
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('compact and 200 percent text preserve every required action', (
    tester,
  ) async {
    for (final fixture in const [
      (Size(320, 568), 1.0),
      (Size(900, 1440), 2.0),
      (Size(1536, 1024), 2.0),
    ]) {
      await tester.binding.setSurfaceSize(fixture.$1);
      await tester.pumpWidget(_app(textScale: fixture.$2));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('application-menu-action')), findsOneWidget);
      expect(find.byTooltip('Open Add Schedule'), findsOneWidget);
      expect(
        find.byKey(const Key('containment-drone-bottom-navigation')),
        findsOneWidget,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${fixture.$1} @ ${fixture.$2}x',
      );
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('destination shell accepts all ten production identities', (
    tester,
  ) async {
    for (final fixture in const [
      (Size(320, 568), 1.0),
      (Size(900, 1440), 1.0),
      (Size(900, 1440), 2.0),
      (Size(1536, 1024), 1.0),
    ]) {
      await tester.binding.setSurfaceSize(fixture.$1);
      for (final destination in applicationMenuDestinations) {
        await tester.pumpWidget(
          MaterialApp(
            theme: containment.standardPresentation.createThemeData(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(fixture.$2)),
              child: child!,
            ),
            home: containment.shellRenderer.buildDestination(
              destination: destination,
              entry: DestinationEntry.applicationMenu,
              onExit: _noop,
              child: Text('Live ${destination.label} destination'),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.text('Live ${destination.label} destination'),
          findsOneWidget,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${destination.label} at ${fixture.$1} @ ${fixture.$2}x',
        );
      }
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}

Widget _app({
  ResponsiveShellSlots slots = _slots,
  VoidCallback onOpenMenu = _noop,
  ValueChanged<ClinicalCalendarDestination> onOpenDestination =
      _ignoreDestination,
  VoidCallback onOpenAttention = _noop,
  VoidCallback onAddSchedule = _noop,
  double textScale = 1,
}) => MediaQuery(
  data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
  child: MaterialApp(
    theme: const VariantFVisualTheme().createThemeData(),
    home: const VariantFThemeBundle().shellRenderer.build(
      slots: slots,
      environmentName: 'TEST',
      onOpenMenu: onOpenMenu,
      onOpenDestination: onOpenDestination,
      onOpenAttention: onOpenAttention,
      onAddSchedule: onAddSchedule,
    ),
  ),
);

const _slots = ResponsiveShellSlots(
  centralContent: ColoredBox(color: Color(0xFF10231B), child: Text('Calendar')),
  planningRegion: Text('Planning'),
  placementDock: Text('Placements'),
  insightRail: Text('Progress and attention'),
  mobilePlacementSummary: Text('Placements'),
  mobileAttention: Text('Attention'),
  profileAvatar: CircleAvatar(child: Text('AS')),
);

void _noop() {}

void _ignoreDestination(ClinicalCalendarDestination _) {}
