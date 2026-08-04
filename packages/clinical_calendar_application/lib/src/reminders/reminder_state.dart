import 'reminder_policy.dart';

/// Student-owned reminder truth that is synchronized independently of native
/// notification permission and delivery history.
final class ReminderState {
  ReminderState({
    required String id,
    required String occurrenceKey,
    required this.kind,
    required String subjectEntityId,
    required DateTime scheduledForUtc,
    DateTime? snoozedUntilUtc,
    DateTime? resolvedAtUtc,
    this.resolutionSource,
  }) : id = _requiredUuid(id, 'Reminder id'),
       occurrenceKey = _requiredText(occurrenceKey, 'Occurrence key'),
       subjectEntityId = _requiredText(subjectEntityId, 'Subject entity id'),
       scheduledForUtc = _requiredUtc(scheduledForUtc, 'Scheduled time'),
       snoozedUntilUtc = snoozedUntilUtc == null
           ? null
           : _requiredUtc(snoozedUntilUtc, 'Snoozed time'),
       resolvedAtUtc = resolvedAtUtc == null
           ? null
           : _requiredUtc(resolvedAtUtc, 'Resolved time') {
    if ((resolvedAtUtc == null) != (resolutionSource == null)) {
      throw ArgumentError(
        'Resolved time and resolution source must be supplied together.',
      );
    }
  }

  final String id;
  final String occurrenceKey;
  final ReminderKind kind;
  final String subjectEntityId;
  final DateTime scheduledForUtc;
  final DateTime? snoozedUntilUtc;
  final DateTime? resolvedAtUtc;
  final String? resolutionSource;

  bool get isResolved => resolvedAtUtc != null;

  ReminderState snoozeUntil(DateTime value) => ReminderState(
    id: id,
    occurrenceKey: occurrenceKey,
    kind: kind,
    subjectEntityId: subjectEntityId,
    scheduledForUtc: scheduledForUtc,
    snoozedUntilUtc: value,
    resolvedAtUtc: resolvedAtUtc,
    resolutionSource: resolutionSource,
  );

  ReminderState resolve({required DateTime atUtc, required String source}) =>
      ReminderState(
        id: id,
        occurrenceKey: occurrenceKey,
        kind: kind,
        subjectEntityId: subjectEntityId,
        scheduledForUtc: scheduledForUtc,
        snoozedUntilUtc: snoozedUntilUtc,
        resolvedAtUtc: atUtc,
        resolutionSource: _requiredText(source, 'Resolution source'),
      );
}

final RegExp _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

String _requiredUuid(String value, String name) {
  final normalized = value.trim().toLowerCase();
  if (!_uuid.hasMatch(normalized)) {
    throw ArgumentError.value(value, name, 'must be a UUID');
  }
  return normalized;
}

String _requiredText(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, name, 'is empty');
  return normalized;
}

DateTime _requiredUtc(DateTime value, String name) {
  if (!value.isUtc) throw ArgumentError.value(value, name, 'must be UTC');
  return value;
}
