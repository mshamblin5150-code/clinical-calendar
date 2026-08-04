import 'package:flutter/material.dart';

enum BackupConflictSelection { keepLocal, useBackup }

final class BackupConflictViewModel {
  const BackupConflictViewModel({
    required this.identity,
    required this.title,
    required this.localSummary,
    required this.backupSummary,
  });

  final String identity;
  final String title;
  final String localSummary;
  final String backupSummary;
}

final class BackupRestorePreviewViewModel {
  const BackupRestorePreviewViewModel({
    required this.additions,
    required this.backupUpdates,
    required this.localRecordsKept,
    this.conflicts = const [],
  });

  final int additions;
  final int backupUpdates;
  final int localRecordsKept;
  final List<BackupConflictViewModel> conflicts;
}

/// Platform-neutral backup workflow. File pickers and persistence are supplied
/// by callbacks at composition; this widget never handles a filesystem path.
final class BackupRestoreSurface extends StatefulWidget {
  const BackupRestoreSurface({
    required this.onCreateBackup,
    required this.onChooseBackup,
    required this.onApplyRestore,
    super.key,
  });

  final Future<void> Function(String passphrase) onCreateBackup;
  final Future<BackupRestorePreviewViewModel?> Function(String passphrase)
  onChooseBackup;
  final Future<void> Function(Map<String, BackupConflictSelection> choices)
  onApplyRestore;

  @override
  State<BackupRestoreSurface> createState() => _BackupRestoreSurfaceState();
}

final class _BackupRestoreSurfaceState extends State<BackupRestoreSurface> {
  final _passphrase = TextEditingController();
  final _confirmation = TextEditingController();
  BackupRestorePreviewViewModel? _preview;
  final _choices = <String, BackupConflictSelection>{};
  bool _busy = false;
  String? _message;

  bool get _validPassphrase =>
      _passphrase.text.length >= 12 && _passphrase.text == _confirmation.text;

  bool get _canApply =>
      !_busy &&
      _preview != null &&
      _preview!.conflicts.every(
        (conflict) => _choices.containsKey(conflict.identity),
      );

  @override
  void dispose() {
    _passphrase.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Encrypted portable backup')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Create a service-independent encrypted copy of your Clinical '
            'Calendar data and history.',
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('backup-passphrase'),
            controller: _passphrase,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Backup passphrase',
              helperText: 'Use at least 12 characters. It cannot be recovered.',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('backup-passphrase-confirmation'),
            controller: _confirmation,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Confirm passphrase'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                key: const Key('create-encrypted-backup'),
                onPressed: _validPassphrase && !_busy ? _create : null,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Create encrypted backup'),
              ),
              OutlinedButton.icon(
                key: const Key('choose-backup-file'),
                onPressed: _validPassphrase && !_busy ? _choose : null,
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Choose backup to restore'),
              ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!, key: const Key('backup-status-message')),
          ],
          if (_preview case final preview?) ...[
            const SizedBox(height: 28),
            Text(
              'Restore preview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${preview.additions} additions · '
              '${preview.backupUpdates} newer backup updates · '
              '${preview.localRecordsKept} local records kept',
            ),
            const SizedBox(height: 12),
            const Text(
              'Restore merges by permanent identity. There is no Replace '
              'Everything action.',
              key: Key('no-replace-warning'),
            ),
            for (final conflict in preview.conflicts)
              _ConflictChoice(
                conflict: conflict,
                selection: _choices[conflict.identity],
                onChanged: (selection) => setState(() {
                  _choices[conflict.identity] = selection;
                }),
              ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('apply-restore'),
              onPressed: _canApply ? _apply : null,
              child: Text(
                preview.conflicts.isEmpty
                    ? 'Apply safe merge'
                    : 'Apply merge with choices',
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Future<void> _create() => _run(() async {
    await widget.onCreateBackup(_passphrase.text);
    _message = 'Encrypted backup created.';
  });

  Future<void> _choose() => _run(() async {
    final preview = await widget.onChooseBackup(_passphrase.text);
    if (preview != null) {
      _preview = preview;
      _choices.clear();
      _message = 'Backup validated. Review the merge before applying it.';
    }
  });

  Future<void> _apply() => _run(() async {
    await widget.onApplyRestore(Map.unmodifiable(_choices));
    _preview = null;
    _choices.clear();
    _message = 'Restore applied successfully.';
  });

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } on Object {
      _message = 'The backup operation could not be completed safely.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

final class _ConflictChoice extends StatelessWidget {
  const _ConflictChoice({
    required this.conflict,
    required this.selection,
    required this.onChanged,
  });

  final BackupConflictViewModel conflict;
  final BackupConflictSelection? selection;
  final ValueChanged<BackupConflictSelection> onChanged;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(conflict.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Current: ${conflict.localSummary}'),
          Text('Backup: ${conflict.backupSummary}'),
          const SizedBox(height: 12),
          SegmentedButton<BackupConflictSelection>(
            key: Key('backup-conflict-${conflict.identity}'),
            segments: const [
              ButtonSegment(
                value: BackupConflictSelection.keepLocal,
                label: Text('Keep current'),
              ),
              ButtonSegment(
                value: BackupConflictSelection.useBackup,
                label: Text('Use backup'),
              ),
            ],
            selected: selection == null ? const {} : {selection!},
            emptySelectionAllowed: true,
            onSelectionChanged: (values) {
              if (values.isNotEmpty) onChanged(values.single);
            },
          ),
        ],
      ),
    ),
  );
}
