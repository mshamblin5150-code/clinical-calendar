import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'academic assignment requires title, course, due date, and identity',
    () {
      final assignment = AcademicAssignment(
        id: 'assignment-1',
        title: '  Evidence review  ',
        course: '  NURS 702  ',
        dueDate: LocalDate(2026, 9, 14),
      );

      expect(assignment.id, 'assignment-1');
      expect(assignment.title, 'Evidence review');
      expect(assignment.course, 'NURS 702');
      expect(assignment.dueDate, LocalDate(2026, 9, 14));
      expect(assignment.status, AcademicAssignmentStatus.pending);
      expect(
        assignment.markCompleted().status,
        AcademicAssignmentStatus.completed,
      );

      expect(
        () => AcademicAssignment(
          id: 'assignment-2',
          title: ' ',
          course: 'NURS 702',
          dueDate: LocalDate(2026, 9, 14),
        ),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () => AcademicAssignment(
          id: 'assignment-3',
          title: 'Evidence review',
          course: ' ',
          dueDate: LocalDate(2026, 9, 14),
        ),
        throwsA(isA<DomainValidationException>()),
      );
    },
  );
}
