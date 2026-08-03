import '../domain_validation.dart';
import 'local_date.dart';
import 'local_time.dart';
import 'time_zone.dart';

/// A local commitment interval with the zone and boundary offsets observed
/// when it was created.
///
/// Persisting both offsets makes elapsed time deterministic across devices and
/// across later time-zone database changes. The application layer is
/// responsible for resolving these offsets from [timeZone] at creation time.
final class ZonedInterval {
  factory ZonedInterval({
    required LocalDate startDate,
    required LocalTime startTime,
    required LocalTime endTime,
    required TimeZoneId timeZone,
    required UtcOffset startOffset,
    required UtcOffset endOffset,
  }) {
    if (startTime == endTime) {
      throw const DomainValidationException(
        'An interval start and end time cannot be equal.',
      );
    }
    final endDate = endTime.compareTo(startTime) < 0
        ? startDate.addDays(1)
        : startDate;
    final startInstantUtc = _instantUtc(startDate, startTime, startOffset);
    final endInstantUtc = _instantUtc(endDate, endTime, endOffset);
    final elapsedMinutes = endInstantUtc.difference(startInstantUtc).inMinutes;
    if (elapsedMinutes <= 0) {
      throw const DomainValidationException(
        'An interval must have a positive elapsed duration.',
      );
    }
    return ZonedInterval._(
      startDate: startDate,
      endDate: endDate,
      startTime: startTime,
      endTime: endTime,
      timeZone: timeZone,
      startOffset: startOffset,
      endOffset: endOffset,
      startInstantUtc: startInstantUtc,
      endInstantUtc: endInstantUtc,
      elapsedMinutes: elapsedMinutes,
    );
  }

  const ZonedInterval._({
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.timeZone,
    required this.startOffset,
    required this.endOffset,
    required this.startInstantUtc,
    required this.endInstantUtc,
    required this.elapsedMinutes,
  });

  final LocalDate startDate;
  final LocalDate endDate;
  final LocalTime startTime;
  final LocalTime endTime;
  final TimeZoneId timeZone;
  final UtcOffset startOffset;
  final UtcOffset endOffset;
  final DateTime startInstantUtc;
  final DateTime endInstantUtc;
  final int elapsedMinutes;

  bool get isOvernight => endDate != startDate;

  List<LocalDate> get coveredDates => List.unmodifiable(
    isOvernight ? <LocalDate>[startDate, endDate] : <LocalDate>[startDate],
  );
}

DateTime _instantUtc(LocalDate date, LocalTime time, UtcOffset offset) =>
    DateTime.utc(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    ).subtract(offset.duration);
