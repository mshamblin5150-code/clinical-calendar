import 'dart:ui' as ui;

import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bundle = VariantFThemeBundle();
  const graphite = GraphiteThemeBundle();
  const federationClassic = FederationClassicThemeBundle();

  test('Containment Drone is one complete internally owned bundle', () {
    ClinicalCalendarThemeBundleValidator.validate(const [bundle]);

    expect(bundle.id, variantFThemeId);
    expect(bundle.metadata.displayName, 'Containment Drone 47-Alpha');
    expect(bundle.standardPresentation, isA<VariantFVisualTheme>());
    expect(bundle.shellRenderer, isA<VariantFShellRenderer>());
    expect(bundle.frame.sourceSize, const Size(1536, 1024));
    expect(
      bundle.frame.sourceCuts,
      const EdgeInsets.fromLTRB(120, 145, 120, 170),
    );
    expect(bundle.frame.assetPaths, hasLength(4));
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
    expect(graphite.frame.assetPaths, hasLength(1));
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
    expect(federationClassic.frame.assetPaths, hasLength(1));
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

  test(
    'Enhanced is an overlay and Standard round trips exactly for both bundles',
    () {
      for (final themedBundle in const <ClinicalCalendarThemeBundle>[
        VariantFThemeBundle(),
        GraphiteThemeBundle(),
        FederationClassicThemeBundle(),
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

  test('Graphite remains fallback until the complete catalog activates', () {
    final resolved = ClinicalCalendarThemeBundleRegistry.standard
        .resolveApplied(graphiteThemeId);

    expect(resolved.storedId, graphiteThemeId);
    expect(resolved.bundle, isA<GraphiteThemeBundle>());
    expect(resolved.isFallback, isTrue);
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

  test('partial catalog is not selectable or visible', () {
    final registry = ClinicalCalendarThemeBundleRegistry.standard;

    expect(registry.isSelectableCatalogComplete, isFalse);
    expect(registry.selectableBundles, isEmpty);
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

  testWidgets('bundle shell exactly matches the existing renderer lane', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final directKey = GlobalKey();
    await tester.pumpWidget(
      _shellHarness(
        theme: const VariantFVisualTheme().createThemeData(),
        boundaryKey: directKey,
        shell: ResponsiveApplicationShell(
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
    final directImage = await _capture(directKey);
    addTearDown(directImage.dispose);

    const resolved = VariantFThemeBundle();
    final bundleKey = GlobalKey();
    await tester.pumpWidget(
      _shellHarness(
        theme: resolved.standardPresentation.createThemeData(),
        boundaryKey: bundleKey,
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
      find.byKey(bundleKey),
      matchesReferenceImage(directImage),
    );
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

  testWidgets(
    'Federation Classic shell uses only Federation Classic raster framing',
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

      expect(find.byType(FederationClassicNineSliceFrame), findsWidgets);
      expect(find.byType(GraphiteNineSliceFrame), findsNothing);
      expect(find.byType(VariantFNineSliceFrame), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

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

        expect(find.byType(FederationClassicNineSliceFrame), findsWidgets);
        expect(find.byType(ClipRect), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Graphite destination keeps compact chrome and no Variant frame',
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
        tester
            .widget<GraphiteNineSliceFrame>(find.byType(GraphiteNineSliceFrame))
            .chromeInsets,
        graphiteCompactDestinationInsets,
      );
      expect(tester.takeException(), isNull);
    },
  );

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
                : MaterialApp(
                    theme: graphite.standardPresentation.createThemeData(),
                    home: graphite.shellRenderer.buildFrame(
                      child: const Text('Fictional Calendar content'),
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

const _slots = ResponsiveShellSlots(
  centralContent: Center(child: Text('Calendar fixture')),
  planningRegion: Text('Planning fixture'),
  placementDock: Text('Placement fixture'),
  insightRail: Text('Insight fixture'),
  mobilePlacementSummary: Text('Placement summary fixture'),
  mobileAttention: Text('Attention fixture'),
  profileAvatar: SizedBox.square(dimension: 44),
);

void _noop() {}

void _ignoreDestination(ClinicalCalendarDestination _) {}

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
