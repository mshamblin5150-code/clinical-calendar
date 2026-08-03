import '../domain_validation.dart';
import '../time/local_time.dart';

enum ScheduleTemplateType { workShift, clinicalSession }

/// Date-free defaults copied into a new commitment when applied.
final class ScheduleTemplate {
  factory ScheduleTemplate({
    required String id,
    required String name,
    required ScheduleTemplateType type,
    required LocalTime startTime,
    required LocalTime endTime,
    String? clinicalPlacementId,
    String? preceptorId,
  }) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty || normalizedName.length > 80) {
      throw const DomainValidationException(
        'Schedule Template name must contain between 1 and 80 characters.',
      );
    }
    if (startTime == endTime) {
      throw const DomainValidationException(
        'Schedule Template start and end time cannot be equal.',
      );
    }
    final hasPlacement = clinicalPlacementId != null;
    final hasPreceptor = preceptorId != null;
    if (hasPlacement != hasPreceptor) {
      throw const DomainValidationException(
        'Clinical Placement and Preceptor defaults must be supplied together.',
      );
    }
    if (type == ScheduleTemplateType.workShift && hasPlacement) {
      throw const DomainValidationException(
        'A Work Shift template cannot have Clinical Placement defaults.',
      );
    }
    return ScheduleTemplate._(
      id: requireIdentifier(id, 'Schedule Template id'),
      name: normalizedName,
      type: type,
      startTime: startTime,
      endTime: endTime,
      clinicalPlacementId: clinicalPlacementId == null
          ? null
          : requireIdentifier(clinicalPlacementId, 'Clinical Placement id'),
      preceptorId: preceptorId == null
          ? null
          : requireIdentifier(preceptorId, 'Preceptor id'),
    );
  }

  const ScheduleTemplate._({
    required this.id,
    required this.name,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.clinicalPlacementId,
    required this.preceptorId,
  });

  final String id;
  final String name;
  final ScheduleTemplateType type;
  final LocalTime startTime;
  final LocalTime endTime;
  final String? clinicalPlacementId;
  final String? preceptorId;

  bool get isOvernight => endTime.compareTo(startTime) < 0;
}
