import 'package:flutter/material.dart';

import 'variant_f_theme.dart';

/// Opts shared workflow widgets into Field Archive-owned flat parchment
/// housing without changing their controllers, validation, or callbacks.
final class HeritageFieldNotesPanelScope extends InheritedWidget {
  const HeritageFieldNotesPanelScope({required super.child, super.key});

  static bool isActive(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<HeritageFieldNotesPanelScope>() !=
      null;

  @override
  bool updateShouldNotify(HeritageFieldNotesPanelScope oldWidget) => false;
}

enum HeritageFieldNotesPanelRole {
  placements('placements', false),
  planning('planning', true),
  clinicalPlacement('clinical-placement', true),
  needsAttention('needs-attention', true),
  supporting('supporting', false);

  const HeritageFieldNotesPanelRole(this.id, this.ownsVerticalScroll);

  final String id;
  final bool ownsVerticalScroll;
}

/// A flat archival field: opaque parchment, one ruled border, and an indexed
/// signal at the page edge. It intentionally contains no gradient or shadow.
final class HeritageFieldNotesWorkflowHousing extends StatelessWidget {
  const HeritageFieldNotesWorkflowHousing({
    required this.role,
    required this.label,
    required this.child,
    this.accent,
    this.count,
    this.showHeader = true,
    super.key,
  });

  final HeritageFieldNotesPanelRole role;
  final String label;
  final Widget child;
  final Color? accent;
  final int? count;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final colors = context.clinicalColors;
    final signal = accent ?? colors.clinical;
    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.hasBoundedHeight;
        final body = ClipRect(
          child: boundedHeight && role.ownsVerticalScroll
              ? SingleChildScrollView(
                  key: Key('heritage-field-notes-${role.id}-scroll'),
                  child: child,
                )
              : child,
        );
        return Container(
          key: role == HeritageFieldNotesPanelRole.supporting
              ? null
              : Key('heritage-field-notes-${role.id}-housing'),
          decoration: BoxDecoration(
            color: colors.structure,
            border: Border(
              left: BorderSide(color: signal, width: 5),
              top: BorderSide(color: colors.insetBorder),
              right: BorderSide(color: colors.insetBorder),
              bottom: BorderSide(color: colors.insetBorder),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
            child: Column(
              mainAxisSize: boundedHeight ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showHeader) ...[
                  Semantics(
                    key: role == HeritageFieldNotesPanelRole.needsAttention
                        ? const Key(
                            'heritage-field-notes-needs-attention-heading',
                          )
                        : null,
                    header: true,
                    label: count == null ? label : '$label, $count items',
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: colors.primaryText,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                          ),
                        ),
                        if (count != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: signal,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '$count',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onError,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  Divider(height: 1, color: colors.insetBorder),
                  const SizedBox(height: 9),
                ],
                if (boundedHeight) Expanded(child: body) else body,
              ],
            ),
          ),
        );
      },
    );
  }
}
