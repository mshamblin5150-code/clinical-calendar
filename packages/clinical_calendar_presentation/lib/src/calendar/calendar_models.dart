import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/foundation.dart';

enum CalendarPeriod { month, week, agenda }

enum CalendarEntryKind { workShift, clinicalSession, protectedDay }

@immutable
final class CalendarEntry {
  const CalendarEntry({
    required this.id,
    required this.kind,
    required this.startDate,
    required this.endDate,
    required this.title,
    required this.statusLabel,
    this.startTime,
    this.endTime,
    this.assignment,
  });

  final String id;
  final CalendarEntryKind kind;
  final LocalDate startDate;
  final LocalDate endDate;
  final LocalTime? startTime;
  final LocalTime? endTime;
  final String title;
  final String? assignment;
  final String statusLabel;

  bool touches(LocalDate date) =>
      !date.isBefore(startDate) && !date.isAfter(endDate);

  bool isContinuationOn(LocalDate date) => date != startDate && touches(date);

  String timeLabel({bool twelveHour = false}) {
    if (kind == CalendarEntryKind.protectedDay) return 'All day';
    final start = twelveHour ? startTime!.twelveHour : startTime!.military;
    final end = twelveHour ? endTime!.twelveHour : endTime!.military;
    return '$start–$end${endDate != startDate ? ' next day' : ''}';
  }
}

@immutable
final class CalendarSnapshot {
  CalendarSnapshot(Iterable<CalendarEntry> entries)
    : entries = List.unmodifiable(entries);

  final List<CalendarEntry> entries;

  List<CalendarEntry> entriesOn(LocalDate date) =>
      entries.where((entry) => entry.touches(date)).toList(growable: false);
}

@immutable
final class CalendarItemReference {
  const CalendarItemReference({
    required this.kind,
    required this.id,
    required this.date,
  });

  final CalendarEntryKind kind;
  final String id;
  final LocalDate date;
}
