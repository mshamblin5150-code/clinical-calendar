import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import '../ports.dart';
import '../repositories.dart';

abstract interface class AcademicAssignmentCalendarQuery {
  Future<List<StoredDomainRecord<AcademicAssignment>>> dueBetween({
    required LocalDate firstDate,
    required LocalDate lastDate,
  });
}

final class AcademicAssignmentApplicationService
    implements AcademicAssignmentCalendarQuery {
  factory AcademicAssignmentApplicationService({
    required RepositoryRegistry repositories,
    required Clock clock,
    required IdentifierGenerator identifiers,
    required String studentId,
  }) => AcademicAssignmentApplicationService._(
    repositories,
    clock,
    identifiers,
    requireIdentifier(studentId, 'Student id'),
  );

  const AcademicAssignmentApplicationService._(
    this._repositories,
    this._clock,
    this._identifiers,
    this._studentId,
  );

  final RepositoryRegistry _repositories;
  final Clock _clock;
  final IdentifierGenerator _identifiers;
  final String _studentId;

  Future<List<StoredDomainRecord<AcademicAssignment>>> list() =>
      _repositories.read((repositories) {
        final assignments = _readRepositories(
          repositories,
        ).academicAssignments.list(studentId: _studentId);
        assignments.sort((left, right) {
          final due = left.value.dueDate.compareTo(right.value.dueDate);
          if (due != 0) return due;
          final title = left.value.title.compareTo(right.value.title);
          return title != 0 ? title : left.value.id.compareTo(right.value.id);
        });
        return assignments;
      });

  @override
  Future<List<StoredDomainRecord<AcademicAssignment>>> dueBetween({
    required LocalDate firstDate,
    required LocalDate lastDate,
  }) async {
    if (lastDate.isBefore(firstDate)) {
      throw ArgumentError('The last calendar date must not precede the first.');
    }
    final assignments = await list();
    return assignments
        .where(
          (record) =>
              !record.value.dueDate.isBefore(firstDate) &&
              !record.value.dueDate.isAfter(lastDate),
        )
        .toList(growable: false);
  }

  Future<StoredDomainRecord<AcademicAssignment>?> find(String assignmentId) =>
      _repositories.read(
        (repositories) => _readRepositories(
          repositories,
        ).academicAssignments.find(studentId: _studentId, id: assignmentId),
      );

  Future<StoredDomainRecord<AcademicAssignment>> create({
    required String title,
    required String courseId,
    required LocalDate dueDate,
  }) async {
    final occurredAt = _now();
    return _repositories.mutate((repositories) {
      final catalogEntry = _catalogEntry(
        repositories,
        courseId,
        requireActive: true,
      );
      final assignment = AcademicAssignment(
        id: _identifiers.nextIdentifier(),
        title: title,
        course: catalogEntry.name,
        courseId: catalogEntry.id,
        dueDate: dueDate,
      );
      return _writeRepositories(repositories).academicAssignments
          .put(
            studentId: _studentId,
            value: assignment,
            expectedRevision: 0,
            mutation: _mutation(occurredAt),
          )
          .record;
    });
  }

  Future<StoredDomainRecord<AcademicAssignment>> update({
    required String assignmentId,
    required int expectedRevision,
    required String title,
    required String? courseId,
    required LocalDate dueDate,
    AcademicAssignmentStatus? status,
  }) async {
    final occurredAt = _now();
    return _repositories.mutate((repositories) {
      final assignmentRepository = _writeRepositories(
        repositories,
      ).academicAssignments;
      final current = assignmentRepository.find(
        studentId: _studentId,
        id: assignmentId,
      );
      if (current == null) {
        throw const RepositoryException(
          RepositoryFailureKind.notFound,
          'The Academic Assignment was not found.',
        );
      }
      if (current.revision != expectedRevision) {
        throw const RepositoryException(
          RepositoryFailureKind.concurrentModification,
          'The Academic Assignment changed before the edit was saved.',
        );
      }
      final selectedCourse = courseId == null
          ? (id: current.value.courseId, name: current.value.course)
          : () {
              final entry = _catalogEntry(
                repositories,
                courseId,
                requireActive: courseId != current.value.courseId,
              );
              return (id: entry.id as String?, name: entry.name);
            }();
      final assignment = AcademicAssignment(
        id: current.value.id,
        title: title,
        course: selectedCourse.name,
        courseId: selectedCourse.id,
        dueDate: dueDate,
        status: status ?? current.value.status,
      );
      return assignmentRepository
          .put(
            studentId: _studentId,
            value: assignment,
            expectedRevision: current.revision,
            mutation: _mutation(occurredAt),
          )
          .record;
    });
  }

  Future<void> delete({
    required String assignmentId,
    required int expectedRevision,
  }) async {
    final occurredAt = _now();
    await _repositories.mutate((repositories) {
      _writeRepositories(repositories).academicAssignments.tombstone(
        studentId: _studentId,
        id: assignmentId,
        expectedRevision: expectedRevision,
        mutation: _mutation(occurredAt),
      );
    });
  }

  AcademicAssignmentLocalReadRepositories _readRepositories(
    LocalReadRepositories repositories,
  ) {
    if (repositories case AcademicAssignmentLocalReadRepositories capable) {
      return capable;
    }
    throw const RepositoryException(
      RepositoryFailureKind.uninitialized,
      'Academic Assignment persistence is unavailable.',
    );
  }

  ClassCatalogEntry _catalogEntry(
    LocalReadRepositories repositories,
    String courseId, {
    required bool requireActive,
  }) {
    if (repositories case ClassCatalogLocalReadRepositories capable) {
      final record = capable.classCatalogEntries.find(
        studentId: _studentId,
        id: courseId,
      );
      if (record == null || requireActive && record.value.isArchived) {
        throw const RepositoryException(
          RepositoryFailureKind.notFound,
          'Select an active class or course from the catalog.',
        );
      }
      return record.value;
    }
    throw const RepositoryException(
      RepositoryFailureKind.uninitialized,
      'Class catalog persistence is unavailable.',
    );
  }

  AcademicAssignmentLocalWriteRepositories _writeRepositories(
    LocalWriteRepositories repositories,
  ) {
    if (repositories case AcademicAssignmentLocalWriteRepositories capable) {
      return capable;
    }
    throw const RepositoryException(
      RepositoryFailureKind.uninitialized,
      'Academic Assignment persistence is unavailable.',
    );
  }

  MutationToken _mutation(DateTime occurredAt) => MutationToken(
    operationId: _identifiers.nextIdentifier(),
    idempotencyKey: _identifiers.nextIdentifier(),
    occurredAtUtc: occurredAt,
  );

  DateTime _now() {
    final value = _clock.nowUtc();
    if (!value.isUtc) throw StateError('Clock.nowUtc() must return UTC.');
    return value;
  }
}
