import 'dart:typed_data';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:flutter/material.dart';

import '../responsive_shell.dart';
import '../variant_f_theme.dart';

typedef AvatarChooser = Future<List<int>?> Function();

final class StudentProfileSurface extends StatefulWidget {
  const StudentProfileSurface({
    required this.profile,
    required this.onSave,
    required this.chooseAvatar,
    super.key,
  });

  final StudentProfile profile;
  final Future<void> Function(StudentProfile profile) onSave;
  final AvatarChooser chooseAvatar;

  @override
  State<StudentProfileSurface> createState() => _StudentProfileSurfaceState();
}

final class _StudentProfileSurfaceState extends State<StudentProfileSurface> {
  late final TextEditingController _displayName;
  late final TextEditingController _program;
  late final TextEditingController _accountIdentity;
  List<int>? _avatarBytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(text: widget.profile.displayName)
      ..addListener(_refresh);
    _program = TextEditingController(text: widget.profile.program);
    _accountIdentity = TextEditingController(
      text: widget.profile.accountIdentity,
    );
    _avatarBytes = widget.profile.avatarBytes;
  }

  @override
  void dispose() {
    _displayName
      ..removeListener(_refresh)
      ..dispose();
    _program.dispose();
    _accountIdentity.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  StudentProfile? get _preview {
    try {
      return StudentProfile(
        id: widget.profile.id,
        displayName: _displayName.text,
        program: _program.text,
        accountIdentity: _accountIdentity.text,
        avatarBytes: _avatarBytes,
      );
    } on ArgumentError {
      return null;
    }
  }

  Future<void> _chooseAvatar() async {
    final bytes = await widget.chooseAvatar();
    if (!mounted || bytes == null) return;
    setState(() => _avatarBytes = List<int>.of(bytes));
  }

  Future<void> _save() async {
    final profile = _preview;
    if (profile == null || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(profile);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return ListView(
      key: const Key('student-profile-surface'),
      padding: const EdgeInsets.all(16),
      children: [
        ShellPanel(
          label: 'Student Profile',
          accent: context.clinicalColors.clinical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    key: const Key('profile-avatar-preview'),
                    radius: 34,
                    foregroundImage: _avatarBytes == null
                        ? null
                        : MemoryImage(Uint8List.fromList(_avatarBytes!)),
                    child: _avatarBytes == null
                        ? Text(preview?.initials ?? '?')
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _avatarBytes == null
                              ? 'Initials avatar'
                              : 'Profile image selected',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _avatarBytes == null
                              ? 'Initials update automatically from the first two name parts.'
                              : 'This image replaces initials in both headers.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('choose-avatar-action'),
                    onPressed: _chooseAvatar,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      _avatarBytes == null ? 'Choose image' : 'Replace image',
                    ),
                  ),
                  if (_avatarBytes != null)
                    OutlinedButton.icon(
                      key: const Key('remove-avatar-action'),
                      onPressed: () => setState(() => _avatarBytes = null),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove image'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('profile-display-name'),
                controller: _displayName,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                key: const Key('profile-initials'),
                decoration: const InputDecoration(
                  labelText: 'Initials (automatic)',
                ),
                child: Text(preview?.initials ?? ''),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('profile-program'),
                controller: _program,
                decoration: const InputDecoration(labelText: 'Program'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('profile-account-identity'),
                controller: _accountIdentity,
                decoration: const InputDecoration(
                  labelText: 'Account identity',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('save-profile-action'),
                onPressed: preview == null || _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Savingâ€¦' : 'Save profile'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
