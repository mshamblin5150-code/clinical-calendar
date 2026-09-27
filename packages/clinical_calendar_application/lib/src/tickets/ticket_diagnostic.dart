import 'dart:collection';

import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import '../repositories.dart';

/// The only values that may cross the Ticket boundary as a diagnostic.
///
/// Domain objects are deliberately absent from this type. A snapshot is built
/// by copying approved structural scalars into this fixed key set.
final class TicketDiagnosticSnapshot {
  TicketDiagnosticSnapshot._(Map<String, Object> values)
    : values = UnmodifiableMapView(values);

  factory TicketDiagnosticSnapshot.fromJson(Map<String, dynamic> json) {
    final values = <String, Object>{};
    for (final entry in json.entries) {
      final value = entry.value;
      if (!allowedKeys.contains(entry.key) ||
          (value is! String && value is! int && value is! bool)) {
        throw const FormatException('Invalid Ticket diagnostic snapshot.');
      }
      values[entry.key] = value as Object;
    }
    if (!values.keys.toSet().containsAll(requiredKeys)) {
      throw const FormatException('Incomplete Ticket diagnostic snapshot.');
    }
    return TicketDiagnosticSnapshot._(values);
  }

  static const requiredKeys = {'snapshot_version', 'build', 'time_zone'};

  static const allowedKeys = {
    ...requiredKeys,
    'count.work_shifts',
    'count.clinical_sessions',
    'count.protected_days',
    'count.schedule_templates',
    'count.preceptors',
    'count.clinical_placements',
    'count.historical_hours_entries',
    'count.evaluation_plans',
    'count.work_schedule_feeds',
    'count.academic_assignments',
    'count.class_catalog_entries',
    'state.clinical_session.scheduled',
    'state.clinical_session.awaiting_confirmation',
    'state.clinical_session.completed',
    'state.clinical_session.cancelled',
    'state.clinical_session.missed',
    'state.clinical_placement.active',
    'state.clinical_placement.ready_to_complete',
    'state.clinical_placement.completed',
    'state.academic_assignment.pending',
    'state.academic_assignment.completed',
    'state.class_catalog_entry.active',
    'state.class_catalog_entry.archived',
    'state.work_schedule_feed.active',
    'state.work_schedule_feed.held',
    'number.work_shift_planned_minutes',
    'number.clinical_session_planned_minutes',
    'number.clinical_session_completed_minutes',
    'number.historical_completed_minutes',
    'number.clinical_placement_target_minutes',
    'setting.week_start',
    'setting.time_display',
    'setting.theme',
    'setting.enhanced_accessibility',
    'setting.synchronization',
    'setting.notification.upcoming_work_shifts',
    'setting.notification.upcoming_clinical_sessions',
    'setting.notification.weekly_summary',
    'setting.notification.backup_reminders',
    'setting.notification.work_shift_first_lead_minutes',
    'setting.notification.work_shift_second_lead_minutes',
    'setting.notification.clinical_session_first_lead_minutes',
    'setting.notification.clinical_session_second_lead_minutes',
    'setting.notification.confirmation_first_delay_minutes',
    'setting.notification.confirmation_repeat_days',
    'setting.notification.evaluation_approaching_hours',
    'setting.notification.evaluation_repeat_days',
    'setting.notification.protected_day_first_lead_days',
    'setting.notification.protected_day_second_lead_days',
    'setting.notification.weekly_summary_weekday',
    'setting.notification.weekly_summary_hour',
    'setting.notification.weekly_summary_minute',
    'setting.notification.no_backup_reminder_days',
    'setting.notification.stale_backup_reminder_days',
  };

  final Map<String, Object> values;

  List<String> get previewLines {
    final keys = values.keys.toList()..sort();
    return [for (final key in keys) '$key: ${values[key]}'];
  }
}

/// A memory-only input to [TicketDiagnosticBuilder]. Private domain values may
/// be present here; the builder reads only counts, enums, numbers, and settings.
final class TicketDiagnosticFacts {
  const TicketDiagnosticFacts({
    required this.build,
    required this.timeZone,
    required this.settings,
    this.workShifts = const [],
    this.clinicalSessions = const [],
    this.protectedDays = const [],
    this.scheduleTemplates = const [],
    this.preceptors = const [],
    this.clinicalPlacements = const [],
    this.historicalHoursEntries = const [],
    this.evaluationPlans = const [],
    this.workScheduleFeeds = const [],
    this.academicAssignments = const [],
    this.classCatalogEntries = const [],
  });

  final String build;
  final String timeZone;
  final StudentSettings settings;
  final List<WorkShift> workShifts;
  final List<ClinicalSession> clinicalSessions;
  final List<ProtectedDay> protectedDays;
  final List<ScheduleTemplate> scheduleTemplates;
  final List<Preceptor> preceptors;
  final List<ClinicalPlacement> clinicalPlacements;
  final List<HistoricalHoursEntry> historicalHoursEntries;
  final List<EvaluationPlan> evaluationPlans;
  final List<WorkScheduleFeed> workScheduleFeeds;
  final List<AcademicAssignment> academicAssignments;
  final List<ClassCatalogEntry> classCatalogEntries;
}

final class TicketDiagnosticBuilder {
  const TicketDiagnosticBuilder();

  TicketDiagnosticSnapshot build(TicketDiagnosticFacts facts) {
    final notifications = facts.settings.notifications;
    return TicketDiagnosticSnapshot.fromJson({
      'snapshot_version': 1,
      'build': facts.build,
      'time_zone': facts.timeZone,
      'count.work_shifts': facts.workShifts.length,
      'count.clinical_sessions': facts.clinicalSessions.length,
      'count.protected_days': facts.protectedDays.length,
      'count.schedule_templates': facts.scheduleTemplates.length,
      'count.preceptors': facts.preceptors.length,
      'count.clinical_placements': facts.clinicalPlacements.length,
      'count.historical_hours_entries': facts.historicalHoursEntries.length,
      'count.evaluation_plans': facts.evaluationPlans.length,
      'count.work_schedule_feeds': facts.workScheduleFeeds.length,
      'count.academic_assignments': facts.academicAssignments.length,
      'count.class_catalog_entries': facts.classCatalogEntries.length,
      for (final state in ClinicalSessionState.values)
        'state.clinical_session.${_snakeCase(state.name)}': facts
            .clinicalSessions
            .where((session) => session.state == state)
            .length,
      for (final state in ClinicalPlacementState.values)
        'state.clinical_placement.${_snakeCase(state.name)}': facts
            .clinicalPlacements
            .where((placement) => placement.state == state)
            .length,
      for (final state in AcademicAssignmentStatus.values)
        'state.academic_assignment.${_snakeCase(state.name)}': facts
            .academicAssignments
            .where((assignment) => assignment.status == state)
            .length,
      'state.class_catalog_entry.active': facts.classCatalogEntries
          .where((entry) => !entry.isArchived)
          .length,
      'state.class_catalog_entry.archived': facts.classCatalogEntries
          .where((entry) => entry.isArchived)
          .length,
      'state.work_schedule_feed.active': facts.workScheduleFeeds
          .where((feed) => feed.heldReason == null)
          .length,
      'state.work_schedule_feed.held': facts.workScheduleFeeds
          .where((feed) => feed.heldReason != null)
          .length,
      'number.work_shift_planned_minutes': facts.workShifts.fold<int>(
        0,
        (total, shift) => total + shift.plannedMinutes,
      ),
      'number.clinical_session_planned_minutes': facts.clinicalSessions
          .fold<int>(0, (total, session) => total + session.plannedMinutes),
      'number.clinical_session_completed_minutes': facts.clinicalSessions
          .fold<int>(0, (total, session) => total + session.completedMinutes),
      'number.historical_completed_minutes': facts.historicalHoursEntries
          .fold<int>(0, (total, entry) => total + entry.completedMinutes),
      'number.clinical_placement_target_minutes': facts.clinicalPlacements
          .fold<int>(
            0,
            (total, placement) => total + placement.targetHours.minutes,
          ),
      'setting.week_start': facts.settings.weekStart,
      'setting.time_display': facts.settings.timeDisplay.name,
      'setting.theme': facts.settings.themeId,
      'setting.enhanced_accessibility': facts.settings.enhancedAccessibility,
      'setting.synchronization': facts.settings.synchronization.name,
      'setting.notification.upcoming_work_shifts':
          notifications.upcomingWorkShiftsEnabled,
      'setting.notification.upcoming_clinical_sessions':
          notifications.upcomingClinicalSessionsEnabled,
      'setting.notification.weekly_summary': notifications.weeklySummaryEnabled,
      'setting.notification.backup_reminders':
          notifications.backupRemindersEnabled,
      'setting.notification.work_shift_first_lead_minutes':
          notifications.workShiftFirstLeadMinutes,
      'setting.notification.work_shift_second_lead_minutes':
          notifications.workShiftSecondLeadMinutes,
      'setting.notification.clinical_session_first_lead_minutes':
          notifications.clinicalSessionFirstLeadMinutes,
      'setting.notification.clinical_session_second_lead_minutes':
          notifications.clinicalSessionSecondLeadMinutes,
      'setting.notification.confirmation_first_delay_minutes':
          notifications.confirmationFirstDelayMinutes,
      'setting.notification.confirmation_repeat_days':
          notifications.confirmationRepeatDays,
      'setting.notification.evaluation_approaching_hours':
          notifications.evaluationApproachingHours,
      'setting.notification.evaluation_repeat_days':
          notifications.evaluationRepeatDays,
      'setting.notification.protected_day_first_lead_days':
          notifications.protectedDayFirstLeadDays,
      'setting.notification.protected_day_second_lead_days':
          notifications.protectedDaySecondLeadDays,
      'setting.notification.weekly_summary_weekday':
          notifications.weeklySummaryWeekday,
      'setting.notification.weekly_summary_hour':
          notifications.weeklySummaryHour,
      'setting.notification.weekly_summary_minute':
          notifications.weeklySummaryMinute,
      'setting.notification.no_backup_reminder_days':
          notifications.noBackupReminderDays,
      'setting.notification.stale_backup_reminder_days':
          notifications.staleBackupReminderDays,
    });
  }
}

String _snakeCase(String value) => value.replaceAllMapped(
  RegExp('[A-Z]'),
  (match) => '_${match.group(0)!.toLowerCase()}',
);
