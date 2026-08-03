enum CommitmentType { workShift, clinicalSession }

final class ScheduleCommitment {
  ScheduleCommitment({
    required this.id,
    required DateTime date,
    required this.startMinutes,
    required this.endMinutes,
    required this.timeZone,
    this.type = CommitmentType.clinicalSession,
  }) : date = DateTime(date.year, date.month, date.day) {
    if (id.trim().isEmpty) throw ArgumentError.value(id, 'id');
    if (startMinutes < 0 || startMinutes >= minutesPerDay) {
      throw ArgumentError.value(startMinutes, 'startMinutes');
    }
    if (endMinutes < 0 || endMinutes >= minutesPerDay) {
      throw ArgumentError.value(endMinutes, 'endMinutes');
    }
    if (startMinutes == endMinutes) {
      throw ArgumentError('A commitment must have a non-zero duration.');
    }
    if (timeZone.trim().isEmpty) {
      throw ArgumentError.value(timeZone, 'timeZone');
    }
  }

  static const minutesPerDay = 24 * 60;

  final String id;
  final DateTime date;
  final int startMinutes;
  final int endMinutes;
  final String timeZone;
  final CommitmentType type;

  bool get isOvernight => endMinutes < startMinutes;

  int get durationMinutes => isOvernight
      ? minutesPerDay - startMinutes + endMinutes
      : endMinutes - startMinutes;

  DateTime get startsAt => date.add(Duration(minutes: startMinutes));

  DateTime get endsAt => date.add(
    Duration(minutes: endMinutes + (isOvernight ? minutesPerDay : 0)),
  );

  Iterable<DateTime> get touchedDates sync* {
    yield date;
    if (isOvernight) yield date.add(const Duration(days: 1));
  }
}

enum ScheduleRejection { overlap, protectedDay }

final class ScheduleValidationResult {
  const ScheduleValidationResult._(this.rejections);

  const ScheduleValidationResult.valid() : this._(const []);

  final List<ScheduleRejection> rejections;

  bool get isValid => rejections.isEmpty;
}

final class ScheduleValidator {
  const ScheduleValidator();

  ScheduleValidationResult validate({
    required ScheduleCommitment candidate,
    required Iterable<ScheduleCommitment> existing,
    required Set<DateTime> protectedDays,
  }) {
    final normalizedProtectedDays = protectedDays
        .map((day) => DateTime(day.year, day.month, day.day))
        .toSet();
    final rejections = <ScheduleRejection>{};

    if (candidate.touchedDates.any(normalizedProtectedDays.contains)) {
      rejections.add(ScheduleRejection.protectedDay);
    }

    for (final other in existing) {
      if (candidate.startsAt.isBefore(other.endsAt) &&
          other.startsAt.isBefore(candidate.endsAt)) {
        rejections.add(ScheduleRejection.overlap);
        break;
      }
    }

    return ScheduleValidationResult._(List.unmodifiable(rejections));
  }
}

String formatMinutes(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}
