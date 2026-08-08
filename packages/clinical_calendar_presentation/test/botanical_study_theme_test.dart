import 'dart:io';

import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
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
    expect(botanical.frame.assetPaths, [botanicalStudyFrameAsset]);
    expect(botanical.gallery.swatches, hasLength(5));
    expect(botanical.marks.marks, hasLength(9));
    expect(botanical.helpGuide.calendarStates, hasLength(5));
    expect(
      ClinicalCalendarThemeBundleRegistry.standard.resolveRoot(
        botanicalStudyThemeId,
      ),
      same(botanical),
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

  testWidgets('Botanical Study owns landscape composition and callbacks', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
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
    expect(find.byType(BotanicalStudyNineSliceFrame), findsWidgets);
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
    expect(placements.right, lessThan(calendar.left));
    expect(calendar.right, lessThan(insight.left));
    expect(planning.top, greaterThan(calendar.top));

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
    expect(calendar.top, lessThan(planning.top));
    expect(planning.top, lessThan(placements.top));
    expect(tester.takeException(), isNull);
  });
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
