import '../domain_validation.dart';
import '../time/local_date.dart';

/// Defines the first weekday used by the Student's continuous calendar weeks.
final class CalendarWeekConfiguration {
  factory CalendarWeekConfiguration({int weekStartsOn = DateTime.sunday}) {
    if (weekStartsOn < DateTime.monday || weekStartsOn > DateTime.sunday) {
      throw const DomainValidationException(
        'Calendar week start must be a weekday from Monday through Sunday.',
      );
    }
    return CalendarWeekConfiguration._(weekStartsOn);
  }

  const CalendarWeekConfiguration._(this.weekStartsOn);

  final int weekStartsOn;

  CalendarWeek weekContaining(LocalDate date) {
    final daysFromStart =
        (date.asUtcCalendarDate.weekday - weekStartsOn + 7) % 7;
    return CalendarWeek._(date.addDays(-daysFromStart));
  }
}

/// A stable seven-day calendar-week identity, represented by its first date.
final class CalendarWeek implements Comparable<CalendarWeek> {
  const CalendarWeek._(this.start);

  final LocalDate start;

  LocalDate get end => start.addDays(6);

  bool contains(LocalDate date) => !date.isBefore(start) && !date.isAfter(end);

  bool intersects(LocalDate first, LocalDate last) =>
      !end.isBefore(first) && !start.isAfter(last);

  CalendarWeek get next => CalendarWeek._(start.addDays(7));

  @override
  int compareTo(CalendarWeek other) => start.compareTo(other.start);

  @override
  bool operator ==(Object other) =>
      other is CalendarWeek && start == other.start;

  @override
  int get hashCode => start.hashCode;

  @override
  String toString() => 'CalendarWeek($start..$end)';
}
