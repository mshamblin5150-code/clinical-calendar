import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'projects an Academic Assignment due date into shared Calendar data',
    () async {
      final assignment = AcademicAssignment(
        id: 'assignment-1',
        title: 'Evidence review',
        course: 'NURS 702',
        dueDate: LocalDate(2026, 9, 14),
        status: AcademicAssignmentStatus.completed,
      );
      final source = AcademicAssignmentCalendarDataSource(
        base: const _EmptyCalendarDataSource(),
        assignments: _AssignmentQuery(assignment),
      );

      final snapshot = await source.load(
        studentId: 'student-1',
        firstDate: LocalDate(2026, 9, 1),
        lastDate: LocalDate(2026, 9, 30),
      );

      final entry = snapshot.entries.single;
      expect(entry.kind, CalendarEntryKind.academicAssignment);
      expect(entry.title, 'Evidence review');
      expect(entry.course, 'NURS 702');
      expect(entry.assignment, isNull);
      expect(entry.startDate, LocalDate(2026, 9, 14));
      expect(entry.statusLabel, 'Completed');
      expect(entry.timeLabel(), 'Due date');
    },
  );
}

final class _EmptyCalendarDataSource implements CalendarDataSource {
  const _EmptyCalendarDataSource();

  @override
  Future<CalendarSnapshot> load({
    required String studentId,
    required LocalDate firstDate,
    required LocalDate lastDate,
  }) async => CalendarSnapshot([]);
}

final class _AssignmentQuery implements AcademicAssignmentCalendarQuery {
  const _AssignmentQuery(this.assignment);
  final AcademicAssignment assignment;

  @override
  Future<List<StoredDomainRecord<AcademicAssignment>>> dueBetween({
    required LocalDate firstDate,
    required LocalDate lastDate,
  }) async => [
    StoredDomainRecord(
      value: assignment,
      studentId: 'student-1',
      revision: 1,
      createdAtUtc: DateTime.utc(2026, 8, 10),
      updatedAtUtc: DateTime.utc(2026, 8, 10),
    ),
  ];
}
