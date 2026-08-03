import '../domain_validation.dart';

/// A calendar date without an implicit time zone or time of day.
final class LocalDate implements Comparable<LocalDate> {
  factory LocalDate(int year, int month, int day) {
    if (year < 1 || year > 9999) {
      throw const DomainValidationException(
        'Local date year must be between 1 and 9999.',
      );
    }
    final candidate = DateTime.utc(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      throw DomainValidationException(
        'Invalid local date: $year-${_twoDigits(month)}-${_twoDigits(day)}.',
      );
    }
    return LocalDate._(year, month, day);
  }

  const LocalDate._(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  LocalDate addDays(int days) {
    final result = DateTime.utc(year, month, day).add(Duration(days: days));
    return LocalDate(result.year, result.month, result.day);
  }

  DateTime get asUtcCalendarDate => DateTime.utc(year, month, day);

  @override
  int compareTo(LocalDate other) =>
      asUtcCalendarDate.compareTo(other.asUtcCalendarDate);

  bool isBefore(LocalDate other) => compareTo(other) < 0;

  bool isAfter(LocalDate other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$year-${_twoDigits(month)}-${_twoDigits(day)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
