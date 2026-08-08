import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  testWidgets('Settings gates the Gallery until catalog activation', (
    tester,
  ) async {
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

    expect(find.byKey(const Key('theme-setting')), findsOneWidget);
    expect(find.byKey(const Key('theme-gallery')), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('save-settings-templates-action')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('save-settings-templates-action')));
    await tester.pumpAndSettle();

    expect(saved?.themeId, variantFThemeId);
  });

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
                'graphite-owned-responsive-instrument-v2',
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
