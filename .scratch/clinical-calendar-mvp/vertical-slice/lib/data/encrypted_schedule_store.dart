import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../domain/scheduling.dart';
import 'session_repository.dart';

abstract interface class EncryptionKeyStore {
  Future<String?> read();

  Future<void> write(String value);
}

final class PlatformEncryptionKeyStore implements EncryptionKeyStore {
  PlatformEncryptionKeyStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _keyName = 'clinical_calendar_database_key_v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _keyName);

  @override
  Future<void> write(String value) =>
      _storage.write(key: _keyName, value: value);
}

final class FixedEncryptionKeyStore implements EncryptionKeyStore {
  FixedEncryptionKeyStore(this.value);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

final class EncryptedScheduleStore implements SessionRepository {
  EncryptedScheduleStore._(this._database, this.path, this.cipherVersion);

  final Database _database;
  final String path;
  final String cipherVersion;

  static Future<EncryptedScheduleStore> open({
    EncryptionKeyStore? keyStore,
    String? databasePath,
  }) async {
    final keys = keyStore ?? PlatformEncryptionKeyStore();
    var key = await keys.read();
    if (key == null) {
      key = _generateHexKey();
      await keys.write(key);
    }

    final path = databasePath ?? await _defaultDatabasePath();
    await Directory(File(path).parent.path).create(recursive: true);
    final database = sqlite3.open(path);
    try {
      database.execute('PRAGMA key = "x\'$key\'"');
      final cipherRows = database.select('PRAGMA cipher_version');
      final version = cipherRows.isEmpty
          ? ''
          : (cipherRows.first.values.firstOrNull?.toString() ?? '');
      if (version.isEmpty) {
        throw StateError(
          'The bundled SQLite library does not provide SQLCipher.',
        );
      }
      database.execute('''
        CREATE TABLE IF NOT EXISTS clinical_sessions (
          id TEXT PRIMARY KEY NOT NULL,
          local_date TEXT NOT NULL,
          start_minutes INTEGER NOT NULL,
          end_minutes INTEGER NOT NULL,
          time_zone TEXT NOT NULL,
          commitment_type TEXT NOT NULL
        )
      ''');
      return EncryptedScheduleStore._(database, path, version);
    } catch (_) {
      database.close();
      rethrow;
    }
  }

  static Future<String> _defaultDatabasePath() async {
    final support = await getApplicationSupportDirectory();
    return '${support.path}${Platform.pathSeparator}clinical_calendar.db';
  }

  static String _generateHexKey() {
    final random = Random.secure();
    return List.generate(
      32,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  Future<List<ScheduleCommitment>> loadAll() async {
    final rows = _database.select('''
      SELECT id, local_date, start_minutes, end_minutes, time_zone,
             commitment_type
      FROM clinical_sessions
      ORDER BY local_date, start_minutes
    ''');
    return rows
        .map((row) {
          return ScheduleCommitment(
            id: row['id'] as String,
            date: DateTime.parse(row['local_date'] as String),
            startMinutes: row['start_minutes'] as int,
            endMinutes: row['end_minutes'] as int,
            timeZone: row['time_zone'] as String,
            type: CommitmentType.values.byName(
              row['commitment_type'] as String,
            ),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> save(ScheduleCommitment commitment) async {
    _database.execute(
      '''
      INSERT INTO clinical_sessions (
        id, local_date, start_minutes, end_minutes, time_zone, commitment_type
      ) VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [
        commitment.id,
        _dateOnly(commitment.date),
        commitment.startMinutes,
        commitment.endMinutes,
        commitment.timeZone,
        commitment.type.name,
      ],
    );
  }

  @override
  Future<void> close() async => _database.close();
}

String _dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
