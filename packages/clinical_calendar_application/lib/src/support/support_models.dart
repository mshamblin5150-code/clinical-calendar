import 'dart:collection';

import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

enum TimeDisplayPreference { military, twelveHour }

enum SynchronizationPreference { enabled, paused }

final class NotificationPreferences {
  const NotificationPreferences({
    this.upcomingCommitmentsEnabled = true,
    this.weeklySummaryEnabled = true,
    this.backupRemindersEnabled = true,
  });

  factory NotificationPreferences.fromJson(Map<String, Object?> json) =>
      NotificationPreferences(
        upcomingCommitmentsEnabled:
            json['upcomingCommitmentsEnabled'] as bool? ?? true,
        weeklySummaryEnabled: json['weeklySummaryEnabled'] as bool? ?? true,
        backupRemindersEnabled: json['backupRemindersEnabled'] as bool? ?? true,
      );

  final bool upcomingCommitmentsEnabled;
  final bool weeklySummaryEnabled;
  final bool backupRemindersEnabled;

  Map<String, Object?> toJson() => {
    'upcomingCommitmentsEnabled': upcomingCommitmentsEnabled,
    'weeklySummaryEnabled': weeklySummaryEnabled,
    'backupRemindersEnabled': backupRemindersEnabled,
  };
}

final class StudentSettings {
  StudentSettings({
    this.weekStart = DateTime.sunday,
    this.timeDisplay = TimeDisplayPreference.military,
    String themeId = variantFThemeId,
    this.synchronization = SynchronizationPreference.enabled,
    this.notifications = const NotificationPreferences(),
  }) : themeId = _requiredText(themeId, 'Theme', 80) {
    if (weekStart < DateTime.monday || weekStart > DateTime.sunday) {
      throw ArgumentError.value(weekStart, 'weekStart', 'must be from 1 to 7');
    }
  }

  static const variantFThemeId = 'variant-f';

  final int weekStart;
  final TimeDisplayPreference timeDisplay;
  final String themeId;
  final SynchronizationPreference synchronization;
  final NotificationPreferences notifications;
}

final class StudentProfile {
  StudentProfile({
    required String id,
    required String displayName,
    String? program,
    String? accountIdentity,
    List<int>? avatarBytes,
  }) : id = requireIdentifier(id, 'Student Profile id'),
       displayName = _requiredText(displayName, 'Display name', 160),
       program = _optionalText(program, 'Program', 200),
       accountIdentity = _optionalText(
         accountIdentity,
         'Account identity',
         320,
       ),
       avatarBytes = _copyAvatar(avatarBytes);

  static const maximumAvatarBytes = 5 * 1024 * 1024;

  final String id;
  final String displayName;
  final String? program;
  final String? accountIdentity;
  final List<int>? avatarBytes;

  String get initials {
    final parts = displayName.split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }

  bool get hasAvatar => avatarBytes != null;
}

final class SupportSnapshot {
  const SupportSnapshot({
    required this.profile,
    required this.settings,
    required this.scheduleTemplates,
  });

  final StoredSupportRecord<StudentProfile> profile;
  final StoredSupportRecord<StudentSettings> settings;
  final List<StoredSupportRecord<ScheduleTemplate>> scheduleTemplates;
}

/// Application-facing metadata without coupling support models to repositories.
final class StoredSupportRecord<T> {
  const StoredSupportRecord({required this.value, required this.revision});

  final T value;
  final int revision;
}

String _requiredText(String value, String fieldName, int maximumLength) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.length > maximumLength) {
    throw ArgumentError.value(
      value,
      fieldName,
      'must contain between 1 and $maximumLength characters',
    );
  }
  return normalized;
}

String? _optionalText(String? value, String fieldName, int maximumLength) {
  if (value == null || value.trim().isEmpty) return null;
  return _requiredText(value, fieldName, maximumLength);
}

List<int>? _copyAvatar(List<int>? value) {
  if (value == null) return null;
  if (value.isEmpty || value.length > StudentProfile.maximumAvatarBytes) {
    throw ArgumentError.value(
      value.length,
      'avatarBytes',
      'must contain between 1 and ${StudentProfile.maximumAvatarBytes} bytes',
    );
  }
  for (final byte in value) {
    if (byte < 0 || byte > 255) {
      throw ArgumentError.value(byte, 'avatarBytes', 'must contain bytes');
    }
  }
  return UnmodifiableListView<int>(List<int>.of(value));
}
