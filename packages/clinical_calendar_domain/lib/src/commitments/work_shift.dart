import '../domain_validation.dart';
import '../time/zoned_interval.dart';

/// A time-zone-specific employment commitment.
final class WorkShift {
  WorkShift({required String id, required this.plannedInterval})
    : id = requireIdentifier(id, 'Work Shift id'),
      workScheduleFeedId = null,
      workScheduleFeedName = null;

  WorkShift.imported({
    required String id,
    required this.plannedInterval,
    required String workScheduleFeedId,
    required String workScheduleFeedName,
  }) : id = requireIdentifier(id, 'Imported Work Shift id'),
       workScheduleFeedId = requireIdentifier(
         workScheduleFeedId,
         'Work Schedule Feed id',
       ),
       workScheduleFeedName = requireIdentifier(
         workScheduleFeedName,
         'Work Schedule Feed name',
       );

  final String id;
  final ZonedInterval plannedInterval;
  final String? workScheduleFeedId;
  final String? workScheduleFeedName;

  bool get isImported => workScheduleFeedId != null;

  int get plannedMinutes => plannedInterval.elapsedMinutes;
}
