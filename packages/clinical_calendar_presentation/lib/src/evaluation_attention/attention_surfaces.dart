import 'dart:math' as math;

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:flutter/material.dart';

import '../graphite_instrument_scope.dart';
import '../responsive_shell.dart';
import '../theme_contract.dart';
import '../variant_f_theme.dart';
import 'evaluation_attention_controller.dart';

typedef AttentionAction = void Function(AttentionItem item);

final class SynchronizationAttentionSurface extends StatefulWidget {
  const SynchronizationAttentionSurface({
    required this.synchronization,
    this.onSynchronized,
    super.key,
  });

  final SynchronizationService synchronization;
  final Future<void> Function()? onSynchronized;

  @override
  State<SynchronizationAttentionSurface> createState() =>
      _SynchronizationAttentionSurfaceState();
}

final class _SynchronizationAttentionSurfaceState
    extends State<SynchronizationAttentionSurface> {
  bool _busy = false;
  String? _status;

  Future<void> _syncNow() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final result = await widget.synchronization.synchronize();
      await widget.onSynchronized?.call();
      if (!mounted) return;
      setState(() {
        _status = switch (result.disposition) {
          SynchronizationDisposition.synchronized =>
            'Synchronization complete.',
          SynchronizationDisposition.offline =>
            'Synchronization is offline. Local changes remain queued.',
          SynchronizationDisposition.deferred =>
            'Synchronization is deferred. Local changes remain queued.',
        };
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _status =
            'Synchronization could not complete. Local changes remain queued.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('synchronization-attention-surface'),
    padding: const EdgeInsets.all(12),
    children: [
      ShellPanel(
        label: 'Synchronization',
        accent: context.clinicalColors.scheduled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sync Now sends queued local changes and checks for changes '
              'from your other devices. Local saves remain available if '
              'synchronization is offline.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('sync-now-action'),
              onPressed: _busy ? null : _syncNow,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(_busy ? 'SYNCING' : 'SYNC NOW'),
            ),
            if (_status != null) ...[
              const SizedBox(height: 10),
              Text(_status!, key: const Key('synchronization-status')),
            ],
          ],
        ),
      ),
    ],
  );
}

final class AttentionRail extends StatelessWidget {
  const AttentionRail({
    required this.controller,
    required this.onOpenAction,
    this.onOpenAll,
    super.key,
  });

  final EvaluationAttentionController controller;
  final AttentionAction onOpenAction;
  final VoidCallback? onOpenAll;

  @override
  Widget build(BuildContext context) {
    if (GraphiteInstrumentScope.isActive(context)) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) => _GraphiteAttentionRail(
          controller: controller,
          onOpenAction: onOpenAction,
        ),
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final items = controller.attentionItems;
        return ShellPanel(
          label: 'Needs Attention · ${items.length}',
          accent: items.isEmpty
              ? context.clinicalColors.clinical
              : context.clinicalColors.urgent,
          child: Column(
            key: const Key('attention-rail'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (controller.isBusy && controller.snapshot == null)
                const Center(child: CircularProgressIndicator())
              else if (controller.error != null && controller.snapshot == null)
                OutlinedButton(
                  onPressed: controller.load,
                  child: const Text('Retry attention'),
                )
              else if (items.isEmpty)
                const Text('No unresolved items need attention.')
              else
                for (final item in items.take(4)) ...[
                  _AttentionRow(item: item, onOpen: () => onOpenAction(item)),
                  const SizedBox(height: 6),
                ],
              if (items.length > 4 || onOpenAll != null)
                TextButton(
                  key: const Key('open-attention-center-action'),
                  onPressed: onOpenAll,
                  child: const Text('OPEN ATTENTION CENTER'),
                ),
            ],
          ),
        );
      },
    );
  }
}

final class _GraphiteAttentionRail extends StatelessWidget {
  const _GraphiteAttentionRail({
    required this.controller,
    required this.onOpenAction,
  });

  final EvaluationAttentionController controller;
  final AttentionAction onOpenAction;

  @override
  Widget build(BuildContext context) {
    final items = controller.attentionItems;
    return KeyedSubtree(
      key: const Key('attention-rail'),
      child: Column(
        key: const Key('graphite-live-attention-rail'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: context.clinicalColors.secondaryText,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'NEEDS ATTENTION',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                'ON  •  ${items.length}',
                style: TextStyle(
                  color: items.isEmpty
                      ? context.clinicalColors.secondaryText
                      : context.clinicalColors.urgent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (controller.isBusy && controller.snapshot == null)
            const Center(child: CircularProgressIndicator())
          else if (controller.error != null && controller.snapshot == null)
            const Text('Attention is temporarily unavailable.')
          else if (items.isEmpty)
            const Text('No unresolved items need attention.')
          else
            for (final item in items.take(4))
              _GraphiteAttentionRow(
                item: item,
                onOpen: () => onOpenAction(item),
              ),
        ],
      ),
    );
  }
}

final class _GraphiteAttentionRow extends StatelessWidget {
  const _GraphiteAttentionRow({required this.item, required this.onOpen});

  final AttentionItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final urgency = _urgencyColor(context, item.urgency);
    return InkWell(
      key: Key('attention-item-${item.id}'),
      onTap: onOpen,
      child: Container(
        key: const Key('graphite-live-attention-item'),
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: context.clinicalColors.insetBorder.withValues(alpha: .55),
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 34,
              child: CustomPaint(
                painter: _GraphiteAttentionMarkPainter(color: urgency),
                child: Icon(_kindIcon(item), size: 18, color: urgency),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: urgency,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (item.urgency == AttentionUrgency.due) ...[
              const SizedBox(width: 6),
              Text('Due', style: TextStyle(color: urgency)),
            ],
          ],
        ),
      ),
    );
  }
}

final class _GraphiteAttentionMarkPainter extends CustomPainter {
  const _GraphiteAttentionMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 2;
    for (var index = 0; index < 8; index++) {
      final angle = -math.pi / 8 + index * math.pi / 4;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_GraphiteAttentionMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

final class AttentionCenterSurface extends StatelessWidget {
  const AttentionCenterSurface({
    required this.controller,
    required this.onOpenAction,
    this.notificationMode = false,
    super.key,
  });

  final EvaluationAttentionController controller;
  final AttentionAction onOpenAction;
  final bool notificationMode;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final items = controller.attentionItems;
      return ListView(
        key: Key(
          notificationMode
              ? 'notification-center-surface'
              : 'attention-center-surface',
        ),
        padding: const EdgeInsets.all(12),
        children: [
          ShellPanel(
            label: notificationMode
                ? 'Notifications · ${items.length}'
                : 'Needs Attention · ${items.length}',
            accent: items.isEmpty
                ? context.clinicalColors.clinical
                : context.clinicalColors.urgent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  notificationMode
                      ? 'Notifications reflect unresolved workflow state. '
                            'Dismissing a system notification does not resolve it.'
                      : 'Each action opens the exact workflow that owns the '
                            'underlying state.',
                ),
                const SizedBox(height: 12),
                if (controller.isBusy && controller.snapshot == null)
                  const Center(child: CircularProgressIndicator())
                else if (controller.error != null &&
                    controller.snapshot == null)
                  OutlinedButton(
                    onPressed: controller.load,
                    child: const Text('Retry attention'),
                  )
                else if (items.isEmpty)
                  const Text('No unresolved items need attention.')
                else
                  for (final item in items) ...[
                    _AttentionRow(
                      item: item,
                      expanded: true,
                      onOpen: () => onOpenAction(item),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
        ],
      );
    },
  );
}

final class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.item,
    required this.onOpen,
    this.expanded = false,
  });

  final AttentionItem item;
  final VoidCallback onOpen;
  final bool expanded;

  @override
  Widget build(BuildContext context) => Material(
    color: context.clinicalColors.structureRaised,
    child: InkWell(
      key: Key('attention-item-${item.id}'),
      onTap: onOpen,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _urgencyColor(context, item.urgency),
              width: 3,
            ),
            top: BorderSide(color: context.clinicalColors.insetBorder),
            right: BorderSide(color: context.clinicalColors.insetBorder),
            bottom: BorderSide(color: context.clinicalColors.insetBorder),
          ),
        ),
        padding: const EdgeInsets.all(9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((ClinicalCalendarSemanticMarkScope.maybeOf(context)?.themeId !=
                        null &&
                    ClinicalCalendarSemanticMarkScope.maybeOf(
                          context,
                        )?.themeId !=
                        variantFThemeId) ||
                context.accessibilityTokens.enhanced)
              ThemeSemanticMarkIcon(
                role: item.urgency == AttentionUrgency.approaching
                    ? ThemeSemanticRole.scheduledProgress
                    : ThemeSemanticRole.urgent,
                color: _urgencyColor(context, item.urgency),
                size: 20,
              )
            else
              Icon(
                _kindIcon(item),
                color: _urgencyColor(context, item.urgency),
                size: 20,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    item.detail,
                    maxLines: expanded ? null : 3,
                    overflow: expanded ? null : TextOverflow.ellipsis,
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: Text(_actionLabel(item.destination)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!expanded) const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    ),
  );
}

Color _urgencyColor(BuildContext context, AttentionUrgency urgency) =>
    switch (urgency) {
      AttentionUrgency.approaching => context.clinicalColors.scheduled,
      AttentionUrgency.due ||
      AttentionUrgency.urgent => context.clinicalColors.urgent,
    };

IconData _kindIcon(AttentionItem item) {
  if (item.kind == AttentionKind.protectedDayPlanning &&
      item.title == 'Planning Incomplete') {
    return Icons.warning_amber_rounded;
  }
  return switch (item.kind) {
    AttentionKind.confirmation => Icons.fact_check_outlined,
    AttentionKind.protectedDayPlanning => Icons.shield_outlined,
    AttentionKind.evaluation => Icons.assignment_turned_in_outlined,
    AttentionKind.deadline => Icons.event_busy_outlined,
    AttentionKind.backup => Icons.lock_clock_outlined,
    AttentionKind.synchronization => Icons.sync_problem_outlined,
  };
}

String _actionLabel(AttentionDestination destination) => switch (destination) {
  AttentionDestination.confirmClinicalSession => 'Confirm Clinical Session',
  AttentionDestination.planProtectedDay => 'Plan Protected Day',
  AttentionDestination.documentEvaluation => 'Open Evaluation Plan',
  AttentionDestination.manageClinicalPlacement => 'Manage Clinical Placement',
  AttentionDestination.createPortableBackup => 'Create Portable Backup',
  AttentionDestination.resolveSynchronization => 'Open Synchronization',
};
