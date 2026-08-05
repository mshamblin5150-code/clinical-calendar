enum ReminderKind {
  upcomingWorkShift,
  upcomingClinicalSession,
  clinicalConfirmation,
  protectedDayPlanning,
  initialSelfAssessment,
  interimReview,
  finalSelfAssessment,
  finalPlacementReview,
  weeklySummary,
  deadlineRisk,
  portableBackup,
  syncConflict,
  syncFailure,
  unsynchronizedChanges,
}

enum ReminderSnooze {
  fifteenMinutes,
  oneHour,
  laterToday,
  tomorrowMorning,
  threeDays,
  oneWeek,
}

abstract interface class ReminderTimeZoneResolver {
  DateTime toLocal(DateTime utc, String timeZoneId);
  DateTime fromLocal(DateTime localWallClock, String timeZoneId);
}

final class ReminderCandidate {
  const ReminderCandidate({
    required this.kind,
    required this.subjectId,
    required this.anchorUtc,
    required this.title,
    required this.route,
    this.detailedBody,
    this.intendedTimeZoneId,
    this.deliverWhenPastDue = false,
  });

  final ReminderKind kind;
  final String subjectId;
  final DateTime anchorUtc;
  final String title;
  final String route;
  final String? detailedBody;
  final String? intendedTimeZoneId;
  final bool deliverWhenPastDue;
}

final class ReminderOccurrence {
  const ReminderOccurrence({
    required this.occurrenceKey,
    required this.synchronizationKey,
    required this.kind,
    required this.subjectId,
    required this.scheduledForUtc,
    required this.title,
    required this.genericBody,
    required this.route,
    required this.snoozeOptions,
    this.detailedBody,
  });

  final String occurrenceKey;
  final String synchronizationKey;
  final ReminderKind kind;
  final String subjectId;
  final DateTime scheduledForUtc;
  final String title;
  final String genericBody;
  final String? detailedBody;
  final String route;
  final List<ReminderSnooze> snoozeOptions;
}

final class ReminderPolicy {
  const ReminderPolicy(this.timeZones);

  final ReminderTimeZoneResolver timeZones;

  List<ReminderOccurrence> build({
    required Iterable<ReminderCandidate> candidates,
    required DateTime nowUtc,
    required String deviceTimeZoneId,
    Map<String, DateTime> synchronizedSnoozes = const {},
    Set<ReminderKind> disabledKinds = const {},
    int quietStartsAtHour = 21,
    int quietStartsAtMinute = 0,
    int quietEndsAtHour = 7,
    int quietEndsAtMinute = 0,
  }) {
    if (quietStartsAtHour < 0 || quietStartsAtHour > 23) {
      throw ArgumentError.value(
        quietStartsAtHour,
        'quietStartsAtHour',
        'must be between 0 and 23',
      );
    }
    if (quietEndsAtHour < 0 || quietEndsAtHour > 23) {
      throw ArgumentError.value(
        quietEndsAtHour,
        'quietEndsAtHour',
        'must be between 0 and 23',
      );
    }
    if (quietStartsAtMinute < 0 || quietStartsAtMinute > 59) {
      throw ArgumentError.value(
        quietStartsAtMinute,
        'quietStartsAtMinute',
        'must be between 0 and 59',
      );
    }
    if (quietEndsAtMinute < 0 || quietEndsAtMinute > 59) {
      throw ArgumentError.value(
        quietEndsAtMinute,
        'quietEndsAtMinute',
        'must be between 0 and 59',
      );
    }
    final result = <ReminderOccurrence>[];
    final now = nowUtc.toUtc();
    for (final candidate in candidates) {
      if (disabledKinds.contains(candidate.kind) &&
          _canDisable(candidate.kind)) {
        continue;
      }
      final baseKey =
          '${candidate.kind.name}:${candidate.subjectId}:${candidate.anchorUtc.toUtc().toIso8601String()}';
      final snoozed = synchronizedSnoozes[baseKey];
      var requested = (snoozed ?? candidate.anchorUtc).toUtc();
      if (!requested.isAfter(now)) {
        if (snoozed != null || candidate.deliverWhenPastDue) {
          // Native schedulers require a future instant. A small grace window
          // also prevents several overdue reminders from aging into the past
          // while earlier entries are being registered.
          requested = now.add(const Duration(minutes: 1));
        } else {
          continue;
        }
      }
      // No Clinical Calendar notification is an emergency. Every category,
      // including conflicts and deadline risk, respects device quiet hours.
      final scheduled = _outsideQuietHours(
        requested,
        deviceTimeZoneId,
        quietStartsAtHour,
        quietStartsAtMinute,
        quietEndsAtHour,
        quietEndsAtMinute,
      );
      result.add(
        ReminderOccurrence(
          occurrenceKey:
              '$baseKey:${snoozed?.toUtc().toIso8601String() ?? 'base'}',
          synchronizationKey: baseKey,
          kind: candidate.kind,
          subjectId: candidate.subjectId,
          scheduledForUtc: scheduled,
          title: candidate.title,
          genericBody: 'Open Clinical Calendar to review this reminder.',
          detailedBody: candidate.detailedBody,
          route: candidate.route,
          snoozeOptions: _snoozes(candidate.kind),
        ),
      );
    }
    result.sort((a, b) => a.scheduledForUtc.compareTo(b.scheduledForUtc));
    return List.unmodifiable(result);
  }

  DateTime snoozedUntilUtc({
    required ReminderSnooze choice,
    required DateTime chosenAtUtc,
    required String deviceTimeZoneId,
  }) {
    final chosenAt = chosenAtUtc.toUtc();
    return switch (choice) {
      ReminderSnooze.fifteenMinutes => chosenAt.add(
        const Duration(minutes: 15),
      ),
      ReminderSnooze.oneHour => chosenAt.add(const Duration(hours: 1)),
      ReminderSnooze.threeDays => chosenAt.add(const Duration(days: 3)),
      ReminderSnooze.oneWeek => chosenAt.add(const Duration(days: 7)),
      ReminderSnooze.laterToday => _localWallClockUtc(
        chosenAt,
        deviceTimeZoneId,
        hour: 18,
        useNextDayWhenPassed: false,
      ),
      ReminderSnooze.tomorrowMorning => _localWallClockUtc(
        chosenAt,
        deviceTimeZoneId,
        hour: 9,
        useNextDayWhenPassed: true,
      ),
    };
  }

  DateTime _localWallClockUtc(
    DateTime chosenAtUtc,
    String zone, {
    required int hour,
    required bool useNextDayWhenPassed,
  }) {
    final local = timeZones.toLocal(chosenAtUtc, zone);
    var date = local;
    if (useNextDayWhenPassed || local.hour >= hour) {
      date = local.add(const Duration(days: 1));
    }
    final wallClock = DateTime.utc(date.year, date.month, date.day, hour);
    return timeZones.fromLocal(wallClock, zone).toUtc();
  }

  DateTime _outsideQuietHours(
    DateTime utc,
    String zone,
    int startHour,
    int startMinute,
    int endHour,
    int endMinute,
  ) {
    final local = timeZones.toLocal(utc, zone);
    final starts = startHour * 60 + startMinute;
    final ends = endHour * 60 + endMinute;
    final current = local.hour * 60 + local.minute;
    final inQuiet = starts > ends
        ? current >= starts || current < ends
        : current >= starts && current < ends;
    if (!inQuiet) return utc;
    final tomorrow = current >= starts
        ? local.add(const Duration(days: 1))
        : local;
    // UTC is only a timezone-naive carrier for these wall-clock fields.
    final wake = DateTime.utc(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      endHour,
      endMinute,
    );
    return timeZones.fromLocal(wake, zone).toUtc();
  }

  bool _canDisable(ReminderKind kind) => switch (kind) {
    ReminderKind.upcomingWorkShift ||
    ReminderKind.upcomingClinicalSession ||
    ReminderKind.weeklySummary ||
    ReminderKind.portableBackup => true,
    _ => false,
  };

  List<ReminderSnooze> _snoozes(ReminderKind kind) => switch (kind) {
    ReminderKind.upcomingWorkShift || ReminderKind.upcomingClinicalSession =>
      const [ReminderSnooze.fifteenMinutes, ReminderSnooze.oneHour],
    ReminderKind.clinicalConfirmation => const [
      ReminderSnooze.oneHour,
      ReminderSnooze.tomorrowMorning,
    ],
    ReminderKind.protectedDayPlanning ||
    ReminderKind.initialSelfAssessment ||
    ReminderKind.interimReview ||
    ReminderKind.finalSelfAssessment ||
    ReminderKind.finalPlacementReview => const [
      ReminderSnooze.laterToday,
      ReminderSnooze.tomorrowMorning,
      ReminderSnooze.threeDays,
    ],
    ReminderKind.portableBackup => const [ReminderSnooze.oneWeek],
    _ => const [],
  };
}

/// Expands the normative schedules into stable, one-off candidates.
final class DefaultReminderSchedules {
  const DefaultReminderSchedules(this.timeZones);

  final ReminderTimeZoneResolver timeZones;

  List<ReminderCandidate> upcoming({
    required ReminderKind kind,
    required String subjectId,
    required DateTime startsAtUtc,
    required String commitmentTimeZoneId,
    required String route,
    String? detailedBody,
    Duration first = const Duration(hours: 24),
    Duration second = const Duration(hours: 2),
    bool enabled = true,
  }) {
    if (!enabled) return const [];
    if (first.isNegative || second.isNegative) {
      throw ArgumentError('Reminder lead times cannot be negative.');
    }
    return [
      for (final lead in [first, second])
        if (lead > Duration.zero)
          ReminderCandidate(
            kind: kind,
            subjectId: '$subjectId:lead-${lead.inMinutes}',
            anchorUtc: _subtractWallClock(
              startsAtUtc,
              lead,
              commitmentTimeZoneId,
            ),
            title: kind == ReminderKind.upcomingWorkShift
                ? 'Upcoming work shift'
                : 'Upcoming clinical session',
            route: route,
            detailedBody: detailedBody,
            intendedTimeZoneId: commitmentTimeZoneId,
          ),
    ];
  }

  List<ReminderCandidate> clinicalConfirmation({
    required String subjectId,
    required DateTime endsAtUtc,
    required DateTime nextMorningNineUtc,
    required DateTime throughUtc,
    required String route,
    Duration firstDelay = const Duration(minutes: 30),
    Duration repeatEvery = const Duration(days: 3),
  }) => _cadence(
    kind: ReminderKind.clinicalConfirmation,
    subjectId: subjectId,
    first: endsAtUtc.add(firstDelay),
    second: nextMorningNineUtc,
    every: repeatEvery,
    through: throughUtc,
    title: 'Clinical session needs confirmation',
    route: route,
  );

  List<ReminderCandidate> evaluation({
    required ReminderKind kind,
    required String subjectId,
    required Iterable<DateTime> anchorsUtc,
    required String route,
  }) => [
    for (final anchor in anchorsUtc)
      ReminderCandidate(
        kind: kind,
        subjectId: subjectId,
        anchorUtc: anchor,
        title: 'Evaluation needs attention',
        route: route,
      ),
  ];

  List<ReminderCandidate> interimReview({
    required String placementId,
    required double completedHours,
    required double thresholdHours,
    required DateTime nowUtc,
    DateTime? nextSessionStartsUtc,
    double nextSessionHours = 0,
    required bool selfAssessmentComplete,
    required bool preceptorAssessmentComplete,
    required DateTime throughUtc,
    required String route,
    double approachingWithinHours = 10,
    Duration repeatEvery = const Duration(days: 3),
  }) {
    if (selfAssessmentComplete && preceptorAssessmentComplete) return const [];
    final remaining = thresholdHours - completedHours;
    final withinApproachingRange =
        remaining > 0 && remaining <= approachingWithinHours;
    final nextSessionCrossesThreshold =
        remaining > 0 &&
        nextSessionStartsUtc != null &&
        nextSessionHours >= remaining;
    final approaching = withinApproachingRange || nextSessionCrossesThreshold;
    final due = completedHours >= thresholdHours;
    if (!approaching && !due) return const [];
    return _everyThreeDays(
      kind: ReminderKind.interimReview,
      subjectId: placementId,
      first: due
          ? nowUtc
          : (withinApproachingRange ? nowUtc : nextSessionStartsUtc!),
      through: throughUtc,
      title: due ? 'Interim review is due' : 'Interim review is approaching',
      route: route,
      every: repeatEvery,
    );
  }

  List<ReminderCandidate> finalEvaluation({
    required ReminderKind kind,
    required String requirementId,
    required double completedHours,
    required double targetHours,
    required DateTime nowUtc,
    required DateTime deadlineUtc,
    required bool hasFutureClinicalSessions,
    required bool evaluationComplete,
    required DateTime throughUtc,
    required String route,
    double approachingWithinHours = 10,
    Duration approachingWithinDeadline = const Duration(days: 7),
    Duration repeatEvery = const Duration(days: 3),
  }) {
    if (kind != ReminderKind.finalSelfAssessment &&
        kind != ReminderKind.finalPlacementReview) {
      throw ArgumentError.value(
        kind,
        'kind',
        'must identify one final Evaluation Requirement',
      );
    }
    if (evaluationComplete) return const [];
    final withinHours =
        targetHours - completedHours > 0 &&
        targetHours - completedHours <= approachingWithinHours;
    final withinDeadline =
        !nowUtc.isAfter(deadlineUtc) &&
        deadlineUtc.difference(nowUtc) <= approachingWithinDeadline;
    final due = completedHours >= targetHours && !hasFutureClinicalSessions;
    if (!due && !withinHours && !withinDeadline) return const [];
    return _everyThreeDays(
      kind: kind,
      subjectId: requirementId,
      first: due
          ? nowUtc
          : (withinHours
                ? nowUtc
                : deadlineUtc.subtract(approachingWithinDeadline)),
      through: throughUtc,
      title: due
          ? 'Final evaluation is due'
          : 'Final evaluation is approaching',
      route: route,
      every: repeatEvery,
    );
  }

  List<ReminderCandidate> protectedWeek({
    required String weekId,
    required DateTime weekStartsUtc,
    required String route,
    List<int> leadDays = const [3, 1],
  }) => [
    for (final days in leadDays)
      ReminderCandidate(
        kind: ReminderKind.protectedDayPlanning,
        subjectId: '$weekId:lead-$days',
        anchorUtc: weekStartsUtc.subtract(Duration(days: days)),
        title: 'Protected Day planning needs attention',
        route: route,
      ),
  ];

  List<ReminderCandidate> initialSelfAssessment({
    required String placementId,
    required DateTime placementStartsUtc,
    required DateTime throughUtc,
    required String route,
    Duration firstLead = const Duration(days: 7),
    Duration secondLead = const Duration(days: 1),
    Duration repeatEvery = const Duration(days: 3),
  }) => _cadence(
    kind: ReminderKind.initialSelfAssessment,
    subjectId: placementId,
    first: placementStartsUtc.subtract(firstLead),
    second: placementStartsUtc.subtract(secondLead),
    every: repeatEvery,
    through: throughUtc,
    title: 'Initial self-assessment needs attention',
    route: route,
    extraAnchor: placementStartsUtc,
  );

  List<ReminderCandidate> weeklySummary({
    required String weekId,
    required DateTime sundayAtConfiguredTimeUtc,
    required String route,
  }) => [
    ReminderCandidate(
      kind: ReminderKind.weeklySummary,
      subjectId: weekId,
      anchorUtc: sundayAtConfiguredTimeUtc,
      title: 'Weekly summary is ready',
      route: route,
    ),
  ];

  List<ReminderCandidate> portableBackup({
    required String profileId,
    required DateTime setupAtUtc,
    required DateTime? lastBackupAtUtc,
    required DateTime nowUtc,
    required String route,
    Duration noBackupDelay = const Duration(days: 7),
    Duration staleAfter = const Duration(days: 30),
  }) {
    final due = lastBackupAtUtc == null
        ? setupAtUtc.add(noBackupDelay)
        : lastBackupAtUtc.add(staleAfter);
    if (nowUtc.isBefore(due)) return const [];
    var nextDelivery = due;
    while (nextDelivery.isBefore(nowUtc)) {
      nextDelivery = nextDelivery.add(const Duration(days: 7));
    }
    return [
      ReminderCandidate(
        kind: ReminderKind.portableBackup,
        subjectId: profileId,
        anchorUtc: nextDelivery,
        title: 'Create a portable backup',
        route: route,
      ),
    ];
  }

  List<ReminderCandidate> syncHealth({
    required String deviceId,
    DateTime? conflictDetectedAtUtc,
    DateTime? failureStartedAtUtc,
    DateTime? oldestUnsynchronizedChangeUtc,
    required String route,
  }) => [
    if (conflictDetectedAtUtc != null)
      ReminderCandidate(
        kind: ReminderKind.syncConflict,
        subjectId: deviceId,
        anchorUtc: conflictDetectedAtUtc,
        title: 'Sync conflict needs attention',
        route: route,
        deliverWhenPastDue: true,
      ),
    if (failureStartedAtUtc != null)
      ReminderCandidate(
        kind: ReminderKind.syncFailure,
        subjectId: deviceId,
        anchorUtc: failureStartedAtUtc.add(const Duration(hours: 1)),
        title: 'Sync has been unavailable',
        route: route,
        deliverWhenPastDue: true,
      ),
    if (oldestUnsynchronizedChangeUtc != null)
      ReminderCandidate(
        kind: ReminderKind.unsynchronizedChanges,
        subjectId: deviceId,
        anchorUtc: oldestUnsynchronizedChangeUtc.add(const Duration(hours: 24)),
        title: 'Changes are waiting to sync',
        route: route,
        deliverWhenPastDue: true,
      ),
  ];

  ReminderCandidate deadlineRisk({
    required String id,
    required DateTime detectedAtUtc,
    required String route,
  }) => ReminderCandidate(
    kind: ReminderKind.deadlineRisk,
    subjectId: id,
    anchorUtc: detectedAtUtc,
    title: 'Deadline risk needs attention',
    route: route,
    deliverWhenPastDue: true,
  );

  DateTime _subtractWallClock(
    DateTime instantUtc,
    Duration lead,
    String timeZoneId,
  ) {
    final local = timeZones.toLocal(instantUtc.toUtc(), timeZoneId);
    final wallClock = DateTime.utc(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
    ).subtract(lead);
    return timeZones.fromLocal(wallClock, timeZoneId).toUtc();
  }

  List<ReminderCandidate> _cadence({
    required ReminderKind kind,
    required String subjectId,
    required DateTime first,
    required DateTime second,
    required Duration every,
    required DateTime through,
    required String title,
    required String route,
    DateTime? extraAnchor,
  }) {
    _requirePositive(every, 'every');
    final anchors = <DateTime>[first, second, ?extraAnchor];
    final cadenceStart = extraAnchor ?? second;
    for (
      var next = cadenceStart.add(every);
      !next.isAfter(through);
      next = next.add(every)
    ) {
      anchors.add(next);
    }
    return [
      for (final anchor in anchors)
        ReminderCandidate(
          kind: kind,
          subjectId: subjectId,
          anchorUtc: anchor,
          title: title,
          route: route,
        ),
    ];
  }

  List<ReminderCandidate> _everyThreeDays({
    required ReminderKind kind,
    required String subjectId,
    required DateTime first,
    required DateTime through,
    required String title,
    required String route,
    Duration every = const Duration(days: 3),
  }) {
    _requirePositive(every, 'every');
    final result = <ReminderCandidate>[];
    for (var at = first; !at.isAfter(through); at = at.add(every)) {
      result.add(
        ReminderCandidate(
          kind: kind,
          subjectId: subjectId,
          anchorUtc: at,
          title: title,
          route: route,
        ),
      );
    }
    return result;
  }

  void _requirePositive(Duration value, String name) {
    if (value <= Duration.zero) {
      throw ArgumentError.value(value, name, 'must be positive');
    }
  }
}
