import 'dart:io';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:test/test.dart';

const _key =
    '0123456789abcdef0123456789abcdef'
    '0123456789abcdef0123456789abcdef';
const _studentId = '00000000-0000-4000-8000-000000000001';

void main() {
  test(
    'Academic Assignment repository persists and enqueues mutations',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'assignment-repo-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final database = await ClinicalCalendarDatabase.open(
        path: '${directory.path}${Platform.pathSeparator}calendar.db',
        secureStorage: _SecureStorage(),
      );
      addTearDown(database.close);
      final registry = SqliteRepositoryRegistry(
        studentId: _studentId,
        database: database,
        identifierGenerator: _Identifiers(),
      );
      await registry.initialize();

      final created = await registry.mutate((repositories) {
        final assignments =
            (repositories as AcademicAssignmentLocalWriteRepositories)
                .academicAssignments;
        return assignments
            .put(
              studentId: _studentId,
              value: AcademicAssignment(
                id: '00000000-0000-4000-8000-000000000010',
                title: 'Evidence review',
                course: 'NURS 702',
                dueDate: LocalDate(2026, 9, 14),
              ),
              expectedRevision: 0,
              mutation: _mutation(1),
            )
            .record;
      });

      expect(created.revision, 1);
      final loaded = await registry.read(
        (repositories) =>
            (repositories as AcademicAssignmentLocalReadRepositories)
                .academicAssignments
                .list(studentId: _studentId)
                .single,
      );
      expect(loaded.value.title, 'Evidence review');
      expect(loaded.value.course, 'NURS 702');
      expect(loaded.value.dueDate, LocalDate(2026, 9, 14));
      expect(
        database.select(
          "SELECT entity_type FROM outbox_operations WHERE entity_id = ?",
          [loaded.value.id],
        ).single['entity_type'],
        'academic_assignment',
      );
    },
  );
}

MutationToken _mutation(int sequence) => MutationToken(
  operationId:
      '10000000-0000-4000-8000-${sequence.toString().padLeft(12, '0')}',
  idempotencyKey:
      '20000000-0000-4000-8000-${sequence.toString().padLeft(12, '0')}',
  occurredAtUtc: DateTime.utc(2026, 8, 10, 12, sequence),
);

final class _Identifiers implements IdentifierGenerator {
  var value = 100;
  @override
  String nextIdentifier() =>
      '30000000-0000-4000-8000-${(++value).toString().padLeft(12, '0')}';
}

final class _SecureStorage implements SecureStorage {
  final values = <String, String>{
    ClinicalCalendarDatabase.encryptionKeyStorageKey: _key,
  };

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
