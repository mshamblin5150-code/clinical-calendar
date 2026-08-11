import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import '../ports.dart';
import '../repositories.dart';

final class ClassCatalogApplicationService {
  factory ClassCatalogApplicationService({
    required RepositoryRegistry repositories,
    required Clock clock,
    required IdentifierGenerator identifiers,
    required String studentId,
  }) => ClassCatalogApplicationService._(
    repositories,
    clock,
    identifiers,
    requireIdentifier(studentId, 'Student id'),
  );

  const ClassCatalogApplicationService._(
    this._repositories,
    this._clock,
    this._identifiers,
    this._studentId,
  );

  final RepositoryRegistry _repositories;
  final Clock _clock;
  final IdentifierGenerator _identifiers;
  final String _studentId;

  Future<List<StoredDomainRecord<ClassCatalogEntry>>> list({
    bool includeArchived = false,
  }) => _repositories.read((repositories) {
    final entries = _read(
      repositories,
    ).classCatalogEntries.list(studentId: _studentId);
    entries.removeWhere(
      (record) => !includeArchived && record.value.isArchived,
    );
    entries.sort((left, right) {
      final name = left.value.name.toLowerCase().compareTo(
        right.value.name.toLowerCase(),
      );
      return name != 0 ? name : left.value.id.compareTo(right.value.id);
    });
    return entries;
  });

  Future<StoredDomainRecord<ClassCatalogEntry>> create({
    required String name,
  }) => _repositories.mutate((repositories) {
    final repository = _write(repositories).classCatalogEntries;
    final entry = ClassCatalogEntry(
      id: _identifiers.nextIdentifier(),
      name: name,
    );
    _requireUnique(repository, entry.name);
    return repository
        .put(
          studentId: _studentId,
          value: entry,
          expectedRevision: 0,
          mutation: _mutation(),
        )
        .record;
  });

  Future<StoredDomainRecord<ClassCatalogEntry>> rename({
    required String entryId,
    required int expectedRevision,
    required String name,
  }) => _repositories.mutate((repositories) {
    final repository = _write(repositories).classCatalogEntries;
    final current = _current(repository, entryId, expectedRevision);
    final renamed = current.value.rename(name);
    _requireUnique(repository, renamed.name, exceptId: current.value.id);
    final result = repository
        .put(
          studentId: _studentId,
          value: renamed,
          expectedRevision: expectedRevision,
          mutation: _mutation(),
        )
        .record;
    if (repositories case AcademicAssignmentLocalWriteRepositories capable) {
      final assignments = capable.academicAssignments;
      for (final assignment in assignments.list(studentId: _studentId)) {
        if (assignment.value.courseId != current.value.id) continue;
        assignments.put(
          studentId: _studentId,
          value: assignment.value.copyWith(course: renamed.name),
          expectedRevision: assignment.revision,
          mutation: _mutation(),
        );
      }
    }
    return result;
  });

  Future<StoredDomainRecord<ClassCatalogEntry>> setArchived({
    required String entryId,
    required int expectedRevision,
    required bool archived,
  }) => _repositories.mutate((repositories) {
    final repository = _write(repositories).classCatalogEntries;
    final current = _current(repository, entryId, expectedRevision);
    final changed = archived
        ? current.value.archive()
        : current.value.restore();
    return repository
        .put(
          studentId: _studentId,
          value: changed,
          expectedRevision: expectedRevision,
          mutation: _mutation(),
        )
        .record;
  });

  StoredDomainRecord<ClassCatalogEntry> _current(
    MutableRepository<ClassCatalogEntry> repository,
    String id,
    int expectedRevision,
  ) {
    final current = repository.find(studentId: _studentId, id: id);
    if (current == null) {
      throw const RepositoryException(
        RepositoryFailureKind.notFound,
        'The class or course was not found.',
      );
    }
    if (current.revision != expectedRevision) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'The class or course changed before the edit was saved.',
      );
    }
    return current;
  }

  void _requireUnique(
    ReadRepository<ClassCatalogEntry> repository,
    String name, {
    String? exceptId,
  }) {
    final normalized = name.toLowerCase();
    final duplicate = repository
        .list(studentId: _studentId)
        .any(
          (record) =>
              record.value.id != exceptId &&
              record.value.name.toLowerCase() == normalized,
        );
    if (duplicate) {
      throw const RepositoryException(
        RepositoryFailureKind.persistenceFailure,
        'That class or course is already in the catalog.',
      );
    }
  }

  ClassCatalogLocalReadRepositories _read(LocalReadRepositories repositories) {
    if (repositories case ClassCatalogLocalReadRepositories capable) {
      return capable;
    }
    throw const RepositoryException(
      RepositoryFailureKind.uninitialized,
      'Class catalog persistence is unavailable.',
    );
  }

  ClassCatalogLocalWriteRepositories _write(
    LocalWriteRepositories repositories,
  ) {
    if (repositories case ClassCatalogLocalWriteRepositories capable) {
      return capable;
    }
    throw const RepositoryException(
      RepositoryFailureKind.uninitialized,
      'Class catalog persistence is unavailable.',
    );
  }

  MutationToken _mutation() {
    final now = _clock.nowUtc();
    if (!now.isUtc) throw StateError('Clock.nowUtc() must return UTC.');
    return MutationToken(
      operationId: _identifiers.nextIdentifier(),
      idempotencyKey: _identifiers.nextIdentifier(),
      occurredAtUtc: now,
    );
  }
}
