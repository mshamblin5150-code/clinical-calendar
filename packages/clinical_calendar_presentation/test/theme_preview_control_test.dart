import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('persistent control identifies Preview and authoritative theme', (
    tester,
  ) async {
    final controller = ThemePreviewController(
      registry: ClinicalCalendarThemeBundleRegistry.standard,
      authoritativeThemeId: variantFThemeId,
      initialRevision: 1,
    );
    addTearDown(controller.dispose);
    await controller.preview(graphiteThemeId, preflight: (_) async {});
    var applied = 0;
    var reverted = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ThemePreviewControl(
            controller: controller,
            onApply: () async => applied++,
            onRevert: () {
              reverted++;
              controller.revert();
            },
          ),
        ),
      ),
    );

    expect(find.text('Previewing Graphite'), findsOneWidget);
    expect(find.text('Not saved'), findsOneWidget);
    expect(
      find.text('Authoritative: Containment Drone 47-Alpha'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('apply-theme-preview')), findsOneWidget);
    expect(find.byKey(const Key('revert-theme-preview')), findsOneWidget);

    await tester.tap(find.byKey(const Key('apply-theme-preview')));
    await tester.pump();
    expect(applied, 1);

    await tester.tap(find.byKey(const Key('revert-theme-preview')));
    await tester.pump();
    expect(reverted, 1);
    expect(controller.isPreviewing, isFalse);
  });

  testWidgets('failed preflight reports unavailable and disables Apply', (
    tester,
  ) async {
    final controller = ThemePreviewController(
      registry: ClinicalCalendarThemeBundleRegistry.standard,
      authoritativeThemeId: variantFThemeId,
      initialRevision: 1,
    );
    addTearDown(controller.dispose);
    await controller.preview(
      graphiteThemeId,
      preflight: (_) async => throw StateError('bad asset'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ThemePreviewControl(
            controller: controller,
            onApply: () async {},
            onRevert: controller.revert,
          ),
        ),
      ),
    );

    expect(find.text('Preview unavailable'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('apply-theme-preview')))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'unknown synchronized authority is named without hiding fallback',
    (tester) async {
      final controller = ThemePreviewController(
        registry: ClinicalCalendarThemeBundleRegistry.standard,
        authoritativeThemeId: 'future-theme',
        initialRevision: 2,
      );
      addTearDown(controller.dispose);
      await controller.preview(variantFThemeId, preflight: (_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemePreviewControl(
              controller: controller,
              onApply: () async {},
              onRevert: controller.revert,
            ),
          ),
        ),
      );

      expect(
        find.text('Authoritative: future-theme (Graphite fallback in use)'),
        findsOneWidget,
      );
    },
  );
}
