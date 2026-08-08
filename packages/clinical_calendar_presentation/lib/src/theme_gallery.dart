import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                SizedBox(width: 280, child: masterList),
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
      _ThemeRuntimeThumbnail(bundle: bundle),
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

final class _ThemeRuntimeThumbnail extends StatelessWidget {
  const _ThemeRuntimeThumbnail({required this.bundle});

  final ClinicalCalendarThemeBundle bundle;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${bundle.metadata.displayName} deterministic Calendar thumbnail, '
        '${bundle.gallery.thumbnailFixtureId}, generated by '
        '${bundle.gallery.rendererId}',
    image: true,
    child: ExcludeSemantics(
      child: RepaintBoundary(
        key: Key('theme-gallery-thumbnail-${bundle.id}'),
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
                    child: bundle.shellRenderer.buildFrame(
                      child: const _PinnedCalendarFixture(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

final class _PinnedCalendarFixture extends StatelessWidget {
  const _PinnedCalendarFixture();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('AUGUST 2026', maxLines: 1),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _FixtureCommitment(
                    label: 'Clinical Session',
                    color: context.clinicalColors.clinical,
                    role: ThemeSemanticRole.clinicalSession,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _FixtureCommitment(
                    label: 'Work Shift',
                    color: context.clinicalColors.work,
                    role: ThemeSemanticRole.workShift,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

final class _FixtureCommitment extends StatelessWidget {
  const _FixtureCommitment({
    required this.label,
    required this.color,
    required this.role,
  });

  final String label;
  final Color color;
  final ThemeSemanticRole role;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.22),
      border: Border.all(color: color, width: 2),
    ),
    child: Center(
      child: FittedBox(
        child: Row(
          children: [
            ThemeSemanticMarkIcon(role: role, size: 14),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
      ),
    ),
  );
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
