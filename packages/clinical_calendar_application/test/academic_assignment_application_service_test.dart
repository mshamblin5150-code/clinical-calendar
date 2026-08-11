import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

const _studentId = '10000000-0000-4000-8000-000000000001';

void main() {
  test(
    'creates, edits, completes, lists, and deletes an Academic Assignment',
    () async {
      final repository = _MemoryRepository<AcademicAssignment>(
        (value) => value.id,
      );
      final catalog = _MemoryRepository<ClassCatalogEntry>((value) => value.id);
      _seedCatalog(catalog, 'course-1', 'NURS 702');
      final service = AcademicAssignmentApplicationService(
        repositories: _Registry(_Repositories(repository, catalog)),
        clock: _Clock(),
        identifiers: _Identifiers(),
        studentId: _studentId,
      );

      final created = await service.create(
        title: 'Evidence review',
        courseId: 'course-1',
        dueDate: LocalDate(2026, 9, 14),
      );
      expect(created.revision, 1);
      expect((await service.list()).single.value.title, 'Evidence review');

      final edited = await service.update(
        assignmentId: created.value.id,
        expectedRevision: created.revision,
        title: 'Final evidence review',
        courseId: 'course-1',
        dueDate: LocalDate(2026, 9, 21),
        status: AcademicAssignmentStatus.completed,
      );
      expect(edited.value.title, 'Final evidence review');
      expect(edited.value.status, AcademicAssignmentStatus.completed);

      await expectLater(
        service.update(
          assignmentId: created.value.id,
          expectedRevision: created.revision,
          title: 'Stale edit',
          courseId: 'course-1',
          dueDate: LocalDate(2026, 9, 21),
        ),
        throwsA(
          isA<RepositoryException>().having(
            (error) => error.kind,
            'kind',
            RepositoryFailureKind.concurrentModification,
          ),
        ),
      );

      await service.delete(
        assignmentId: edited.value.id,
        expectedRevision: edited.revision,
      );
      expect(await service.list(), isEmpty);
    },
  );

  test(
    'calendar query returns only assignments due in the requested period',
    () async {
      final repository = _MemoryRepository<AcademicAssignment>(
        (value) => value.id,
      );
      final catalog = _MemoryRepository<ClassCatalogEntry>((value) => value.id);
      _seedCatalog(catalog, 'course-1', 'NURS 702');
      _seedCatalog(catalog, 'course-2', 'NURS 703');
      final service = AcademicAssignmentApplicationService(
        repositories: _Registry(_Repositories(repository, catalog)),
        clock: _Clock(),
        identifiers: _Identifiers(),
        studentId: _studentId,
      );
      await service.create(
        title: 'In period',
        courseId: 'course-1',
        dueDate: LocalDate(2026, 9, 14),
      );
      await service.create(
        title: 'Outside period',
        courseId: 'course-2',
        dueDate: LocalDate(2026, 10, 1),
      );

      final due = await service.dueBetween(
        firstDate: LocalDate(2026, 9, 1),
        lastDate: LocalDate(2026, 9, 30),
      );

      expect(due.map((record) => record.value.title), ['In period']);
    },
  );
}

final class _Registry implements RepositoryRegistry {
  const _Registry(this.repositories);
  final _Repositories repositories;

  @override
  Future<void> initialize() async {}

  @override
  Future<R> read<R>(
    R Function(LocalReadRepositories repositories) callback,
  ) async => callback(repositories);

  @override
  Future<R> mutate<R>(
    R Function(LocalWriteRepositories repositories) callback,
  ) async => callback(repositories);
}

final class _Repositories
    implements
        LocalWriteRepositories,
        AcademicAssignmentLocalWriteRepositories,
        ClassCatalogLocalWriteRepositories {
  const _Repositories(this.academicAssignments, this.classCatalogEntries);

  @override
  final MutableRepository<AcademicAssignment> academicAssignments;
  @override
  final MutableRepository<ClassCatalogEntry> classCatalogEntries;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void _seedCatalog(
  _MemoryRepository<ClassCatalogEntry> repository,
  String id,
  String name,
) {
  repository.records[id] = StoredDomainRecord(
    value: ClassCatalogEntry(id: id, name: name),
    studentId: _studentId,
    revision: 1,
    createdAtUtc: DateTime.utc(2026, 8, 10, 12),
    updatedAtUtc: DateTime.utc(2026, 8, 10, 12),
  );
}

final class _MemoryRepository<T> implements MutableRepository<T> {
  _MemoryRepository(this.idOf);
  final String Function(T) idOf;
  final Map<String, StoredDomainRecord<T>> records = {};

  @override
  StoredDomainRecord<T>? find({
    required String studentId,
    required String id,
    bool includeDeleted = false,
  }) {
    final record = records[id];
    if (record == null || record.studentId != studentId) return null;
    return !includeDeleted && record.isDeleted ? null : record;
  }

  @override
  List<StoredDomainRecord<T>> list({
    required String studentId,
    bool includeDeleted = false,
  }) => records.values
      .where(
        (record) =>
            record.studentId == studentId &&
            (includeDeleted || !record.isDeleted),
      )
      .toList(growable: false);

  @override
  MutationReceipt<T> put({
    required String studentId,
    required T value,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    final id = idOf(value);
    final current = records[id];
    if ((current?.revision ?? 0) != expectedRevision) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'Revision mismatch.',
      );
    }
    final record = StoredDomainRecord(
      value: value,
      studentId: studentId,
      revision: expectedRevision + 1,
      createdAtUtc: current?.createdAtUtc ?? mutation.occurredAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
    );
    records[id] = record;
    return MutationReceipt(record: record, replayed: false);
  }

  @override
  MutationReceipt<T> tombstone({
    required String studentId,
    required String id,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    final current = records[id];
    if (current == null || current.revision != expectedRevision) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'Revision mismatch.',
      );
    }
    final record = StoredDomainRecord(
      value: current.value,
      studentId: studentId,
      revision: expectedRevision + 1,
      createdAtUtc: current.createdAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
      deletedAtUtc: mutation.occurredAtUtc,
    );
    records[id] = record;
    return MutationReceipt(record: record, replayed: false);
  }
}

final class _Clock implements Clock {
  @override
  DateTime nowUtc() => DateTime.utc(2026, 8, 10, 12);
}

final class _Identifiers implements IdentifierGenerator {
  var value = 0;
  @override
  String nextIdentifier() =>
      '20000000-0000-4000-8000-${(++value).toString().padLeft(12, '0')}';
}
