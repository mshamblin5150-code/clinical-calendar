import 'dart:convert';
import 'dart:io';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

const _studentId = '00000000-0000-4000-8000-000000000001';
const _key =
    '0123456789abcdef0123456789abcdef'
    '0123456789abcdef0123456789abcdef';
const _createdAt = '2026-08-03T12:00:00.000Z';
const _preceptorId = '00000000-0000-4000-8000-000000000002';
const _placementId = '00000000-0000-4000-8000-000000000003';
const _planId = '00000000-0000-4000-8000-000000000004';
const _legacySettingsId = '00000000-0000-4000-8000-000000000005';

void main() {
  test(
    'version four upgrades terminal outbox and health state atomically',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'clinical-calendar-sync-v4-',
      );
      final path = '${directory.path}${Platform.pathSeparator}calendar.db';
      final raw = sqlite3.open(path);
      raw.execute('PRAGMA key = "x\'$_key\'"');
      final runner = DatabaseMigrationRunner.forTesting((version, _) {
        if (version == 5) throw StateError('stop at version four');
      });
      try {
        runner.migrate(raw, 0);
      } on ClinicalCalendarDatabaseException catch (error) {
        expect(error.kind, DatabaseFailureKind.migrationFailed);
      }
      expect(raw.userVersion, 4);
      raw.execute(
        '''INSERT INTO student_profiles
        (id, student_id, revision, created_at_utc, updated_at_utc, display_name)
        VALUES (?, ?, 0, ?, ?, 'Student')''',
        [_studentId, _studentId, _createdAt, _createdAt],
      );
      raw.execute(
        '''INSERT INTO settings
        (id, student_id, revision, created_at_utc, updated_at_utc)
        VALUES (?, ?, 1, ?, ?)''',
        [_legacySettingsId, _studentId, _createdAt, _createdAt],
      );
      raw.execute(
        '''INSERT INTO outbox_operations
        (id, student_id, idempotency_key, entity_type, entity_id,
         operation_type, base_revision, payload_json, created_at_utc)
        VALUES (?, ?, ?, 'settings', ?, 'upsert', 0, ?, ?)''',
        [
          '00000000-0000-4000-8000-000000000006',
          _studentId,
          '00000000-0000-4000-8000-000000000007',
          _legacySettingsId,
          jsonEncode({
            'schema_version': 1,
            'entity_type': 'settings',
            'entity_id': _legacySettingsId,
            'student_id': _studentId,
            'revision': 1,
            'created_at_utc': _createdAt,
            'updated_at_utc': _createdAt,
            'deleted_at_utc': null,
            'value': <String, Object?>{},
          }),
          _createdAt,
        ],
      );
      raw.close();

      final database = await ClinicalCalendarDatabase.open(
        path: path,
        secureStorage: _Storage(),
      );
      try {
        expect(database.schemaVersion, 5);
        final outboxColumns = database
            .select('PRAGMA table_info(outbox_operations)')
            .map((row) => row['name'])
            .toSet();
        expect(
          outboxColumns,
          containsAll(['terminal_rejection_code', 'terminal_rejected_at_utc']),
        );
        final stateColumns = database
            .select('PRAGMA table_info(sync_state)')
            .map((row) => row['name'])
            .toSet();
        expect(stateColumns, contains('failure_started_at_utc'));
        final indexSql =
            database
                    .select(
                      "SELECT sql FROM sqlite_schema WHERE name = 'outbox_pending_index'",
                    )
                    .single['sql']
                as String;
        expect(indexSql, contains('terminal_rejected_at_utc IS NULL'));
        expect(
          database.select('SELECT id FROM settings').single['id'],
          _studentId,
        );
        final migratedOutbox = database
            .select(
              "SELECT entity_id, payload_json FROM outbox_operations WHERE entity_type = 'settings'",
            )
            .single;
        expect(migratedOutbox['entity_id'], _studentId);
        expect(
          (jsonDecode(migratedOutbox['payload_json'] as String)
              as Map<String, dynamic>)['entity_id'],
          _studentId,
        );
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'attempted random Settings identity fails the migration closed',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'clinical-calendar-sync-v4-attempted-settings-',
      );
      final path = '${directory.path}${Platform.pathSeparator}calendar.db';
      final raw = sqlite3.open(path);
      raw.execute('PRAGMA key = "x\'$_key\'"');
      final runner = DatabaseMigrationRunner.forTesting((version, _) {
        if (version == 5) throw StateError('stop at version four');
      });
      try {
        runner.migrate(raw, 0);
      } on ClinicalCalendarDatabaseException catch (error) {
        expect(error.kind, DatabaseFailureKind.migrationFailed);
      }
      raw.execute(
        '''INSERT INTO student_profiles
      (id, student_id, revision, created_at_utc, updated_at_utc, display_name)
      VALUES (?, ?, 0, ?, ?, 'Student')''',
        [_studentId, _studentId, _createdAt, _createdAt],
      );
      raw.execute(
        '''INSERT INTO settings
      (id, student_id, revision, created_at_utc, updated_at_utc)
      VALUES (?, ?, 1, ?, ?)''',
        [_legacySettingsId, _studentId, _createdAt, _createdAt],
      );
      raw.execute(
        '''INSERT INTO outbox_operations
      (id, student_id, idempotency_key, entity_type, entity_id,
       operation_type, base_revision, payload_json, created_at_utc,
       attempt_count)
      VALUES (?, ?, ?, 'settings', ?, 'upsert', 0, ?, ?, 1)''',
        [
          '00000000-0000-4000-8000-000000000008',
          _studentId,
          '00000000-0000-4000-8000-000000000009',
          _legacySettingsId,
          '{"entity_id":"$_legacySettingsId"}',
          _createdAt,
        ],
      );
      raw.close();

      await expectLater(
        ClinicalCalendarDatabase.open(path: path, secureStorage: _Storage()),
        throwsA(
          isA<ClinicalCalendarDatabaseException>().having(
            (error) => error.kind,
            'kind',
            DatabaseFailureKind.migrationFailed,
          ),
        ),
      );
      final unchanged = sqlite3.open(path);
      unchanged.execute('PRAGMA key = "x\'$_key\'"');
      expect(unchanged.userVersion, 4);
      expect(
        unchanged.select('SELECT id FROM settings').single['id'],
        _legacySettingsId,
      );
      unchanged.close();
      await directory.delete(recursive: true);
    },
  );

  test('Evaluation Plan outbox payload carries its Clinical Placement', () async {
    final directory = await Directory.systemTemp.createTemp(
      'clinical-calendar-sync-payload-',
    );
    final database = await ClinicalCalendarDatabase.open(
      path: '${directory.path}${Platform.pathSeparator}calendar.db',
      secureStorage: _Storage(),
    );
    final identifiers = _Identifiers();
    final registry = SqliteRepositoryRegistry(
      studentId: _studentId,
      database: database,
      identifierGenerator: identifiers,
    );
    await registry.initialize();
    final occurredAt = DateTime.parse(_createdAt);
    final preceptor = Preceptor(id: _preceptorId, name: 'Primary');
    final plan = EvaluationPlan.restore(
      id: _planId,
      configuration: EvaluationPlanConfiguration(
        interimReviewCadenceMinutes: 5400,
      ),
      requirements: const [],
    );
    final placement = ClinicalPlacement.create(
      id: _placementId,
      name: 'Family Medicine',
      targetHours: TargetHours.fromWholeHours(270),
      startDate: LocalDate(2026, 8, 1),
      completionDeadline: LocalDate(2026, 12, 31),
      attachedPreceptorIds: [_preceptorId],
      primaryPreceptorId: _preceptorId,
      evaluationPlanId: _planId,
    );
    try {
      await registry.mutate((repositories) {
        repositories.preceptors.put(
          studentId: _studentId,
          value: preceptor,
          expectedRevision: 0,
          mutation: identifiers.mutation(occurredAt),
        );
        repositories.clinicalPlacements.put(
          studentId: _studentId,
          value: placement,
          expectedRevision: 0,
          mutation: identifiers.mutation(occurredAt),
        );
        repositories.evaluationPlans.put(
          studentId: _studentId,
          value: plan,
          expectedRevision: 0,
          mutation: identifiers.mutation(occurredAt),
        );
      });
      final payload =
          jsonDecode(
                database
                        .select(
                          "SELECT payload_json FROM outbox_operations WHERE entity_type = 'evaluation_plan'",
                        )
                        .single['payload_json']
                    as String,
              )
              as Map<String, dynamic>;
      expect(
        (payload['value'] as Map<String, dynamic>)['placement_id'],
        _placementId,
      );
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}

final class _Identifiers implements IdentifierGenerator {
  var next = 100;

  @override
  String nextIdentifier() =>
      '00000000-0000-4000-8000-${(next++).toString().padLeft(12, '0')}';

  MutationToken mutation(DateTime occurredAtUtc) => MutationToken(
    operationId: nextIdentifier(),
    idempotencyKey: nextIdentifier(),
    occurredAtUtc: occurredAtUtc,
  );
}

final class _Storage implements SecureStorage {
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
