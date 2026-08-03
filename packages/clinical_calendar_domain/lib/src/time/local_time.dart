import '../domain_validation.dart';

/// A minute-precision wall-clock time stored in 24-hour form.
final class LocalTime implements Comparable<LocalTime> {
  factory LocalTime(int hour, int minute) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw DomainValidationException(
        'Invalid local time: $hour:${minute.toString().padLeft(2, '0')}.',
      );
    }
    return LocalTime._(hour, minute);
  }

  factory LocalTime.parseMilitary(String input) {
    final normalized = input.trim();
    final match = RegExp(r'^(\d{2})(?::?(\d{2}))$').firstMatch(normalized);
    if (match == null) {
      throw DomainValidationException('Military time must use HHMM or HH:MM.');
    }
    return LocalTime(int.parse(match.group(1)!), int.parse(match.group(2)!));
  }

  const LocalTime._(this.hour, this.minute);

  final int hour;
  final int minute;

  int get minutesSinceMidnight => hour * 60 + minute;

  String get military =>
      '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';

  String get twelveHour {
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  int compareTo(LocalTime other) =>
      minutesSinceMidnight.compareTo(other.minutesSinceMidnight);

  @override
  bool operator ==(Object other) =>
      other is LocalTime && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => military;
}
