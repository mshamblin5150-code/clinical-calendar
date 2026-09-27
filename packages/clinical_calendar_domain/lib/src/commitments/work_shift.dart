import '../domain_validation.dart';
import '../time/zoned_interval.dart';

final class WorkScheduleFeedReference {
  WorkScheduleFeedReference({required String id, required String name})
    : id = requireIdentifier(id, 'Work Schedule Feed id'),
      name = requireIdentifier(name, 'Work Schedule Feed name');

  final String id;
  final String name;
}

/// A time-zone-specific employment commitment.
final class WorkShift {
  WorkShift({required String id, required this.plannedInterval})
    : id = requireIdentifier(id, 'Work Shift id'),
      workScheduleFeed = null,
      sourceEventUid = null;

  WorkShift.imported({
    required String id,
    required this.plannedInterval,
    required String workScheduleFeedId,
    required String workScheduleFeedName,
    String? sourceEventUid,
  }) : id = requireIdentifier(id, 'Imported Work Shift id'),
       sourceEventUid = sourceEventUid == null
           ? null
           : requireIdentifier(
               sourceEventUid,
               'Source event UID',
               maximumLength: 1024,
             ),
       workScheduleFeed = WorkScheduleFeedReference(
         id: workScheduleFeedId,
         name: workScheduleFeedName,
       );

  final String id;
  final ZonedInterval plannedInterval;
  final WorkScheduleFeedReference? workScheduleFeed;
  final String? sourceEventUid;

  String? get workScheduleFeedId => workScheduleFeed?.id;
  String? get workScheduleFeedName => workScheduleFeed?.name;

  bool get isImported => workScheduleFeed != null;

  int get plannedMinutes => plannedInterval.elapsedMinutes;
}
