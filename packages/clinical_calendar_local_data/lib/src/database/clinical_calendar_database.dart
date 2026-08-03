import 'dart:io';
import 'dart:math';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:sqlite3/sqlite3.dart';

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

  final Database _database;
  final String path;
  final String cipherVersion;
  bool _closed = false;

  int get schemaVersion => _database.userVersion;

  static Future<ClinicalCalendarDatabase> open({
    required String path,
    required SecureStorage secureStorage,
    DatabaseMigrationRunner migrationRunner = const DatabaseMigrationRunner(),
  }) async {
    final file = File(path);
    final existed = await file.exists();
    var key = await secureStorage.read(encryptionKeyStorageKey);
    if (key == null) {
      if (existed) {
        throw ClinicalCalendarDatabaseException.missingEncryptionKey();
      }
      key = _generateHexKey();
      await secureStorage.write(encryptionKeyStorageKey, key);
    }
    if (!_validKey.hasMatch(key)) {
      throw ClinicalCalendarDatabaseException.invalidEncryptionKey();
    }

    await file.parent.create(recursive: true);
    final database = sqlite3.open(path);
    try {
      // Hex is validated above, so no SQL syntax or data can be injected here.
      database.execute('PRAGMA key = "x\'$key\'"');
      final cipherRows = database.select('PRAGMA cipher_version');
      final cipherVersion = cipherRows.isEmpty
          ? ''
          : (cipherRows.first.values.firstOrNull?.toString() ?? '').trim();
      if (cipherVersion.isEmpty) {
        throw ClinicalCalendarDatabaseException.sqlCipherUnavailable();
      }

      int currentVersion;
      try {
        // Force an authenticated page/schema read before any pragma that could
        // write the database or create a journal sidecar.
        database.select('SELECT count(*) FROM sqlite_schema').single;
        currentVersion = database.userVersion;
      } on SqliteException {
        throw ClinicalCalendarDatabaseException.authenticationOrCorruption();
      }
      if (currentVersion > DatabaseMigrationRunner.latestVersion) {
        throw ClinicalCalendarDatabaseException.unsupportedSchemaVersion();
      }

      database
        ..execute('PRAGMA foreign_keys = ON')
        ..execute('PRAGMA secure_delete = ON')
        ..execute('PRAGMA journal_mode = WAL')
        ..execute('PRAGMA synchronous = FULL')
        ..execute('PRAGMA busy_timeout = 5000');
      migrationRunner.migrate(database, currentVersion);
      return ClinicalCalendarDatabase._(
        database,
        path: path,
        cipherVersion: cipherVersion,
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

  static String _generateHexKey() {
    final random = Random.secure();
    return List<int>.generate(
      32,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
