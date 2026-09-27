import 'dart:async';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/material.dart';

typedef PreviewWorkScheduleFeed =
    Future<WorkScheduleFeedConnectionPreview> Function(String name, Uri url);
typedef ConfirmWorkScheduleFeed =
    Future<void> Function(
      WorkScheduleFeedConnectionPreview preview, {
      required bool replaceMatching,
    });
typedef RefreshWorkScheduleFeed =
    Future<WorkScheduleFeedRefreshResult> Function(
      WorkScheduleFeed feed, {
      bool confirmEmpty,
    });
typedef UpdateWorkScheduleFeedSkipWords =
    Future<WorkScheduleFeed> Function(
      WorkScheduleFeed feed,
      List<String> skipWords,
    );
typedef DisconnectWorkScheduleFeed =
    Future<void> Function(WorkScheduleFeed feed);

/// Shared live surface for every theme and platform's Work Schedule Feeds.
final class WorkScheduleFeedSurface extends StatefulWidget {
  const WorkScheduleFeedSurface({
    required this.initialFeeds,
    required this.onPreviewConnection,
    required this.onConfirmConnection,
    this.onDiscardPreview,
    required this.onRefresh,
    required this.onUpdateSkipWords,
    required this.onDisconnect,
    super.key,
  });

  final List<WorkScheduleFeed> initialFeeds;
  final PreviewWorkScheduleFeed onPreviewConnection;
  final ConfirmWorkScheduleFeed onConfirmConnection;
  final DisconnectWorkScheduleFeed? onDiscardPreview;
  final RefreshWorkScheduleFeed onRefresh;
  final UpdateWorkScheduleFeedSkipWords onUpdateSkipWords;
  final DisconnectWorkScheduleFeed onDisconnect;

  @override
  State<WorkScheduleFeedSurface> createState() =>
      _WorkScheduleFeedSurfaceState();
}

final class _WorkScheduleFeedSurfaceState
    extends State<WorkScheduleFeedSurface> {
  late List<WorkScheduleFeed> _feeds;
  WorkScheduleFeed? _selected;

  @override
  void initState() {
    super.initState();
    _feeds = List.of(widget.initialFeeds);
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 120),
    child: _selected == null
        ? _FeedList(
            key: const ValueKey('feed-list'),
            feeds: _feeds,
            onOpen: (feed) => setState(() => _selected = feed),
            onConnected: (feed) => setState(() => _feeds.add(feed)),
            onPreviewConnection: widget.onPreviewConnection,
            onConfirmConnection: widget.onConfirmConnection,
            onDiscardPreview: widget.onDiscardPreview,
          )
        : _FeedPage(
            key: ValueKey(_selected!.id),
            feed: _selected!,
            onBack: () => setState(() => _selected = null),
            onRefresh: widget.onRefresh,
            onUpdateSkipWords: widget.onUpdateSkipWords,
            onChanged: _replace,
            onDisconnect: (feed) async {
              await widget.onDisconnect(feed);
              if (!mounted) return;
              setState(() {
                _feeds.removeWhere((candidate) => candidate.id == feed.id);
                _selected = null;
              });
            },
          ),
  );

  void _replace(WorkScheduleFeed feed) => setState(() {
    _feeds = [
      for (final candidate in _feeds)
        if (candidate.id == feed.id) feed else candidate,
    ];
    _selected = feed;
  });
}

final class _FeedList extends StatefulWidget {
  const _FeedList({
    required this.feeds,
    required this.onOpen,
    required this.onConnected,
    required this.onPreviewConnection,
    required this.onConfirmConnection,
    required this.onDiscardPreview,
    super.key,
  });

  final List<WorkScheduleFeed> feeds;
  final ValueChanged<WorkScheduleFeed> onOpen;
  final ValueChanged<WorkScheduleFeed> onConnected;
  final PreviewWorkScheduleFeed onPreviewConnection;
  final ConfirmWorkScheduleFeed onConfirmConnection;
  final DisconnectWorkScheduleFeed? onDiscardPreview;

  @override
  State<_FeedList> createState() => _FeedListState();
}

final class _FeedListState extends State<_FeedList> {
  final _name = TextEditingController();
  final _url = TextEditingController();
  WorkScheduleFeedConnectionPreview? _preview;
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    final preview = _preview;
    if (preview != null && !_busy) {
      unawaited(widget.onDiscardPreview?.call(preview.feed));
    }
    _name.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _previewConnection() async {
    Uri url;
    try {
      url = Uri.parse(_url.text.trim());
      if (_name.text.trim().isEmpty || url.host.isEmpty) {
        throw const FormatException();
      }
    } on FormatException {
      setState(() => _message = 'Enter a name and an HTTPS or webcal URL.');
      return;
    }
    final previousPreview = _preview;
    setState(() {
      _busy = true;
      _message = null;
      _preview = null;
    });
    try {
      if (previousPreview != null) {
        await widget.onDiscardPreview?.call(previousPreview.feed);
      }
      final preview = await widget.onPreviewConnection(_name.text.trim(), url);
      if (!mounted) {
        await widget.onDiscardPreview?.call(preview.feed);
        return;
      }
      setState(() => _preview = preview);
    } on WorkScheduleFeedTeamFeedException {
      if (mounted) {
        setState(() => _message = WorkScheduleFeedTeamFeedException.message);
      }
    } on Object {
      if (mounted) {
        setState(() => _message = 'The feed could not be previewed.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final preview = _preview;
    if (preview == null) return;
    var replaceMatching = false;
    if (preview.matchingHandEnteredWorkShiftIds.isNotEmpty) {
      final choice = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace matching shifts?'),
          content: Text(
            '${preview.matchingHandEnteredWorkShiftIds.length} hand-entered '
            '${preview.matchingHandEnteredWorkShiftIds.length == 1 ? 'shift matches' : 'shifts match'}. '
            'Replace ${preview.matchingHandEnteredWorkShiftIds.length == 1 ? 'it' : 'them'} with the imported versions?',
          ),
          actions: [
            TextButton(
              key: const Key('keep-matching-shifts-action'),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep hand-entered'),
            ),
            FilledButton(
              key: const Key('replace-matching-shifts-action'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Replace shifts'),
            ),
          ],
        ),
      );
      if (choice == null) return;
      replaceMatching = choice;
    }
    setState(() {
      _busy = true;
      _preview = null;
    });
    try {
      await widget.onConfirmConnection(
        preview,
        replaceMatching: replaceMatching,
      );
      if (!mounted) return;
      widget.onConnected(preview.feed);
      setState(() {
        _name.clear();
        _url.clear();
      });
    } on Object {
      if (mounted) {
        setState(() {
          _preview = preview;
          _message = 'The feed could not be connected.';
        });
      } else {
        await widget.onDiscardPreview?.call(preview.feed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('work-schedule-feed-surface'),
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        'Work Schedule Feeds',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      if (widget.feeds.isEmpty) const Text('No Work Schedule Feeds connected.'),
      for (final feed in widget.feeds)
        ListTile(
          title: Text(feed.name),
          subtitle: Text(_status(feed)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => widget.onOpen(feed),
        ),
      const Divider(height: 32),
      Text(
        'Connect a work schedule feed',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      TextField(
        key: const Key('feed-name-field'),
        controller: _name,
        decoration: const InputDecoration(labelText: 'Feed name'),
      ),
      const SizedBox(height: 8),
      TextField(
        key: const Key('feed-url-field'),
        controller: _url,
        autocorrect: false,
        decoration: const InputDecoration(labelText: 'Personal calendar URL'),
      ),
      const SizedBox(height: 10),
      FilledButton(
        key: const Key('preview-feed-action'),
        onPressed: _busy ? null : _previewConnection,
        child: const Text('Preview feed'),
      ),
      if (_message != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(_message!, key: const Key('feed-message')),
        ),
      if (_preview case final preview?)
        _ConnectionPreview(preview: preview, busy: _busy, onConfirm: _confirm),
    ],
  );
}

final class _ConnectionPreview extends StatelessWidget {
  const _ConnectionPreview({
    required this.preview,
    required this.busy,
    required this.onConfirm,
  });

  final WorkScheduleFeedConnectionPreview preview;
  final bool busy;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final count = preview.upcomingShifts.length;
    final matches = preview.matchingHandEnteredWorkShiftIds.length;
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('$count upcoming ${count == 1 ? 'shift' : 'shifts'}'),
            ..._notImported(preview.notImported),
            if (matches > 0)
              Text(
                '$matches hand-entered ${matches == 1 ? 'shift matches' : 'shifts match'}. '
                'Replace ${matches == 1 ? 'it' : 'them'} with the imported versions?',
              ),
            const SizedBox(height: 10),
            FilledButton(
              key: const Key('confirm-feed-action'),
              onPressed: busy ? null : onConfirm,
              child: const Text('Connect feed'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _FeedPage extends StatefulWidget {
  const _FeedPage({
    required this.feed,
    required this.onBack,
    required this.onRefresh,
    required this.onUpdateSkipWords,
    required this.onChanged,
    required this.onDisconnect,
    super.key,
  });

  final WorkScheduleFeed feed;
  final VoidCallback onBack;
  final RefreshWorkScheduleFeed onRefresh;
  final UpdateWorkScheduleFeedSkipWords onUpdateSkipWords;
  final ValueChanged<WorkScheduleFeed> onChanged;
  final DisconnectWorkScheduleFeed onDisconnect;

  @override
  State<_FeedPage> createState() => _FeedPageState();
}

final class _FeedPageState extends State<_FeedPage> {
  late final TextEditingController _skipWords;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _skipWords = TextEditingController(text: widget.feed.skipWords.join(', '));
  }

  @override
  void dispose() {
    _skipWords.dispose();
    super.dispose();
  }

  Future<void> _saveWords() async {
    final words = _skipWords.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    setState(() => _busy = true);
    try {
      final feed = await widget.onUpdateSkipWords(widget.feed, words);
      widget.onChanged(feed);
      await _refresh(
        feed: feed,
        successMessage: 'Skip words saved and applied.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh({
    WorkScheduleFeed? feed,
    bool confirmEmpty = false,
    String successMessage = 'Feed refreshed.',
  }) async {
    final target = feed ?? widget.feed;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await widget.onRefresh(target, confirmEmpty: confirmEmpty);
      if (!mounted) return;
      widget.onChanged(result.feed);
      if (result.disposition ==
          WorkScheduleFeedRefreshDisposition.requiresEmptyConfirmation) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No upcoming shifts were found'),
            content: const Text(
              'Remove the upcoming Imported Work Shifts from this feed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep shifts'),
              ),
              FilledButton(
                key: const Key('confirm-empty-feed-action'),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove upcoming shifts'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await _refresh(
            feed: target,
            confirmEmpty: true,
            successMessage: successMessage,
          );
        }
      } else if (result.disposition ==
          WorkScheduleFeedRefreshDisposition.heldTeamFeed) {
        setState(() => _message = WorkScheduleFeedTeamFeedException.message);
      } else if (result.disposition ==
          WorkScheduleFeedRefreshDisposition.failed) {
        setState(() => _message = _status(result.feed));
      } else {
        setState(() => _message = successMessage);
      }
    } on Object {
      if (mounted) {
        setState(
          () => _message =
              "${widget.feed.name} hasn't updated since ${_date(widget.feed.lastSuccessfulUpdateAtUtc)}",
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDisconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Work Schedule Feed?'),
        content: const Text(
          'Upcoming Imported Work Shifts will be removed. Past shifts stay in history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-disconnect-feed-action'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.onDisconnect(widget.feed);
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Row(
        children: [
          BackButton(onPressed: widget.onBack),
          Expanded(
            child: Text(
              widget.feed.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ),
      Text(_status(widget.feed)),
      Text(widget.feed.maskedUrl),
      if (widget.feed.heldReason != null) Text(widget.feed.heldReason!),
      const SizedBox(height: 16),
      Text('Not imported', style: Theme.of(context).textTheme.titleMedium),
      if (widget.feed.notImported.isEmpty) const Text('Nothing skipped.'),
      ..._notImported(widget.feed.notImported),
      const SizedBox(height: 16),
      TextField(
        key: const Key('feed-skip-words-field'),
        controller: _skipWords,
        decoration: const InputDecoration(
          labelText: 'Skip words (comma separated)',
        ),
      ),
      OutlinedButton(
        key: const Key('save-skip-words-action'),
        onPressed: _busy ? null : _saveWords,
        child: const Text('Save skip words'),
      ),
      FilledButton.icon(
        key: const Key('refresh-feed-action'),
        onPressed: _busy ? null : _refresh,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh now'),
      ),
      OutlinedButton.icon(
        key: const Key('disconnect-feed-action'),
        onPressed: _busy ? null : _confirmDisconnect,
        icon: const Icon(Icons.link_off),
        label: const Text('Disconnect'),
      ),
      if (_message != null) Text(_message!),
    ],
  );
}

Iterable<Widget> _notImported(
  Iterable<WorkScheduleFeedNotImportedEvent> events,
) => events.map(
  (event) => Text(
    '${event.title} — ${switch (event.reason) {
      WorkScheduleFeedNotImportedReason.allDay => 'all-day event',
      WorkScheduleFeedNotImportedReason.skipWord => 'skipped by word',
    }}',
  ),
);

String _status(WorkScheduleFeed feed) => feed.heldReason == null
    ? 'updated ${_dateTime(feed.lastSuccessfulUpdateAtUtc)}'
    : "${feed.name} hasn't updated since ${_date(feed.lastSuccessfulUpdateAtUtc)}";

String _date(DateTime value) =>
    '${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}-${value.year}';

String _dateTime(DateTime value) =>
    '${_date(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
