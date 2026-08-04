import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import '../placements/placement_application_service.dart';
import '../repositories.dart';
import 'production_notification_service.dart';
import 'reminder_policy.dart';

final class ReminderWorkflowRoutes {
  const ReminderWorkflowRoutes._();

  static const summary = '/reminders/summary';
  static const backup = '/reminders/backup';
  static const synchronization = '/reminders/synchronization';
  static String commitment(String kind, String id) =>
      '/reminders/commitment/$kind/$id';
  static String planning(LocalDate weekStart) =>
      '/reminders/planning/$weekStart';
  static String evaluation(String placementId) =>
      '/reminders/evaluation/$placementId';
}

/// Derives reminder candidates from the same repository and placement read
/// models used by the visible application surfaces.
final class RepositoryReminderCandidateSource
    implements ReminderCandidateSource {
  RepositoryReminderCandidateSource({
    required this.repositories,
    required this.placements,
    required this.studentId,
    required this.deviceTimeZoneId,
    required ReminderTimeZoneResolver timeZones,
    this.deviceId = 'local-device',
  }) : _timeZones = timeZones,
       _schedules = DefaultReminderSchedules(timeZones);

  final RepositoryRegistry repositories;
  final PlacementApplicationService placements;
  final String studentId;
  final String deviceTimeZoneId;
  final String deviceId;
  final ReminderTimeZoneResolver _timeZones;
  final DefaultReminderSchedules _schedules;

  @override
  Future<ReminderCandidatePlan> load(DateTime nowUtc) async {
    final now = nowUtc.toUtc();
    final facts = await repositories.read((values) => _facts(values, now));
    final candidates = <ReminderCandidate>[];
    final preferences = facts.settings.notifications;

    for (final shift in facts.workShifts) {
      final interval = shift.plannedInterval;
      if (!interval.startInstantUtc.isAfter(now)) continue;
      candidates.addAll(
        _schedules.upcoming(
          kind: ReminderKind.upcomingWorkShift,
          subjectId: shift.id,
          startsAtUtc: interval.startInstantUtc,
          commitmentTimeZoneId: interval.timeZone.value,
          route: ReminderWorkflowRoutes.commitment('work', shift.id),
          detailedBody: 'Work shift starts at ${interval.startTime}.',
          first: Duration(minutes: preferences.workShiftFirstLeadMinutes),
          second: Duration(minutes: preferences.workShiftSecondLeadMinutes),
          enabled: preferences.upcomingWorkShiftsEnabled,
        ),
      );
    }

    for (final original in facts.clinicalSessions) {
      final session = original.refreshStatus(now);
      final interval = session.plannedInterval;
      final route = ReminderWorkflowRoutes.commitment('clinical', session.id);
      if (session.state == ClinicalSessionState.scheduled) {
        candidates.addAll(
          _schedules.upcoming(
            kind: ReminderKind.upcomingClinicalSession,
            subjectId: session.id,
            startsAtUtc: interval.startInstantUtc,
            commitmentTimeZoneId: interval.timeZone.value,
            route: route,
            detailedBody: 'Clinical session starts at ${interval.startTime}.',
            first: Duration(
              minutes: preferences.clinicalSessionFirstLeadMinutes,
            ),
            second: Duration(
              minutes: preferences.clinicalSessionSecondLeadMinutes,
            ),
            enabled: preferences.upcomingClinicalSessionsEnabled,
          ),
        );
      } else if (session.state == ClinicalSessionState.awaitingConfirmation) {
        candidates.addAll(
          _schedules.clinicalConfirmation(
            subjectId: session.id,
            endsAtUtc: interval.endInstantUtc,
            nextMorningNineUtc: _nextLocalHour(now, 9),
            throughUtc: now.add(const Duration(days: 31)),
            route: route,
            firstDelay: Duration(
              minutes: preferences.confirmationFirstDelayMinutes,
            ),
            repeatEvery: Duration(days: preferences.confirmationRepeatDays),
          ),
        );
      }
    }

    final localNow = _timeZones.toLocal(now, deviceTimeZoneId);
    final today = LocalDate(localNow.year, localNow.month, localNow.day);
    final nextWeek = CalendarWeekConfiguration(
      weekStartsOn: facts.settings.weekStart,
    ).weekContaining(today).next;
    if (!facts.protectedDays.any(nextWeek.contains)) {
      candidates.addAll(
        _schedules.protectedWeek(
          weekId: nextWeek.start.toString(),
          weekStartsUtc: _localDateAtHour(nextWeek.start, 7),
          route: ReminderWorkflowRoutes.planning(nextWeek.start),
          leadDays: [
            preferences.protectedDayFirstLeadDays,
            preferences.protectedDaySecondLeadDays,
          ],
        ),
      );
    }

    for (final placement in await placements.placements()) {
      final route = ReminderWorkflowRoutes.evaluation(placement.placement.id);
      final attention = placement.evaluationAttention;
      if (attention.isEmpty) continue;
      final through = now.add(const Duration(days: 31));
      var first = _localDateAtHour(placement.placement.startDate, 9);
      final every = Duration(days: preferences.evaluationRepeatDays);
      while (first.isBefore(now)) {
        first = first.add(every);
      }
      for (final item in attention) {
        final kind = switch (item.requirement.identity.kind) {
          EvaluationRequirementKind.initialSelfAssessment =>
            ReminderKind.initialSelfAssessment,
          EvaluationRequirementKind.interimStudentReviewsPrimaryPreceptor ||
          EvaluationRequirementKind.interimPrimaryPreceptorReviewsStudent =>
            ReminderKind.interimReview,
          EvaluationRequirementKind.finalSelfAssessment =>
            ReminderKind.finalSelfAssessment,
          EvaluationRequirementKind.finalPlacementReview =>
            ReminderKind.finalPlacementReview,
        };
        final anchors = <DateTime>[];
        for (var at = first; !at.isAfter(through); at = at.add(every)) {
          anchors.add(at);
        }
        candidates.addAll(
          _schedules.evaluation(
            kind: kind,
            subjectId: item.requirement.identity.stableValue,
            anchorsUtc: anchors,
            route: route,
          ),
        );
      }
      if (placement.progress.requiredWeeklyPace?.isDeadlinePassed ?? false) {
        candidates.add(
          _schedules.deadlineRisk(
            id: placement.placement.id,
            detectedAtUtc: _localDateAtHour(
              placement.placement.completionDeadline,
              7,
            ),
            route: route,
          ),
        );
      }
    }

    candidates.addAll(
      _schedules.weeklySummary(
        weekId: CalendarWeekConfiguration(
          weekStartsOn: facts.settings.weekStart,
        ).weekContaining(today).start.toString(),
        sundayAtConfiguredTimeUtc: _nextWeekdayHour(
          now,
          preferences.weeklySummaryWeekday,
          preferences.weeklySummaryHour,
        ),
        route: ReminderWorkflowRoutes.summary,
      ),
    );
    if (facts.profileId != null && facts.profileCreatedAtUtc != null) {
      candidates.addAll(
        _schedules.portableBackup(
          profileId: facts.profileId!,
          setupAtUtc: facts.profileCreatedAtUtc!,
          lastBackupAtUtc: null,
          nowUtc: now,
          route: ReminderWorkflowRoutes.backup,
          noBackupDelay: Duration(days: preferences.noBackupReminderDays),
          staleAfter: Duration(days: preferences.staleBackupReminderDays),
        ),
      );
    }
    candidates.addAll(
      _schedules.syncHealth(
        deviceId: deviceId,
        conflictDetectedAtUtc: facts.conflictDetectedAtUtc,
        failureStartedAtUtc: facts.syncHealth?.failureStartedAtUtc,
        oldestUnsynchronizedChangeUtc: facts.syncHealth?.oldestPendingAtUtc,
        route: ReminderWorkflowRoutes.synchronization,
      ),
    );

    return ReminderCandidatePlan(
      candidates: List.unmodifiable(candidates),
      disabledKinds: {
        if (!preferences.upcomingWorkShiftsEnabled)
          ReminderKind.upcomingWorkShift,
        if (!preferences.upcomingClinicalSessionsEnabled)
          ReminderKind.upcomingClinicalSession,
        if (!preferences.weeklySummaryEnabled) ReminderKind.weeklySummary,
        if (!preferences.backupRemindersEnabled) ReminderKind.portableBackup,
      },
    );
  }

  _ReminderFacts _facts(LocalReadRepositories values, DateTime now) {
    var settings = StudentSettings();
    String? profileId;
    DateTime? profileCreatedAtUtc;
    if (values case final SupportLocalReadRepositories support) {
      final settingsRecord = support.studentSettings.find(studentId: studentId);
      settings = settingsRecord?.value ?? settings;
      final profile = support.studentProfile.find(studentId: studentId);
      profileId = profile?.value.id;
      profileCreatedAtUtc = profile?.createdAtUtc;
    }
    SynchronizationHealthSnapshot? health;
    DateTime? conflictDetectedAtUtc;
    if (values case final SynchronizationLocalReadRepositories synchronized) {
      health = synchronized.synchronization.inspect(
        studentId: studentId,
        remoteScope: 'student-calendar',
      );
      final conflicts = synchronized.synchronization.listConflicts(
        studentId: studentId,
      );
      if (conflicts.isNotEmpty) {
        conflicts.sort((a, b) => a.detectedAtUtc.compareTo(b.detectedAtUtc));
        conflictDetectedAtUtc = conflicts.first.detectedAtUtc;
      }
    }
    return _ReminderFacts(
      workShifts: values.workShifts
          .list(studentId: studentId)
          .map((record) => record.value)
          .toList(growable: false),
      clinicalSessions: values.clinicalSessions
          .list(studentId: studentId)
          .map((record) => record.value)
          .toList(growable: false),
      protectedDays: values.protectedDays
          .list(studentId: studentId)
          .map((record) => record.value.date)
          .toList(growable: false),
      settings: settings,
      profileId: profileId,
      profileCreatedAtUtc: profileCreatedAtUtc,
      syncHealth: health,
      conflictDetectedAtUtc: conflictDetectedAtUtc,
    );
  }

  DateTime _nextLocalHour(DateTime nowUtc, int hour) {
    final local = _timeZones.toLocal(nowUtc, deviceTimeZoneId);
    final date = LocalDate(local.year, local.month, local.day).addDays(1);
    return _localDateAtHour(date, hour);
  }

  DateTime _localDateAtHour(LocalDate date, int hour) => _timeZones
      .fromLocal(
        DateTime.utc(date.year, date.month, date.day, hour),
        deviceTimeZoneId,
      )
      .toUtc();

  DateTime _nextWeekdayHour(DateTime nowUtc, int weekday, int hour) {
    final local = _timeZones.toLocal(nowUtc, deviceTimeZoneId);
    var days = (weekday - local.weekday + 7) % 7;
    if (days == 0 && local.hour >= hour) days = 7;
    return _localDateAtHour(
      LocalDate(local.year, local.month, local.day).addDays(days),
      hour,
    );
  }
}

final class _ReminderFacts {
  const _ReminderFacts({
    required this.workShifts,
    required this.clinicalSessions,
    required this.protectedDays,
    required this.settings,
    required this.profileId,
    required this.profileCreatedAtUtc,
    required this.syncHealth,
    required this.conflictDetectedAtUtc,
  });

  final List<WorkShift> workShifts;
  final List<ClinicalSession> clinicalSessions;
  final List<LocalDate> protectedDays;
  final StudentSettings settings;
  final String? profileId;
  final DateTime? profileCreatedAtUtc;
  final SynchronizationHealthSnapshot? syncHealth;
  final DateTime? conflictDetectedAtUtc;
}
