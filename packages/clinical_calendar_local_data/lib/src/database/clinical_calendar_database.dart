import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:sqlite3/common.dart';

import 'database_open.dart';
import 'database_failure.dart';
import 'schema_migrations.dart';

final class ClinicalCalendarDatabase {
  ClinicalCalendarDatabase._(
    this._database, {
    required this.path,
    required this.cipherVersion,
  });

  static const encryptionKeyStorageKey = 'clinical_calendar_database_key_v1';
  static final RegExp _validKey = RegExp(r'^[0-9a-fA-F]{64}$');

  final CommonDatabase _database;
  final String path;
  final String cipherVersion;
  bool _closed = false;

  int get schemaVersion => _database.userVersion;

  static Future<ClinicalCalendarDatabase> open({
    required String path,
    required SecureStorage secureStorage,
    DatabaseMigrationRunner migrationRunner = const DatabaseMigrationRunner(),
  }) async {
    final opened = await openEncryptedDatabase(
      path: path,
      secureStorage: secureStorage,
      migrationRunner: migrationRunner,
      encryptionKeyStorageKey: encryptionKeyStorageKey,
      validKey: _validKey,
    );
    return ClinicalCalendarDatabase._(
      opened.database,
      path: path,
      cipherVersion: opened.cipherVersion,
    );
  }

  /// Opens the production schema over a caller-owned, process-memory SQLite
  /// connection. No encryption key or filesystem location is created because
  /// the complete database disappears with the connection.
  static ClinicalCalendarDatabase openInMemory(
    CommonDatabase database, {
    DatabaseMigrationRunner migrationRunner = const DatabaseMigrationRunner(),
  }) {
    try {
      database
        ..execute('PRAGMA foreign_keys = ON')
        ..execute('PRAGMA secure_delete = ON');
      final currentVersion = database.userVersion;
      if (currentVersion > DatabaseMigrationRunner.latestVersion) {
        throw ClinicalCalendarDatabaseException.unsupportedSchemaVersion();
      }
      migrationRunner.migrate(database, currentVersion);
      return ClinicalCalendarDatabase._(
        database,
        path: ':memory:',
        cipherVersion: '',
      );
    } on ClinicalCalendarDatabaseException {
      database.close();
      rethrow;
    } on Object {
      database.close();
      throw ClinicalCalendarDatabaseException.migrationFailed();
    }
  }

  ResultSet select(String sql, [List<Object?> parameters = const []]) {
    _requireOpen();
    return _database.select(sql, parameters);
  }

  void execute(String sql, [List<Object?> parameters = const []]) {
    _requireOpen();
    _database.execute(sql, parameters);
  }

  T transaction<T>(T Function() action) {
    _requireOpen();
    _database.execute('BEGIN IMMEDIATE');
    try {
      final result = action();
      _database.execute('COMMIT');
      return result;
    } catch (_) {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _database.close();
  }

  void _requireOpen() {
    if (_closed) throw StateError('The local database is closed.');
  }
}
