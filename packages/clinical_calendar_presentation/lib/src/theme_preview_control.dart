import 'package:flutter/material.dart';

import 'theme_preview_controller.dart';

/// Persistent signed-in control for an active or failed theme Preview.
final class ThemePreviewControl extends StatelessWidget {
  const ThemePreviewControl({
    required this.controller,
    required this.onApply,
    required this.onRevert,
    super.key,
  });

  final ThemePreviewController controller;
  final Future<void> Function() onApply;
  final VoidCallback onRevert;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final preview = controller.previewBundle;
      if (preview == null &&
          !controller.previewUnavailable &&
          !controller.isPreflighting) {
        return const SizedBox.shrink();
      }
      final colors = Theme.of(context).colorScheme;
      final unavailable = controller.previewUnavailable;
      return Material(
        key: const Key('theme-preview-control'),
        color: unavailable
            ? colors.errorContainer
            : colors.surfaceContainerHigh,
        elevation: 3,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (controller.isPreflighting)
                  const Text('Preparing Preview...')
                else if (unavailable)
                  const Text('Preview unavailable')
                else ...[
                  Text('Previewing ${preview!.metadata.displayName}'),
                  const Chip(label: Text('Not saved')),
                  Text(
                    'Authoritative: '
                    '${controller.authoritativeResolution.isFallback ? '${controller.authoritativeThemeId} (Graphite fallback in use)' : controller.authoritativeBundle.metadata.displayName}',
                  ),
                ],
                if (controller.authoritativeChangedDuringPreview)
                  const Text(
                    'The synchronized authoritative theme changed. '
                    'Revert will use the newer setting.',
                  ),
                if (controller.applyError case final error?)
                  Text(error, key: const Key('theme-apply-error')),
                FilledButton(
                  key: const Key('apply-theme-preview'),
                  onPressed: controller.canApply ? onApply : null,
                  child: Text(
                    controller.applyError == null ? 'Apply' : 'Retry',
                  ),
                ),
                TextButton(
                  key: const Key('revert-theme-preview'),
                  onPressed: controller.isApplying ? null : onRevert,
                  child: Text(unavailable ? 'Dismiss' : 'Revert'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
