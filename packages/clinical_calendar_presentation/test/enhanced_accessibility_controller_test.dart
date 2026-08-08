import 'dart:async';

import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  test(
    'signed-in change is immediate and successful save becomes authoritative',
    () async {
      final save = Completer<void>();
      final controller = EnhancedAccessibilityController(initialValue: false);

      final pending = controller.setEnabled(true, persist: (_) => save.future);

      expect(controller.enabled, isTrue);
      expect(controller.isSaving, isTrue);
      save.complete();
      await pending;
      expect(controller.enabled, isTrue);
      expect(controller.authoritativeValue, isTrue);
      expect(controller.isSaving, isFalse);
      expect(controller.errorMessage, isNull);
    },
  );

  test('failed save restores the prior authoritative value', () async {
    final controller = EnhancedAccessibilityController(initialValue: false);

    await controller.setEnabled(
      true,
      persist: (_) async => throw StateError('offline'),
    );

    expect(controller.enabled, isFalse);
    expect(controller.authoritativeValue, isFalse);
    expect(controller.isSaving, isFalse);
    expect(
      controller.errorMessage,
      'Enhanced accessibility could not be saved. Try again.',
    );
  });

  test('theme Revert does not change Enhanced accessibility', () async {
    final accessibility = EnhancedAccessibilityController(initialValue: false);
    final preview = ThemePreviewController(
      registry: ClinicalCalendarThemeBundleRegistry.standard,
      authoritativeThemeId: variantFThemeId,
      initialRevision: 1,
    );
    await preview.preview(graphiteThemeId, preflight: (_) async {});
    await accessibility.setEnabled(true, persist: (_) async {});

    preview.revert();

    expect(preview.effectiveBundle.id, variantFThemeId);
    expect(accessibility.enabled, isTrue);
  });

  testWidgets('platform accessibility MediaQuery values remain authoritative', (
    tester,
  ) async {
    const platformData = MediaQueryData(
      textScaler: TextScaler.linear(2),
      boldText: true,
      disableAnimations: true,
      invertColors: true,
      accessibleNavigation: true,
    );
    MediaQueryData? observed;
    await tester.pumpWidget(
      MediaQuery(
        data: platformData,
        child: MaterialApp(
          theme: buildGraphiteTheme(enhancedAccessibility: true),
          home: Builder(
            builder: (context) {
              observed = MediaQuery.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(observed?.textScaler.scale(10), 20);
    expect(observed?.boldText, isTrue);
    expect(observed?.disableAnimations, isTrue);
    expect(observed?.invertColors, isTrue);
    expect(observed?.accessibleNavigation, isTrue);
  });

  testWidgets('Enhanced focus is an unobscured dual-tone perimeter', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGraphiteTheme(enhancedAccessibility: true),
        home: Center(
          child: EnhancedFocusPerimeter(
            child: TextButton(
              focusNode: focusNode,
              onPressed: () {},
              child: const Text('Continue'),
            ),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();

    expect(
      find.byKey(const Key('enhanced-dual-tone-focus-perimeter')),
      findsOneWidget,
    );
    expect(
      Theme.of(
        tester.element(find.text('Continue')),
      ).extension<ClinicalCalendarAccessibilityTokens>()?.focusWidth,
      3,
    );
  });
}
