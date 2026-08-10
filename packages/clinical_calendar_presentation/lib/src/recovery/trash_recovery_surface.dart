import 'package:flutter/material.dart';
import 'package:clinical_calendar_application/clinical_calendar_application.dart';

import '../date_input.dart';
import '../variant_f_theme.dart';

final class TrashRecoverySurface extends StatefulWidget {
  const TrashRecoverySurface({
    required this.loadTrash,
    required this.restore,
    required this.permanentlyDelete,
    required this.clearTrash,
    required this.loadSnapshots,
    required this.previewSnapshot,
    required this.restoreSnapshot,
    this.showAppBar = true,
    this.reauthenticateForClear,
    super.key,
  });

  final Future<List<TrashEntry>> Function() loadTrash;
  final Future<void> Function(String trashId) restore;
  final Future<void> Function(String trashId) permanentlyDelete;
  final Future<void> Function() clearTrash;
  final Future<List<OperationalSnapshotSummary>> Function() loadSnapshots;
  final Future<OperationalRecoveryPreview> Function(String snapshotId)
  previewSnapshot;
  final Future<void> Function(
    String snapshotId,
    Map<String, RecoveryConflictChoice> choices,
  )
  restoreSnapshot;
  final bool showAppBar;
  final Future<bool> Function()? reauthenticateForClear;

  @override
  State<TrashRecoverySurface> createState() => _TrashRecoverySurfaceState();
}

final class _TrashRecoverySurfaceState extends State<TrashRecoverySurface> {
  List<TrashEntry> _trash = const [];
  List<OperationalSnapshotSummary> _snapshots = const [];
  OperationalRecoveryPreview? _preview;
  final _choices = <String, RecoveryConflictChoice>{};
  bool _busy = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: _busy && _trash.isEmpty && _snapshots.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final sections = <Widget>[
                  _trashPanel(context),
                  _snapshotPanel(context),
                ];
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Deleted records remain recoverable on connected devices '
                      'for 30 days. Recovery always checks the current calendar rules.',
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(_message!, key: const Key('recovery-message')),
                    ],
                    const SizedBox(height: 16),
                    if (constraints.maxWidth >= 760)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: sections[0]),
                          const SizedBox(width: 16),
                          Expanded(child: sections[1]),
                        ],
                      )
                    else
                      ...sections.expand(
                        (section) => [section, const SizedBox(height: 16)],
                      ),
                  ],
                );
              },
            ),
    );
    if (!widget.showAppBar) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Trash & recovery')),
      body: content,
    );
  }

  Widget _trashPanel(BuildContext context) => _Panel(
    title: 'Trash',
    trailing: OutlinedButton(
      key: const Key('clear-trash'),
      onPressed: _trash.isEmpty || _busy ? null : _confirmClear,
      child: const Text('Clear Trash'),
    ),
    child: _trash.isEmpty
        ? const Text('Trash is empty.')
        : Column(
            children: [
              for (final entry in _trash)
                ListTile(
                  key: Key('trash-${entry.id}'),
                  title: Text(_entityLabel(entry.entityType)),
                  subtitle: Text(
                    'Recoverable until '
                    '${formatUsDateFromDateTime(entry.purgeAfterUtc)}',
                  ),
                  contentPadding: EdgeInsets.zero,
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: 'Restore',
                        onPressed: _busy ? null : () => _restore(entry.id),
                        icon: const Icon(Icons.restore),
                      ),
                      IconButton(
                        tooltip: 'Delete permanently',
                        onPressed: _busy
                            ? null
                            : () => _confirmPermanent(entry.id),
                        icon: const Icon(Icons.delete_forever_outlined),
                      ),
                    ],
                  ),
                ),
            ],
          ),
  );

  Widget _snapshotPanel(BuildContext context) => _Panel(
    title: 'Daily recovery copies',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_snapshots.isEmpty)
          const Text('A recovery copy will appear after the daily snapshot.'),
        for (final snapshot in _snapshots)
          ListTile(
            key: Key('snapshot-${snapshot.id}'),
            contentPadding: EdgeInsets.zero,
            title: Text(snapshot.snapshotDate),
            subtitle: const Text('Preview required before merge'),
            trailing: TextButton(
              onPressed: _busy ? null : () => _previewRecovery(snapshot.id),
              child: const Text('Preview'),
            ),
          ),
        if (_preview case final preview?) ...[
          const Divider(),
          Text(
            '${preview.additions} additions · ${preview.snapshotUpdates} updates',
            key: const Key('snapshot-preview-summary'),
          ),
          const SizedBox(height: 8),
          for (final conflict in preview.conflicts)
            SegmentedButton<RecoveryConflictChoice>(
              key: Key('recovery-conflict-${conflict.identity}'),
              segments: const [
                ButtonSegment(
                  value: RecoveryConflictChoice.keepCurrent,
                  label: Text('Keep current'),
                ),
                ButtonSegment(
                  value: RecoveryConflictChoice.useSnapshot,
                  label: Text('Use copy'),
                ),
              ],
              selected: _choices[conflict.identity] == null
                  ? const {}
                  : {_choices[conflict.identity]!},
              emptySelectionAllowed: true,
              onSelectionChanged: (value) => setState(() {
                if (value.isNotEmpty) {
                  _choices[conflict.identity] = value.single;
                }
              }),
            ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('confirm-snapshot-merge'),
            onPressed:
                _busy ||
                    preview.conflicts.any(
                      (item) => !_choices.containsKey(item.identity),
                    )
                ? null
                : _applySnapshot,
            child: const Text('Confirm safe merge'),
          ),
        ],
      ],
    ),
  );

  Future<void> _refresh() => _run(() async {
    final values = await Future.wait([
      widget.loadTrash(),
      widget.loadSnapshots(),
    ]);
    _trash = values[0] as List<TrashEntry>;
    _snapshots = values[1] as List<OperationalSnapshotSummary>;
  }, clearMessage: false);

  Future<void> _restore(String id) => _run(() async {
    await widget.restore(id);
    _message = 'Record restored and queued for synchronization.';
    _trash = await widget.loadTrash();
  });

  Future<void> _previewRecovery(String id) => _run(() async {
    _preview = await widget.previewSnapshot(id);
    _choices.clear();
    _message = 'Recovery copy validated. Live data has not changed.';
  });

  Future<void> _applySnapshot() => _run(() async {
    await widget.restoreSnapshot(_preview!.snapshot.id, Map.of(_choices));
    _preview = null;
    _choices.clear();
    _message = 'Recovery merge applied.';
  });

  Future<void> _confirmPermanent(String id) async {
    if (!await _confirm('Delete permanently?', 'This cannot be undone.')) {
      return;
    }
    await _run(() async {
      await widget.permanentlyDelete(id);
      _trash = await widget.loadTrash();
      _message = 'Record permanently deleted.';
    });
  }

  Future<void> _confirmClear() async {
    if (!await _confirm(
      'Clear all Trash?',
      'Reauthentication follows. This cannot be undone.',
    )) {
      return;
    }
    final reauthenticate = widget.reauthenticateForClear;
    if (reauthenticate != null && !await reauthenticate()) {
      if (mounted) {
        setState(
          () => _message =
              'Reauthentication was cancelled. Trash was not changed.',
        );
      }
      return;
    }
    await _run(() async {
      await widget.clearTrash();
      _trash = await widget.loadTrash();
      _message = 'Trash cleared.';
    });
  }

  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _run(
    Future<void> Function() action, {
    bool clearMessage = true,
  }) async {
    setState(() {
      _busy = true;
      if (clearMessage) _message = null;
    });
    try {
      await action();
    } on Object {
      _message = 'Recovery could not be completed safely.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

final class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.clinicalColors.structure,
      border: Border.all(color: context.clinicalColors.insetBorder),
      borderRadius: BorderRadius.circular(context.clinicalMetrics.cornerRadius),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

String _entityLabel(String type) => switch (type) {
  'work_shift' => 'Work Shift',
  'clinical_session' => 'Clinical Session',
  'protected_day' => 'Protected Day',
  'schedule_template' => 'Schedule Template',
  'preceptor' => 'Preceptor',
  'clinical_placement' => 'Clinical Placement',
  'historical_hours_entry' => 'Historical Hours Entry',
  'evaluation_plan' => 'Evaluation Plan',
  'academic_assignment' => 'Academic Assignment',
  _ => 'Calendar record',
};
