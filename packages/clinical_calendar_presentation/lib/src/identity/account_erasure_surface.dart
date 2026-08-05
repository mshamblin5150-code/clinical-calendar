import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:flutter/material.dart';

import '../date_input.dart';

typedef AccountBackupCreator = Future<bool> Function(String passphrase);

final class AccountErasureSurface extends StatefulWidget {
  const AccountErasureSurface({
    required this.identity,
    required this.email,
    required this.onClose,
    this.createBackup,
    this.pendingRequest,
    this.onErasureRequested,
    this.onErasureCancelled,
    super.key,
  });

  final PasswordlessIdentityService identity;
  final String email;
  final VoidCallback onClose;
  final AccountBackupCreator? createBackup;
  final AccountErasureRequest? pendingRequest;
  final ValueChanged<AccountErasureRequest>? onErasureRequested;
  final VoidCallback? onErasureCancelled;

  @override
  State<AccountErasureSurface> createState() => _AccountErasureSurfaceState();
}

enum _ErasureStep { overview, reauthenticate, pending, cancelled }

final class _AccountErasureSurfaceState extends State<AccountErasureSurface> {
  late _ErasureStep _step;
  AccountErasureBackupChoice? _backupChoice;
  AccountErasureRequest? _request;
  var _codeSent = false;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _request = widget.pendingRequest;
    _step = widget.pendingRequest == null
        ? _ErasureStep.overview
        : _ErasureStep.pending;
  }

  Future<void> _chooseBackup() async {
    final choice = await showDialog<AccountErasureBackupChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Before deleting your account'),
        content: const Text(
          'A portable backup is the only copy you control after the grace '
          'period ends. Choose whether to create one before continuing.',
        ),
        actions: [
          TextButton(
            key: const Key('cancel-account-erasure'),
            onPressed: () =>
                Navigator.pop(context, AccountErasureBackupChoice.cancelled),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            key: const Key('continue-without-account-backup'),
            onPressed: () =>
                Navigator.pop(context, AccountErasureBackupChoice.skipped),
            child: const Text('Continue without backup'),
          ),
          FilledButton(
            key: const Key('create-account-backup-first'),
            onPressed: () =>
                Navigator.pop(context, AccountErasureBackupChoice.completed),
            child: const Text('Create Backup First'),
          ),
        ],
      ),
    );
    if (choice == null || choice == AccountErasureBackupChoice.cancelled) {
      return;
    }
    if (choice == AccountErasureBackupChoice.completed) {
      final creator = widget.createBackup;
      if (creator == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Encrypted backup is unavailable. Account deletion was not requested.',
            ),
          ),
        );
        return;
      }
      var passphrase = await _collectBackupPassphrase();
      if (passphrase == null || !mounted) return;
      setState(() => _busy = true);
      bool created;
      try {
        created = await creator(passphrase);
      } on Object {
        created = false;
      } finally {
        // The passphrase is kept only in this short-lived local variable and
        // is never copied into widget state, storage, logs, or status text.
        passphrase = '';
      }
      if (!mounted) return;
      setState(() => _busy = false);
      if (!created) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The backup was not created. Account deletion was not requested.',
            ),
          ),
        );
        return;
      }
    }
    setState(() {
      _backupChoice = choice;
      _step = _ErasureStep.reauthenticate;
      _codeSent = false;
      _error = null;
    });
  }

  Future<String?> _collectBackupPassphrase() async {
    var passphrase = '';
    var confirmation = '';
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final valid = passphrase.length >= 12 && passphrase == confirmation;
          return AlertDialog(
            title: const Text('Create encrypted backup'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('erasure-backup-passphrase'),
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Backup passphrase',
                    helperText:
                        'Use at least 12 characters. It cannot be recovered.',
                  ),
                  onChanged: (value) =>
                      setDialogState(() => passphrase = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('erasure-backup-confirmation'),
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Confirm passphrase',
                  ),
                  onChanged: (value) =>
                      setDialogState(() => confirmation = value),
                ),
              ],
            ),
            actions: [
              TextButton(
                key: const Key('cancel-erasure-backup-passphrase'),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const Key('confirm-erasure-backup-passphrase'),
                onPressed: valid
                    ? () => Navigator.pop(context, passphrase)
                    : null,
                child: const Text('Create encrypted backup'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.identity.sendSignInCode(widget.email);
      if (mounted) setState(() => _codeSent = true);
    } on IdentityException catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestErasure(String code) async {
    final backup = _backupChoice;
    if (backup == null || backup == AccountErasureBackupChoice.cancelled) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final request = await widget.identity.requestAccountErasure(
        email: widget.email,
        code: code,
        backupChoice: backup,
      );
      if (!mounted) return;
      if (request.status != AccountErasureRequestStatus.pending ||
          request.purgeAfterUtc == null) {
        setState(() => _error = 'Account deletion was not requested.');
        return;
      }
      setState(() {
        _request = request;
        _step = _ErasureStep.pending;
        _codeSent = false;
      });
      widget.onErasureRequested?.call(request);
    } on IdentityException catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelErasure(String code) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final status = await widget.identity.cancelAccountErasure(
        email: widget.email,
        code: code,
      );
      if (!mounted) return;
      switch (status) {
        case AccountErasureCancellationStatus.cancelled:
          setState(() {
            _step = _ErasureStep.cancelled;
            _request = null;
            _codeSent = false;
          });
          widget.onErasureCancelled?.call();
        case AccountErasureCancellationStatus.notPending:
          setState(() => _error = 'No pending account deletion was found.');
        case AccountErasureCancellationStatus.graceExpired:
          setState(
            () => _error =
                'The 30-day grace period has ended. Deletion can no longer be cancelled.',
          );
      }
    } on IdentityException catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('account-erasure-surface'),
    padding: const EdgeInsets.all(16),
    children: [
      Row(
        children: [
          IconButton(
            key: const Key('close-account-erasure'),
            onPressed: _busy ? null : widget.onClose,
            tooltip: 'Back to Connected Devices',
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Delete Account and All Data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      switch (_step) {
        _ErasureStep.overview => _overview(context),
        _ErasureStep.reauthenticate => _reauthentication(
          context,
          cancelling: false,
        ),
        _ErasureStep.pending => _pending(context),
        _ErasureStep.cancelled => _cancelled(context),
      },
    ],
  );

  Widget _overview(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This is not Sign Out',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign Out removes only this device copy. Delete Account and All '
            'Data starts deletion for the account, synchronized calendar, '
            'Trash, and every Connected Device.',
          ),
          const SizedBox(height: 12),
          const Text(
            'A fresh emailed code is required. The request then enters a '
            '30-day grace period. During grace, all Connected Devices are '
            'revoked and you may cancel with another fresh code.',
          ),
          const SizedBox(height: 12),
          const Text(
            'At the purge date, active data, Trash, device registrations, and '
            'authentication records are deleted. Residual encrypted '
            'operational snapshots expire within 30 additional days.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('begin-account-erasure'),
            onPressed: _busy ? null : _chooseBackup,
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Begin guarded deletion'),
          ),
        ],
      ),
    ),
  );

  Widget _reauthentication(
    BuildContext context, {
    required bool cancelling,
  }) => _FreshCodeCard(
    email: widget.email,
    busy: _busy,
    codeSent: _codeSent,
    error: _error,
    title: cancelling ? 'Cancel pending deletion' : 'Confirm account deletion',
    explanation: cancelling
        ? 'Request a fresh code to cancel before the purge date.'
        : 'Request a fresh code. Stored or refreshed credentials are not enough.',
    sendKey: cancelling
        ? const Key('send-cancel-erasure-code')
        : const Key('send-erasure-code'),
    submitKey: cancelling
        ? const Key('confirm-cancel-erasure')
        : const Key('confirm-account-erasure'),
    submitLabel: cancelling ? 'Cancel deletion' : 'Request deletion',
    onSend: _sendCode,
    onSubmit: cancelling ? _cancelErasure : _requestErasure,
  );

  Widget _pending(BuildContext context) {
    final purge = _request?.purgeAfterUtc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Deletion pending',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  purge == null
                      ? 'The purge date is unavailable.'
                      : 'Purge date: ${_date(purge)}',
                  key: const Key('account-erasure-purge-date'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Every Connected Device is revoked during the 30-day grace '
                  'period. Offline copies cannot be remotely erased.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _reauthentication(context, cancelling: true),
      ],
    );
  }

  Widget _cancelled(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Account deletion cancelled',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'The pending purge was cancelled after fresh verification. This '
            'device may synchronize again.',
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: widget.onClose, child: const Text('Done')),
        ],
      ),
    ),
  );
}

final class _FreshCodeCard extends StatefulWidget {
  const _FreshCodeCard({
    required this.email,
    required this.busy,
    required this.codeSent,
    required this.error,
    required this.title,
    required this.explanation,
    required this.sendKey,
    required this.submitKey,
    required this.submitLabel,
    required this.onSend,
    required this.onSubmit,
  });

  final String email;
  final bool busy;
  final bool codeSent;
  final String? error;
  final String title;
  final String explanation;
  final Key sendKey;
  final Key submitKey;
  final String submitLabel;
  final Future<void> Function() onSend;
  final Future<void> Function(String code) onSubmit;

  @override
  State<_FreshCodeCard> createState() => _FreshCodeCardState();
}

final class _FreshCodeCardState extends State<_FreshCodeCard> {
  var _code = '';

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(widget.explanation),
          const SizedBox(height: 8),
          Text(widget.email),
          const SizedBox(height: 12),
          if (!widget.codeSent)
            FilledButton(
              key: widget.sendKey,
              onPressed: widget.busy ? null : widget.onSend,
              child: Text(widget.busy ? 'Please wait…' : 'Email a fresh code'),
            )
          else ...[
            TextField(
              key: const Key('account-erasure-otp'),
              onChanged: (value) => _code = value,
              enabled: !widget.busy,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 8,
              decoration: const InputDecoration(labelText: 'One-time code'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: widget.submitKey,
              onPressed: widget.busy ? null : () => widget.onSubmit(_code),
              child: Text(widget.busy ? 'Please wait…' : widget.submitLabel),
            ),
          ],
          if (widget.error case final error?) ...[
            const SizedBox(height: 8),
            Text(
              error,
              key: const Key('account-erasure-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
  );
}

String _date(DateTime value) => formatUsDateFromDateTime(value);

String _message(IdentityException error) => switch (error.code) {
  'expired_otp' => 'That code expired. Request a new code and try again.',
  'invalid_otp' => 'Enter the numeric code from the email.',
  'rate_limited' => 'Too many requests. Wait before trying again.',
  _ when error.offline => 'A connection is required for account deletion.',
  _ => 'The request could not be completed. Try again.',
};
