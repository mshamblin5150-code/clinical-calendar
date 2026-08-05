import 'package:flutter/material.dart';

typedef StudentProfileOnboardingSave =
    Future<void> Function(String firstName, String lastName);

final class StudentProfileOnboardingDialog extends StatefulWidget {
  const StudentProfileOnboardingDialog({
    required this.email,
    required this.onSave,
    super.key,
  });

  final String email;
  final StudentProfileOnboardingSave onSave;

  @override
  State<StudentProfileOnboardingDialog> createState() =>
      _StudentProfileOnboardingDialogState();
}

final class _StudentProfileOnboardingDialogState
    extends State<StudentProfileOnboardingDialog> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _firstName.addListener(_refresh);
    _lastName.addListener(_refresh);
  }

  @override
  void dispose() {
    _firstName
      ..removeListener(_refresh)
      ..dispose();
    _lastName
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _error = null);

  String get _normalizedFirstName => _normalizeName(_firstName.text);
  String get _normalizedLastName => _normalizeName(_lastName.text);

  bool get _canSave =>
      !_saving &&
      _normalizedFirstName.isNotEmpty &&
      _normalizedLastName.isNotEmpty &&
      _normalizedFirstName.length <= 80 &&
      _normalizedLastName.length <= 80;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_normalizedFirstName, _normalizedLastName);
      if (mounted) Navigator.of(context).pop();
    } on Object {
      if (mounted) {
        setState(() => _error = 'Profile could not be saved. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const Key('student-profile-onboarding'),
    title: const Text('Finish your profile'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your name is used in required profile and export fields. '
              'Your sign-in email is filled automatically.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('onboarding-first-name'),
              controller: _firstName,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.givenName],
              decoration: const InputDecoration(labelText: 'First name'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('onboarding-last-name'),
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.familyName],
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('onboarding-email'),
              initialValue: widget.email,
              readOnly: true,
              enableInteractiveSelection: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                helperText: 'From your signed-in account',
              ),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 12),
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      FilledButton(
        key: const Key('save-onboarding-profile'),
        onPressed: _canSave ? _save : null,
        child: Text(_saving ? 'Saving…' : 'Continue'),
      ),
    ],
  );
}

String _normalizeName(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ');
