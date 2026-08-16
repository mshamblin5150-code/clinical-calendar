import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:flutter/material.dart';

import '../date_input.dart';

import '../variant_f_theme.dart';
import 'conflict_resolution_controller.dart';

typedef OpenConflictRecordAction =
    void Function(
      SynchronizationConflictEntityReference record,
      CrossRecordResolutionAction action,
    );

final class SynchronizationConflictResolutionSurface extends StatelessWidget {
  const SynchronizationConflictResolutionSurface({
    required this.controller,
    this.onOpenRecordAction,
    super.key,
  });

  final ConflictResolutionController controller;
  final OpenConflictRecordAction? onOpenRecordAction;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final snapshot = controller.snapshot;
      return CustomScrollView(
        key: const Key('synchronization-conflict-resolution-surface'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _Header(
                conflictCount: snapshot?.items.length ?? 0,
                planningIncompleteCount: snapshot?.planningIncompleteCount ?? 0,
                busy: controller.busy,
                onRefresh: controller.load,
              ),
            ),
          ),
          if (controller.error != null && snapshot != null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  controller.error!,
                  style: TextStyle(color: context.clinicalColors.urgent),
                ),
              ),
            ),
          if (snapshot == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: controller.error == null
                  ? const Center(child: CircularProgressIndicator())
                  : _ConflictLoadFailure(onRetry: controller.load),
            )
          else if (!snapshot.hasConflicts)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No Sync Conflicts need attention.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.separated(
                itemCount: snapshot.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _ConflictCard(
                  item: snapshot.items[index],
                  controller: controller,
                  onOpenRecordAction: onOpenRecordAction,
                ),
              ),
            ),
        ],
      );
    },
  );
}

final class _ConflictLoadFailure extends StatelessWidget {
  const _ConflictLoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sync_problem_outlined,
            color: context.clinicalColors.urgent,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Synchronization conflicts could not be loaded.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'No records were changed. Retry before editing or moving '
            'affected records to Trash.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('retry-conflict-load-action'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('RETRY'),
          ),
        ],
      ),
    ),
  );
}

final class _Header extends StatelessWidget {
  const _Header({
    required this.conflictCount,
    required this.planningIncompleteCount,
    required this.busy,
    required this.onRefresh,
  });

  final int conflictCount;
  final int planningIncompleteCount;
  final bool busy;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SYNC CONFLICTS',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '$conflictCount need attention. Both originals remain in '
              'resolution history.',
            ),
            if (planningIncompleteCount > 0)
              Text(
                '$planningIncompleteCount affected '
                '${planningIncompleteCount == 1 ? 'week remains' : 'weeks remain'} '
                'Planning Incomplete.',
                key: const Key('planning-incomplete-conflict-summary'),
                style: TextStyle(color: context.clinicalColors.scheduled),
              ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Refresh Sync Conflicts',
        onPressed: busy ? null : onRefresh,
        icon: const Icon(Icons.refresh),
      ),
    ],
  );
}

final class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    required this.item,
    required this.controller,
    this.onOpenRecordAction,
  });

  final ConflictResolutionItem item;
  final ConflictResolutionController controller;
  final OpenConflictRecordAction? onOpenRecordAction;

  @override
  Widget build(BuildContext context) => Card(
    key: Key('sync-conflict-${item.record.id}'),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _entityLabel(item.record.entityType),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _StatusChip(label: _reasonLabel(item.record.rejectionCode)),
              if (item.planningIncomplete)
                const _StatusChip(label: 'Planning Incomplete'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Detected ${_dateTime(item.record.detectedAtUtc)}. '
            'Nothing is discarded until you choose a resolution.',
          ),
          const SizedBox(height: 14),
          if (item.workflow == SynchronizationConflictWorkflow.sameRecord ||
              item.workflow == SynchronizationConflictWorkflow.relationship)
            _SameRecordResolution(item: item, controller: controller)
          else
            _CrossRecordResolution(
              item: item,
              controller: controller,
              onOpenRecordAction: onOpenRecordAction,
            ),
        ],
      ),
    ),
  );
}

final class _SameRecordResolution extends StatelessWidget {
  const _SameRecordResolution({required this.item, required this.controller});

  final ConflictResolutionItem item;
  final ConflictResolutionController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final versions = [
            _VersionPanel(
              title: 'This device',
              version: item.local,
              actionKey: const Key('choose-local-conflict-version'),
              onChoose: controller.busy || !item.local.isComplete
                  ? null
                  : () => controller.resolve(
                      conflict: item,
                      choice:
                          SynchronizationConflictResolutionChoice.localVersion,
                    ),
            ),
            _VersionPanel(
              title: 'Other device',
              version: item.remote,
              actionKey: const Key('choose-remote-conflict-version'),
              onChoose: controller.busy || !item.remote.isComplete
                  ? null
                  : () => controller.resolve(
                      conflict: item,
                      choice:
                          SynchronizationConflictResolutionChoice.remoteVersion,
                    ),
            ),
          ];
          if (constraints.maxWidth < 620) {
            return Column(
              children: [
                versions.first,
                const SizedBox(height: 10),
                versions.last,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: versions.first),
              const SizedBox(width: 10),
              Expanded(child: versions.last),
            ],
          );
        },
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        key: const Key('compose-corrected-conflict-version'),
        onPressed: controller.busy || !item.remote.isComplete
            ? null
            : () => _composeCorrected(context, item, controller),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Compose corrected version'),
      ),
      if (!item.remote.isComplete)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Waiting for the complete version from the other device.',
          ),
        ),
    ],
  );
}

final class _VersionPanel extends StatelessWidget {
  const _VersionPanel({
    required this.title,
    required this.version,
    required this.actionKey,
    required this.onChoose,
  });

  final String title;
  final ConflictVersionSnapshot version;
  final Key actionKey;
  final VoidCallback? onChoose;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: context.clinicalColors.insetBorder),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (!version.isComplete)
            const Text('Complete version not received yet.')
          else
            for (final entry in version.values.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${_fieldLabel(entry.key)}: ${_value(entry.value)}',
                ),
              ),
          const SizedBox(height: 8),
          FilledButton(
            key: actionKey,
            onPressed: onChoose,
            child: const Text('Use this version'),
          ),
        ],
      ),
    ),
  );
}

final class _CrossRecordResolution extends StatelessWidget {
  const _CrossRecordResolution({
    required this.item,
    required this.controller,
    this.onOpenRecordAction,
  });

  final ConflictResolutionItem item;
  final ConflictResolutionController controller;
  final OpenConflictRecordAction? onOpenRecordAction;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Affected records'),
      const SizedBox(height: 6),
      for (final record in item.record.affectedRecords)
        ListTile(
          key: Key('affected-conflict-record-${record.entityId}'),
          contentPadding: EdgeInsets.zero,
          title: Text(_entityLabel(record.entityType)),
          subtitle: Text(record.entityId),
          trailing: const Icon(Icons.open_in_new),
          onTap: onOpenRecordAction == null
              ? null
              : () => onOpenRecordAction!(
                  record,
                  CrossRecordResolutionAction.move,
                ),
        ),
      const SizedBox(height: 8),
      if (!item.local.isComplete) ...[
        const Text(
          'A complete version is required before resolving this conflict.',
        ),
        const SizedBox(height: 8),
      ],
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            key: const Key('move-conflicting-record-action'),
            onPressed: controller.busy || !item.local.isComplete
                ? null
                : () => _composeCorrected(context, item, controller),
            child: const Text('Move'),
          ),
          if (item.record.entityType == 'clinical_session') ...[
            OutlinedButton(
              key: const Key('cancel-conflicting-session-action'),
              onPressed: controller.busy || !item.local.isComplete
                  ? null
                  : () => controller.resolveCrossRecord(
                      conflict: item,
                      action: CrossRecordResolutionAction.cancel,
                    ),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              key: const Key('miss-conflicting-session-action'),
              onPressed: controller.busy || !item.local.isComplete
                  ? null
                  : () => controller.resolveCrossRecord(
                      conflict: item,
                      action: CrossRecordResolutionAction.missed,
                    ),
              child: const Text('Missed'),
            ),
          ],
          OutlinedButton(
            key: const Key('delete-conflicting-record-action'),
            onPressed: controller.busy || !item.local.isComplete
                ? null
                : () => _confirmDelete(context, item, controller),
            child: const Text('Delete if eligible'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        'Move, Cancel, Missed, or eligible deletion must leave every affected '
        'record valid before synchronization can converge.',
      ),
    ],
  );
}

final class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.clinicalColors.scheduled.withValues(alpha: 0.12),
      border: Border.all(color: context.clinicalColors.scheduled),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(label),
    ),
  );
}

Future<void> _composeCorrected(
  BuildContext context,
  ConflictResolutionItem item,
  ConflictResolutionController controller,
) async {
  final result = await showDialog<Map<String, Object?>>(
    context: context,
    builder: (context) => _CorrectedVersionDialog(item: item),
  );
  if (result != null) {
    await controller.resolve(
      conflict: item,
      choice: SynchronizationConflictResolutionChoice.correctedVersion,
      correctedValues: result,
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  ConflictResolutionItem item,
  ConflictResolutionController controller,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete conflicting record?'),
      content: const Text(
        'The record will be deleted as the explicit conflict resolution. '
        'Both original versions remain in local resolution history.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep record'),
        ),
        FilledButton(
          key: const Key('confirm-delete-conflicting-record'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete record'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await controller.resolveCrossRecord(
      conflict: item,
      action: CrossRecordResolutionAction.deleteIfEligible,
    );
  }
}

final class _CorrectedVersionDialog extends StatefulWidget {
  const _CorrectedVersionDialog({required this.item});
  final ConflictResolutionItem item;

  @override
  State<_CorrectedVersionDialog> createState() =>
      _CorrectedVersionDialogState();
}

final class _CorrectedVersionDialogState
    extends State<_CorrectedVersionDialog> {
  late final List<String> _fields;
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _fields = widget.item.comparableFields;
    _controllers = {
      for (final field in _fields)
        field: TextEditingController(
          text: _value(widget.item.local.values[field]),
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Compose corrected version'),
    content: SizedBox(
      width: 520,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _fields.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final field = _fields[index];
          return TextField(
            controller: _controllers[field],
            decoration: InputDecoration(labelText: _fieldLabel(field)),
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('save-corrected-conflict-version'),
        onPressed: () => Navigator.pop(context, {
          for (final field in _fields)
            field: _parseLike(
              _controllers[field]!.text,
              widget.item.local.values[field] ??
                  widget.item.remote.values[field],
            ),
        }),
        child: const Text('Use corrected version'),
      ),
    ],
  );
}

Object? _parseLike(String value, Object? exemplar) {
  if (exemplar is int) return int.tryParse(value) ?? value;
  if (exemplar is bool) return value.toLowerCase() == 'true';
  if (exemplar == null && value == 'null') return null;
  return value;
}

String _entityLabel(String type) => _fieldLabel(type);

String _fieldLabel(String value) => value
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');

String _reasonLabel(String value) => switch (value) {
  'stale_revision' => 'Same record changed on two devices',
  'schedule_conflict' => 'Schedule Conflict',
  'protected_day_violation' => 'Protected Day conflict',
  'relationship_violation' => 'Relationship conflict',
  _ => 'Synchronization conflict',
};

String _value(Object? value) => switch (value) {
  null => 'null',
  List<Object?> values => values.join(', '),
  Map<Object?, Object?> values =>
    values.entries.map((entry) => '${entry.key}: ${entry.value}').join(', '),
  _ => value.toString(),
};

String _dateTime(DateTime value) => formatUsDateTime(value);
