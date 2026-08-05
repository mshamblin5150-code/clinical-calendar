import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/material.dart';

String formatUsDate(LocalDate value) =>
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}-'
    '${value.year.toString().padLeft(4, '0')}';

String formatUsDateFromDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}-'
      '${local.year.toString().padLeft(4, '0')}';
}

String formatUsDateTime(DateTime value) {
  final local = value.toLocal();
  final period = local.hour >= 12 ? 'PM' : 'AM';
  final hour = switch (local.hour % 12) {
    0 => 12,
    final value => value,
  };
  return '${formatUsDateFromDateTime(local)} $hour:'
      '${local.minute.toString().padLeft(2, '0')} $period';
}

LocalDate parseUsDate(String value) {
  final parts = value.trim().split('-');
  if (parts.length != 3 || parts[2].length != 4) {
    throw const FormatException('Use MM-DD-YYYY.');
  }
  return LocalDate(
    int.parse(parts[2]),
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

Future<LocalDate?> pickUsDate(
  BuildContext context, {
  LocalDate? initialDate,
}) async {
  final today = DateTime.now();
  final initial = initialDate == null
      ? DateTime(today.year, today.month, today.day)
      : DateTime(initialDate.year, initialDate.month, initialDate.day);
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(1900),
    lastDate: DateTime(2200, 12, 31),
  );
  return picked == null
      ? null
      : LocalDate(picked.year, picked.month, picked.day);
}
