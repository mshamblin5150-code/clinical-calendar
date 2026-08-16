import 'dart:ui' as ui;

import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:clinical_calendar_presentation/src/canonical_delta_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bundle = VariantFThemeBundle();
  const graphite = GraphiteThemeBundle();
  const federationClassic = FederationClassicThemeBundle();
  const federation2399 = Federation2399ThemeBundle();
  const coastalLight = CoastalLightThemeBundle();

  test('Containment Drone is one complete internally owned bundle', () {
    ClinicalCalendarThemeBundleValidator.validate(const [bundle]);

    expect(bundle.id, variantFThemeId);
    expect(bundle.metadata.displayName, 'Containment Drone 47-Alpha');
    expect(bundle.standardPresentation, isA<VariantFVisualTheme>());
    expect(bundle.shellRenderer, isA<ContainmentDroneShellRenderer>());
    expect(bundle.frame.sourceSize, const Size(1536, 1024));
    expect(
      bundle.frame.sourceCuts,
      const EdgeInsets.fromLTRB(120, 145, 120, 170),
    );
    expect(bundle.frame.assetPaths, hasLength(9));
    expect(
      bundle.frame.assetPaths,
      contains(containmentDroneChassisBridgeAsset),
    );
    expect(bundle.frame.assetPaths, contains(containmentDronePanelAsset));
    expect(bundle.gallery.swatches, hasLength(5));
    expect(bundle.marks.marks, hasLength(9));
    expect(bundle.helpGuide.calendarStates, hasLength(5));
  });

  test('root resolution returns the complete bundle', () {
    final resolved = ClinicalCalendarThemeBundleRegistry.standard.resolveRoot(
      variantFThemeId,
    );

    expect(resolved, isA<VariantFThemeBundle>());
    expect(resolved.standardPresentation.themeId, resolved.id);
    expect(resolved.shellRenderer.themeId, resolved.id);
    expect(resolved.frame.themeId, resolved.id);
    expect(resolved.gallery.themeId, resolved.id);
    expect(resolved.marks.themeId, resolved.id);
    expect(resolved.helpGuide.themeId, resolved.id);
  });

  test('Graphite is a complete independently owned fallback bundle', () {
    ClinicalCalendarThemeBundleValidator.validate(const [graphite]);

    expect(graphite.id, graphiteThemeId);
    expect(graphite.metadata.displayName, 'Graphite');
    expect(graphite.standardPresentation, isA<GraphiteVisualTheme>());
    expect(graphite.shellRenderer, isA<GraphiteShellRenderer>());
    expect(graphite.frame.sourceSize, const Size(1536, 1024));
    expect(
      graphite.frame.sourceCuts,
      const EdgeInsets.fromLTRB(120, 145, 120, 170),
    );
    expect(graphite.frame.assetPaths, hasLength(2));
    expect(graphite.gallery.swatches, hasLength(5));
    expect(graphite.marks.marks, hasLength(9));
    expect(graphite.helpGuide.calendarStates, hasLength(5));
    expect(graphite.frame.safeInsets, const {
      ThemeFrameRegion.calendar: graphiteCalendarSafeInsets,
      ThemeFrameRegion.placements: graphitePlacementsSafeInsets,
      ThemeFrameRegion.planning: graphitePlanningSafeInsets,
      ThemeFrameRegion.status: graphiteStatusSafeInsets,
    });
    expect(
      graphite.marks.marks.map((mark) => mark.icon),
      everyElement(isA<IconData>()),
    );
    expect(
      graphite.helpGuide.calendarStates,
      everyElement(
        isA<CalendarStateGuide>()
            .having((state) => state.nonColorCue, 'non-color cue', isNotEmpty)
            .having(
              (state) => state.enhancedBehavior,
              'Enhanced behavior',
              isNotEmpty,
            ),
      ),
    );
  });

  test('Federation Classic is a complete independently owned bundle', () {
    ClinicalCalendarThemeBundleValidator.validate(const [federationClassic]);

    expect(federationClassic.id, federationClassicThemeId);
    expect(federationClassic.metadata.displayName, 'Federation Classic');
    expect(
      federationClassic.standardPresentation,
      isA<FederationClassicVisualTheme>(),
    );
    expect(
      federationClassic.shellRenderer,
      isA<FederationClassicShellRenderer>(),
    );
    expect(federationClassic.frame.sourceSize, const Size(1536, 1024));
    expect(
      federationClassic.frame.sourceCuts,
      const EdgeInsets.fromLTRB(120, 145, 120, 170),
    );
    expect(
      federationClassic.frame.assetPaths,
      containsAll([
        federationClassicFrameAsset,
        federationClassicRailNineSliceAsset,
        canonicalDeltaMarkAsset,
      ]),
    );
    expect(federationClassic.gallery.swatches, hasLength(5));
    expect(federationClassic.marks.marks, hasLength(9));
    expect(federationClassic.helpGuide.calendarStates, hasLength(5));
    expect(
      federationClassic.helpGuide.calendarStates,
      everyElement(
        isA<CalendarStateGuide>()
            .having((state) => state.nonColorCue, 'non-color cue', isNotEmpty)
            .having(
              (state) => state.enhancedBehavior,
              'Enhanced behavior',
              isNotEmpty,
            ),
      ),
    );
    final additiveColors = federationClassic.standardPresentation
        .createThemeData()
        .extension<ClinicalCalendarAdditiveColors>()!;
    expect(additiveColors.completed, FederationClassicColors.completed);
    expect(additiveColors.unscheduled, FederationClassicColors.unscheduled);
    expect(additiveColors.overTarget, FederationClassicColors.overTarget);
    expect(additiveColors.today, FederationClassicColors.today);
    expect(
      ClinicalCalendarThemeBundleRegistry.standard.resolveRoot(
        federationClassicThemeId,
      ),
      same(federationClassic),
    );
  });

  test('Federation 2399 is a complete independently owned bundle', () {
    ClinicalCalendarThemeBundleValidator.validate(const [federation2399]);

    expect(federation2399.id, federation2399ThemeId);
    expect(federation2399.metadata.displayName, 'Federation 2399');
    expect(
      federation2399.standardPresentation,
      isA<Federation2399VisualTheme>(),
    );
    expect(federation2399.shellRenderer, isA<Federation2399ShellRenderer>());
    expect(federation2399.frame.sourceSize, const Size(1536, 1024));
    expect(
      federation2399.frame.sourceCuts,
      const EdgeInsets.fromLTRB(120, 145, 120, 170),
    );
    expect(
      federation2399.frame.assetPaths,
      containsAll([
        federation2399FrameAsset,
        federation2399LandscapeChassisAsset,
        canonicalDeltaMarkAsset,
      ]),
    );
    expect(federation2399.gallery.swatches, hasLength(5));
    expect(federation2399.marks.marks, hasLength(9));
    expect(federation2399.helpGuide.calendarStates, hasLength(5));
    expect(
      federation2399.helpGuide.calendarStates,
      everyElement(
        isA<CalendarStateGuide>()
            .having((state) => state.nonColorCue, 'non-color cue', isNotEmpty)
            .having(
              (state) => state.enhancedBehavior,
              'Enhanced behavior',
              isNotEmpty,
            ),
      ),
    );
    final additiveColors = federation2399.standardPresentation
        .createThemeData()
        .extension<ClinicalCalendarAdditiveColors>()!;
    expect(additiveColors.completed, Federation2399Colors.completed);
    expect(additiveColors.unscheduled, Federation2399Colors.unscheduled);
    expect(additiveColors.overTarget, Federation2399Colors.overTarget);
    expect(additiveColors.today, Federation2399Colors.today);
    final enhanced = federation2399.standardPresentation.createThemeData(
      enhancedAccessibility: true,
    );
    expect(
      enhanced.inputDecorationTheme.enabledBorder,
      isA<OutlineInputBorder>().having(
        (border) => border.borderSide.color,
        'Enhanced control border',
        const Color(0xFFD6C5D1),
      ),
    );
    expect(
      enhanced.inputDecorationTheme.focusedBorder,
      isA<OutlineInputBorder>().having(
        (border) => border.borderSide.color,
        'Enhanced focus border',
        const Color(0xFFFFE28E),
      ),
    );
    expect(
      enhanced.outlinedButtonTheme.style?.side?.resolve(const {}),
      const BorderSide(color: Color(0xFFD6C5D1), width: 1.5),
    );
    expect(
      ClinicalCalendarThemeBundleRegistry.standard.resolveRoot(
        federation2399ThemeId,
      ),
      same(federation2399),
    );
  });

  test(
    'Federation Classic rebuild leaves every other renderer path unchanged',
    () {
      final cases = <(ClinicalCalendarThemeBundle, String, Type)>[
        (bundle, containmentDroneRendererId, ContainmentDroneApplicationShell),
        (
          graphite,
          'graphite-owned-responsive-instrument-v4',
          GraphiteApplicationShell,
        ),
        (
          federation2399,
          'federation-2399-owned-responsive-console-v5',
          Federation2399ApplicationShell,
        ),
      ];

      for (final (bundle, rendererId, shellType) in cases) {
        expect(bundle.shellRenderer.rendererId, rendererId);
        expect(
          bundle.shellRenderer
              .build(
                slots: _slots,
                environmentName: 'TEST',
                onOpenMenu: _noop,
                onOpenDestination: _ignoreDestination,
                onOpenAttention: _noop,
                onAddSchedule: _noop,
              )
              .runtimeType,
          shellType,
          reason: '${bundle.id} must retain its production renderer path',
        );
      }
    },
  );

  test('Field Archive is a complete independently owned bundle', () {
    const fieldArchive = HeritageFieldNotesThemeBundle();

    ClinicalCalendarThemeBundleValidator.validate(const [fieldArchive]);
    expect(fieldArchive.id, heritageFieldNotesThemeId);
    expect(fieldArchive.metadata.displayName, 'Field Archive');
    expect(
      fieldArchive.standardPresentation,
      isA<HeritageFieldNotesVisualTheme>(),
    );
    expect(fieldArchive.shellRenderer, isA<HeritageFieldNotesShellRenderer>());
    expect(fieldArchive.frame.assetPaths, const [
      heritageFieldNotesFrameAsset,
      canonicalDeltaMarkAsset,
      heritageFieldNotesMaterialChassisAsset,
    ]);
    expect(fieldArchive.gallery.swatches, hasLength(5));
    expect(fieldArchive.marks.marks, hasLength(9));
    expect(fieldArchive.helpGuide.calendarStates, hasLength(5));
    expect(
      fieldArchive.standardPresentation
          .createThemeData()
          .extension<ClinicalCalendarPresentationPolicy>()
          ?.denseMarkerStyle,
      CalendarDenseMarkerStyle.chip,
    );
    expect(
      ClinicalCalendarThemeBundleRegistry.standard.resolveRoot(
        heritageFieldNotesThemeId,
      ),
      same(fieldArchive),
    );
  });

  test(
    'Enhanced is an overlay and Standard round trips exactly for registered bundles',
    () {
      for (final themedBundle in const <ClinicalCalendarThemeBundle>[
        VariantFThemeBundle(),
        GraphiteThemeBundle(),
        FederationClassicThemeBundle(),
        Federation2399ThemeBundle(),
        CoastalLightThemeBundle(),
        HeritageFieldNotesThemeBundle(),
      ]) {
        final standard = themedBundle.standardPresentation.createThemeData();
        final enhanced = themedBundle.standardPresentation.createThemeData(
          enhancedAccessibility: true,
        );
        final restored = themedBundle.standardPresentation.createThemeData();

        expect(enhanced, isNot(standard));
        expect(
          enhanced.extension<ClinicalCalendarAccessibilityTokens>()?.enhanced,
          isTrue,
        );
        expect(restored.colorScheme, standard.colorScheme);
        expect(restored.textTheme, standard.textTheme);
        expect(restored.cardTheme, standard.cardTheme);
        expect(
          restored.extension<ClinicalCalendarColors>(),
          standard.extension<ClinicalCalendarColors>(),
        );
        expect(
          restored.extension<ClinicalCalendarAccessibilityTokens>(),
          standard.extension<ClinicalCalendarAccessibilityTokens>(),
        );
        expect(themedBundle.standardPresentation.themeId, themedBundle.id);
        expect(themedBundle.frame.assetPaths, isNotEmpty);
        expect(themedBundle.frame.sourceSize, const Size(1536, 1024));
        expect(
          themedBundle.frame.sourceCuts,
          const EdgeInsets.fromLTRB(120, 145, 120, 170),
        );
      }
    },
  );

  test('unknown applied ID falls back without changing the stored ID', () {
    final resolved = ClinicalCalendarThemeBundleRegistry.standard
        .resolveApplied('future-theme');

    expect(resolved.storedId, 'future-theme');
    expect(resolved.bundle, isA<GraphiteThemeBundle>());
    expect(resolved.isFallback, isTrue);
  });

  test('every catalog ID resolves as its authoritative complete bundle', () {
    final registry = ClinicalCalendarThemeBundleRegistry.standard;

    for (final bundle in registry.selectableBundles) {
      final resolved = registry.resolveApplied(bundle.id);

      expect(resolved.storedId, bundle.id);
      expect(resolved.bundle, same(bundle));
      expect(resolved.isFallback, isFalse);
    }
  });

  test(
    'candidate preflight failure preserves the valid applied bundle',
    () async {
      final registry = ClinicalCalendarThemeBundleRegistry.standard;
      final applied = registry.resolveApplied(variantFThemeId);

      final failed = await registry.preflightCandidate(
        applied: applied,
        candidateId: graphiteThemeId,
        preflight: (_) async => throw StateError('asset decode failed'),
      );

      expect(failed.previewUnavailable, isTrue);
      expect(failed.applied, same(applied));
      expect(failed.candidate, isNull);
      expect(failed.effectiveBundle, same(applied.bundle));
    },
  );

  test(
    'successful candidate preflight returns the complete candidate',
    () async {
      final registry = ClinicalCalendarThemeBundleRegistry.standard;
      final applied = registry.resolveApplied(variantFThemeId);

      final result = await registry.preflightCandidate(
        applied: applied,
        candidateId: graphiteThemeId,
        preflight: (candidate) async {
          ClinicalCalendarThemeBundleValidator.validate([candidate]);
        },
      );

      expect(result.previewUnavailable, isFalse);
      expect(result.applied, same(applied));
      expect(result.candidate, isA<GraphiteThemeBundle>());
      expect(result.effectiveBundle, same(result.candidate));
    },
  );

  test('closed catalog activates exactly seven immutable IDs together', () {
    final registry = ClinicalCalendarThemeBundleRegistry.standard;

    expect(registry.isSelectableCatalogComplete, isTrue);
    expect(
      registry.selectableBundles.map((bundle) => bundle.id),
      orderedEquals(const [
        variantFThemeId,
        graphiteThemeId,
        federationClassicThemeId,
        federation2399ThemeId,
        coastalCalmThemeId,
        botanicalStudyThemeId,
        heritageFieldNotesThemeId,
      ]),
    );
  });

  test('duplicate bundles are rejected', () {
    expect(
      () =>
          ClinicalCalendarThemeBundleValidator.validate(const [bundle, bundle]),
      throwsA(isA<InvalidThemeBundle>()),
    );
  });

  test('incomplete bundles are rejected', () {
    expect(
      () => ClinicalCalendarThemeBundleValidator.validate(const [
        _TestBundle(
          id: variantFThemeId,
          overrideMetadata: ThemeCatalogMetadata(
            themeId: variantFThemeId,
            displayName: '',
            personality: '',
          ),
        ),
      ]),
      throwsA(isA<InvalidThemeBundle>()),
    );
  });

  for (final origin in const [
    ThemeBundleOrigin.runtime,
    ThemeBundleOrigin.remote,
  ]) {
    test('${origin.name} bundles are rejected', () {
      expect(
        () => ClinicalCalendarThemeBundleValidator.validate([
          _TestBundle(id: variantFThemeId, origin: origin),
        ]),
        throwsA(isA<InvalidThemeBundle>()),
      );
    });
  }

  test('partially borrowed bundles are rejected', () {
    expect(
      () => ClinicalCalendarThemeBundleValidator.validate(const [
        _TestBundle(
          id: 'graphite',
          overrideMetadata: ThemeCatalogMetadata(
            themeId: 'graphite',
            displayName: 'Graphite',
            personality: 'Neutral precision slate.',
          ),
        ),
      ]),
      throwsA(isA<InvalidThemeBundle>()),
    );
  });

  testWidgets('bundle shell uses the approved Containment renderer lane', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const resolved = VariantFThemeBundle();
    await tester.pumpWidget(
      MaterialApp(
        theme: resolved.standardPresentation.createThemeData(),
        home: resolved.shellRenderer.build(
          slots: _slots,
          environmentName: 'TEST',
          onOpenMenu: _noop,
          onOpenDestination: _ignoreDestination,
          onOpenAttention: _noop,
          onAddSchedule: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ContainmentDroneApplicationShell), findsOneWidget);
    expect(find.byType(ResponsiveApplicationShell), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Containment Drone rendered Standard survives an Enhanced round trip exactly',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const resolved = VariantFThemeBundle();

      final standardKey = GlobalKey();
      await tester.pumpWidget(
        _shellHarness(
          theme: resolved.standardPresentation.createThemeData(),
          boundaryKey: standardKey,
          shell: resolved.shellRenderer.build(
            slots: _slots,
            environmentName: 'TEST',
            onOpenMenu: _noop,
            onOpenDestination: _ignoreDestination,
            onOpenAttention: _noop,
            onAddSchedule: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final acceptedStandard = await _capture(standardKey);
      addTearDown(acceptedStandard.dispose);

      await tester.pumpWidget(
        _shellHarness(
          theme: resolved.standardPresentation.createThemeData(
            enhancedAccessibility: true,
          ),
          boundaryKey: GlobalKey(),
          shell: resolved.shellRenderer.build(
            slots: _slots,
            environmentName: 'TEST',
            onOpenMenu: _noop,
            onOpenDestination: _ignoreDestination,
            onOpenAttention: _noop,
            onAddSchedule: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final restoredKey = GlobalKey();
      await tester.pumpWidget(
        _shellHarness(
          theme: resolved.standardPresentation.createThemeData(),
          boundaryKey: restoredKey,
          shell: resolved.shellRenderer.build(
            slots: _slots,
            environmentName: 'TEST',
            onOpenMenu: _noop,
            onOpenDestination: _ignoreDestination,
            onOpenAttention: _noop,
            onAddSchedule: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(restoredKey),
        matchesReferenceImage(acceptedStandard),
      );
    },
  );

  testWidgets('Graphite shell uses only Graphite-owned raster framing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _shellHarness(
        theme: graphite.standardPresentation.createThemeData(),
        boundaryKey: GlobalKey(),
        shell: graphite.shellRenderer.build(
          slots: _slots,
          environmentName: 'TEST',
          onOpenMenu: _noop,
          onOpenDestination: _ignoreDestination,
          onOpenAttention: _noop,
          onAddSchedule: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GraphiteNineSliceFrame), findsWidgets);
    expect(find.byType(VariantFNineSliceFrame), findsNothing);
  });

  testWidgets('Graphite landscape matches the approved instrument silhouette', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1536, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _shellHarness(
        theme: graphite.standardPresentation.createThemeData(),
        boundaryKey: GlobalKey(),
        shell: graphite.shellRenderer.build(
          slots: _slots,
          environmentName: 'TEST',
          onOpenMenu: _noop,
          onOpenDestination: _ignoreDestination,
          onOpenAttention: _noop,
          onAddSchedule: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('graphite-landscape-shell')), findsOneWidget);
    final crown = tester.getRect(
      find.byKey(const Key('graphite-command-crown')),
    );
    final placements = tester.getRect(
      find.byKey(const Key('graphite-placement-housing')),
    );
    final calendar = tester.getRect(
      find.byKey(const Key('graphite-calendar-bay')),
    );
    final planning = tester.getRect(
      find.byKey(const Key('graphite-planning-bay')),
    );
    final placementProgress = tester.getRect(
      find.byKey(const Key('graphite-placement-progress-housing')),
    );
    final attention = tester.getRect(
      find.byKey(const Key('graphite-attention-housing')),
    );
    final navigation = tester.getRect(
      find.byKey(const Key('graphite-bottom-navigation')),
    );
    expect(crown.height / 1024, closeTo(.078, .012));
    expect(placements.width / 1536, closeTo(.19, .012));
    expect(calendar.width / 1536, closeTo(.55, .012));
    expect(placementProgress.width / 1536, closeTo(.24, .012));
    expect(attention.width, placementProgress.width);
    expect(placements.right, lessThan(calendar.left));
    expect(calendar.right, lessThan(placementProgress.left));
    expect(placementProgress.bottom, lessThan(attention.top));
    expect(planning.left, calendar.left);
    expect(planning.right, calendar.right);
    expect(planning.top, greaterThan(calendar.bottom));
    expect(navigation.top, greaterThan(planning.bottom));
    expect(navigation.height / 1024, closeTo(.086, .012));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Graphite-owned commands preserve shared callbacks', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1536, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var menuCount = 0;
    var addCount = 0;
    var attentionCount = 0;
    final destinations = <ClinicalCalendarDestination>[];

    await tester.pumpWidget(
      _shellHarness(
        theme: graphite.standardPresentation.createThemeData(),
        boundaryKey: GlobalKey(),
        shell: graphite.shellRenderer.build(
          slots: _slots,
          environmentName: 'TEST',
          onOpenMenu: () => menuCount++,
          onOpenDestination: destinations.add,
          onOpenAttention: () => attentionCount++,
          onAddSchedule: () => addCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final applicationMenu = find.byKey(const Key('application-menu-action'));
    expect(
      find.descendant(
        of: applicationMenu,
        matching: find.byType(CanonicalDeltaMark),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('graphite-destination-grid')), findsNothing);
    await tester.tap(find.byTooltip('Open menu'));
    await tester.tap(find.byTooltip('Add schedule'));
    await tester.tap(find.byTooltip('Help'));
    await tester.tap(find.byKey(const Key('graphite-navigation-2')));
    await tester.tap(find.byKey(const Key('graphite-navigation-3')));
    await tester.tap(find.byKey(const Key('graphite-navigation-4')));

    expect(menuCount, 1);
    expect(addCount, 1);
    expect(attentionCount, 1);
    expect(destinations, [
      ClinicalCalendarDestination.help,
      ClinicalCalendarDestination.clinicalPlacements,
      ClinicalCalendarDestination.settings,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Graphite keeps expanded preceptor progress above the attention boundary',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1536, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _shellHarness(
          theme: graphite.standardPresentation.createThemeData(),
          boundaryKey: GlobalKey(),
          shell: graphite.shellRenderer.build(
            slots: ResponsiveShellSlots(
              centralContent: const Text('Calendar fixture'),
              planningRegion: const Text('Planning fixture'),
              placementDock: const Text('Placement fixture'),
              insightRail: const GraphiteInsightRailSlots(
                placementProgress: _ExpandablePreceptorFixture(),
                attention: ColoredBox(
                  key: Key('attention-menu-fixture'),
                  color: Colors.red,
                  child: SizedBox(height: 200),
                ),
              ),
              mobilePlacementSummary: const Text('Placement summary fixture'),
              mobileAttention: const Text('Attention fixture'),
              profileAvatar: const SizedBox.square(dimension: 44),
            ),
            environmentName: 'TEST',
            onOpenMenu: _noop,
            onOpenDestination: _ignoreDestination,
            onOpenAttention: _noop,
            onAddSchedule: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final upperFinder = find.byKey(
        const Key('graphite-placement-progress-housing'),
      );
      final lowerFinder = find.byKey(const Key('graphite-attention-housing'));
      final collapsedUpper = tester.getRect(upperFinder);
      final collapsedLower = tester.getRect(lowerFinder);
      expect(collapsedUpper.bottom, lessThan(collapsedLower.top));
      expect(
        find.descendant(
          of: upperFinder,
          matching: find.byKey(const Key('graphite-placement-progress-clip')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: lowerFinder,
          matching: find.byKey(const Key('graphite-attention-clip')),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('toggle-preceptor-breakdown')));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(upperFinder),
        collapsedUpper,
        reason: 'Expanding Preceptors must not move the ownership boundary.',
      );
      expect(tester.getRect(lowerFinder), collapsedLower);
      expect(
        tester
            .getRect(find.byKey(const Key('attention-menu-fixture')))
            .overlaps(collapsedUpper),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Graphite portrait owns one ordered vertical reading path', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1440));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _shellHarness(
        theme: graphite.standardPresentation.createThemeData(),
        boundaryKey: GlobalKey(),
        shell: graphite.shellRenderer.build(
          slots: _slots,
          environmentName: 'TEST',
          onOpenMenu: _noop,
          onOpenDestination: _ignoreDestination,
          onOpenAttention: _noop,
          onAddSchedule: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('graphite-portrait-shell')), findsOneWidget);
    expect(find.byKey(const Key('graphite-portrait-scroll')), findsOneWidget);
    final calendar = tester.getRect(
      find.byKey(const Key('graphite-calendar-bay')),
    );
    final planning = tester.getRect(
      find.byKey(const Key('graphite-planning-bay')),
    );
    final placements = tester.getRect(
      find.byKey(const Key('graphite-placement-housing')),
    );
    final insight = tester.getRect(
      find.byKey(const Key('graphite-insight-bay')),
    );
    expect(calendar.top, lessThan(planning.top));
    expect(planning.top, lessThan(placements.top));
    expect(placements.right, lessThan(insight.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Graphite portrait remains operable at 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1440));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: graphite.standardPresentation.createThemeData(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: graphite.shellRenderer.build(
          slots: _slots,
          environmentName: 'TEST',
          onOpenMenu: _noop,
          onOpenDestination: _ignoreDestination,
          onOpenAttention: _noop,
          onAddSchedule: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('graphite-portrait-shell')), findsOneWidget);
    expect(find.byKey(const Key('graphite-bottom-navigation')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Federation Classic shell uses only Federation Classic-owned chassis',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _shellHarness(
          theme: federationClassic.standardPresentation.createThemeData(),
          boundaryKey: GlobalKey(),
          shell: federationClassic.shellRenderer.build(
            slots: _slots,
            environmentName: 'TEST',
            onOpenMenu: _noop,
            onOpenDestination: _ignoreDestination,
            onOpenAttention: _noop,
            onAddSchedule: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FederationClassicLandscapeChassis), findsOneWidget);
      expect(find.byType(FederationClassicNineSliceFrame), findsNothing);
      expect(find.byType(FederationClassicRasterRails), findsOneWidget);
      expect(
        FederationClassicRasterRails.centerSlice,
        const Rect.fromLTRB(64, 64, 448, 448),
      );
      expect(find.byType(GraphiteNineSliceFrame), findsNothing);
      expect(find.byType(VariantFNineSliceFrame), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Federation 2399 shell uses only Federation 2399 raster framing',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _shellHarness(
          theme: federation2399.standardPresentation.createThemeData(),
          boundaryKey: GlobalKey(),
          shell: federation2399.shellRenderer.build(
            slots: _slots,
            environmentName: 'TEST',
            onOpenMenu: _noop,
            onOpenDestination: _ignoreDestination,
            onOpenAttention: _noop,
            onAddSchedule: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Federation2399LandscapeChassis), findsOneWidget);
      expect(find.byType(Federation2399NineSliceFrame), findsNothing);
      expect(find.byType(FederationClassicNineSliceFrame), findsNothing);
      expect(find.byType(GraphiteNineSliceFrame), findsNothing);
      expect(find.byType(VariantFNineSliceFrame), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Federation Classic landscape composes one integrated concept chassis',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1586, 992));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _shellHarness(
          theme: federationClassic.standardPresentation.createThemeData(),
          boundaryKey: GlobalKey(),
          shell: federationClassic.shellRenderer.build(
            slots: _slots,
            environmentName: 'TEST',
            onOpenMenu: _noop,
            onOpenDestination: _ignoreDestination,
            onOpenAttention: _noop,
            onAddSchedule: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('federation-classic-landscape-shell')),
        findsOneWidget,
      );
      expect(find.byType(FederationClassicLandscapeChassis), findsOneWidget);
      expect(find.byType(FederationClassicNineSliceFrame), findsNothing);
      final placements = tester.getRect(
        find.byKey(const Key('federation-classic-placement-bay')),
      );
      final calendar = tester.getRect(
        find.byKey(const Key('federation-classic-calendar-bay')),
      );
      final planning = tester.getRect(
        find.byKey(const Key('federation-classic-planning-bay')),
      );
      final insight = tester.getRect(
        find.byKey(const Key('federation-classic-insight-bay')),
      );
      final navigation = tester.getRect(
        find.byKey(const Key('federation-classic-bottom-navigation')),
      );
      // Independent literals measured from the approved #113 concept at its
      // native 1586x992 exemplar. These are intentionally not derived from
      // the renderer or from a runtime-generated golden.
      _expectRectNear(placements, const Rect.fromLTWH(90, 112, 306, 702));
      _expectRectNear(calendar, const Rect.fromLTWH(406, 112, 736, 473));
      _expectRectNear(planning, const Rect.fromLTWH(406, 591, 736, 276));
      _expectRectNear(insight, const Rect.fromLTWH(1162, 112, 367, 702));
      _expectRectNear(navigation, const Rect.fromLTWH(10, 887, 1566, 97));
      expect(placements.right, lessThan(calendar.left));
      expect(calendar.right, lessThan(insight.left));
      expect(planning.top, greaterThan(calendar.top));
      expect(planning.left, calendar.left);
      expect(planning.right, calendar.right);
      expect(navigation.top, greaterThan(planning.bottom));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Federation Classic owned controls preserve shell callbacks', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1536, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var menuCount = 0;
    var addCount = 0;
    var attentionCount = 0;
    final destinations = <ClinicalCalendarDestination>[];

    await tester.pumpWidget(
      _shellHarness(
        theme: federationClassic.standardPresentation.createThemeData(),
        boundaryKey: GlobalKey(),
        shell: federationClassic.shellRenderer.build(
          slots: _slots,
          environmentName: 'TEST',
          onOpenMenu: () => menuCount++,
          onOpenDestination: destinations.add,
          onOpenAttention: () => attentionCount++,
          onAddSchedule: () => addCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open menu'));
    await tester.tap(find.byTooltip('Add schedule'));
    await tester.tap(find.byTooltip('Help'));
    await tester.tap(find.byKey(const Key('federation-classic-navigation-0')));
    await tester.tap(find.byKey(const Key('federation-classic-navigation-1')));
    await tester.tap(find.byKey(const Key('federation-classic-navigation-2')));
    await tester.tap(find.byKey(const Key('federation-classic-navigation-3')));
    await tester.tap(find.byKey(const Key('federation-classic-navigation-4')));

    expect(menuCount, 1);
    expect(addCount, 1);
    expect(attentionCount, 1);
    expect(destinations, [
      ClinicalCalendarDestination.help,
      ClinicalCalendarDestination.calendar,
      ClinicalCalendarDestination.calendar,
      ClinicalCalendarDestination.clinicalPlacements,
      ClinicalCalendarDestination.settings,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Federation Classic portrait has an intentional reading order', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1440));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _shellHarness(
        theme: federationClassic.standardPresentation.createThemeData(),
        boundaryKey: GlobalKey(),
        shell: federationClassic.shellRenderer.build(
          slots: _slots,
          environmentName: 'TEST',
          onOpenMenu: _noop,
          onOpenDestination: _ignoreDestination,
          onOpenAttention: _noop,
          onAddSchedule: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('federation-classic-portrait-shell')),
      findsOneWidget,
    );
    expect(find.byType(FederationClassicNineSliceFrame), findsOneWidget);
    final calendar = tester.getRect(
      find.byKey(const Key('federation-classic-calendar-bay')),
    );
    final planning = tester.getRect(
      find.byKey(const Key('federation-classic-planning-bay')),
    );
    final placements = tester.getRect(
      find.byKey(const Key('federation-classic-placement-bay')),
    );
    final insight = tester.getRect(
      find.byKey(const Key('federation-classic-insight-bay')),
    );
    final navigation = tester.getRect(
      find.byKey(const Key('federation-classic-bottom-navigation')),
    );
    expect(navigation.right, lessThan(calendar.left));
    expect(calendar.top, lessThan(planning.top));
    expect(planning.top, lessThan(placements.top));
    expect(placements.top, lessThan(insight.top));
    expect(navigation.bottom, lessThanOrEqualTo(1440));
    expect(navigation.top, lessThanOrEqualTo(calendar.top));
    expect(
      find.byKey(const Key('federation-classic-portrait-scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('federation-classic-help-action')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Federation Classic gives shared landing workflows owned housings',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1586, 992));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const slots = ResponsiveShellSlots(
        centralContent: Text('Calendar fixture'),
        placementDock: ShellPanel(
          label: 'My placements',
          child: Text('Live placement workflow'),
        ),
        planningRegion: ShellPanel(
          label: 'Planning',
          child: Text('Live planning workflow'),
        ),
        insightRail: Column(
          children: [
            ShellPanel(
              label: 'Clinical Placement',
              child: Text('Live progress workflow'),
            ),
            ShellPanel(
              label: 'Needs Attention · 2',
              child: Text('Live attention workflow'),
            ),
          ],
        ),
        mobilePlacementSummary: Text('Placement summary fixture'),
        mobileAttention: Text('Attention fixture'),
        profileAvatar: SizedBox.square(dimension: 44),
      );
      await tester.pumpWidget(
        _shellHarness(
          theme: federationClassic.standardPresentation.createThemeData(),
          boundaryKey: GlobalKey(),
          shell: federationClassic.shellRenderer.build(
            slots: slots,
            environmentName: 'TEST',
            onOpenMenu: _noop,
            onOpenDestination: _ignoreDestination,
            onOpenAttention: _noop,
            onAddSchedule: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final key in const [
        'federation-classic-placements-housing',
        'federation-classic-planning-housing',
        'federation-classic-clinical-placement-housing',
        'federation-classic-needs-attention-housing',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
      expect(find.byType(VariantFTacticalFrame), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Federation Classic tablet console survives 200% text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1440));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: federationClassic.standardPresentation.createThemeData(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: federationClassic.shellRenderer.build(
          slots: _slots,
          environmentName: 'TEST',
          onOpenMenu: _noop,
          onOpenDestination: _ignoreDestination,
          onOpenAttention: _noop,
          onAddSchedule: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('federation-classic-portrait-shell')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('federation-classic-bottom-navigation')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('federation-classic-calendar-horizontal-scroll')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Federation 2399 landscape composes one integrated concept chassis',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1536, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _shellHarness(
          theme: federation2399.standardPresentation.createThemeData(),
          boundaryKey: GlobalKey(),
          shell: federation2399.shellRenderer.build(
            slots: _slots,
            environmentName: 'TEST',
            onOpenMenu: _noop,
            onOpenDestination: _ignoreDestination,
            onOpenAttention: _noop,
            onAddSchedule: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('federation-2399-landscape-shell')),
        findsOneWidget,
      );
      expect(find.byType(Federation2399LandscapeChassis), findsOneWidget);
      expect(find.byType(Federation2399NineSliceFrame), findsNothing);
      final crown = tester.getRect(
        find.byKey(const Key('federation-2399-command-crown')),
      );
      final placements = tester.getRect(
        find.byKey(const Key('federation-2399-placement-bay')),
      );
      final calendar = tester.getRect(
        find.byKey(const Key('federation-2399-calendar-bay')),
      );
      final planning = tester.getRect(
        find.byKey(const Key('federation-2399-planning-bay')),
      );
      final insight = tester.getRect(
        find.byKey(const Key('federation-2399-insight-bay')),
      );
      final navigation = tester.getRect(
        find.byKey(const Key('federation-2399-bottom-navigation')),
      );
      // Absolute 1536 x 1024 coordinates measured from the approved #114
      // concept, not ratios copied from the renderer implementation.
      _expectRectCloseTo(crown, const Rect.fromLTWH(40, 45, 1044, 76));
      _expectRectCloseTo(placements, const Rect.fromLTWH(54, 131, 261, 748));
      _expectRectCloseTo(calendar, const Rect.fromLTWH(361, 133, 734, 458));
      _expectRectCloseTo(planning, const Rect.fromLTWH(361, 625, 734, 251));
      _expectRectCloseTo(insight, const Rect.fromLTWH(1158, 85, 346, 791));
      _expectRectCloseTo(navigation, const Rect.fromLTWH(86, 916, 1364, 70));
      expect(placements.right, lessThan(calendar.left));
      expect(calendar.right, lessThan(insight.left));
      expect(planning.top, greaterThan(calendar.top));
      expect(planning.left, calendar.left);
      expect(planning.right, calendar.right);
      expect(navigation.top, greaterThan(planning.bottom));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Federation 2399 owned controls preserve shell callbacks', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1536, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var menuCount = 0;
    var addCount = 0;
    var attentionCount = 0;
    final destinations = <ClinicalCalendarDestination>[];

    await tester.pumpWidget(
      _shellHarness(
        theme: federation2399.standardPresentation.createThemeData(),
        boundaryKey: GlobalKey(),
        shell: federation2399.shellRenderer.build(
          slots: _slots,
          environmentName: 'TEST',
          onOpenMenu: () => menuCount++,
          onOpenDestination: destinations.add,
          onOpenAttention: () => attentionCount++,
          onAddSchedule: () => addCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final applicationMenu = find.byKey(const Key('application-menu-action'));
    expect(
      find.descendant(
        of: applicationMenu,
        matching: find.byType(CanonicalDeltaMark),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Open menu'), findsOneWidget);
    expect(find.bySemanticsLabel('Axion delta'), findsNothing);
    await tester.tap(find.byTooltip('Open menu'));
    await tester.tap(find.byTooltip('Add Placement'));
    await tester.tap(find.byTooltip('Help'));
    expect(
      find.byKey(const Key('federation-2399-profile-control-housing')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('federation-2399-navigation-2')));
    await tester.tap(find.byKey(const Key('federation-2399-navigation-3')));
    await tester.tap(find.byKey(const Key('federation-2399-navigation-4')));

    expect(menuCount, 1);
    expect(addCount, 0);
    expect(attentionCount, 1);
    expect(destinations, [
      ClinicalCalendarDestination.clinicalPlacements,
      ClinicalCalendarDestination.help,
      ClinicalCalendarDestination.clinicalPlacements,
      ClinicalCalendarDestination.settings,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Federation 2399 portrait has an intentional ordered console', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1440));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _shellHarness(
        theme: federation2399.standardPresentation.createThemeData(),
        boundaryKey: GlobalKey(),
        shell: federation2399.shellRenderer.build(
          slots: _slots,
          environmentName: 'TEST',
          onOpenMenu: _noop,
          onOpenDestination: _ignoreDestination,
          onOpenAttention: _noop,
          onAddSchedule: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('federation-2399-portrait-shell')),
      findsOneWidget,
    );
    expect(find.byType(Federation2399NineSliceFrame), findsOneWidget);
    final calendar = tester.getRect(
      find.byKey(const Key('federation-2399-calendar-bay')),
    );
    final planning = tester.getRect(
      find.byKey(const Key('federation-2399-planning-bay')),
    );
    final placements = tester.getRect(
      find.byKey(const Key('federation-2399-placement-bay')),
    );
    final insight = tester.getRect(
      find.byKey(const Key('federation-2399-insight-bay')),
    );
    final navigation = tester.getRect(
      find.byKey(const Key('federation-2399-bottom-navigation')),
    );
    expect(calendar.top, lessThan(planning.top));
    expect(planning.top, lessThan(placements.top));
    expect(placements.top, insight.top);
    expect(placements.right, lessThan(insight.left));
    expect(navigation.top, greaterThan(calendar.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Federation 2399 tablet console survives 200% text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1440));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: federation2399.standardPresentation.createThemeData(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: federation2399.shellRenderer.build(
          slots: _slots,
          environmentName: 'TEST',
          onOpenMenu: _noop,
          onOpenDestination: _ignoreDestination,
          onOpenAttention: _noop,
          onAddSchedule: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('federation-2399-portrait-shell')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('federation-2399-bottom-navigation')),
      findsOneWidget,
    );
    expect(find.byTooltip('Add Placement'), findsOneWidget);
    expect(find.byTooltip('Help'), findsOneWidget);
    expect(
      find.byKey(const Key('federation-2399-profile-control-housing')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Coastal Light shell uses only Coastal Light raster framing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _shellHarness(
        theme: coastalLight.standardPresentation.createThemeData(),
        boundaryKey: GlobalKey(),
        shell: coastalLight.shellRenderer.build(
          slots: _slots,
          environmentName: 'TEST',
          onOpenMenu: _noop,
          onOpenDestination: _ignoreDestination,
          onOpenAttention: _noop,
          onAddSchedule: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CoastalLightLandscapeChassis), findsOneWidget);
    expect(find.byType(CoastalLightNineSliceFrame), findsNothing);
    expect(find.byType(FederationClassicNineSliceFrame), findsNothing);
    expect(find.byType(GraphiteNineSliceFrame), findsNothing);
    expect(find.byType(VariantFNineSliceFrame), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Coastal Light Enhanced suppresses atmospheric shell artwork', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final shell = coastalLight.shellRenderer.build(
      slots: _slots,
      environmentName: 'TEST',
      onOpenMenu: _noop,
      onOpenDestination: _ignoreDestination,
      onOpenAttention: _noop,
      onAddSchedule: _noop,
    );
    final theme = coastalLight.standardPresentation.createThemeData(
      enhancedAccessibility: true,
    );

    await tester.binding.setSurfaceSize(const Size(1586, 992));
    await tester.pumpWidget(
      _shellHarness(theme: theme, boundaryKey: GlobalKey(), shell: shell),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('coastal-light-enhanced-flat-chassis')),
      findsOneWidget,
    );
    expect(find.byType(CanonicalDeltaMark), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(900, 1440));
    await tester.pumpWidget(
      _shellHarness(theme: theme, boundaryKey: GlobalKey(), shell: shell),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('coastal-light-enhanced-flat-frame')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('coastal-light-enhanced-flat-crown')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('coastal-light-enhanced-flat-bay')),
      findsNWidgets(4),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Coastal Light landscape composes one integrated concept chassis',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1586, 992));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _shellHarness(
          theme: coastalLight.standardPresentation.createThemeData(),
          boundaryKey: GlobalKey(),
          shell: coastalLight.shellRenderer.build(
            slots: _slots,
            environmentName: 'TEST',
            onOpenMenu: _noop,
            onOpenDestination: _ignoreDestination,
            onOpenAttention: _noop,
            onAddSchedule: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('coastal-calm-landscape-shell')),
        findsOneWidget,
      );
      expect(find.byType(CoastalLightLandscapeChassis), findsOneWidget);
      expect(find.byType(CoastalLightNineSliceFrame), findsNothing);
      final crown = tester.getRect(
        find.byKey(const Key('coastal-calm-command-crown')),
      );
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
      expect(crown.height / 992, closeTo(.072, .01));
      expect(placements.width / 1586, closeTo(.205, .01));
      expect(insight.width / 1586, closeTo(.227, .01));
      expect(calendar.width / 1586, closeTo(.519, .01));
      expect(placements.right, lessThan(calendar.left));
      expect(calendar.right, lessThan(insight.left));
      expect(planning.top, greaterThan(calendar.top));
      expect(planning.left, calendar.left);
      expect(planning.right, calendar.right);
      expect(navigation.top, greaterThan(planning.bottom));
      expect(calendar.height / 992, closeTo(.54, .01));
      expect(planning.height / 992, closeTo(.263, .01));
      expect(navigation.height / 992, closeTo(.076, .01));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Coastal Light owned controls preserve shell callbacks', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1536, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var menuCount = 0;
    var addCount = 0;
    var attentionCount = 0;
    final destinations = <ClinicalCalendarDestination>[];

    await tester.pumpWidget(
      _shellHarness(
        theme: coastalLight.standardPresentation.createThemeData(),
        boundaryKey: GlobalKey(),
        shell: coastalLight.shellRenderer.build(
          slots: _slots,
          environmentName: 'TEST',
          onOpenMenu: () => menuCount++,
          onOpenDestination: destinations.add,
          onOpenAttention: () => attentionCount++,
          onAddSchedule: () => addCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open menu'));
    await tester.tap(find.byTooltip('Add schedule'));
    await tester.tap(
      find.byKey(const Key('coastal-light-add-placement-action')),
    );
    await tester.tap(find.byKey(const Key('coastal-light-help-action')));
    await tester.tap(find.byKey(const Key('coastal-calm-navigation-2')));
    await tester.tap(find.byKey(const Key('coastal-calm-navigation-3')));
    await tester.tap(find.byKey(const Key('coastal-calm-navigation-4')));

    expect(menuCount, 1);
    expect(addCount, 1);
    expect(attentionCount, 1);
    expect(destinations, [
      ClinicalCalendarDestination.clinicalPlacements,
      ClinicalCalendarDestination.help,
      ClinicalCalendarDestination.clinicalPlacements,
      ClinicalCalendarDestination.settings,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Coastal Light portrait has an intentional ordered console', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1440));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _shellHarness(
        theme: coastalLight.standardPresentation.createThemeData(),
        boundaryKey: GlobalKey(),
        shell: coastalLight.shellRenderer.build(
          slots: _slots,
          environmentName: 'TEST',
          onOpenMenu: _noop,
          onOpenDestination: _ignoreDestination,
          onOpenAttention: _noop,
          onAddSchedule: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('coastal-calm-portrait-shell')),
      findsOneWidget,
    );
    expect(find.byType(CoastalLightNineSliceFrame), findsOneWidget);
    final calendar = tester.getRect(
      find.byKey(const Key('coastal-calm-calendar-bay')),
    );
    final planning = tester.getRect(
      find.byKey(const Key('coastal-calm-planning-bay')),
    );
    final placements = tester.getRect(
      find.byKey(const Key('coastal-calm-placement-bay')),
    );
    final insight = tester.getRect(
      find.byKey(const Key('coastal-calm-insight-bay')),
    );
    final navigation = tester.getRect(
      find.byKey(const Key('coastal-calm-bottom-navigation')),
    );
    expect(calendar.top, lessThan(planning.top));
    expect(planning.top, lessThan(placements.top));
    expect(placements.top, insight.top);
    expect(placements.right, lessThan(insight.left));
    expect(navigation.top, greaterThan(calendar.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Coastal Light tablet console survives 200% text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1440));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: coastalLight.standardPresentation.createThemeData(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: coastalLight.shellRenderer.build(
          slots: _slots,
          environmentName: 'TEST',
          onOpenMenu: _noop,
          onOpenDestination: _ignoreDestination,
          onOpenAttention: _noop,
          onAddSchedule: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('coastal-calm-portrait-shell')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('coastal-calm-bottom-navigation')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(320, 568), Size(768, 1024), Size(1440, 900)]) {
    testWidgets(
      'Federation Classic shell fits ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _shellHarness(
            theme: federationClassic.standardPresentation.createThemeData(),
            boundaryKey: GlobalKey(),
            shell: federationClassic.shellRenderer.build(
              slots: _slots,
              environmentName: 'TEST',
              onOpenMenu: _noop,
              onOpenDestination: _ignoreDestination,
              onOpenAttention: _noop,
              onAddSchedule: _noop,
            ),
          ),
        );
        await tester.pumpAndSettle();

        if (size.width > size.height && size.width >= 960) {
          expect(
            find.byType(FederationClassicLandscapeChassis),
            findsOneWidget,
          );
          expect(find.byType(FederationClassicNineSliceFrame), findsNothing);
        } else {
          expect(find.byType(FederationClassicNineSliceFrame), findsWidgets);
          expect(find.byType(FederationClassicLandscapeChassis), findsNothing);
          expect(find.byType(ClipRect), findsWidgets);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final size in const [Size(320, 568), Size(768, 1024), Size(1440, 900)]) {
    testWidgets(
      'Federation 2399 shell fits ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _shellHarness(
            theme: federation2399.standardPresentation.createThemeData(),
            boundaryKey: GlobalKey(),
            shell: federation2399.shellRenderer.build(
              slots: _slots,
              environmentName: 'TEST',
              onOpenMenu: _noop,
              onOpenDestination: _ignoreDestination,
              onOpenAttention: _noop,
              onAddSchedule: _noop,
            ),
          ),
        );
        await tester.pumpAndSettle();

        if (size.width > size.height && size.width >= 960) {
          expect(find.byType(Federation2399LandscapeChassis), findsOneWidget);
          expect(find.byType(Federation2399NineSliceFrame), findsNothing);
        } else {
          expect(find.byType(Federation2399NineSliceFrame), findsWidgets);
          expect(find.byType(Federation2399LandscapeChassis), findsNothing);
        }
        if (!(size.width > size.height && size.width >= 960)) {
          expect(find.byType(ClipRect), findsWidgets);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final size in const [Size(320, 568), Size(768, 1024), Size(1440, 900)]) {
    testWidgets(
      'Coastal Light shell fits ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _shellHarness(
            theme: coastalLight.standardPresentation.createThemeData(),
            boundaryKey: GlobalKey(),
            shell: coastalLight.shellRenderer.build(
              slots: _slots,
              environmentName: 'TEST',
              onOpenMenu: _noop,
              onOpenDestination: _ignoreDestination,
              onOpenAttention: _noop,
              onAddSchedule: _noop,
            ),
          ),
        );
        await tester.pumpAndSettle();

        if (size.width > size.height && size.width >= 960) {
          expect(find.byType(CoastalLightLandscapeChassis), findsOneWidget);
          expect(find.byType(CoastalLightNineSliceFrame), findsNothing);
        } else {
          expect(find.byType(CoastalLightNineSliceFrame), findsWidgets);
          expect(find.byType(CoastalLightLandscapeChassis), findsNothing);
        }
        if (!(size.width > size.height && size.width >= 960)) {
          expect(find.byType(ClipRect), findsWidgets);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Federation 2399 destination keeps compact owned chrome', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: federation2399.standardPresentation.createThemeData(),
        home: federation2399.shellRenderer.buildDestination(
          destination: ClinicalCalendarDestination.settings,
          entry: DestinationEntry.direct,
          onExit: _noop,
          child: const ShellPanel(
            label: 'Settings fixture',
            child: Text('Fictional content'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VariantFNineSliceFrame), findsNothing);
    expect(
      tester
          .widget<Federation2399NineSliceFrame>(
            find.byType(Federation2399NineSliceFrame),
          )
          .chromeInsets,
      federation2399CompactDestinationInsets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Coastal Light destination keeps compact owned chrome', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: coastalLight.standardPresentation.createThemeData(),
        home: coastalLight.shellRenderer.buildDestination(
          destination: ClinicalCalendarDestination.settings,
          entry: DestinationEntry.direct,
          onExit: _noop,
          child: const ShellPanel(
            label: 'Settings fixture',
            child: Text('Fictional content'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VariantFNineSliceFrame), findsNothing);
    expect(find.byType(CoastalLightNineSliceFrame), findsNothing);
    expect(
      find.byKey(const Key('coastal-light-destination-crown')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('coastal-light-destination-housing')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Graphite destination keeps owned compact machinery and no raster frame',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: graphite.standardPresentation.createThemeData(),
          home: graphite.shellRenderer.buildDestination(
            destination: ClinicalCalendarDestination.settings,
            entry: DestinationEntry.direct,
            onExit: _noop,
            child: const ShellPanel(
              label: 'Settings fixture',
              child: Text('Fictional content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VariantFNineSliceFrame), findsNothing);
      expect(
        find.byKey(const Key('graphite-destination-shell')),
        findsOneWidget,
      );
      expect(find.byType(GraphiteNineSliceFrame), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Graphite owns one coherent shell across all ten top-level destinations',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1536, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final destination in applicationMenuDestinations) {
        await tester.pumpWidget(
          MaterialApp(
            theme: graphite.standardPresentation.createThemeData(),
            home: graphite.shellRenderer.buildDestination(
              destination: destination,
              entry: DestinationEntry.applicationMenu,
              onExit: _noop,
              child: ShellPanel(
                label: '${destination.label} fixture',
                child: const Text('Fictional shared workflow content'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('graphite-destination-shell')),
          findsOneWidget,
          reason: destination.label,
        );
        expect(
          find.byKey(const Key('graphite-destination-crown')),
          findsOneWidget,
          reason: destination.label,
        );
        expect(
          find.byKey(const Key('graphite-destination-bay')),
          findsOneWidget,
          reason: destination.label,
        );
        expect(
          find.byKey(const Key('graphite-destination-grid')),
          findsNothing,
          reason: destination.label,
        );
        expect(find.byType(CanonicalDeltaMark), findsOneWidget);
        expect(find.byType(AdditiveThemeDestinationSurface), findsNothing);
        expect(find.byType(GraphiteNineSliceFrame), findsNothing);
        expect(find.byType(VariantFNineSliceFrame), findsNothing);
        expect(tester.takeException(), isNull, reason: destination.label);
      }
    },
  );

  testWidgets(
    'Federation Classic owns one coherent shell across all top-level destinations',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1586, 992));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final destination in applicationMenuDestinations) {
        await tester.pumpWidget(
          MaterialApp(
            theme: federationClassic.standardPresentation.createThemeData(),
            home: federationClassic.shellRenderer.buildDestination(
              destination: destination,
              entry: DestinationEntry.applicationMenu,
              onExit: _noop,
              child: ShellPanel(
                label: '${destination.label} fixture',
                child: const Text('Fictional shared workflow content'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('federation-classic-destination-shell')),
          findsOneWidget,
          reason: destination.label,
        );
        expect(
          find.byKey(const Key('federation-classic-destination-crown')),
          findsOneWidget,
          reason: destination.label,
        );
        expect(
          find.byKey(const Key('federation-classic-destination-bay')),
          findsOneWidget,
          reason: destination.label,
        );
        expect(find.byType(CanonicalDeltaMark), findsOneWidget);
        expect(find.byType(AdditiveThemeDestinationSurface), findsNothing);
        expect(find.byType(GraphiteNineSliceFrame), findsNothing);
        expect(find.byType(VariantFNineSliceFrame), findsNothing);
        expect(tester.takeException(), isNull, reason: destination.label);
      }
    },
  );

  testWidgets(
    'Federation Classic destination remains operable at 200 percent text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1440));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var exitCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: federationClassic.standardPresentation.createThemeData(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: federationClassic.shellRenderer.buildDestination(
              destination: ClinicalCalendarDestination.clinicalPlacements,
              entry: DestinationEntry.applicationMenu,
              onExit: () => exitCount++,
              child: const SingleChildScrollView(
                child: SizedBox(
                  height: 1800,
                  child: Text('Fictional shared Clinical Placement content'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('federation-classic-destination-scroll')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('back-action')), findsOneWidget);
      expect(find.text('Clinical Placements'), findsOneWidget);
      await tester.tap(find.byKey(const Key('back-action')));
      expect(exitCount, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Graphite destination remains operable at 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1440));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var exitCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: graphite.standardPresentation.createThemeData(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: graphite.shellRenderer.buildDestination(
            destination: ClinicalCalendarDestination.clinicalPlacements,
            entry: DestinationEntry.applicationMenu,
            onExit: () => exitCount++,
            child: const SingleChildScrollView(
              child: SizedBox(
                height: 1800,
                child: Text('Fictional shared Clinical Placement content'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('graphite-destination-scroll')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('back-action')), findsOneWidget);
    expect(find.text('Clinical Placements'), findsOneWidget);
    await tester.tap(find.byKey(const Key('back-action')));
    expect(exitCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late Graphite failure replaces the complete application', (
    tester,
  ) async {
    var restarted = false;
    await tester.pumpWidget(
      GraphitePresentationFailureBoundary(
        onRestart: () => restarted = true,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  const Text('Fictional Student calendar data'),
                  FilledButton(
                    onPressed: () => GraphitePresentationFailureBoundary.report(
                      context,
                      StateError('late decode'),
                      themeId: graphiteThemeId,
                      isGraphite: true,
                    ),
                    child: const Text('Fail frame'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Fail frame'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('graphite-presentation-unavailable')),
      findsOneWidget,
    );
    expect(find.text('Fictional Student calendar data'), findsNothing);
    await tester.tap(find.text('Restart'));
    expect(restarted, isTrue);
  });

  testWidgets(
    'Federation Classic frame decode failure swaps to complete Graphite',
    (tester) async {
      ClinicalCalendarThemeBundle effectiveBundle = federationClassic;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => GraphitePresentationFailureBoundary(
            onRestart: _noop,
            onBundleFailure: (failedThemeId) {
              expect(failedThemeId, federationClassicThemeId);
              setState(() => effectiveBundle = graphite);
            },
            child: effectiveBundle.id == federationClassicThemeId
                ? DefaultAssetBundle(
                    bundle: _FailingAssetBundle(),
                    child: MaterialApp(
                      theme: federationClassic.standardPresentation
                          .createThemeData(),
                      home: const FederationClassicNineSliceFrame(
                        child: Text('Fictional Calendar content'),
                      ),
                    ),
                  )
                : DefaultAssetBundle(
                    bundle: rootBundle,
                    child: MaterialApp(
                      theme: graphite.standardPresentation.createThemeData(),
                      home: graphite.shellRenderer.buildFrame(
                        child: const Text('Fictional Calendar content'),
                      ),
                    ),
                  ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FederationClassicNineSliceFrame), findsNothing);
      expect(find.byType(GraphiteNineSliceFrame), findsOneWidget);
      expect(find.text('Fictional Calendar content'), findsOneWidget);
      expect(
        find.byKey(const Key('graphite-presentation-unavailable')),
        findsNothing,
      );
    },
  );
}

Widget _shellHarness({
  required ThemeData theme,
  required GlobalKey boundaryKey,
  required Widget shell,
}) => MaterialApp(
  theme: theme,
  home: RepaintBoundary(key: boundaryKey, child: shell),
);

Future<ui.Image> _capture(GlobalKey key) =>
    (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
        .toImage();

void _expectRectNear(Rect actual, Rect expected) {
  const tolerance = 3.0;
  expect(actual.left, closeTo(expected.left, tolerance));
  expect(actual.top, closeTo(expected.top, tolerance));
  expect(actual.width, closeTo(expected.width, tolerance));
  expect(actual.height, closeTo(expected.height, tolerance));
}

const _slots = ResponsiveShellSlots(
  centralContent: Center(child: Text('Calendar fixture')),
  planningRegion: Text('Planning fixture'),
  placementDock: Text('Placement fixture'),
  insightRail: GraphiteInsightRailSlots(
    placementProgress: Text('Placement progress fixture'),
    attention: Text('Attention rail fixture'),
  ),
  mobilePlacementSummary: Text('Placement summary fixture'),
  mobileAttention: Text('Attention fixture'),
  profileAvatar: SizedBox.square(dimension: 44),
);

final class _ExpandablePreceptorFixture extends StatefulWidget {
  const _ExpandablePreceptorFixture();

  @override
  State<_ExpandablePreceptorFixture> createState() =>
      _ExpandablePreceptorFixtureState();
}

final class _ExpandablePreceptorFixtureState
    extends State<_ExpandablePreceptorFixture> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 160, child: Text('Placement wheel fixture')),
      TextButton(
        key: const Key('toggle-preceptor-breakdown'),
        onPressed: () => setState(() => _expanded = !_expanded),
        child: Text(_expanded ? 'HIDE PRECEPTORS' : 'SHOW PRECEPTORS'),
      ),
      if (_expanded)
        const SizedBox(
          height: 600,
          child: ColoredBox(
            color: Colors.green,
            child: Text('Expanded Preceptors'),
          ),
        ),
    ],
  );
}

void _noop() {}

void _ignoreDestination(ClinicalCalendarDestination _) {}

void _expectRectCloseTo(Rect actual, Rect expected) {
  expect(actual.left, closeTo(expected.left, 3));
  expect(actual.top, closeTo(expected.top, 3));
  expect(actual.width, closeTo(expected.width, 3));
  expect(actual.height, closeTo(expected.height, 3));
}

final class _TestBundle implements ClinicalCalendarThemeBundle {
  const _TestBundle({
    required this.id,
    this.origin = ThemeBundleOrigin.compiled,
    this.overrideMetadata,
  });

  static const _delegate = VariantFThemeBundle();

  @override
  final String id;
  @override
  final ThemeBundleOrigin origin;
  final ThemeCatalogMetadata? overrideMetadata;

  @override
  ThemeCatalogMetadata get metadata => overrideMetadata ?? _delegate.metadata;

  @override
  ClinicalCalendarStandardPresentation get standardPresentation =>
      _delegate.standardPresentation;

  @override
  ClinicalCalendarShellRenderer get shellRenderer => _delegate.shellRenderer;

  @override
  ThemeFrameDescriptor get frame => _delegate.frame;

  @override
  ThemeGalleryData get gallery => _delegate.gallery;

  @override
  ClinicalCalendarSemanticMarks get marks => _delegate.marks;

  @override
  ThemeHelpGuide get helpGuide => _delegate.helpGuide;
}

final class _FailingAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) =>
      Future.error(StateError('fixture asset decode failure'));
}
