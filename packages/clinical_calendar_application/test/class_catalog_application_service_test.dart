import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

const _studentId = '10000000-0000-4000-8000-000000000001';

void main() {
  test('Student can add, rename, archive, restore, and list classes', () async {
    final repository = _MemoryRepository<ClassCatalogEntry>(
      (value) => value.id,
    );
    final assignments = _MemoryRepository<AcademicAssignment>(
      (value) => value.id,
    );
    final service = ClassCatalogApplicationService(
      repositories: _Registry(_Repositories(repository, assignments)),
      clock: _Clock(),
      identifiers: _Identifiers(),
      studentId: _studentId,
    );

    final created = await service.create(name: 'NURS 702');
    assignments.records['assignment-1'] = StoredDomainRecord(
      value: AcademicAssignment(
        id: 'assignment-1',
        title: 'Evidence review',
        course: 'NURS 702',
        courseId: created.value.id,
        dueDate: LocalDate(2026, 9, 14),
      ),
      studentId: _studentId,
      revision: 1,
      createdAtUtc: DateTime.utc(2026, 8, 11, 12),
      updatedAtUtc: DateTime.utc(2026, 8, 11, 12),
    );
    expect((await service.list()).single.value.name, 'NURS 702');

    final renamed = await service.rename(
      entryId: created.value.id,
      expectedRevision: created.revision,
      name: 'NURS 703',
    );
    expect(renamed.value.name, 'NURS 703');
    expect(assignments.records['assignment-1']!.value.course, 'NURS 703');

    final archived = await service.setArchived(
      entryId: renamed.value.id,
      expectedRevision: renamed.revision,
      archived: true,
    );
    expect(await service.list(), isEmpty);
    expect(
      (await service.list(includeArchived: true)).single.value.isArchived,
      isTrue,
    );

    await service.setArchived(
      entryId: archived.value.id,
      expectedRevision: archived.revision,
      archived: false,
    );
    expect((await service.list()).single.value.isArchived, isFalse);
  });

  test('class names are unique for a Student regardless of case', () async {
    final repository = _MemoryRepository<ClassCatalogEntry>(
      (value) => value.id,
    );
    final service = ClassCatalogApplicationService(
      repositories: _Registry(
        _Repositories(
          repository,
          _MemoryRepository<AcademicAssignment>((value) => value.id),
        ),
      ),
      clock: _Clock(),
      identifiers: _Identifiers(),
      studentId: _studentId,
    );
    await service.create(name: 'NURS 702');

    await expectLater(
      service.create(name: ' nurs 702 '),
      throwsA(isA<RepositoryException>()),
    );
  });
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
        ClassCatalogLocalWriteRepositories,
        AcademicAssignmentLocalWriteRepositories {
  const _Repositories(this.classCatalogEntries, this.academicAssignments);
  @override
  final MutableRepository<ClassCatalogEntry> classCatalogEntries;
  @override
  final MutableRepository<AcademicAssignment> academicAssignments;
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
    return record == null ||
            record.studentId != studentId ||
            (!includeDeleted && record.isDeleted)
        ? null
        : record;
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
      .toList();

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
    final record = StoredDomainRecord<T>(
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
  }) => throw UnimplementedError();
}

final class _Clock implements Clock {
  @override
  DateTime nowUtc() => DateTime.utc(2026, 8, 11, 12);
}

final class _Identifiers implements IdentifierGenerator {
  var value = 0;
  @override
  String nextIdentifier() =>
      '20000000-0000-4000-8000-${(++value).toString().padLeft(12, '0')}';
}
