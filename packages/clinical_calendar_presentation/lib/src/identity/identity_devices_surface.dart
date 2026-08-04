import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:flutter/material.dart';

final class IdentityDevicesSurface extends StatefulWidget {
  const IdentityDevicesSurface({
    required this.identity,
    required this.email,
    required this.onLocalCopyRemoved,
    super.key,
  });

  final PasswordlessIdentityService identity;
  final String email;
  final Future<void> Function() onLocalCopyRemoved;

  @override
  State<IdentityDevicesSurface> createState() => _IdentityDevicesSurfaceState();
}

final class _IdentityDevicesSurfaceState extends State<IdentityDevicesSurface> {
  late Future<List<ConnectedDevice>> _devices;

  @override
  void initState() {
    super.initState();
    _devices = widget.identity.connectedDevices();
  }

  void _reload() =>
      setState(() => _devices = widget.identity.connectedDevices());

  Future<void> _changeEmail() async {
    var replacementEmail = '';
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change email'),
        content: TextField(
          key: const Key('new-identity-email'),
          onChanged: (value) => replacementEmail = value,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'New email address'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('request-email-change'),
            onPressed: () => Navigator.pop(context, replacementEmail),
            child: const Text('Send verification'),
          ),
        ],
      ),
    );
    if (email == null || email.trim().isEmpty || !mounted) return;
    await widget.identity.requestEmailChange(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Verify the replacement address from the email before it changes.',
        ),
      ),
    );
  }

  Future<void> _revoke(ConnectedDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Revoke ${device.name}?'),
        content: const Text(
          'This blocks future server access from that device. It cannot erase '
          'a copy that is already stored offline on the device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-device-revocation'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke device'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.identity.revokeDevice(device.id);
    _reload();
  }

  Future<void> _removeLocalCopy() async {
    final preview = await widget.identity.previewLocalRemoval();
    if (!mounted) return;
    var confirmed = false;
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Sign Out and Remove This Device's Copy"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                preview.hasPendingChanges
                    ? '${preview.pendingChangeCount} pending change(s) have not reached the server and will be lost from this device.'
                    : 'There are no pending local changes.',
                key: const Key('pending-removal-report'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Only this device copy is removed. Your account and other '
                'connected devices remain intact.',
              ),
              CheckboxListTile(
                key: const Key('confirm-local-removal'),
                value: confirmed,
                onChanged: (value) =>
                    setDialogState(() => confirmed = value ?? false),
                title: const Text('I understand this removes this device copy'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('remove-local-copy'),
              onPressed: confirmed ? () => Navigator.pop(context, true) : null,
              child: const Text('Sign out and remove'),
            ),
          ],
        ),
      ),
    );
    if (remove != true) return;
    await widget.identity.signOutAndRemoveLocalCopy(confirmed: true);
    await widget.onLocalCopyRemoved();
  }

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('identity-devices-surface'),
    padding: const EdgeInsets.all(16),
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Identity', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(widget.email, key: const Key('signed-in-email')),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('change-email-action'),
                onPressed: _changeEmail,
                icon: const Icon(Icons.alternate_email),
                label: const Text('Change verified email'),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Connected Devices',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<ConnectedDevice>>(
                future: _devices,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'Connected devices are unavailable while offline.',
                    );
                  }
                  return Column(
                    children: [
                      for (final device in snapshot.data!)
                        ListTile(
                          key: Key('connected-device-${device.id}'),
                          leading: Icon(_icon(device.platform)),
                          title: Text(
                            '${device.name}${device.isCurrent ? ' (this device)' : ''}',
                          ),
                          subtitle: Text(
                            device.isRevoked
                                ? 'Revoked — offline copies are not remotely erased'
                                : 'Last sync: ${_lastSync(device.lastSynchronizedAtUtc)}',
                          ),
                          trailing: device.isCurrent || device.isRevoked
                              ? null
                              : OutlinedButton(
                                  onPressed: () => _revoke(device),
                                  child: const Text('Revoke'),
                                ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        key: const Key('sign-out-remove-local-action'),
        onPressed: _removeLocalCopy,
        icon: const Icon(Icons.phonelink_erase_outlined),
        label: const Text("Sign Out and Remove This Device's Copy"),
      ),
    ],
  );
}

IconData _icon(DevicePlatform platform) => switch (platform) {
  DevicePlatform.windows => Icons.laptop_windows,
  DevicePlatform.ios => Icons.phone_iphone,
  DevicePlatform.android => Icons.tablet_android,
};

String _lastSync(DateTime? value) =>
    value == null ? 'Never' : value.toLocal().toString();
