import 'dart:async';

import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ThemePreviewController controller;

  setUp(() {
    controller = ThemePreviewController(
      registry: ClinicalCalendarThemeBundleRegistry.standard,
      authoritativeThemeId: variantFThemeId,
      initialRevision: 3,
    );
  });

  tearDown(() => controller.dispose());

  test('successful preflight atomically enters an unsaved Preview', () async {
    await controller.preview(graphiteThemeId, preflight: (_) async {});

    expect(controller.isPreviewing, isTrue);
    expect(controller.effectiveBundle.id, graphiteThemeId);
    expect(controller.authoritativeBundle.id, variantFThemeId);
    expect(controller.previewUnavailable, isFalse);
    expect(controller.canApply, isTrue);
  });

  test('failed preflight preserves the authoritative presentation', () async {
    await controller.preview(
      graphiteThemeId,
      preflight: (_) async => throw StateError('decode failed'),
    );

    expect(controller.isPreviewing, isFalse);
    expect(controller.effectiveBundle.id, variantFThemeId);
    expect(controller.previewUnavailable, isTrue);
    expect(controller.canApply, isFalse);
  });

  test(
    'late Federation Preview failure returns to the applied bundle',
    () async {
      await controller.preview(
        federationClassicThemeId,
        preflight: (_) async {},
      );

      controller.handleRuntimeBundleFailure(federationClassicThemeId);

      expect(controller.isPreviewing, isFalse);
      expect(controller.effectiveBundle.id, variantFThemeId);
      expect(controller.authoritativeThemeId, variantFThemeId);
      expect(controller.previewUnavailable, isTrue);
    },
  );

  test(
    'late Federation 2399 Preview failure returns to the applied bundle',
    () async {
      await controller.preview(federation2399ThemeId, preflight: (_) async {});

      controller.handleRuntimeBundleFailure(federation2399ThemeId);

      expect(controller.isPreviewing, isFalse);
      expect(controller.effectiveBundle.id, variantFThemeId);
      expect(controller.authoritativeThemeId, variantFThemeId);
      expect(controller.previewUnavailable, isTrue);
    },
  );

  test(
    'Revert follows an authoritative change received during Preview',
    () async {
      await controller.preview(graphiteThemeId, preflight: (_) async {});

      controller.updateAuthoritativeTheme(themeId: 'future-theme', revision: 4);

      expect(controller.isPreviewing, isTrue);
      expect(controller.effectiveBundle.id, graphiteThemeId);
      expect(controller.authoritativeThemeId, 'future-theme');
      expect(controller.authoritativeChangedDuringPreview, isTrue);
      final apply = controller.beginApply();
      expect(apply.expectedRevision, 4);
      controller.failApply('Apply cancelled for this Revert test.');

      controller.revert();

      expect(controller.isPreviewing, isFalse);
      expect(controller.effectiveBundle.id, graphiteThemeId);
      expect(controller.authoritativeResolution.isFallback, isTrue);
    },
  );

  test(
    'Apply request is revision-aware and failure keeps Preview retryable',
    () async {
      await controller.preview(graphiteThemeId, preflight: (_) async {});

      final request = controller.beginApply();
      expect(request.themeId, graphiteThemeId);
      expect(request.expectedRevision, 3);
      expect(controller.canApply, isFalse);

      controller.failApply('Student Settings changed. Reload and try again.');

      expect(controller.isPreviewing, isTrue);
      expect(controller.authoritativeThemeId, variantFThemeId);
      expect(controller.applyError, contains('changed'));
      expect(controller.canApply, isTrue);

      final retry = controller.beginApply();
      expect(retry.expectedRevision, 3);
      controller.completeApply(revision: 4);

      expect(controller.isPreviewing, isFalse);
      expect(controller.authoritativeThemeId, graphiteThemeId);
      expect(controller.authoritativeRevision, 4);
    },
  );

  test('an older preflight cannot replace a newer Preview', () async {
    final first = Completer<void>();
    final firstPreview = controller.preview(
      graphiteThemeId,
      preflight: (_) => first.future,
    );
    await controller.preview(variantFThemeId, preflight: (_) async {});

    first.complete();
    await firstPreview;

    expect(controller.effectiveBundle.id, variantFThemeId);
  });

  test('Revert cannot race an Apply already in flight', () async {
    await controller.preview(graphiteThemeId, preflight: (_) async {});
    controller.beginApply();

    controller.revert();

    expect(controller.isApplying, isTrue);
    expect(controller.isPreviewing, isTrue);
    controller.completeApply(revision: 4);
    expect(controller.authoritativeThemeId, graphiteThemeId);
  });

  test(
    'authoritative change during preflight becomes the Preview base',
    () async {
      final preflight = Completer<void>();
      final pending = controller.preview(
        graphiteThemeId,
        preflight: (_) => preflight.future,
      );

      controller.updateAuthoritativeTheme(themeId: 'future-theme', revision: 4);
      preflight.complete();
      await pending;

      expect(controller.authoritativeThemeId, 'future-theme');
      expect(controller.authoritativeChangedDuringPreview, isTrue);
      expect(controller.beginApply().expectedRevision, 4);
    },
  );

  test(
    'every registered directed theme swap can Preview, Revert, and Apply',
    () async {
      final bundles =
          ClinicalCalendarThemeBundleRegistry.standard.galleryBundles;
      for (final source in bundles) {
        for (final candidate in bundles.where(
          (bundle) => bundle.id != source.id,
        )) {
          final swap = ThemePreviewController(
            registry: ClinicalCalendarThemeBundleRegistry.standard,
            authoritativeThemeId: source.id,
            initialRevision: 10,
          );
          await swap.preview(candidate.id, preflight: (_) async {});
          expect(swap.effectiveBundle.id, candidate.id);
          swap.revert();
          expect(swap.authoritativeThemeId, source.id);

          await swap.preview(candidate.id, preflight: (_) async {});
          expect(swap.beginApply().expectedRevision, 10);
          swap.completeApply(revision: 11);
          expect(swap.authoritativeThemeId, candidate.id);
          swap.dispose();
        }
      }
    },
  );
}
