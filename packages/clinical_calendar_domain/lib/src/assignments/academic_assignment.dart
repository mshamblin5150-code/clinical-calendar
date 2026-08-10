import '../domain_validation.dart';
import '../time/local_date.dart';

enum AcademicAssignmentStatus { pending, completed }

/// A course deliverable with one required calendar due date.
///
/// This is intentionally separate from the Clinical Placement assignment
/// language used to associate Clinical Sessions with placements and
/// Preceptors.
final class AcademicAssignment {
  factory AcademicAssignment({
    required String id,
    required String title,
    required String course,
    required LocalDate dueDate,
    AcademicAssignmentStatus status = AcademicAssignmentStatus.pending,
  }) => AcademicAssignment._(
    id: requireIdentifier(id, 'Academic Assignment id'),
    title: _requiredText(title, 'Assignment title', 200),
    course: _requiredText(course, 'Class or course', 120),
    dueDate: dueDate,
    status: status,
  );

  const AcademicAssignment._({
    required this.id,
    required this.title,
    required this.course,
    required this.dueDate,
    required this.status,
  });

  final String id;
  final String title;
  final String course;
  final LocalDate dueDate;
  final AcademicAssignmentStatus status;

  AcademicAssignment markCompleted() =>
      copyWith(status: AcademicAssignmentStatus.completed);

  AcademicAssignment copyWith({
    String? title,
    String? course,
    LocalDate? dueDate,
    AcademicAssignmentStatus? status,
  }) => AcademicAssignment(
    id: id,
    title: title ?? this.title,
    course: course ?? this.course,
    dueDate: dueDate ?? this.dueDate,
    status: status ?? this.status,
  );
}

String _requiredText(String value, String fieldName, int maximumLength) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.length > maximumLength) {
    throw DomainValidationException(
      '$fieldName must contain between 1 and $maximumLength characters.',
    );
  }
  if (normalized.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)) {
    throw DomainValidationException('$fieldName contains control characters.');
  }
  return normalized;
}
