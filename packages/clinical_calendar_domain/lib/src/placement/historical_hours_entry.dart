import '../domain_validation.dart';
import '../time/local_date.dart';

/// Aggregate pre-adoption Completed Hours, deliberately not a calendar
/// commitment and therefore not a timed interval.
final class HistoricalHoursEntry {
  factory HistoricalHoursEntry({
    required String id,
    required String clinicalPlacementId,
    required int completedMinutes,
    required LocalDate effectiveDate,
    String? preceptorId,
    String? note,
  }) {
    if (completedMinutes <= 0) {
      throw const DomainValidationException(
        'Historical Hours Entry minutes must be greater than zero.',
      );
    }
    final normalizedNote = note?.trim();
    if (normalizedNote != null && normalizedNote.length > 1000) {
      throw const DomainValidationException(
        'Historical Hours Entry note cannot exceed 1000 characters.',
      );
    }
    if (normalizedNote != null &&
        normalizedNote.codeUnits.any(
          (unit) =>
              unit == 0x7f || (unit < 0x20 && unit != 0x0a && unit != 0x0d),
        )) {
      throw const DomainValidationException(
        'Historical Hours Entry note contains control characters.',
      );
    }
    return HistoricalHoursEntry._(
      id: requireIdentifier(id, 'Historical Hours Entry id'),
      clinicalPlacementId: requireIdentifier(
        clinicalPlacementId,
        'Clinical Placement id',
      ),
      completedMinutes: completedMinutes,
      effectiveDate: effectiveDate,
      preceptorId: preceptorId == null
          ? null
          : requireIdentifier(preceptorId, 'Preceptor id'),
      note: normalizedNote == null || normalizedNote.isEmpty
          ? null
          : normalizedNote,
    );
  }

  const HistoricalHoursEntry._({
    required this.id,
    required this.clinicalPlacementId,
    required this.completedMinutes,
    required this.effectiveDate,
    required this.preceptorId,
    required this.note,
  });

  final String id;
  final String clinicalPlacementId;
  final int completedMinutes;
  final LocalDate effectiveDate;
  final String? preceptorId;
  final String? note;

  bool get isUnattributed => preceptorId == null;
}
