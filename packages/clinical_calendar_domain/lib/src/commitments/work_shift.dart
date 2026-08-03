import '../domain_validation.dart';
import '../time/zoned_interval.dart';

/// A time-zone-specific employment commitment.
final class WorkShift {
  WorkShift({required String id, required this.plannedInterval})
    : id = requireIdentifier(id, 'Work Shift id');

  final String id;
  final ZonedInterval plannedInterval;

  int get plannedMinutes => plannedInterval.elapsedMinutes;
}
