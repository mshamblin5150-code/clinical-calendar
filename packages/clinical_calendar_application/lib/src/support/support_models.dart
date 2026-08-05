import 'dart:collection';

import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

enum TimeDisplayPreference { military, twelveHour }

enum SynchronizationPreference { enabled, paused }

final class NotificationPreferences {
  const NotificationPreferences({
    bool upcomingCommitmentsEnabled = true,
    bool? upcomingWorkShiftsEnabled,
    bool? upcomingClinicalSessionsEnabled,
    this.weeklySummaryEnabled = true,
    this.backupRemindersEnabled = true,
    this.workShiftFirstLeadMinutes = 1440,
    this.workShiftSecondLeadMinutes = 120,
    this.clinicalSessionFirstLeadMinutes = 1440,
    this.clinicalSessionSecondLeadMinutes = 120,
    this.confirmationFirstDelayMinutes = 30,
    this.confirmationRepeatDays = 3,
    this.evaluationApproachingHours = 10,
    this.evaluationRepeatDays = 3,
    this.protectedDayFirstLeadDays = 3,
    this.protectedDaySecondLeadDays = 1,
    this.weeklySummaryWeekday = DateTime.sunday,
    this.weeklySummaryHour = 18,
    this.weeklySummaryMinute = 0,
    this.noBackupReminderDays = 7,
    this.staleBackupReminderDays = 30,
  }) : assert(weeklySummaryHour >= 0 && weeklySummaryHour <= 23),
       assert(weeklySummaryMinute >= 0 && weeklySummaryMinute <= 59),
       upcomingWorkShiftsEnabled =
           upcomingWorkShiftsEnabled ?? upcomingCommitmentsEnabled,
       upcomingClinicalSessionsEnabled =
           upcomingClinicalSessionsEnabled ?? upcomingCommitmentsEnabled;

  factory NotificationPreferences.fromJson(
    Map<String, Object?> json,
  ) => NotificationPreferences(
    upcomingCommitmentsEnabled:
        json['upcomingCommitmentsEnabled'] as bool? ?? true,
    upcomingWorkShiftsEnabled: json['upcomingWorkShiftsEnabled'] as bool?,
    upcomingClinicalSessionsEnabled:
        json['upcomingClinicalSessionsEnabled'] as bool?,
    weeklySummaryEnabled: json['weeklySummaryEnabled'] as bool? ?? true,
    backupRemindersEnabled: json['backupRemindersEnabled'] as bool? ?? true,
    workShiftFirstLeadMinutes:
        json['workShiftFirstLeadMinutes'] as int? ?? 1440,
    workShiftSecondLeadMinutes:
        json['workShiftSecondLeadMinutes'] as int? ?? 120,
    clinicalSessionFirstLeadMinutes:
        json['clinicalSessionFirstLeadMinutes'] as int? ?? 1440,
    clinicalSessionSecondLeadMinutes:
        json['clinicalSessionSecondLeadMinutes'] as int? ?? 120,
    confirmationFirstDelayMinutes:
        json['confirmationFirstDelayMinutes'] as int? ?? 30,
    confirmationRepeatDays: json['confirmationRepeatDays'] as int? ?? 3,
    evaluationApproachingHours:
        json['evaluationApproachingHours'] as int? ?? 10,
    evaluationRepeatDays: json['evaluationRepeatDays'] as int? ?? 3,
    protectedDayFirstLeadDays: json['protectedDayFirstLeadDays'] as int? ?? 3,
    protectedDaySecondLeadDays: json['protectedDaySecondLeadDays'] as int? ?? 1,
    weeklySummaryWeekday:
        json['weeklySummaryWeekday'] as int? ?? DateTime.sunday,
    weeklySummaryHour: json['weeklySummaryHour'] as int? ?? 18,
    weeklySummaryMinute: json['weeklySummaryMinute'] as int? ?? 0,
    noBackupReminderDays: json['noBackupReminderDays'] as int? ?? 7,
    staleBackupReminderDays: json['staleBackupReminderDays'] as int? ?? 30,
  );

  final bool upcomingWorkShiftsEnabled;
  final bool upcomingClinicalSessionsEnabled;
  final bool weeklySummaryEnabled;
  final bool backupRemindersEnabled;
  final int workShiftFirstLeadMinutes;
  final int workShiftSecondLeadMinutes;
  final int clinicalSessionFirstLeadMinutes;
  final int clinicalSessionSecondLeadMinutes;
  final int confirmationFirstDelayMinutes;
  final int confirmationRepeatDays;
  final int evaluationApproachingHours;
  final int evaluationRepeatDays;
  final int protectedDayFirstLeadDays;
  final int protectedDaySecondLeadDays;
  final int weeklySummaryWeekday;
  final int weeklySummaryHour;
  final int weeklySummaryMinute;
  final int noBackupReminderDays;
  final int staleBackupReminderDays;

  bool get upcomingCommitmentsEnabled =>
      upcomingWorkShiftsEnabled && upcomingClinicalSessionsEnabled;

  NotificationPreferences copyWith({
    bool? upcomingWorkShiftsEnabled,
    bool? upcomingClinicalSessionsEnabled,
    bool? weeklySummaryEnabled,
    bool? backupRemindersEnabled,
    int? workShiftFirstLeadMinutes,
    int? workShiftSecondLeadMinutes,
    int? clinicalSessionFirstLeadMinutes,
    int? clinicalSessionSecondLeadMinutes,
    int? confirmationFirstDelayMinutes,
    int? confirmationRepeatDays,
    int? evaluationApproachingHours,
    int? evaluationRepeatDays,
    int? protectedDayFirstLeadDays,
    int? protectedDaySecondLeadDays,
    int? weeklySummaryWeekday,
    int? weeklySummaryHour,
    int? weeklySummaryMinute,
    int? noBackupReminderDays,
    int? staleBackupReminderDays,
  }) => NotificationPreferences(
    upcomingWorkShiftsEnabled:
        upcomingWorkShiftsEnabled ?? this.upcomingWorkShiftsEnabled,
    upcomingClinicalSessionsEnabled:
        upcomingClinicalSessionsEnabled ?? this.upcomingClinicalSessionsEnabled,
    weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
    backupRemindersEnabled:
        backupRemindersEnabled ?? this.backupRemindersEnabled,
    workShiftFirstLeadMinutes:
        workShiftFirstLeadMinutes ?? this.workShiftFirstLeadMinutes,
    workShiftSecondLeadMinutes:
        workShiftSecondLeadMinutes ?? this.workShiftSecondLeadMinutes,
    clinicalSessionFirstLeadMinutes:
        clinicalSessionFirstLeadMinutes ?? this.clinicalSessionFirstLeadMinutes,
    clinicalSessionSecondLeadMinutes:
        clinicalSessionSecondLeadMinutes ??
        this.clinicalSessionSecondLeadMinutes,
    confirmationFirstDelayMinutes:
        confirmationFirstDelayMinutes ?? this.confirmationFirstDelayMinutes,
    confirmationRepeatDays:
        confirmationRepeatDays ?? this.confirmationRepeatDays,
    evaluationApproachingHours:
        evaluationApproachingHours ?? this.evaluationApproachingHours,
    evaluationRepeatDays: evaluationRepeatDays ?? this.evaluationRepeatDays,
    protectedDayFirstLeadDays:
        protectedDayFirstLeadDays ?? this.protectedDayFirstLeadDays,
    protectedDaySecondLeadDays:
        protectedDaySecondLeadDays ?? this.protectedDaySecondLeadDays,
    weeklySummaryWeekday: weeklySummaryWeekday ?? this.weeklySummaryWeekday,
    weeklySummaryHour: weeklySummaryHour ?? this.weeklySummaryHour,
    weeklySummaryMinute: weeklySummaryMinute ?? this.weeklySummaryMinute,
    noBackupReminderDays: noBackupReminderDays ?? this.noBackupReminderDays,
    staleBackupReminderDays:
        staleBackupReminderDays ?? this.staleBackupReminderDays,
  );

  Map<String, Object?> toJson() => {
    'upcomingCommitmentsEnabled': upcomingCommitmentsEnabled,
    'upcomingWorkShiftsEnabled': upcomingWorkShiftsEnabled,
    'upcomingClinicalSessionsEnabled': upcomingClinicalSessionsEnabled,
    'weeklySummaryEnabled': weeklySummaryEnabled,
    'backupRemindersEnabled': backupRemindersEnabled,
    'workShiftFirstLeadMinutes': workShiftFirstLeadMinutes,
    'workShiftSecondLeadMinutes': workShiftSecondLeadMinutes,
    'clinicalSessionFirstLeadMinutes': clinicalSessionFirstLeadMinutes,
    'clinicalSessionSecondLeadMinutes': clinicalSessionSecondLeadMinutes,
    'confirmationFirstDelayMinutes': confirmationFirstDelayMinutes,
    'confirmationRepeatDays': confirmationRepeatDays,
    'evaluationApproachingHours': evaluationApproachingHours,
    'evaluationRepeatDays': evaluationRepeatDays,
    'protectedDayFirstLeadDays': protectedDayFirstLeadDays,
    'protectedDaySecondLeadDays': protectedDaySecondLeadDays,
    'weeklySummaryWeekday': weeklySummaryWeekday,
    'weeklySummaryHour': weeklySummaryHour,
    'weeklySummaryMinute': weeklySummaryMinute,
    'noBackupReminderDays': noBackupReminderDays,
    'staleBackupReminderDays': staleBackupReminderDays,
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
