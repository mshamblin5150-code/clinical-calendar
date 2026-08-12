import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'responsive_shell.dart';
import 'theme_contract.dart';
import 'variant_f_theme.dart';

typedef PreviewTheme = Future<void> Function(String themeId);

/// The comparison-only Theme Gallery. Selection changes the inspected bundle
/// and never changes the effective or persisted presentation.
final class ThemeGallery extends StatefulWidget {
  const ThemeGallery({
    required this.appliedThemeId,
    required this.selectedThemeId,
    this.onSelected,
    this.onPreview,
    this.bundles,
    super.key,
  });

  final String appliedThemeId;
  final String selectedThemeId;
  final ValueChanged<String>? onSelected;
  final PreviewTheme? onPreview;
  final List<ClinicalCalendarThemeBundle>? bundles;

  @override
  State<ThemeGallery> createState() => _ThemeGalleryState();
}

final class _ThemeGalleryState extends State<ThemeGallery> {
  late String _selectedThemeId;
  late List<FocusNode> _rowFocusNodes;

  List<ClinicalCalendarThemeBundle> get _bundles =>
      widget.bundles ??
      ClinicalCalendarThemeBundleRegistry.standard.galleryBundles;

  @override
  void initState() {
    super.initState();
    _selectedThemeId = _availableSelection(widget.selectedThemeId);
    _rowFocusNodes = _bundles
        .map((bundle) => FocusNode(debugLabel: 'Theme ${bundle.id}'))
        .toList(growable: false);
  }

  @override
  void didUpdateWidget(ThemeGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedThemeId != widget.selectedThemeId) {
      _selectedThemeId = _availableSelection(widget.selectedThemeId);
    }
    if (oldWidget.bundles != widget.bundles &&
        oldWidget.bundles?.length != widget.bundles?.length) {
      for (final node in _rowFocusNodes) {
        node.dispose();
      }
      _rowFocusNodes = _bundles
          .map((bundle) => FocusNode(debugLabel: 'Theme ${bundle.id}'))
          .toList(growable: false);
    }
  }

  @override
  void dispose() {
    for (final node in _rowFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _availableSelection(String requested) =>
      _bundles.any((bundle) => bundle.id == requested)
      ? requested
      : graphiteThemeId;

  void _select(int index, {bool requestFocus = false}) {
    final bundle = _bundles[index];
    if (_selectedThemeId != bundle.id) {
      setState(() => _selectedThemeId = bundle.id);
      widget.onSelected?.call(bundle.id);
    }
    if (requestFocus) _rowFocusNodes[index].requestFocus();
  }

  KeyEventResult _handleKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _select((index + 1) % _bundles.length, requestFocus: true);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _select((index - 1) % _bundles.length, requestFocus: true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _bundles.singleWhere(
      (bundle) => bundle.id == _selectedThemeId,
    );
    return Semantics(
      key: const Key('theme-gallery'),
      container: true,
      explicitChildNodes: true,
      label: 'Theme Gallery',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final masterList = _ThemeMasterList(
            bundles: _bundles,
            selectedThemeId: _selectedThemeId,
            appliedThemeId: widget.appliedThemeId,
            focusNodes: _rowFocusNodes,
            onSelected: _select,
            onKeyEvent: _handleKey,
          );
          final detail = _ThemeDetail(
            bundle: selected,
            appliedThemeId: widget.appliedThemeId,
            onPreview: widget.onPreview,
          );
          if (constraints.maxWidth >= 700) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 280,
                  child: SingleChildScrollView(child: masterList),
                ),
                const SizedBox(width: 16),
                Expanded(child: SingleChildScrollView(child: detail)),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [masterList, const SizedBox(height: 12), detail],
          );
        },
      ),
    );
  }
}

final class _ThemeMasterList extends StatelessWidget {
  const _ThemeMasterList({
    required this.bundles,
    required this.selectedThemeId,
    required this.appliedThemeId,
    required this.focusNodes,
    required this.onSelected,
    required this.onKeyEvent,
  });

  final List<ClinicalCalendarThemeBundle> bundles;
  final String selectedThemeId;
  final String appliedThemeId;
  final List<FocusNode> focusNodes;
  final void Function(int index) onSelected;
  final KeyEventResult Function(int index, KeyEvent event) onKeyEvent;

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('theme-gallery-master-list'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var index = 0; index < bundles.length; index++)
        _ThemeMasterRow(
          bundle: bundles[index],
          selected: bundles[index].id == selectedThemeId,
          stateLabels: _stateLabels(
            bundle: bundles[index],
            selectedThemeId: selectedThemeId,
            appliedThemeId: appliedThemeId,
          ),
          focusNode: focusNodes[index],
          onTap: () => onSelected(index),
          onKeyEvent: (node, event) => onKeyEvent(index, event),
        ),
    ],
  );
}

final class _ThemeMasterRow extends StatelessWidget {
  const _ThemeMasterRow({
    required this.bundle,
    required this.selected,
    required this.stateLabels,
    required this.focusNode,
    required this.onTap,
    required this.onKeyEvent,
  });

  final ClinicalCalendarThemeBundle bundle;
  final bool selected;
  final List<String> stateLabels;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final FocusOnKeyEventCallback onKeyEvent;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    excludeSemantics: true,
    label: [
      bundle.metadata.displayName,
      bundle.metadata.personality,
      ...stateLabels,
    ].join(', '),
    child: Focus(
      focusNode: focusNode,
      onKeyEvent: onKeyEvent,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('theme-gallery-row-${bundle.id}'),
          onTap: () {
            focusNode.requestFocus();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bundle.metadata.displayName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(bundle.metadata.personality),
                if (stateLabels.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final label in stateLabels) Chip(label: Text(label)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

final class _ThemeDetail extends StatelessWidget {
  const _ThemeDetail({
    required this.bundle,
    required this.appliedThemeId,
    required this.onPreview,
  });

  final ClinicalCalendarThemeBundle bundle;
  final String appliedThemeId;
  final PreviewTheme? onPreview;

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('theme-gallery-detail'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        bundle.metadata.displayName,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 4),
      Text(bundle.metadata.personality),
      const SizedBox(height: 12),
      ThemeRuntimeThumbnail(bundle: bundle),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final swatch in bundle.gallery.swatches)
            _ThemeSwatch(swatch: swatch),
        ],
      ),
      if (onPreview != null) ...[
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const Key('preview-selected-theme'),
            onPressed: () => onPreview!(bundle.id),
            icon: const Icon(Icons.visibility_outlined),
            label: Text('Preview ${bundle.metadata.displayName}'),
          ),
        ),
      ],
    ],
  );
}

String themeRuntimeThumbnailAssetPath(String themeId) =>
    'assets/theme_gallery_runtime/$themeId.png';

/// The deterministic real-bundle renderer used by gallery cards and evidence.
final class ThemeRuntimeThumbnail extends StatelessWidget {
  const ThemeRuntimeThumbnail({
    required this.bundle,
    this.useBakedAsset = !kDebugMode,
    super.key,
  });

  final ClinicalCalendarThemeBundle bundle;

  @visibleForTesting
  final bool useBakedAsset;

  @override
  Widget build(BuildContext context) {
    final thumbnail = MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Theme(
        data: bundle.standardPresentation.createThemeData(),
        child: ClinicalCalendarSemanticMarkScope(
          marks: bundle.marks,
          child: AspectRatio(
            aspectRatio: bundle.gallery.thumbnailViewport.aspectRatio,
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox.fromSize(
                  size: bundle.gallery.thumbnailViewport,
                  // Do not replace this with buildFrame. The completed
                  // concept-fidelity issues #128 and #133-#137 retained
                  // normalized frames for compact/destination use, while
                  // their accepted Calendar designs live in build().
                  child: bundle.shellRenderer.build(
                    key: const Key('theme-thumbnail-product-shell'),
                    environmentName: 'GALLERY PREVIEW',
                    onOpenMenu: _ignoreThumbnailAction,
                    onOpenDestination: _ignoreThumbnailDestination,
                    onOpenAttention: _ignoreThumbnailAction,
                    onAddSchedule: _ignoreThumbnailAction,
                    slots: const ResponsiveShellSlots(
                      centralContent: _PinnedCalendarFixture(),
                      planningRegion: _ThumbnailPlanningFixture(),
                      placementDock: _ThumbnailPlacementsFixture(),
                      insightRail: _ThumbnailProgressFixture(),
                      mobilePlacementSummary: _ThumbnailPlacementsFixture(),
                      mobileAttention: _ThumbnailProgressFixture(),
                      profileAvatar: Icon(Icons.person_outline),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final captureKey = Key('theme-gallery-thumbnail-${bundle.id}');
    final renderedThumbnail = useBakedAsset
        ? AspectRatio(
            aspectRatio: bundle.gallery.thumbnailViewport.aspectRatio,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
                final cacheWidth = (constraints.maxWidth * devicePixelRatio)
                    .ceil()
                    .clamp(1, bundle.gallery.thumbnailViewport.width.toInt());
                final cacheHeight = (constraints.maxHeight * devicePixelRatio)
                    .ceil()
                    .clamp(1, bundle.gallery.thumbnailViewport.height.toInt());
                return Image.asset(
                  themeRuntimeThumbnailAssetPath(bundle.id),
                  key: captureKey,
                  package: 'clinical_calendar_presentation',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  cacheWidth: cacheWidth,
                  cacheHeight: cacheHeight,
                );
              },
            ),
          )
        : RepaintBoundary(key: captureKey, child: thumbnail);
    return Semantics(
      label:
          '${bundle.metadata.displayName} deterministic Calendar thumbnail, '
          '${bundle.gallery.thumbnailFixtureId}, generated by '
          '${bundle.gallery.rendererId}',
      image: true,
      child: ExcludeSemantics(
        child: ExcludeFocus(child: IgnorePointer(child: renderedThumbnail)),
      ),
    );
  }
}

void _ignoreThumbnailAction() {}

void _ignoreThumbnailDestination(ClinicalCalendarDestination _) {}

final class _ThumbnailPlacementsFixture extends StatelessWidget {
  const _ThumbnailPlacementsFixture();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(8),
    child: Column(
      key: Key('theme-thumbnail-placement-fixture'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('MY PLACEMENTS'),
        SizedBox(height: 10),
        Text('Acceptance Family Medicine'),
        SizedBox(height: 6),
        LinearProgressIndicator(value: 0.62),
        SizedBox(height: 14),
        Text('Acceptance Internal Medicine'),
        SizedBox(height: 6),
        LinearProgressIndicator(value: 0.38),
      ],
    ),
  );
}

final class _ThumbnailProgressFixture extends StatelessWidget {
  const _ThumbnailProgressFixture();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(8),
    child: Column(
      key: Key('theme-thumbnail-progress-fixture'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('TOTAL PROGRESS'),
        SizedBox(height: 10),
        Center(
          child: SizedBox.square(
            dimension: 76,
            child: CircularProgressIndicator(value: 0.54, strokeWidth: 8),
          ),
        ),
        SizedBox(height: 12),
        Text('97 of 180 hours'),
        SizedBox(height: 16),
        Text('NEEDS ATTENTION'),
        SizedBox(height: 8),
        Text('1 evaluation due'),
      ],
    ),
  );
}

final class _ThumbnailPlanningFixture extends StatelessWidget {
  const _ThumbnailPlanningFixture();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(8),
    child: Row(
      key: Key('theme-thumbnail-planning-fixture'),
      children: [
        Icon(Icons.add_box_outlined),
        SizedBox(width: 8),
        Text('PLANNING'),
        SizedBox(width: 18),
        Expanded(child: Text('Clinical Session · Aug 12 · 08:00–16:00')),
      ],
    ),
  );
}

final class _PinnedCalendarFixture extends StatelessWidget {
  const _PinnedCalendarFixture();

  static const _weekdays = <String>[
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
  ];

  static const _dates = <int>[
    26,
    27,
    28,
    29,
    30,
    31,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
    31,
    1,
    2,
    3,
    4,
    5,
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: constraints.hasBoundedHeight ? constraints.maxHeight : 520,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.chevron_left, size: 20),
                  const Icon(Icons.chevron_right, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'AUGUST 2026',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        Expanded(
                          child: _ThumbnailViewMode(
                            label: 'MONTH',
                            selected: true,
                          ),
                        ),
                        Expanded(child: _ThumbnailViewMode(label: 'WEEK')),
                        Expanded(child: _ThumbnailViewMode(label: 'AGENDA')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                key: const Key('theme-thumbnail-weekday-grid'),
                children: [
                  for (final weekday in _weekdays)
                    Expanded(
                      child: Center(
                        child: Text(
                          weekday,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Column(
                  children: [
                    for (var week = 0; week < 6; week++)
                      Expanded(
                        child: Row(
                          children: [
                            for (var day = 0; day < 7; day++)
                              Expanded(
                                child: _ThumbnailDayCell(
                                  key: Key(
                                    'theme-thumbnail-day-cell-${week * 7 + day}',
                                  ),
                                  date: _dates[week * 7 + day],
                                  outsideMonth:
                                      week * 7 + day < 6 || week * 7 + day > 36,
                                  today: week * 7 + day == 14,
                                  commitment: switch (week * 7 + day) {
                                    10 => _ThumbnailCommitment.workShift,
                                    17 => _ThumbnailCommitment.clinicalSession,
                                    _ => null,
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final class _ThumbnailViewMode extends StatelessWidget {
  const _ThumbnailViewMode({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: selected
          ? Theme.of(context).colorScheme.secondaryContainer
          : Theme.of(context).colorScheme.surfaceContainerLow,
      border: Border.all(color: Theme.of(context).colorScheme.outline),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    ),
  );
}

enum _ThumbnailCommitment { clinicalSession, workShift }

final class _ThumbnailDayCell extends StatelessWidget {
  const _ThumbnailDayCell({
    required this.date,
    required this.outsideMonth,
    required this.today,
    required this.commitment,
    super.key,
  });

  final int date;
  final bool outsideMonth;
  final bool today;
  final _ThumbnailCommitment? commitment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final commitmentColor = switch (commitment) {
      _ThumbnailCommitment.clinicalSession => context.clinicalColors.clinical,
      _ThumbnailCommitment.workShift => context.clinicalColors.work,
      null => null,
    };
    final commitmentLabel = switch (commitment) {
      _ThumbnailCommitment.clinicalSession => 'CLINICAL SESSION',
      _ThumbnailCommitment.workShift => 'WORK SHIFT',
      null => null,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 64 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        final dateLabel = Text(
          '$date',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: outsideMonth
                ? scheme.onSurface.withValues(alpha: 0.48)
                : scheme.onSurface,
            fontWeight: today ? FontWeight.w700 : null,
          ),
        );
        return Container(
          padding: EdgeInsets.all(compact ? 3 : 6),
          decoration: BoxDecoration(
            color: today
                ? scheme.primaryContainer.withValues(alpha: 0.45)
                : compact && commitmentColor != null
                ? commitmentColor.withValues(alpha: 0.18)
                : scheme.surfaceContainerLowest,
            border: Border.all(
              color: today ? scheme.error : scheme.outlineVariant,
              width: today ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact)
                SizedBox(
                  height: 14,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topLeft,
                    child: dateLabel,
                  ),
                ),
              if (!compact) dateLabel,
              if (!compact &&
                  commitmentColor != null &&
                  commitmentLabel != null) ...[
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 4,
                  ),
                  color: commitmentColor.withValues(alpha: 0.28),
                  child: Text(
                    commitmentLabel,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: commitmentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

final class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.swatch});

  final ThemeGallerySwatch swatch;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${swatch.label} semantic role, ${swatch.colorName}',
    excludeSemantics: true,
    child: SizedBox(
      width: 132,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: swatch.color,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('${swatch.label}\n${swatch.colorName}')),
        ],
      ),
    ),
  );
}

List<String> _stateLabels({
  required ClinicalCalendarThemeBundle bundle,
  required String selectedThemeId,
  required String appliedThemeId,
}) {
  final appliedUsesFallback = ClinicalCalendarThemeBundleRegistry.standard
      .resolveApplied(appliedThemeId)
      .isFallback;
  return [
    if (!appliedUsesFallback && bundle.id == appliedThemeId) 'Applied',
    if (bundle.id == variantFThemeId) 'Unchanged',
    if (bundle.id == selectedThemeId) 'Selected',
    if (appliedUsesFallback && bundle.id == graphiteThemeId) 'Fallback in use',
  ];
}
