import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/material.dart';

String formatClinicalTime(LocalTime value, {required bool twelveHour}) =>
    twelveHour ? value.twelveHour : value.military;

Future<LocalTime?> pickClinicalTime(
  BuildContext context, {
  required LocalTime initialTime,
  required bool twelveHour,
}) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: initialTime.hour, minute: initialTime.minute),
    initialEntryMode: TimePickerEntryMode.dialOnly,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: !twelveHour),
      child: child!,
    ),
  );
  return picked == null ? null : LocalTime(picked.hour, picked.minute);
}

final class ClinicalTimePickerField extends StatelessWidget {
  const ClinicalTimePickerField({
    required this.label,
    required this.value,
    required this.twelveHour,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final String label;
  final LocalTime value;
  final bool twelveHour;
  final ValueChanged<LocalTime> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label ${formatClinicalTime(value, twelveHour: twelveHour)}',
    child: InkWell(
      onTap: enabled
          ? () async {
              final picked = await pickClinicalTime(
                context,
                initialTime: value,
                twelveHour: twelveHour,
              );
              if (picked != null) onChanged(picked);
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(formatClinicalTime(value, twelveHour: twelveHour)),
      ),
    ),
  );
}
