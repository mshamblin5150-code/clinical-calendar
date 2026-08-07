import 'dart:ui' as ui;

import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bundle = VariantFThemeBundle();

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
    expect(bundle.marks.marks, hasLength(5));
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
