import '../commitments/clinical_session.dart';
import '../domain_validation.dart';
import '../placement/clinical_placement.dart';
import '../placement/historical_hours_entry.dart';
import '../time/local_date.dart';

/// The one canonical, derived progress ledger for a Clinical Placement.
///
/// Every value is recomputed from the placement's source records. No displayed
/// or previously derived value is accepted as input.
final class ClinicalPlacementProgress {
  const ClinicalPlacementProgress._({
    required this.clinicalPlacementId,
    required this.targetMinutes,
    required this.completedMinutes,
    required this.scheduledMinutes,
    required this.awaitingConfirmationMinutes,
    required this.historicalMinutes,
    required this.remainingMinutes,
    required this.unscheduledMinutes,
    required this.overTargetMinutes,
    required this.preceptorProgress,
    required this.unattributedProgress,
    required this.projectedCompletionDate,
    required this.requiredWeeklyPace,
  });

  final String clinicalPlacementId;
  final int targetMinutes;
  final int completedMinutes;
  final int scheduledMinutes;
  final int awaitingConfirmationMinutes;
  final int historicalMinutes;
  final int remainingMinutes;
  final int unscheduledMinutes;
  final int overTargetMinutes;
  final Map<String, PreceptorProgress> preceptorProgress;
  final PreceptorProgress unattributedProgress;
  final LocalDate? projectedCompletionDate;
  final RequiredWeeklyPace? requiredWeeklyPace;
}

/// Completed and active Scheduled Hours owned by one Preceptor bucket.
final class PreceptorProgress {
  const PreceptorProgress({
    required this.completedMinutes,
    required this.scheduledMinutes,
    required this.awaitingConfirmationMinutes,
    required this.historicalMinutes,
  });

  final int completedMinutes;
  final int scheduledMinutes;
  final int awaitingConfirmationMinutes;
  final int historicalMinutes;
}

/// The additional average pace needed to schedule all currently Unscheduled
/// Hours by the Completion Deadline.
final class RequiredWeeklyPace {
  const RequiredWeeklyPace({
    required this.requiredMinutes,
    required this.availableDays,
  });

  final int requiredMinutes;
  final int availableDays;

  bool get isDeadlinePassed => availableDays == 0;

  /// Exact-minute weekly ratio. An overdue placement with remaining work has
  /// no finite achievable pace and therefore reports positive infinity.
  double get averageMinutesPerWeek => availableDays == 0
      ? double.infinity
      : requiredMinutes * DateTime.daysPerWeek / availableDays;
}

/// Aggregate Completed Hours and the shared Variant F eight-segment model.
final class TotalProgress {
  const TotalProgress._({
    required this.completedMinutes,
    required this.targetMinutes,
    required this.completedPercentage,
    required this.segmentFillPercentages,
  });

  static const int segmentCount = 8;

  final int completedMinutes;
  final int targetMinutes;

  /// Whole percentage used by every presentation, capped at 100.
  final int completedPercentage;

  /// Fill percentage for each of the eight equal-width segments.
  final List<double> segmentFillPercentages;
}

/// Deterministically derives placement and aggregate progress from source
/// domain records.
final class ClinicalPlacementProgressEngine {
  const ClinicalPlacementProgressEngine();

  ClinicalPlacementProgress derivePlacement({
    required ClinicalPlacement placement,
    required Iterable<ClinicalSession> sessions,
    required Iterable<HistoricalHoursEntry> historicalHoursEntries,
    required LocalDate today,
  }) {
    // TargetHours is the denominator authority and cannot represent zero.
    final targetMinutes = placement.targetHours.minutes;
    if (targetMinutes <= 0) {
      throw const DomainValidationException(
        'Progress requires Target Hours greater than zero.',
      );
    }

    final placementSessions = sessions
        .where((session) => session.clinicalPlacementId == placement.id)
        .toList(growable: false);
    final placementHistory = historicalHoursEntries
        .where((entry) => entry.clinicalPlacementId == placement.id)
        .toList(growable: false);
    _requireUniqueIds(
      placementSessions.map((session) => session.id),
      'Clinical Session',
    );
    _requireUniqueIds(
      placementHistory.map((entry) => entry.id),
      'Historical Hours Entry',
    );

    for (final session in placementSessions) {
      placement.validateClinicalSession(session);
    }
    for (final entry in placementHistory) {
      placement.validateHistoricalHoursEntry(entry);
    }

    final mutableBuckets = <String, _MutablePreceptorProgress>{
      for (final id in placement.attachedPreceptorIds)
        id: _MutablePreceptorProgress(),
    };
    final unattributed = _MutablePreceptorProgress();
    var completedMinutes = 0;
    var scheduledMinutes = 0;
    var awaitingConfirmationMinutes = 0;
    var historicalMinutes = 0;

    for (final session in placementSessions) {
      final bucket = mutableBuckets[session.preceptorId]!;
      switch (session.state) {
        case ClinicalSessionState.completed:
          completedMinutes += session.completedMinutes;
          bucket.completedMinutes += session.completedMinutes;
        case ClinicalSessionState.scheduled:
          scheduledMinutes += session.plannedMinutes;
          bucket.scheduledMinutes += session.plannedMinutes;
        case ClinicalSessionState.awaitingConfirmation:
          scheduledMinutes += session.plannedMinutes;
          awaitingConfirmationMinutes += session.plannedMinutes;
          bucket.scheduledMinutes += session.plannedMinutes;
          bucket.awaitingConfirmationMinutes += session.plannedMinutes;
        case ClinicalSessionState.cancelled || ClinicalSessionState.missed:
          break;
      }
    }

    for (final entry in placementHistory) {
      completedMinutes += entry.completedMinutes;
      historicalMinutes += entry.completedMinutes;
      final bucket = entry.preceptorId == null
          ? unattributed
          : mutableBuckets[entry.preceptorId]!;
      bucket.completedMinutes += entry.completedMinutes;
      bucket.historicalMinutes += entry.completedMinutes;
    }

    final remainingMinutes = _floorAtZero(targetMinutes - completedMinutes);
    final unscheduledMinutes = _floorAtZero(
      targetMinutes - completedMinutes - scheduledMinutes,
    );
    final overTargetMinutes = _floorAtZero(completedMinutes - targetMinutes);
    final projectedCompletionDate =
        completedMinutes + scheduledMinutes >= targetMinutes
        ? _projectedCompletionDate(
            targetMinutes: targetMinutes,
            completedMinutes: completedMinutes,
            sessions: placementSessions,
            historicalHoursEntries: placementHistory,
          )
        : null;
    final requiredWeeklyPace = projectedCompletionDate == null
        ? RequiredWeeklyPace(
            requiredMinutes: unscheduledMinutes,
            availableDays: _availableDays(today, placement),
          )
        : null;

    return ClinicalPlacementProgress._(
      clinicalPlacementId: placement.id,
      targetMinutes: targetMinutes,
      completedMinutes: completedMinutes,
      scheduledMinutes: scheduledMinutes,
      awaitingConfirmationMinutes: awaitingConfirmationMinutes,
      historicalMinutes: historicalMinutes,
      remainingMinutes: remainingMinutes,
      unscheduledMinutes: unscheduledMinutes,
      overTargetMinutes: overTargetMinutes,
      preceptorProgress: Map.unmodifiable(
        mutableBuckets.map((id, bucket) => MapEntry(id, bucket.freeze())),
      ),
      unattributedProgress: unattributed.freeze(),
      projectedCompletionDate: projectedCompletionDate,
      requiredWeeklyPace: requiredWeeklyPace,
    );
  }

  TotalProgress deriveTotal(Iterable<ClinicalPlacementProgress> placements) {
    final placementList = placements.toList(growable: false);
    _requireUniqueIds(
      placementList.map((placement) => placement.clinicalPlacementId),
      'Clinical Placement progress',
    );
    if (placementList.isEmpty) {
      return const TotalProgress._(
        completedMinutes: 0,
        targetMinutes: 0,
        completedPercentage: 0,
        segmentFillPercentages: <double>[0, 0, 0, 0, 0, 0, 0, 0],
      );
    }
    final completedMinutes = placementList.fold<int>(
      0,
      (sum, placement) => sum + placement.completedMinutes,
    );
    final targetMinutes = placementList.fold<int>(
      0,
      (sum, placement) => sum + placement.targetMinutes,
    );
    if (targetMinutes <= 0) {
      throw const DomainValidationException(
        'Total Progress requires aggregate Target Hours greater than zero.',
      );
    }
    final percentage = (completedMinutes * 100 / targetMinutes).round().clamp(
      0,
      100,
    );
    final segmentSize = 100 / TotalProgress.segmentCount;
    final fills = List<double>.generate(TotalProgress.segmentCount, (index) {
      return ((percentage - index * segmentSize) * TotalProgress.segmentCount)
          .clamp(0, 100)
          .toDouble();
    }, growable: false);
    return TotalProgress._(
      completedMinutes: completedMinutes,
      targetMinutes: targetMinutes,
      completedPercentage: percentage,
      segmentFillPercentages: List.unmodifiable(fills),
    );
  }
}

LocalDate _projectedCompletionDate({
  required int targetMinutes,
  required int completedMinutes,
  required List<ClinicalSession> sessions,
  required List<HistoricalHoursEntry> historicalHoursEntries,
}) {
  if (completedMinutes >= targetMinutes) {
    final completedContributions = <_DatedContribution>[
      for (final entry in historicalHoursEntries)
        _DatedContribution(
          entry.effectiveDate,
          entry.completedMinutes,
          entry.id,
        ),
      for (final session in sessions)
        if (session.state == ClinicalSessionState.completed)
          _DatedContribution(
            session.actualInterval!.endDate,
            session.completedMinutes,
            session.id,
          ),
    ]..sort(_compareContribution);
    var cumulativeMinutes = 0;
    for (final contribution in completedContributions) {
      cumulativeMinutes += contribution.minutes;
      if (cumulativeMinutes >= targetMinutes) {
        return contribution.date;
      }
    }
  }

  var projectedMinutes = completedMinutes;
  final scheduledContributions = <_DatedContribution>[
    for (final session in sessions)
      if (session.state == ClinicalSessionState.scheduled ||
          session.state == ClinicalSessionState.awaitingConfirmation)
        _DatedContribution(
          session.plannedInterval.endDate,
          session.plannedMinutes,
          session.id,
        ),
  ]..sort(_compareContribution);
  for (final contribution in scheduledContributions) {
    projectedMinutes += contribution.minutes;
    if (projectedMinutes >= targetMinutes) {
      return contribution.date;
    }
  }
  throw const DomainValidationException(
    'Projected completion requires enough Completed and Scheduled Hours.',
  );
}

int _availableDays(LocalDate today, ClinicalPlacement placement) {
  final paceStart = today.isBefore(placement.startDate)
      ? placement.startDate
      : today;
  if (paceStart.isAfter(placement.completionDeadline)) {
    return 0;
  }
  return placement.completionDeadline.asUtcCalendarDate
          .difference(paceStart.asUtcCalendarDate)
          .inDays +
      1;
}

int _floorAtZero(int value) => value < 0 ? 0 : value;

void _requireUniqueIds(Iterable<String> ids, String recordName) {
  final observed = <String>{};
  for (final id in ids) {
    if (!observed.add(id)) {
      throw DomainValidationException('$recordName ids must be unique.');
    }
  }
}

int _compareContribution(_DatedContribution left, _DatedContribution right) {
  final dateComparison = left.date.compareTo(right.date);
  return dateComparison != 0
      ? dateComparison
      : left.tieBreaker.compareTo(right.tieBreaker);
}

final class _DatedContribution {
  const _DatedContribution(this.date, this.minutes, this.tieBreaker);

  final LocalDate date;
  final int minutes;
  final String tieBreaker;
}

final class _MutablePreceptorProgress {
  int completedMinutes = 0;
  int scheduledMinutes = 0;
  int awaitingConfirmationMinutes = 0;
  int historicalMinutes = 0;

  PreceptorProgress freeze() => PreceptorProgress(
    completedMinutes: completedMinutes,
    scheduledMinutes: scheduledMinutes,
    awaitingConfirmationMinutes: awaitingConfirmationMinutes,
    historicalMinutes: historicalMinutes,
  );
}
