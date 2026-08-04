import 'dart:convert';
import 'dart:io';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

const _key =
    '0123456789abcdef0123456789abcdef'
    '0123456789abcdef0123456789abcdef';
const _otherKey =
    'abcdefabcdefabcdefabcdefabcdefab'
    'cdefabcdefabcdefabcdefabcdefabcd';
const _studentId = '00000000-0000-4000-8000-000000000001';
const _profileId = '00000000-0000-4000-8000-000000000002';
const _createdAt = '2026-08-03T12:00:00.000Z';

void main() {
  late Directory temporaryDirectory;
  late String databasePath;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'clinical-calendar-database-',
    );
    databasePath =
        '${temporaryDirectory.path}${Platform.pathSeparator}calendar.db';
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'fresh database is SQLCipher encrypted and has complete strict schema',
    () async {
      final keys = MemorySecureStorage();
      final database = await ClinicalCalendarDatabase.open(
        path: databasePath,
        secureStorage: keys,
      );
      var databaseClosed = false;
      addTearDown(() async {
        if (!databaseClosed) await database.close();
      });

      expect(database.cipherVersion, isNotEmpty);
      expect(database.schemaVersion, DatabaseMigrationRunner.latestVersion);
      expect(
        keys.values[ClinicalCalendarDatabase.encryptionKeyStorageKey],
        matches(RegExp(r'^[0-9a-f]{64}$')),
      );

      final expectedTables = <String>{
        'schema_migrations',
        'student_profiles',
        'clinical_placements',
        'preceptors',
        'placement_preceptors',
        'commitments',
        'protected_days',
        'historical_hours_entries',
        'evaluation_plans',
        'evaluation_requirements',
        'schedule_templates',
        'settings',
        'reminder_state',
        'device_metadata',
        'reminder_delivery_state',
        'trash',
        'sync_cursors',
        'sync_state',
        'sync_conflicts',
        'outbox_operations',
        'operational_recovery_snapshots',
        'permanent_purge_markers',
      };
      final tableRows = database.select(
        "SELECT name, strict FROM pragma_table_list WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%'",
      );
      expect(tableRows.map((row) => row['name']).toSet(), expectedTables);
      expect(tableRows.every((row) => row['strict'] == 1), isTrue);
      expect(database.select('PRAGMA foreign_keys').single.values.single, 1);
      expect(database.select('PRAGMA secure_delete').single.values.single, 1);
      expect(
        database.select('PRAGMA journal_mode').single.values.single,
        'wal',
      );
      expect(database.select('PRAGMA synchronous').single.values.single, 2);
      expect(
        database
            .select('SELECT version FROM schema_migrations ORDER BY version')
            .map((row) => row['version']),
        List<int>.generate(
          DatabaseMigrationRunner.latestVersion,
          (index) => index + 1,
        ),
      );

      expect(
        () => database.execute(
          '''INSERT INTO student_profiles
           (id, student_id, revision, created_at_utc, updated_at_utc, display_name)
           VALUES (?, ?, -1, ?, ?, 'Student')''',
          [_profileId, _studentId, _createdAt, _createdAt],
        ),
        throwsA(isA<SqliteException>()),
      );
      expect(
        () => database.execute(
          '''INSERT INTO preceptors
           (id, student_id, revision, created_at_utc, updated_at_utc, name)
           VALUES (?, ?, 0, ?, ?, 'Preceptor')''',
          [
            '00000000-0000-4000-8000-000000000003',
            _studentId,
            _createdAt,
            _createdAt,
          ],
        ),
        throwsA(isA<SqliteException>()),
      );

      await database.close();
      databaseClosed = true;
      final header = await File(databasePath).openRead(0, 16).first;
      expect(
        utf8.decode(header, allowMalformed: true),
        isNot('SQLite format 3\u0000'),
      );
    },
  );

  test('offline close and restart preserves encrypted data', () async {
    final keys = MemorySecureStorage(_key);
    final first = await ClinicalCalendarDatabase.open(
      path: databasePath,
      secureStorage: keys,
    );
    _insertStudent(first, displayName: 'Persisted Student');
    await first.close();

    final reopened = await ClinicalCalendarDatabase.open(
      path: databasePath,
      secureStorage: keys,
    );
    expect(
      reopened
          .select('SELECT display_name FROM student_profiles')
          .single['display_name'],
      'Persisted Student',
    );
    expect(reopened.cipherVersion, isNotEmpty);
    await reopened.close();
  });

  test(
    'wrong key is rejected without modifying or deleting the file',
    () async {
      final database = await ClinicalCalendarDatabase.open(
        path: databasePath,
        secureStorage: MemorySecureStorage(_key),
      );
      _insertStudent(database, displayName: 'Private marker');
      await database.close();
      final before = await File(databasePath).readAsBytes();

      await expectLater(
        ClinicalCalendarDatabase.open(
          path: databasePath,
          secureStorage: MemorySecureStorage(_otherKey),
        ),
        throwsA(
          isA<ClinicalCalendarDatabaseException>().having(
            (error) => error.kind,
            'kind',
            DatabaseFailureKind.authenticationOrCorruption,
          ),
        ),
      );

      expect(await File(databasePath).exists(), isTrue);
      expect(await File(databasePath).readAsBytes(), orderedEquals(before));
    },
  );

  test(
    'existing database without stored key fails without generating one',
    () async {
      final database = await ClinicalCalendarDatabase.open(
        path: databasePath,
        secureStorage: MemorySecureStorage(_key),
      );
      await database.close();
      final before = await File(databasePath).readAsBytes();
      final missingKeys = MemorySecureStorage();

      await expectLater(
        ClinicalCalendarDatabase.open(
          path: databasePath,
          secureStorage: missingKeys,
        ),
        throwsA(
          isA<ClinicalCalendarDatabaseException>().having(
            (error) => error.kind,
            'kind',
            DatabaseFailureKind.missingEncryptionKey,
          ),
        ),
      );
      expect(missingKeys.values, isEmpty);
      expect(await File(databasePath).readAsBytes(), orderedEquals(before));
    },
  );

  test('invalid stored key is rejected before a database is created', () async {
    final keys = MemorySecureStorage('not-a-256-bit-hex-key');
    await expectLater(
      ClinicalCalendarDatabase.open(path: databasePath, secureStorage: keys),
      throwsA(
        isA<ClinicalCalendarDatabaseException>().having(
          (error) => error.kind,
          'kind',
          DatabaseFailureKind.invalidEncryptionKey,
        ),
      ),
    );
    expect(await File(databasePath).exists(), isFalse);
  });

  test(
    'corruption reports sanitized failure and preserves corrupted file',
    () async {
      final database = await ClinicalCalendarDatabase.open(
        path: databasePath,
        secureStorage: MemorySecureStorage(_key),
      );
      _insertStudent(
        database,
        displayName: 'Never include this in diagnostics',
      );
      await database.close();

      final corrupted = await File(databasePath).readAsBytes();
      // Page one contains sqlite_schema, which open() always authenticates.
      corrupted[100] ^= 0xff;
      await File(databasePath).writeAsBytes(corrupted, flush: true);

      ClinicalCalendarDatabaseException? failure;
      ClinicalCalendarDatabase? unexpectedlyOpened;
      try {
        unexpectedlyOpened = await ClinicalCalendarDatabase.open(
          path: databasePath,
          secureStorage: MemorySecureStorage(_key),
        );
      } on ClinicalCalendarDatabaseException catch (error) {
        failure = error;
      } finally {
        await unexpectedlyOpened?.close();
      }
      expect(failure?.kind, DatabaseFailureKind.authenticationOrCorruption);
      expect(failure.toString(), isNot(contains(_key)));
      expect(failure.toString(), isNot(contains('Never include')));
      expect(await File(databasePath).readAsBytes(), orderedEquals(corrupted));
    },
  );

  test(
    'composite foreign keys enforce placement attachment ownership',
    () async {
      const primaryId = '00000000-0000-4000-8000-000000000010';
      const unattachedId = '00000000-0000-4000-8000-000000000011';
      const placementId = '00000000-0000-4000-8000-000000000012';
      final database = await ClinicalCalendarDatabase.open(
        path: databasePath,
        secureStorage: MemorySecureStorage(_key),
      );
      _insertStudent(database, displayName: 'Owner');
      for (final preceptorId in [primaryId, unattachedId]) {
        database.execute(
          '''INSERT INTO preceptors
           (id, student_id, revision, created_at_utc, updated_at_utc, name)
           VALUES (?, ?, 0, ?, ?, 'Preceptor')''',
          [preceptorId, _studentId, _createdAt, _createdAt],
        );
      }
      database.transaction(() {
        database.execute(
          '''INSERT INTO clinical_placements
           (id, student_id, revision, created_at_utc, updated_at_utc, name,
            target_minutes, start_date, completion_deadline, lifecycle_state,
            primary_preceptor_id)
           VALUES (?, ?, 0, ?, ?, 'Placement', 6000, '2026-08-01',
                   '2026-12-31', 'active', ?)''',
          [placementId, _studentId, _createdAt, _createdAt, primaryId],
        );
        database.execute(
          '''INSERT INTO placement_preceptors
           (placement_id, preceptor_id, student_id, attached_at_utc)
           VALUES (?, ?, ?, ?)''',
          [placementId, primaryId, _studentId, _createdAt],
        );
      });

      expect(
        () => database.execute(
          '''INSERT INTO historical_hours_entries
           (id, student_id, revision, created_at_utc, updated_at_utc,
            placement_id, preceptor_id, completed_minutes, effective_date)
           VALUES (?, ?, 0, ?, ?, ?, ?, 60, '2026-08-02')''',
          [
            '00000000-0000-4000-8000-000000000013',
            _studentId,
            _createdAt,
            _createdAt,
            placementId,
            unattachedId,
          ],
        ),
        throwsA(isA<SqliteException>()),
      );
      await database.close();
    },
  );

  test('v1 fixture upgrades to latest without losing prior data', () async {
    await _createFixture(databasePath, version: 1);
    final database = await ClinicalCalendarDatabase.open(
      path: databasePath,
      secureStorage: MemorySecureStorage(_key),
    );
    expect(database.schemaVersion, DatabaseMigrationRunner.latestVersion);
    expect(
      database
          .select('SELECT display_name FROM student_profiles')
          .single['display_name'],
      'Fixture v1',
    );
    expect(
      database
          .select(
            "SELECT count(*) AS count FROM sqlite_schema WHERE name = 'outbox_operations'",
          )
          .single['count'],
      1,
    );
    await database.close();
  });

  test('v2 fixture upgrades to latest without losing prior data', () async {
    await _createFixture(databasePath, version: 2);
    final database = await ClinicalCalendarDatabase.open(
      path: databasePath,
      secureStorage: MemorySecureStorage(_key),
    );
    expect(database.schemaVersion, DatabaseMigrationRunner.latestVersion);
    expect(
      database
          .select('SELECT display_name FROM student_profiles')
          .single['display_name'],
      'Fixture v2',
    );
    expect(
      database
          .select(
            "SELECT count(*) AS count FROM sqlite_schema WHERE name = 'outbox_pending_index'",
          )
          .single['count'],
      1,
    );
    await database.close();
  });

  test('repeated open is idempotent', () async {
    final keys = MemorySecureStorage(_key);
    final first = await ClinicalCalendarDatabase.open(
      path: databasePath,
      secureStorage: keys,
    );
    await first.close();
    final second = await ClinicalCalendarDatabase.open(
      path: databasePath,
      secureStorage: keys,
    );
    expect(
      second
          .select('SELECT count(*) AS count FROM schema_migrations')
          .single['count'],
      DatabaseMigrationRunner.latestVersion,
    );
    await second.close();
  });

  test('newer schema is rejected without changing its version', () async {
    final raw = _openRaw(databasePath);
    raw.userVersion = DatabaseMigrationRunner.latestVersion + 1;
    raw.close();
    final before = await File(databasePath).readAsBytes();

    await expectLater(
      ClinicalCalendarDatabase.open(
        path: databasePath,
        secureStorage: MemorySecureStorage(_key),
      ),
      throwsA(
        isA<ClinicalCalendarDatabaseException>().having(
          (error) => error.kind,
          'kind',
          DatabaseFailureKind.unsupportedSchemaVersion,
        ),
      ),
    );
    expect(await File(databasePath).readAsBytes(), orderedEquals(before));
  });

  test('interrupted migration rolls back schema, version, and data', () async {
    await _createFixture(databasePath, version: 2);
    await expectLater(
      ClinicalCalendarDatabase.open(
        path: databasePath,
        secureStorage: MemorySecureStorage(_key),
        migrationRunner: DatabaseMigrationRunner.forTesting((version, raw) {
          if (version == 3) {
            raw
              ..execute('CREATE TABLE partial_migration_artifact (id INTEGER)')
              ..execute(
                "UPDATE student_profiles SET display_name = 'partial value'",
              );
            throw StateError('simulated interruption');
          }
        }),
      ),
      throwsA(
        isA<ClinicalCalendarDatabaseException>().having(
          (error) => error.kind,
          'kind',
          DatabaseFailureKind.migrationFailed,
        ),
      ),
    );

    final raw = _openRaw(databasePath);
    expect(raw.userVersion, 2);
    expect(
      raw
          .select(
            "SELECT count(*) AS count FROM sqlite_schema WHERE name = 'partial_migration_artifact'",
          )
          .single['count'],
      0,
    );
    expect(
      raw
          .select('SELECT display_name FROM student_profiles')
          .single['display_name'],
      'Fixture v2',
    );
    expect(
      raw
          .select(
            "SELECT count(*) AS count FROM sqlite_schema WHERE name = 'outbox_pending_index'",
          )
          .single['count'],
      0,
    );
    raw.close();
  });
}

final class MemorySecureStorage implements SecureStorage {
  MemorySecureStorage([String? initialValue]) {
    if (initialValue != null) {
      values[ClinicalCalendarDatabase.encryptionKeyStorageKey] = initialValue;
    }
  }

  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void _insertStudent(
  ClinicalCalendarDatabase database, {
  required String displayName,
}) {
  database.execute(
    '''INSERT INTO student_profiles
       (id, student_id, revision, created_at_utc, updated_at_utc, display_name)
       VALUES (?, ?, 0, ?, ?, ?)''',
    [_profileId, _studentId, _createdAt, _createdAt, displayName],
  );
}

Database _openRaw(String path) {
  final database = sqlite3.open(path);
  database.execute('PRAGMA key = "x\'$_key\'"');
  return database;
}

Future<void> _createFixture(String path, {required int version}) async {
  final database = _openRaw(path);
  final runner = DatabaseMigrationRunner.forTesting((targetVersion, raw) {
    if (targetVersion == version + 1) {
      throw StateError('stop after fixture version');
    }
  });
  try {
    runner.migrate(database, 0);
  } on ClinicalCalendarDatabaseException catch (error) {
    expect(error.kind, DatabaseFailureKind.migrationFailed);
  }
  expect(database.userVersion, version);
  database.execute(
    '''INSERT INTO student_profiles
       (id, student_id, revision, created_at_utc, updated_at_utc, display_name)
       VALUES (?, ?, 0, ?, ?, ?)''',
    [_profileId, _studentId, _createdAt, _createdAt, 'Fixture v$version'],
  );
  database.close();
}
