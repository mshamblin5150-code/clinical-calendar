import 'package:flutter/material.dart';

import 'variant_f_theme.dart';

/// Opt-in presentation scope for live content mounted in Federation 2399 bays.
///
/// The scope carries no workflow state. It only lets shared live surfaces use
/// Federation-owned housings while retaining their existing controllers and
/// callbacks.
final class Federation2399ConsoleScope extends InheritedWidget {
  const Federation2399ConsoleScope({required super.child, super.key});

  static bool isActive(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<Federation2399ConsoleScope>() !=
      null;

  @override
  bool updateShouldNotify(Federation2399ConsoleScope oldWidget) => false;
}

/// Federation 2399's recessed, segmented housing for a live console section.
final class Federation2399SectionHousing extends StatelessWidget {
  const Federation2399SectionHousing({
    required this.label,
    required this.child,
    this.count,
    this.headingKey,
    this.accent,
    super.key,
  });

  final String label;
  final Widget child;
  final int? count;
  final Key? headingKey;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.clinicalColors;
    final signal = accent ?? colors.clinical;
    final heading = Semantics(
      key: headingKey,
      container: true,
      header: true,
      label: count == null ? label : '$label, $count items',
      excludeSemantics: true,
      child: Row(
        children: [
          Flexible(
            flex: 3,
            child: Text(
              label.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: signal,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Container(height: 1, color: signal.withValues(alpha: .72)),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 46),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: signal.withValues(alpha: .12),
                border: Border.all(color: signal.withValues(alpha: .72)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Text(
                'ON • $count',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: signal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(colors.canvas, colors.structure, .38),
        border: Border.all(color: colors.insetBorder.withValues(alpha: .72)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: signal.withValues(alpha: .82),
            offset: const Offset(-3, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.hasBoundedHeight) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heading,
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      key: Key(
                        'federation-2399-${label.toLowerCase().replaceAll(' ', '-')}-section-scroll',
                      ),
                      child: child,
                    ),
                  ),
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [heading, const SizedBox(height: 10), child],
            );
          },
        ),
      ),
    );
  }
}
