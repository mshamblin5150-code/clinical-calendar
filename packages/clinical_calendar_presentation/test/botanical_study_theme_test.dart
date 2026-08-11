import 'dart:io';

import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:clinical_calendar_presentation/src/canonical_delta_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const botanical = BotanicalStudyThemeBundle();

  test('Botanical Study is one complete independently owned bundle', () {
    ClinicalCalendarThemeBundleValidator.validate(const [botanical]);

    expect(botanical.id, botanicalStudyThemeId);
    expect(botanical.metadata.displayName, 'Botanical Study');
    expect(botanical.standardPresentation, isA<BotanicalStudyVisualTheme>());
    expect(botanical.shellRenderer, isA<BotanicalStudyShellRenderer>());
    expect(botanical.frame.sourceSize, const Size(1536, 1024));
    expect(
      botanical.frame.sourceCuts,
      const EdgeInsets.fromLTRB(120, 145, 120, 170),
    );
    expect(botanical.frame.assetPaths, [
      botanicalStudyFrameAsset,
      botanicalStudyLandscapeChassisAsset,
      canonicalDeltaMarkAsset,
    ]);
    expect(botanical.gallery.swatches, hasLength(5));
    expect(botanical.marks.marks, hasLength(9));
    expect(botanical.helpGuide.calendarStates, hasLength(5));
    final standardTokens = botanical.standardPresentation
        .createThemeData()
        .extension<ClinicalCalendarAccessibilityTokens>()!;
    final calendarVisuals = botanical.standardPresentation
        .createThemeData()
        .extension<ClinicalCalendarPresentationPolicy>()!;
    final enhancedTokens = botanical.standardPresentation
        .createThemeData(enhancedAccessibility: true)
        .extension<ClinicalCalendarAccessibilityTokens>()!;
    final enhancedCalendarVisuals = botanical.standardPresentation
        .createThemeData(enhancedAccessibility: true)
        .extension<ClinicalCalendarPresentationPolicy>()!;
    expect(standardTokens.selectionWidth, 2);
    expect(enhancedTokens.focusOuterColor, const Color(0xFF4D1F55));
    expect(enhancedTokens.selectionWidth, 3);
    expect(enhancedCalendarVisuals.selectedDayBorder, const Color(0xFF4D1F55));
    expect(calendarVisuals.denseMarkerStyle, CalendarDenseMarkerStyle.chip);
    expect(calendarVisuals.toolbarStyle, CalendarToolbarStyle.conceptTitle);
    expect(calendarVisuals.neutralMonthDayBackgrounds, isTrue);
    expect(calendarVisuals.showMonthLegend, isTrue);
    expect(calendarVisuals.colorWeekdayHeader, isTrue);
    expect(calendarVisuals.monthColumnFlex?.values, [
      113,
      110,
      110,
      110,
      110,
      110,
      79,
    ]);
    expect(
      calendarVisuals.monthColumnFlex?.forDisplayColumn(
        displayColumn: 0,
        weekStartsOn: DateTime.monday,
      ),
      110,
    );
    expect(
      calendarVisuals.monthColumnFlex?.forDisplayColumn(
        displayColumn: 6,
        weekStartsOn: DateTime.monday,
      ),
      113,
    );
    expect(calendarVisuals.selectedDaySurface, const Color(0xFFE9D8E3));
    expect(calendarVisuals.selectedDayBorder, BotanicalStudyColors.focus);
    expect(
      ClinicalCalendarThemeBundleRegistry.standard.resolveRoot(
        botanicalStudyThemeId,
      ),
      same(botanical),
    );
  });

  test('existing themes retain their default owned frame paths', () {
    expect(
      const VariantFThemeBundle().shellRenderer.buildFrame(
        child: SizedBox.shrink(),
      ),
      isA<VariantFTacticalFrame>(),
    );
    expect(
      const GraphiteThemeBundle().shellRenderer.buildFrame(
        child: SizedBox.shrink(),
      ),
      isA<GraphiteNineSliceFrame>(),
    );
    expect(
      const FederationClassicThemeBundle().shellRenderer.buildFrame(
        child: SizedBox.shrink(),
      ),
      isA<FederationClassicNineSliceFrame>(),
    );
    expect(
      const Federation2399ThemeBundle().shellRenderer.buildFrame(
        child: SizedBox.shrink(),
      ),
      isA<Federation2399NineSliceFrame>(),
    );
  });

  test('Botanical Study frame is normalized original transparent artwork', () {
    final packageRelative = File(
      'assets/botanical_study_raster/panel-nine-slice-v1.png',
    );
    final file = packageRelative.existsSync()
        ? packageRelative
        : File(
            'packages/clinical_calendar_presentation/'
            'assets/botanical_study_raster/panel-nine-slice-v1.png',
          );
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(100000));
  });

  test('Botanical Study crown ships the Axion company mark', () {
    final packageRelative = File(canonicalDeltaMarkAsset);
    final file = packageRelative.existsSync()
        ? packageRelative
        : File(
            'packages/clinical_calendar_presentation/'
            '$canonicalDeltaMarkAsset',
          );
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(500));
  });

  testWidgets('Botanical Study owns landscape composition and callbacks', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1586, 992));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var menuCount = 0;
    var addCount = 0;
    var attentionCount = 0;
    final destinations = <ClinicalCalendarDestination>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: botanical.standardPresentation.createThemeData(),
        home: botanical.shellRenderer.build(
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

    expect(
      find.byKey(const Key('botanical-study-landscape-shell')),
      findsOneWidget,
    );
    expect(find.byType(BotanicalStudyLandscapeChassis), findsOneWidget);
    expect(find.byType(VariantFNineSliceFrame), findsNothing);
    final placements = tester.getRect(
      find.byKey(const Key('botanical-study-placement-bay')),
    );
    final calendar = tester.getRect(
      find.byKey(const Key('botanical-study-calendar-bay')),
    );
    final planning = tester.getRect(
      find.byKey(const Key('botanical-study-planning-bay')),
    );
    final insight = tester.getRect(
      find.byKey(const Key('botanical-study-insight-bay')),
    );
    final crown = tester.getRect(
      find.byKey(const Key('botanical-study-command-crown')),
    );
    final axionDelta = tester.getRect(
      find.byKey(const Key('botanical-study-axion-delta')),
    );
    final applicationTitle = tester.getRect(
      find.byKey(const Key('application-menu-action')),
    );
    final axionImage = tester.widget<Image>(
      find.byKey(const Key('botanical-study-axion-delta-image')),
    );
    final navigation = tester.getRect(
      find.byKey(const Key('botanical-study-bottom-navigation')),
    );
    _expectRectClose(crown, const Rect.fromLTWH(61, 0, 1494, 65));
    expect(axionDelta.size, const Size.square(42));
    expect(axionDelta.right, lessThan(applicationTitle.left));
    expect(axionImage.color, isNull);
    expect(axionImage.errorBuilder, isNotNull);
    _expectRectClose(placements, const Rect.fromLTWH(61, 66, 307, 834));
    _expectRectClose(calendar, const Rect.fromLTWH(378, 66, 767, 561));
    _expectRectClose(planning, const Rect.fromLTWH(378, 638, 767, 262));
    _expectRectClose(insight, const Rect.fromLTWH(1154, 66, 401, 834));
    _expectRectClose(navigation, const Rect.fromLTWH(0, 912, 1586, 80));

    await tester.tap(find.byTooltip('Open menu'));
    await tester.tap(find.byTooltip('Add schedule'));
    await tester.tap(find.byTooltip('Help'));
    await tester.tap(find.byKey(const Key('botanical-study-navigation-2')));
    await tester.tap(find.byKey(const Key('botanical-study-navigation-3')));
    await tester.tap(find.byKey(const Key('botanical-study-navigation-4')));

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
    'Botanical Study owns one coherent border shell across all ten top-level destinations',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1586, 992));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final destination in applicationMenuDestinations) {
        await tester.pumpWidget(
          MaterialApp(
            theme: botanical.standardPresentation.createThemeData(),
            home: botanical.shellRenderer.buildDestination(
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
          find.byKey(const Key('botanical-study-destination-shell')),
          findsOneWidget,
          reason: destination.label,
        );
        expect(
          find.byKey(const Key('botanical-study-destination-crown')),
          findsOneWidget,
          reason: destination.label,
        );
        expect(
          find.byKey(const Key('botanical-study-destination-bay')),
          findsOneWidget,
          reason: destination.label,
        );
        expect(find.byType(CanonicalDeltaMark), findsOneWidget);
        expect(find.byType(AdditiveThemeDestinationSurface), findsNothing);
        expect(find.byType(VariantFNineSliceFrame), findsNothing);
        expect(tester.takeException(), isNull, reason: destination.label);
      }
    },
  );

  testWidgets(
    'Botanical Study destination remains operable at 200 percent text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1440));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var exitCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: botanical.standardPresentation.createThemeData(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: botanical.shellRenderer.buildDestination(
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
        find.byKey(const Key('botanical-study-destination-scroll')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('back-action')), findsOneWidget);
      expect(find.text('Clinical Placements'), findsOneWidget);
      await tester.tap(find.byKey(const Key('back-action')));
      expect(exitCount, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Botanical Study portrait has explicit calendar-first order', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1440));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: botanical.standardPresentation.createThemeData(),
        home: botanical.shellRenderer.build(
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
      find.byKey(const Key('botanical-study-portrait-scroll')),
      findsOneWidget,
    );
    final calendar = tester.getRect(
      find.byKey(const Key('botanical-study-calendar-bay')),
    );
    final planning = tester.getRect(
      find.byKey(const Key('botanical-study-planning-bay')),
    );
    final placements = tester.getRect(
      find.byKey(const Key('botanical-study-placement-bay')),
    );
    final axionDelta = tester.getRect(
      find.byKey(const Key('botanical-study-axion-delta')),
    );
    expect(calendar.top, lessThan(planning.top));
    expect(planning.top, lessThan(placements.top));
    expect(axionDelta.width, greaterThanOrEqualTo(36));
    expect(axionDelta.height, greaterThanOrEqualTo(36));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Axion decode failure swaps the complete shell to Graphite', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1586, 992));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    ClinicalCalendarThemeBundle effectiveBundle = botanical;
    String? failedThemeId;
    final failingBundle = _FailingAxionAssetBundle(
      frameFile: _findWorkspaceFile(botanicalStudyFrameAsset),
      chassisFile: _findWorkspaceFile(botanicalStudyLandscapeChassisAsset),
    );
    final graphiteBundle = _GraphiteAssetBundle(
      frameFile: _findWorkspaceFile(graphiteFrameAsset),
    );

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => GraphitePresentationFailureBoundary(
          onBundleFailure: (themeId) {
            if (failedThemeId != null) return;
            failedThemeId = themeId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                setState(() => effectiveBundle = const GraphiteThemeBundle());
              }
            });
          },
          child: DefaultAssetBundle(
            bundle: effectiveBundle.id == botanicalStudyThemeId
                ? failingBundle
                : graphiteBundle,
            child: MaterialApp(
              theme: effectiveBundle.standardPresentation.createThemeData(),
              home: effectiveBundle.shellRenderer.build(
                slots: _slots,
                environmentName: 'TEST',
                onOpenMenu: _noop,
                onOpenDestination: _ignoreDestination,
                onOpenAttention: _noop,
                onAddSchedule: _noop,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(failedThemeId, botanicalStudyThemeId);
    expect(failingBundle.failedAxionLoad, isTrue);
    expect(effectiveBundle.id, graphiteThemeId);
    expect(
      find.byKey(const Key('graphite-presentation-unavailable')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('botanical-study-landscape-shell')),
      findsNothing,
    );
    expect(find.byType(GraphiteApplicationShell), findsOneWidget);
    expect(find.byType(GraphiteNineSliceFrame), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

final class _FailingAxionAssetBundle extends CachingAssetBundle {
  _FailingAxionAssetBundle({
    required this.frameFile,
    required this.chassisFile,
  });

  final File frameFile;
  final File chassisFile;
  bool failedAxionLoad = false;

  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith(botanicalStudyFrameAsset)) {
      return ByteData.sublistView(await frameFile.readAsBytes());
    }
    if (key.endsWith(botanicalStudyLandscapeChassisAsset)) {
      return ByteData.sublistView(await chassisFile.readAsBytes());
    }
    if (key.endsWith(canonicalDeltaMarkAsset)) {
      failedAxionLoad = true;
      throw StateError('fixture Axion decode failure');
    }
    return rootBundle.load(key);
  }
}

final class _GraphiteAssetBundle extends CachingAssetBundle {
  _GraphiteAssetBundle({required this.frameFile});

  final File frameFile;

  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith(graphiteFrameAsset)) {
      return ByteData.sublistView(await frameFile.readAsBytes());
    }
    return rootBundle.load(key);
  }
}

File _findWorkspaceFile(String assetPath) {
  var root = Directory.current.absolute;
  final relativePath = 'packages/clinical_calendar_presentation/$assetPath'
      .replaceAll('/', Platform.pathSeparator);
  while (root.parent.path != root.path) {
    final candidate = File(
      '${root.path}${Platform.pathSeparator}$relativePath',
    );
    if (candidate.existsSync()) return candidate;
    root = root.parent;
  }
  throw StateError('Botanical asset was not found: $assetPath');
}

const _slots = ResponsiveShellSlots(
  centralContent: ColoredBox(color: Colors.white),
  planningRegion: ColoredBox(color: Colors.white),
  placementDock: ColoredBox(color: Colors.white),
  insightRail: ColoredBox(color: Colors.white),
  mobilePlacementSummary: ColoredBox(color: Colors.white),
  mobileAttention: ColoredBox(color: Colors.white),
  profileAvatar: SizedBox.shrink(),
);

void _noop() {}

void _ignoreDestination(ClinicalCalendarDestination _) {}

void _expectRectClose(Rect actual, Rect expected) {
  const tolerance = 12.0;
  expect(actual.left, closeTo(expected.left, tolerance));
  expect(actual.top, closeTo(expected.top, tolerance));
  expect(actual.width, closeTo(expected.width, tolerance));
  expect(actual.height, closeTo(expected.height, tolerance));
}
