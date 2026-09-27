import 'dart:io';
import 'dart:math';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

import 'database_failure.dart';
import 'schema_migrations.dart';

Future<({CommonDatabase database, String cipherVersion})>
openEncryptedDatabase({
  required String path,
  required SecureStorage secureStorage,
  required DatabaseMigrationRunner migrationRunner,
  required String encryptionKeyStorageKey,
  required RegExp validKey,
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
  if (!validKey.hasMatch(key)) {
    throw ClinicalCalendarDatabaseException.invalidEncryptionKey();
  }

  await file.parent.create(recursive: true);
  final database = sqlite3.open(path);
  try {
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
    return (database: database, cipherVersion: cipherVersion);
  } on ClinicalCalendarDatabaseException {
    database.close();
    rethrow;
  } on Object {
    database.close();
    throw ClinicalCalendarDatabaseException.migrationFailed();
  }
}

String _generateHexKey() {
  final random = Random.secure();
  return List<int>.generate(
    32,
    (_) => random.nextInt(256),
  ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}
