import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../enhanced_accessibility_controller.dart';
import '../responsive_shell.dart';

enum TicketMenuAction { putInTicket, tickets }

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
    super.key,
  });

  final TicketGateway gateway;
  final TicketContext attachedContext;

  @override
  State<PutInTicketSurface> createState() => _PutInTicketSurfaceState();
}

final class _PutInTicketSurfaceState extends State<PutInTicketSurface> {
  final _formKey = GlobalKey<FormState>();
  final _text = TextEditingController();
  TicketKind? _kind;
  bool _sending = false;
  String? _message;

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

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final ticket = widget.maintainer
          ? await widget.gateway.openForMaintainer(widget.initialTicket.id)
          : widget.initialTicket;
      if (mounted) setState(() => _ticket = ticket);
    } catch (error) {
      if (mounted) setState(() => _error = error);
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
                if (widget.maintainer)
                  Text('Student ${_shortId(_ticket!.senderId)}'),
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
              ],
            ),
          ),
  );
}

String ticketContextSummary(TicketContext context) => [
  'Screen: ${context.screen}',
  'Build: ${context.build}',
  'Device: ${context.device}',
  'Platform: ${context.platform}',
  'Captured: ${context.capturedAtUtc.toLocal()}',
].join('\n');

String _shortId(String value) =>
    value.length <= 8 ? value : value.substring(0, 8);
