import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../enhanced_accessibility_controller.dart';
import '../responsive_shell.dart';

enum TicketMenuAction { putInTicket, tickets }

enum TicketActivity {
  openedCalendar('opened Calendar'),
  openedBatchPlanner('opened batch planner'),
  openedWorkShiftEditor('opened Work Shift editor'),
  openedClinicalSessionEditor('opened Clinical Session editor'),
  openedProtectedDayEditor('opened Protected Day editor'),
  openedSynchronizationConflicts('opened Synchronization conflicts'),
  tappedNext('tapped Next'),
  tappedSave('tapped Save'),
  tappedApplyBatch('tapped Apply batch');

  const TicketActivity(this.label);

  final String label;
}

/// A bounded, memory-only diagnostic trail whose public write API accepts
/// developer-owned labels and stable refusal codes, never form values.
final class TicketActivityLog {
  TicketActivityLog({this.limit = 8}) : assert(limit > 0);

  final int limit;
  final List<String> _actions = [];

  void record(TicketActivity action) => _add(action.label);

  void recordRefusal(String code) {
    if (!RegExp(r'^[a-z][a-z0-9_]{0,79}$').hasMatch(code)) {
      throw ArgumentError.value(code, 'code', 'Must be a stable refusal code');
    }
    _add('refused: $code');
  }

  List<String> snapshot() => List.unmodifiable(_actions);

  void _add(String action) {
    if (_actions.lastOrNull == action) return;
    _actions.add(action);
    if (_actions.length > limit) _actions.removeAt(0);
  }
}

final class TicketRefusalContext {
  const TicketRefusalContext({required this.screen, required this.code});

  final String screen;
  final String code;
}

typedef OpenTicketFromRefusal =
    Future<void> Function(TicketRefusalContext refusal);

final class TicketSupportScope extends InheritedWidget {
  const TicketSupportScope({
    required this.actions,
    required this.onOpenRefusal,
    required super.child,
    super.key,
  });

  final TicketActivityLog actions;
  final OpenTicketFromRefusal onOpenRefusal;

  static TicketSupportScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TicketSupportScope>();

  Widget wrap(Widget child) => TicketSupportScope(
    actions: actions,
    onOpenRefusal: onOpenRefusal,
    child: child,
  );

  @override
  bool updateShouldNotify(TicketSupportScope oldWidget) =>
      actions != oldWidget.actions || onOpenRefusal != oldWidget.onOpenRefusal;
}

const putRefusalInTicketLabel = 'Think this is wrong? Put in a Ticket';

final class TicketRefusalOffer extends StatelessWidget {
  const TicketRefusalOffer({
    required this.screen,
    required this.refusalCode,
    super.key,
  });

  final String screen;
  final String refusalCode;

  @override
  Widget build(BuildContext context) {
    final support = TicketSupportScope.maybeOf(context);
    if (support == null) return const SizedBox.shrink();
    return TextButton(
      key: Key('ticket-refusal-$refusalCode'),
      onPressed: () {
        support.actions.recordRefusal(refusalCode);
        support.onOpenRefusal(
          TicketRefusalContext(screen: screen, code: refusalCode),
        );
      },
      child: const Text(putRefusalInTicketLabel),
    );
  }
}

final class TicketApplicationMenu extends StatelessWidget {
  const TicketApplicationMenu({
    required this.onDestinationSelected,
    required this.onTicketSelected,
    required this.ticketSubmissionAvailable,
    this.enhancedAccessibilityController,
    this.onPersistEnhancedAccessibility,
    super.key,
  });

  final ValueChanged<ClinicalCalendarDestination> onDestinationSelected;
  final ValueChanged<TicketMenuAction> onTicketSelected;
  final bool ticketSubmissionAvailable;
  final EnhancedAccessibilityController? enhancedAccessibilityController;
  final PersistEnhancedAccessibility? onPersistEnhancedAccessibility;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const Key('ticket-enabled-application-menu'),
    child: Column(
      children: [
        ApplicationMenu(
          onSelected: onDestinationSelected,
          enhancedAccessibilityController: enhancedAccessibilityController,
          onPersistEnhancedAccessibility: onPersistEnhancedAccessibility,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.add_comment_outlined),
                title: const Text('Put in a Ticket'),
                subtitle: ticketSubmissionAvailable
                    ? null
                    : const Text('Connect to send a Ticket.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: ticketSubmissionAvailable
                    ? () => onTicketSelected(TicketMenuAction.putInTicket)
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.forum_outlined),
                title: const Text('Tickets'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onTicketSelected(TicketMenuAction.tickets),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class PutInTicketSurface extends StatefulWidget {
  const PutInTicketSurface({
    required this.gateway,
    required this.attachedContext,
    this.initialKind,
    super.key,
  });

  final TicketGateway gateway;
  final TicketContext attachedContext;
  final TicketKind? initialKind;

  @override
  State<PutInTicketSurface> createState() => _PutInTicketSurfaceState();
}

final class _PutInTicketSurfaceState extends State<PutInTicketSurface> {
  final _formKey = GlobalKey<FormState>();
  final _text = TextEditingController();
  late TicketKind? _kind;
  bool _sending = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate() || _kind == null) return;
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await widget.gateway.putIn(
        kind: _kind!,
        text: _text.text.trim(),
        context: widget.attachedContext,
      );
      if (!mounted) return;
      _text.clear();
      setState(() => _message = 'Ticket sent.');
    } on TicketSubmissionRejected catch (error) {
      if (!mounted) return;
      setState(() {
        _message = switch (error.reason) {
          TicketSubmissionRefusal.textInvalid =>
            'Write something before sending.',
          TicketSubmissionRefusal.contextIncomplete =>
            'The attached context is incomplete. Reopen the form and try again.',
          TicketSubmissionRefusal.rateLimited =>
            'You have put in a lot of Tickets. The Maintainer will see them all.',
        };
      });
    } catch (_) {
      if (mounted) setState(() => _message = "The Ticket wasn't sent.");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Form(
      key: _formKey,
      child: ListView(
        key: const Key('put-in-ticket-surface'),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Put in a Ticket',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Do not include patient information, patient names, or other '
                'clinical details. Tickets are private between you and the '
                'Maintainer.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TicketKind>(
            initialValue: _kind,
            decoration: const InputDecoration(
              labelText: 'Kind',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final kind in TicketKind.values)
                DropdownMenuItem(value: kind, child: Text(kind.label)),
            ],
            onChanged: _sending ? null : (kind) => setState(() => _kind = kind),
            validator: (kind) => kind == null ? 'Choose a kind.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('ticket-text'),
            controller: _text,
            enabled: !_sending,
            minLines: 5,
            maxLines: 10,
            maxLength: 2000,
            inputFormatters: [LengthLimitingTextInputFormatter(2000)],
            decoration: const InputDecoration(
              labelText: 'What would you like the Maintainer to know?',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Write something before sending.'
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            'Attached context',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            ticketContextSummary(widget.attachedContext),
            key: const Key('ticket-attached-context'),
          ),
          if (_message case final message?) ...[
            const SizedBox(height: 12),
            Semantics(liveRegion: true, child: Text(message)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('send-ticket-action'),
            onPressed: _sending ? null : _send,
            child: Text(_sending ? 'Sending…' : 'Send Ticket'),
          ),
        ],
      ),
    ),
  );
}

final class TicketsSurface extends StatefulWidget {
  const TicketsSurface({
    required this.gateway,
    this.onOpenApplicationMenu,
    super.key,
  });

  final TicketGateway gateway;
  final VoidCallback? onOpenApplicationMenu;

  @override
  State<TicketsSurface> createState() => _TicketsSurfaceState();
}

final class _TicketsSurfaceState extends State<TicketsSurface> {
  bool _loading = true;
  bool _maintainer = false;
  Object? _error;
  List<Ticket> _tickets = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final maintainer = await widget.gateway.hasMaintainerGrant();
      final tickets = maintainer
          ? await widget.gateway.readForMaintainer()
          : await widget.gateway.readMine();
      if (!mounted) return;
      setState(() {
        _maintainer = maintainer;
        _tickets = tickets;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Ticket ticket) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _TicketDetailPage(
          gateway: widget.gateway,
          initialTicket: ticket,
          maintainer: _maintainer,
          onOpenApplicationMenu: widget.onOpenApplicationMenu,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent, child: _body(context));
  }

  Widget _body(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tickets could not be loaded.'),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }
    if (_tickets.isEmpty) return const Center(child: Text('No Tickets yet.'));
    return ListView(
      key: const Key('tickets-surface'),
      children: [
        for (final ticket in _tickets)
          ListTile(
            key: Key('ticket-${ticket.id}'),
            title: Text(ticket.kind.label),
            subtitle: Text(
              '${ticket.firstLine}\n${ticket.status.label}'
              '${_maintainer ? '\nStudent ${_shortId(ticket.senderId)}' : ''}',
            ),
            isThreeLine: _maintainer,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(ticket),
          ),
      ],
    );
  }
}

final class _TicketDetailPage extends StatefulWidget {
  const _TicketDetailPage({
    required this.gateway,
    required this.initialTicket,
    required this.maintainer,
    required this.onOpenApplicationMenu,
  });

  final TicketGateway gateway;
  final Ticket initialTicket;
  final bool maintainer;
  final VoidCallback? onOpenApplicationMenu;

  @override
  State<_TicketDetailPage> createState() => _TicketDetailPageState();
}

final class _TicketDetailPageState extends State<_TicketDetailPage> {
  Ticket? _ticket;
  Object? _error;
  bool _working = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final ticket = widget.maintainer
          ? await widget.gateway.openForMaintainer(widget.initialTicket.id)
          : await widget.gateway.openForSender(widget.initialTicket.id);
      if (mounted) setState(() => _ticket = ticket);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _close(TicketStatus outcome) async {
    final reason = await _ticketTextDialog(
      context,
      title: outcome == TicketStatus.done
          ? 'Close as Done'
          : "Close as Won't do",
      guidance: outcome == TicketStatus.done
          ? 'Done means the change is already live on the web app, not merely merged.'
          : 'Tell the sender why this Ticket will not be done.',
      label: 'Reason the sender will see',
      fieldKey: const Key('ticket-close-reason'),
      action: 'Close Ticket',
      maxLength: 1000,
    );
    if (reason == null) return;
    await _mutate(
      () => widget.gateway.close(
        widget.initialTicket.id,
        outcome: outcome,
        reason: reason,
      ),
      'Ticket closed.',
    );
  }

  Future<void> _reopen() async {
    final note = await _ticketTextDialog(
      context,
      title: 'Reopen Ticket',
      guidance: 'Tell the Maintainer what happened again.',
      label: 'What happened again?',
      fieldKey: const Key('ticket-reopen-note'),
      action: 'Reopen',
      maxLength: 500,
    );
    if (note == null) return;
    await _mutate(
      () => widget.gateway.reopen(widget.initialTicket.id, note: note),
      'Ticket reopened.',
    );
  }

  Future<void> _mutate(
    Future<Ticket> Function() mutation,
    String success,
  ) async {
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      final ticket = await mutation();
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _message = success;
      });
    } on TicketMutationRejected catch (error) {
      if (!mounted) return;
      setState(() {
        _message = switch (error.reason) {
          TicketMutationRefusal.closingReasonRequired =>
            'Write a reason for the sender.',
          TicketMutationRefusal.cannotClose =>
            'This Ticket can no longer be closed.',
          TicketMutationRefusal.reopeningNoteRequired =>
            'Write what happened again.',
          TicketMutationRefusal.cannotReopen =>
            'This Ticket cannot be reopened.',
          TicketMutationRefusal.reopenExpired =>
            'This Ticket can no longer be reopened. Put in a new Ticket instead.',
        };
      });
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'This Ticket could not be updated.');
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Ticket'),
      actions: [
        if (widget.onOpenApplicationMenu case final onOpen?)
          IconButton(
            key: const Key('ticket-detail-menu-action'),
            tooltip: 'Application menu',
            onPressed: onOpen,
            icon: const Icon(Icons.menu),
          ),
      ],
    ),
    body: _error != null
        ? const Center(child: Text('This Ticket could not be opened.'))
        : _ticket == null
        ? const Center(child: CircularProgressIndicator())
        : SelectionArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _ticket!.kind.label,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(_ticket!.status.label),
                if (_ticket!.reopenedAtUtc != null) const Text('Reopened'),
                if (widget.maintainer)
                  Text('Student ${_shortId(_ticket!.senderId)}'),
                if (_ticket!.closeReason case final reason?) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Closing reason',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(reason),
                ],
                if (_ticket!.reopenNote case final note?) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Reopening note',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(note),
                ],
                const SizedBox(height: 20),
                Text(
                  'Ticket text',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(_ticket!.text),
                const SizedBox(height: 20),
                Text(
                  'Attached context',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(ticketContextSummary(_ticket!.context)),
                if (widget.maintainer && !_ticket!.status.isClosed) ...[
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _working
                            ? null
                            : () => _close(TicketStatus.done),
                        child: const Text('Close as Done'),
                      ),
                      OutlinedButton(
                        onPressed: _working
                            ? null
                            : () => _close(TicketStatus.wontDo),
                        child: const Text("Close as Won't do"),
                      ),
                    ],
                  ),
                ] else if (!widget.maintainer && _ticket!.status.isClosed) ...[
                  const SizedBox(height: 20),
                  if (_ticket!.canReopen)
                    FilledButton.tonal(
                      onPressed: _working ? null : _reopen,
                      child: const Text('Reopen Ticket'),
                    )
                  else
                    const Text(
                      'This Ticket can no longer be reopened. Please put in a new Ticket if you still need help.',
                    ),
                ],
                if (_message case final message?) ...[
                  const SizedBox(height: 12),
                  Semantics(liveRegion: true, child: Text(message)),
                ],
              ],
            ),
          ),
  );
}

Future<String?> _ticketTextDialog(
  BuildContext context, {
  required String title,
  required String guidance,
  required String label,
  required Key fieldKey,
  required String action,
  required int maxLength,
}) async {
  final formKey = GlobalKey<FormState>();
  var value = '';
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(guidance),
              const SizedBox(height: 12),
              TextFormField(
                key: fieldKey,
                autofocus: true,
                maxLength: maxLength,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(labelText: label),
                onChanged: (next) => value = next,
                validator: (next) => next == null || next.trim().isEmpty
                    ? 'Write a response.'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(dialogContext, value.trim());
            }
          },
          child: Text(action),
        ),
      ],
    ),
  );
}

String ticketContextSummary(TicketContext context) => [
  'Screen: ${context.screen}',
  'Build: ${context.build}',
  'Device: ${context.device}',
  'Platform: ${context.platform}',
  'Captured: ${context.capturedAtUtc.toLocal()}',
  if (context.recentActions.isNotEmpty) ...[
    'Recent actions:',
    for (final action in context.recentActions) '• $action',
  ],
  if (context.refusalCode case final code?) 'Refusal code: $code',
].join('\n');

String _shortId(String value) =>
    value.length <= 8 ? value : value.substring(0, 8);
