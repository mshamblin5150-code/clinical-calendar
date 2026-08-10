import 'dart:io';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/proof_fonts.dart';
import 'support/theme_acceptance_harness.dart';

void main() {
  setUpAll(() {
    if (!Platform.isWindows) {
      goldenFileComparator = createProofGoldenComparator(
        goldenFileComparator,
        highDeltaPixelTolerance: .0045,
      );
    }
  });

  testWidgets('runtime thumbnail renders the deterministic month grid', (
    tester,
  ) async {
    final bundle = ClinicalCalendarThemeBundleRegistry
        .standard
        .selectableBundles
        .singleWhere((candidate) => candidate.id == graphiteThemeId);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 800,
            child: ThemeRuntimeThumbnail(bundle: bundle),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('theme-thumbnail-weekday-grid')),
      findsOneWidget,
    );
    expect(find.byType(GraphiteApplicationShell), findsOneWidget);
    expect(
      find.byKey(const Key('graphite-landscape-shell')),
      findsOneWidget,
      reason: 'Gallery must render the accepted product shell, not buildFrame.',
    );
    for (var index = 0; index < 42; index++) {
      expect(
        find.byKey(Key('theme-thumbnail-day-cell-$index')),
        findsOneWidget,
      );
    }
    expect(find.byKey(const Key('theme-thumbnail-day-cell-42')), findsNothing);
  });

  testWidgets('every thumbnail enters its accepted product shell', (
    tester,
  ) async {
    const expectedShellKeys = <String, String>{
      variantFThemeId: 'command-bar',
      graphiteThemeId: 'graphite-landscape-shell',
      federationClassicThemeId: 'federation-classic-landscape-shell',
      federation2399ThemeId: 'federation-2399-landscape-shell',
      coastalCalmThemeId: 'coastal-calm-landscape-shell',
      botanicalStudyThemeId: 'botanical-study-landscape-shell',
      heritageFieldNotesThemeId: 'heritage-field-notes-landscape-shell',
    };

    for (final bundle
        in ClinicalCalendarThemeBundleRegistry.standard.selectableBundles) {
      await tester.pumpWidget(
        MaterialApp(home: ThemeRuntimeThumbnail(bundle: bundle)),
      );
      expect(
        find.byKey(Key(expectedShellKeys[bundle.id]!)),
        findsOneWidget,
        reason: '${bundle.id} must not fall back to its legacy Gallery frame.',
      );
      final thumbnail = find.byKey(Key('theme-gallery-thumbnail-${bundle.id}'));
      expect(
        find.ancestor(
          of: thumbnail,
          matching: find.byWidgetPredicate(
            (widget) => widget is IgnorePointer && widget.ignoring,
          ),
        ),
        findsOneWidget,
        reason: '${bundle.id} preview controls must remain inert.',
      );
      expect(
        find.ancestor(
          of: thumbnail,
          matching: find.byWidgetPredicate(
            (widget) => widget is ExcludeFocus && widget.excluding,
          ),
        ),
        findsOneWidget,
        reason: '${bundle.id} preview controls must be skipped by traversal.',
      );
      expect(tester.takeException(), isNull, reason: bundle.id);
    }
  });

  for (final bundle
      in ClinicalCalendarThemeBundleRegistry.standard.selectableBundles) {
    testWidgets('${bundle.id} runtime thumbnail is visually pinned', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(bundle.gallery.thumbnailViewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.fromSize(
            size: bundle.gallery.thumbnailViewport,
            child: ThemeRuntimeThumbnail(bundle: bundle),
          ),
        ),
      );

      final thumbnail = find.byKey(Key('theme-gallery-thumbnail-${bundle.id}'));
      await tester.runAsync(() async {
        for (final assetPath in bundle.frame.assetPaths) {
          await precacheImage(
            AssetImage(assetPath, package: bundle.frame.assetPackage),
            tester.element(thumbnail),
          );
        }
      });
      await tester.pumpAndSettle();

      expect(tester.getSize(thumbnail), bundle.gallery.thumbnailViewport);
      await expectLater(
        thumbnail,
        matchesGoldenFile('goldens/theme_gallery_runtime/${bundle.id}.png'),
      );
      expect(tester.takeException(), isNull, reason: bundle.id);
    });

    test(
      '${bundle.id} pinned runtime thumbnail passes the evidence audit',
      () async {
        final packageRoot =
            Directory.current.path.endsWith('clinical_calendar_presentation')
            ? Directory.current
            : Directory('packages/clinical_calendar_presentation');
        final bytes = await File(
          '${packageRoot.path}/test/goldens/theme_gallery_runtime/'
          '${bundle.id}.png',
        ).readAsBytes();
        final evidence = ThemeThumbnailEvidence(
          themeId: bundle.id,
          rendererVersion: bundle.shellRenderer.rendererId,
          fixtureId: bundle.gallery.thumbnailFixtureId,
          viewport: bundle.gallery.thumbnailViewport,
          sha256: sha256.convert(bytes).toString(),
          captureUri: 'captures/${bundle.id}-runtime-thumbnail.png',
          fictionalFixture: true,
          swatches: [
            for (final swatch in bundle.gallery.swatches)
              ThemeThumbnailSwatchEvidence(
                role: swatch.role,
                label: swatch.label,
                color: swatch.color,
              ),
          ],
        );

        final result = await ThemeThumbnailAcceptanceAuditor.audit(
          bundle: bundle,
          bytes: bytes,
          evidence: evidence,
        );
        expect(result.passed, isTrue, reason: result.failures.join('\n'));
      },
    );
  }

  testWidgets('Preview is explicit and follows the inspected identity', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    String? previewed;
    await tester.pumpWidget(
      MaterialApp(
        theme: const VariantFVisualTheme().createThemeData(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ThemeGallery(
              appliedThemeId: variantFThemeId,
              selectedThemeId: graphiteThemeId,
              onPreview: (themeId) async => previewed = themeId,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('preview-selected-theme')), findsOneWidget);
    expect(find.text('Apply'), findsNothing);

    await tester.tap(find.byKey(const Key('preview-selected-theme')));
    await tester.pump();

    expect(previewed, graphiteThemeId);
  });

  testWidgets(
    'Student compares complete identities without changing the applied theme',
    (tester) async {
      var inspected = variantFThemeId;
      await tester.pumpWidget(
        MaterialApp(
          theme: const VariantFVisualTheme().createThemeData(),
          home: Scaffold(
            body: ThemeGallery(
              appliedThemeId: variantFThemeId,
              selectedThemeId: inspected,
              onSelected: (themeId) => inspected = themeId,
            ),
          ),
        ),
      );

      expect(find.text('Containment Drone 47-Alpha'), findsWidgets);
      expect(find.text('Graphite'), findsWidgets);
      expect(find.text('Applied'), findsOneWidget);
      expect(find.text('Unchanged'), findsOneWidget);
      expect(find.text('Selected'), findsOneWidget);
      expect(
        find.byKey(const Key('theme-gallery-thumbnail-variant-f')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('theme-gallery-thumbnail-graphite')),
        findsNothing,
      );
      expect(find.text('Apply'), findsNothing);

      await tester.tap(find.byKey(const Key('theme-gallery-row-graphite')));
      await tester.pump();

      expect(inspected, graphiteThemeId);
      expect(find.text('Selected'), findsOneWidget);
      expect(find.text('Applied'), findsOneWidget);
      expect(
        find.byKey(const Key('theme-gallery-thumbnail-graphite')),
        findsOneWidget,
      );
      expect(find.text('Apply'), findsNothing);
    },
  );

  testWidgets(
    'Settings exposes the complete Gallery after catalog activation',
    (tester) async {
      StudentSettings? saved;
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: const VariantFVisualTheme().createThemeData(),
          home: Scaffold(
            body: SettingsTemplatesSurface(
              settings: StudentSettings(),
              scheduleTemplates: const [],
              newTemplateId: () => 'unused',
              onSaveSettings: (settings) async => saved = settings,
              onSaveTemplate: (_) async {},
              onRemoveTemplate: (_) async {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('theme-setting')), findsNothing);
      expect(find.byKey(const Key('theme-gallery')), findsOneWidget);
      for (final bundle
          in ClinicalCalendarThemeBundleRegistry.standard.selectableBundles) {
        expect(
          find.byKey(Key('theme-gallery-row-${bundle.id}')),
          findsOneWidget,
        );
      }

      await tester.scrollUntilVisible(
        find.byKey(const Key('save-settings-templates-action')),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('save-settings-templates-action')));
      await tester.pumpAndSettle();

      expect(saved?.themeId, graphiteThemeId);
    },
  );

  testWidgets('keyboard navigation changes only the inspected identity', (
    tester,
  ) async {
    var inspected = variantFThemeId;
    await tester.pumpWidget(
      MaterialApp(
        theme: const VariantFVisualTheme().createThemeData(),
        home: Scaffold(
          body: ThemeGallery(
            appliedThemeId: variantFThemeId,
            selectedThemeId: variantFThemeId,
            onSelected: (themeId) => inspected = themeId,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('theme-gallery-row-variant-f')));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(inspected, graphiteThemeId);
    expect(find.text('Applied'), findsOneWidget);
    expect(find.text('Selected'), findsOneWidget);
  });

  testWidgets(
    'compact Gallery exposes fallback and ordered swatches to TalkBack',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: const GraphiteVisualTheme().createThemeData(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: ThemeGallery(
                appliedThemeId: 'unavailable-theme',
                selectedThemeId: graphiteThemeId,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Applied'), findsNothing);
      expect(find.text('Fallback in use'), findsOneWidget);
      expect(find.text('Selected'), findsOneWidget);
      expect(find.text('Unchanged'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Canvas semantic role, near-black graphite'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Structure semantic role, layered charcoal'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Clinical Session semantic role, clear cobalt'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Work Shift semantic role, cool violet'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Urgent semantic role, signal coral'),
        findsOneWidget,
      );
      expect(
        tester.semantics.simulatedAccessibilityTraversal(
          startNode: find.semantics.byLabel('Theme Gallery'),
        ),
        containsAllInOrder([
          isSemantics(
            label:
                'Containment Drone 47-Alpha, The accepted gunmetal tactical '
                'identity, preserved unchanged., Unchanged',
          ),
          isSemantics(
            label:
                'Graphite, Neutral precision slate with cool silver and '
                'restrained emerald signals., Selected, Fallback in use',
          ),
          isSemantics(
            label:
                'Graphite deterministic Calendar thumbnail, '
                '$themeGalleryFixtureId, generated by '
                'graphite-owned-responsive-instrument-v3',
          ),
          isSemantics(label: 'Canvas semantic role, near-black graphite'),
          isSemantics(label: 'Structure semantic role, layered charcoal'),
          isSemantics(label: 'Clinical Session semantic role, clear cobalt'),
          isSemantics(label: 'Work Shift semantic role, cool violet'),
          isSemantics(label: 'Urgent semantic role, signal coral'),
        ]),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('theme-gallery-thumbnail-graphite')),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is SizedBox &&
                widget.width == themeGalleryViewport.width &&
                widget.height == themeGalleryViewport.height,
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}
