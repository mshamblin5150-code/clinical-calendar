import 'dart:typed_data';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:flutter/material.dart';

final class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({
    required this.profile,
    required this.onPressed,
    this.tooltip = 'Student Profile',
    super.key,
  });

  final StudentProfile profile;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$tooltip, ${profile.displayName}',
    child: Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 44,
        child: IconButton(
          key: const Key('student-profile-avatar-action'),
          padding: const EdgeInsets.all(2),
          onPressed: onPressed,
          icon: CircleAvatar(
            radius: 20,
            foregroundImage: profile.avatarBytes == null
                ? null
                : MemoryImage(Uint8List.fromList(profile.avatarBytes!)),
            child: profile.avatarBytes == null ? Text(profile.initials) : null,
          ),
        ),
      ),
    ),
  );
}
