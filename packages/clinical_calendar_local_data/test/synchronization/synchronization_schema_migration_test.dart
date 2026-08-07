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
    'pre-catalog settings migrate to variant-f in storage and pending synchronization',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'clinical-calendar-settings-v13-',
      );
      final path = '${directory.path}${Platform.pathSeparator}calendar.db';
      final raw = sqlite3.open(path);
      raw.execute('PRAGMA key = "x\'$_key\'"');
      final runner = DatabaseMigrationRunner.forTesting((version, _) {
        if (version == 13) throw StateError('stop at version twelve');
      });
      try {
        runner.migrate(raw, 0);
      } on ClinicalCalendarDatabaseException catch (error) {
        expect(error.kind, DatabaseFailureKind.migrationFailed);
      }
      expect(raw.userVersion, 12);
      raw.execute(
        '''INSERT INTO student_profiles
        (id, student_id, revision, created_at_utc, updated_at_utc, display_name)
        VALUES (?, ?, 0, ?, ?, 'Student')''',
        [_studentId, _studentId, _createdAt, _createdAt],
      );
      raw.execute(
        '''INSERT INTO settings
        (id, student_id, revision, created_at_utc, updated_at_utc, theme)
        VALUES (?, ?, 1, ?, ?, 'borg_tactical')''',
        [_studentId, _studentId, _createdAt, _createdAt],
      );
      raw.execute(
        '''INSERT INTO outbox_operations
        (id, student_id, idempotency_key, entity_type, entity_id,
         operation_type, base_revision, payload_json, created_at_utc)
        VALUES (?, ?, ?, 'settings', ?, 'upsert', 0, ?, ?)''',
        [
          '00000000-0000-4000-8000-000000000098',
          _studentId,
          '00000000-0000-4000-8000-000000000099',
          _studentId,
          jsonEncode({
            'value': {'theme': 'borg_tactical'},
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
        final settings = database.select('SELECT * FROM settings').single;
        expect(settings['theme'], StudentSettings.variantFThemeId);
        expect(settings['enhanced_accessibility'], 0);
        final payload =
            jsonDecode(
                  database
                          .select(
                            "SELECT payload_json FROM outbox_operations WHERE entity_type = 'settings'",
                          )
                          .single['payload_json']
                      as String,
                )
                as Map<String, dynamic>;
        expect(payload['value']['theme'], StudentSettings.variantFThemeId);
        expect(payload['value']['enhanced_accessibility'], isFalse);
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'version four upgrades sync health and conflict evidence atomically',
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
        expect(database.schemaVersion, DatabaseMigrationRunner.latestVersion);
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
        final conflictColumns = database
            .select('PRAGMA table_info(sync_conflicts)')
            .map((row) => row['name'])
            .toSet();
        expect(
          conflictColumns,
          containsAll(['rejection_code', 'rejection_json']),
        );
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

  test(
    'version ten requeues relationship rejections with fresh identities once',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'clinical-calendar-sync-v10-retry-',
      );
      final path = '${directory.path}${Platform.pathSeparator}calendar.db';
      final raw = sqlite3.open(path);
      raw.execute('PRAGMA key = "x\'$_key\'"');
      final runner = DatabaseMigrationRunner.forTesting((version, _) {
        if (version == 10) throw StateError('stop at version nine');
      });
      try {
        runner.migrate(raw, 0);
      } on ClinicalCalendarDatabaseException catch (error) {
        expect(error.kind, DatabaseFailureKind.migrationFailed);
      }
      expect(raw.userVersion, 9);
      raw.execute(
        '''INSERT INTO student_profiles
        (id, student_id, revision, created_at_utc, updated_at_utc, display_name)
        VALUES (?, ?, 0, ?, ?, 'Student')''',
        [_studentId, _studentId, _createdAt, _createdAt],
      );
      const rejectedId = '00000000-0000-4000-8000-000000000010';
      const rejectedKey = '00000000-0000-4000-8000-000000000011';
      raw.execute(
        '''INSERT INTO outbox_operations
        (id, student_id, idempotency_key, entity_type, entity_id,
         operation_type, base_revision, payload_json, created_at_utc,
         attempt_count, last_failure_code, terminal_rejection_code,
         terminal_rejected_at_utc)
        VALUES (?, ?, ?, 'evaluation_plan', ?, 'upsert', 0, ?, ?, 1,
          'relationship_violation', 'relationship_violation', ?)''',
        [
          rejectedId,
          _studentId,
          rejectedKey,
          _planId,
          '{"entity_id":"$_planId"}',
          _createdAt,
          _createdAt,
        ],
      );

      const DatabaseMigrationRunner().migrate(raw, 9);

      expect(raw.userVersion, DatabaseMigrationRunner.latestVersion);
      final rows = raw.select(
        '''SELECT * FROM outbox_operations
        WHERE entity_type = 'evaluation_plan' ORDER BY terminal_rejected_at_utc''',
      );
      expect(rows, hasLength(2));
      final retry = rows.firstWhere(
        (row) => row['terminal_rejected_at_utc'] == null,
      );
      expect(retry['id'], isNot(rejectedId));
      expect(retry['idempotency_key'], isNot(rejectedKey));
      expect(
        retry['id'],
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(retry['attempt_count'], 0);
      expect(retry['last_failure_code'], isNull);
      expect(retry['terminal_rejection_code'], isNull);
      expect(rows.singleWhere((row) => row['id'] == rejectedId), isNotNull);

      raw.close();
      await directory.delete(recursive: true);
    },
  );

  test(
    'version eleven resolves only relationship conflicts with accepted retries',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'clinical-calendar-sync-v11-recovery-',
      );
      final path = '${directory.path}${Platform.pathSeparator}calendar.db';
      final raw = sqlite3.open(path);
      raw.execute('PRAGMA key = "x\'$_key\'"');
      final runner = DatabaseMigrationRunner.forTesting((version, _) {
        if (version == 11) throw StateError('stop at version ten');
      });
      try {
        runner.migrate(raw, 0);
      } on ClinicalCalendarDatabaseException catch (error) {
        expect(error.kind, DatabaseFailureKind.migrationFailed);
      }
      expect(raw.userVersion, 10);
      raw.execute(
        '''INSERT INTO student_profiles
        (id, student_id, revision, created_at_utc, updated_at_utc, display_name)
        VALUES (?, ?, 0, ?, ?, 'Student')''',
        [_studentId, _studentId, _createdAt, _createdAt],
      );
      const payload = '{"entity_id":"$_planId"}';
      const acceptedAt = '2026-08-04T19:00:00.000Z';
      raw.execute(
        '''INSERT INTO outbox_operations
        (id, student_id, idempotency_key, entity_type, entity_id,
         operation_type, base_revision, payload_json, created_at_utc,
         attempt_count, last_failure_code, terminal_rejection_code,
         terminal_rejected_at_utc)
        VALUES ('00000000-0000-4000-8000-000000000020', ?,
          '00000000-0000-4000-8000-000000000021', 'evaluation_plan', ?,
          'upsert', 0, ?, ?, 1, 'relationship_violation',
          'relationship_violation', ?)''',
        [_studentId, _planId, payload, _createdAt, _createdAt],
      );
      raw.execute(
        '''INSERT INTO outbox_operations
        (id, student_id, idempotency_key, entity_type, entity_id,
         operation_type, base_revision, payload_json, created_at_utc,
         attempt_count, acknowledged_cursor, acknowledged_at_utc)
        VALUES ('00000000-0000-4000-8000-000000000022', ?,
          '00000000-0000-4000-8000-000000000023', 'evaluation_plan', ?,
          'upsert', 0, ?, ?, 0, 8, ?)''',
        [_studentId, _planId, payload, _createdAt, acceptedAt],
      );
      raw.execute(
        '''INSERT INTO sync_conflicts
        (id, student_id, revision, created_at_utc, updated_at_utc,
         entity_type, entity_id, local_revision, remote_revision,
         local_snapshot_json, remote_snapshot_json, detected_at_utc,
         rejection_code, rejection_json)
        VALUES ('00000000-0000-4000-8000-000000000024', ?, 1, ?, ?,
          'evaluation_plan', ?, 1, 0, ?,
          '{"code":"relationship_violation"}', ?,
          'relationship_violation', '{"code":"relationship_violation"}')''',
        [_studentId, _createdAt, _createdAt, _planId, payload, _createdAt],
      );

      const DatabaseMigrationRunner().migrate(raw, 10);

      final conflict = raw.select('SELECT * FROM sync_conflicts').single;
      expect(conflict['resolved_at_utc'], acceptedAt);
      expect(conflict['updated_at_utc'], acceptedAt);
      expect(conflict['revision'], 2);
      expect(conflict['resolution_json'], contains('automatic_retry'));

      raw.close();
      await directory.delete(recursive: true);
    },
  );

  test(
    'version twelve requeues the rejected synchronized reminder once',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'clinical-calendar-sync-v12-reminder-',
      );
      final path = '${directory.path}${Platform.pathSeparator}calendar.db';
      final raw = sqlite3.open(path);
      raw.execute('PRAGMA key = "x\'$_key\'"');
      final runner = DatabaseMigrationRunner.forTesting((version, _) {
        if (version == 12) throw StateError('stop at version eleven');
      });
      try {
        runner.migrate(raw, 0);
      } on ClinicalCalendarDatabaseException catch (error) {
        expect(error.kind, DatabaseFailureKind.migrationFailed);
      }
      expect(raw.userVersion, 11);
      raw.execute(
        '''INSERT INTO student_profiles
        (id, student_id, revision, created_at_utc, updated_at_utc, display_name)
        VALUES (?, ?, 0, ?, ?, 'Student')''',
        [_studentId, _studentId, _createdAt, _createdAt],
      );
      const reminderId = '00000000-0000-4000-8000-000000000030';
      const rejectedId = '00000000-0000-4000-8000-000000000031';
      const rejectedKey = '00000000-0000-4000-8000-000000000032';
      raw.execute(
        '''INSERT INTO outbox_operations
        (id, student_id, idempotency_key, entity_type, entity_id,
         operation_type, base_revision, payload_json, created_at_utc,
         attempt_count, last_failure_code, terminal_rejection_code,
         terminal_rejected_at_utc)
        VALUES (?, ?, ?, 'reminder_state', ?, 'upsert', 0, ?, ?, 1,
          'invalid_request', 'invalid_request', ?)''',
        [
          rejectedId,
          _studentId,
          rejectedKey,
          reminderId,
          '{"entity_id":"$reminderId","revision":1}',
          _createdAt,
          _createdAt,
        ],
      );

      const DatabaseMigrationRunner().migrate(raw, 11);

      final rows = raw.select(
        "SELECT * FROM outbox_operations WHERE entity_type = 'reminder_state'",
      );
      expect(rows, hasLength(2));
      final retry = rows.singleWhere(
        (row) => row['terminal_rejected_at_utc'] == null,
      );
      expect(retry['id'], isNot(rejectedId));
      expect(retry['idempotency_key'], isNot(rejectedKey));
      expect(retry['attempt_count'], 0);
      expect(retry['last_failure_code'], isNull);

      raw.close();
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
