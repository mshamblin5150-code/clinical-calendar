import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:sqlite3/sqlite3.dart';

import '../database/clinical_calendar_database.dart';
import '../database/schema_migrations.dart';
import 'portable_backup_crypto.dart';
import 'portable_backup_models.dart';

const _payloadVersion = 2;
const _logicalTables = <String>[
  'student_profiles',
  'preceptors',
  'clinical_placements',
  'placement_preceptors',
  'commitments',
  'protected_days',
  'historical_hours_entries',
  'evaluation_plans',
  'evaluation_requirements',
  'schedule_templates',
  'settings',
  'reminder_state',
  'trash',
];

const _primaryKeys = <String, List<String>>{
  'student_profiles': ['id'],
  'preceptors': ['id'],
  'clinical_placements': ['id'],
  'placement_preceptors': ['placement_id', 'preceptor_id'],
  'commitments': ['id'],
  'protected_days': ['id'],
  'historical_hours_entries': ['id'],
  'evaluation_plans': ['id'],
  'evaluation_requirements': ['id'],
  'schedule_templates': ['id'],
  'settings': ['id'],
  'reminder_state': ['id'],
  'trash': ['id'],
};

/// Tables deliberately excluded because they contain local operational state,
/// device state, or synchronization retry/cursor identity.
const excludedPortableBackupTables = <String>{
  'schema_migrations',
  'device_metadata',
  'reminder_delivery_state',
  'sync_cursors',
  'sync_state',
  'sync_conflicts',
  'outbox_operations',
  'operational_recovery_snapshots',
  'permanent_purge_markers',
};

final class PortableBackupService {
  PortableBackupService({
    required this.database,
    required String studentId,
    required RestoreSynchronizationIntentSink synchronizationIntentSink,
    PortableBackupCrypto? crypto,
    this.migrator = const DefaultPortableBackupMigrator(),
  }) : _studentId = _uuid(studentId),
       _intentSink = synchronizationIntentSink,
       _crypto = crypto ?? PortableBackupCrypto();

  final ClinicalCalendarDatabase database;
  final String _studentId;
  final RestoreSynchronizationIntentSink _intentSink;
  final PortableBackupCrypto _crypto;
  final PortableBackupMigrator migrator;

  /// Revalidates the complete logical dataset through an isolated in-memory
  /// schema copy. Callers use this immediately before committing recovery.
  void validateCurrentState() => _validateDataset(_readCurrentTables());

  /// Creates a logical recovery copy inside the encrypted local database.
  /// Unlike a portable backup this payload is not independently encrypted;
  /// it never leaves the SQLCipher file.
  String createOperationalSnapshotPayload({required DateTime createdAtUtc}) {
    if (!createdAtUtc.isUtc) {
      throw ArgumentError.value(createdAtUtc, 'createdAtUtc', 'must be UTC');
    }
    final tables = database.transaction(_readCurrentTables);
    _validateDataset(tables);
    return canonicalJson({
      'payload_version': _payloadVersion,
      'source_database_schema_version': database.schemaVersion,
      'student_id': _studentId,
      'created_at_utc': createdAtUtc.toIso8601String(),
      'tables': _encodeTables(tables),
    });
  }

  Future<PortableRestorePreview> previewOperationalRestore({
    required String payloadJson,
  }) async {
    try {
      final raw = jsonDecode(payloadJson);
      if (raw is! Map<String, dynamic> || raw['student_id'] != _studentId) {
        throw const FormatException();
      }
      final migrated = migrator.migrate(Map<String, Object?>.from(raw));
      final tables = _decodeTables(migrated['tables']);
      _validateDataset(tables);
      final decoded = _DecodedBackup(
        _studentId,
        DateTime.parse(migrated['created_at_utc'] as String).toUtc(),
        tables,
      );
      return _previewDecoded(decoded);
    } on PortableBackupException {
      rethrow;
    } on Object catch (error) {
      throw PortableBackupException(
        PortableBackupFailureKind.invalidRecord,
        'The recovery snapshot is invalid.',
        cause: error,
      );
    }
  }

  Future<List<int>> createEncryptedBackup({
    required String passphrase,
    required DateTime createdAtUtc,
  }) async {
    if (!createdAtUtc.isUtc) {
      throw ArgumentError.value(createdAtUtc, 'createdAtUtc', 'must be UTC');
    }
    final tables = database.transaction(_readCurrentTables);
    final content = <String, Object?>{
      'payload_version': _payloadVersion,
      'source_database_schema_version': database.schemaVersion,
      'student_id': _studentId,
      'created_at_utc': createdAtUtc.toIso8601String(),
      'tables': _encodeTables(tables),
    };
    final digest = await Sha256().hash(utf8.encode(canonicalJson(content)));
    final plaintext = utf8.encode(
      canonicalJson({
        ...content,
        'checksum_sha256': base64Url.encode(digest.bytes),
      }),
    );
    try {
      return await _crypto.encrypt(
        plaintext: plaintext,
        passphrase: passphrase,
      );
    } finally {
      plaintext.fillRange(0, plaintext.length, 0);
    }
  }

  Future<PortableRestorePreview> previewRestore({
    required List<int> encryptedBytes,
    required String passphrase,
  }) async {
    final decoded = await _decryptAndValidate(encryptedBytes, passphrase);
    return _previewDecoded(decoded);
  }

  PortableRestorePreview _previewDecoded(_DecodedBackup decoded) {
    final local = database.transaction(_readCurrentTables);
    final items = <RestoreMergeItem>[];
    for (final table in _logicalTables) {
      final localByIdentity = _byIdentity(table, local[table]!);
      final backupByIdentity = _byIdentity(table, decoded.tables[table]!);
      final identities = {
        ...localByIdentity.keys,
        ...backupByIdentity.keys,
      }.toList()..sort();
      for (final identity in identities) {
        final localRow = localByIdentity[identity];
        final backupRow = backupByIdentity[identity];
        if (backupRow == null) continue;
        final disposition = _disposition(localRow, backupRow);
        items.add(
          RestoreMergeItem(
            identity: identity,
            disposition: disposition,
            localRevision: _revision(localRow),
            backupRevision: _revision(backupRow),
          ),
        );
      }
    }
    return PortableRestorePreview.validated(
      studentId: decoded.studentId,
      createdAtUtc: decoded.createdAtUtc,
      items: List.unmodifiable(items),
      decodedTables: decoded.tables,
    );
  }

  Future<PortableRestoreResult> applyRestore({
    required PortableRestorePreview preview,
    Map<BackupRecordIdentity, RestoreConflictChoice> conflictChoices = const {},
  }) async {
    if (preview.studentId != _studentId) {
      throw const PortableBackupException(
        PortableBackupFailureKind.ownerMismatch,
        'The backup belongs to a different Student.',
      );
    }
    final unresolved = preview.conflicts.where(
      (item) => !conflictChoices.containsKey(item.identity),
    );
    if (unresolved.isNotEmpty) {
      throw const PortableBackupException(
        PortableBackupFailureKind.unresolvedConflicts,
        'Every genuine restore conflict requires a choice.',
      );
    }

    try {
      return database.transaction(() {
        final current = _readCurrentTables();
        final merged = {
          for (final table in _logicalTables)
            table: current[table]!.map(Map<String, Object?>.from).toList(),
        };
        final applied = <RestoreSynchronizationIntent>[];
        var unchanged = 0;
        for (final item in preview.items) {
          final source = _byIdentity(
            item.identity.table,
            preview.decodedTables[item.identity.table]!,
          )[item.identity]!;
          final currentByIdentity = _byIdentity(
            item.identity.table,
            merged[item.identity.table]!,
          );
          final liveDisposition = _disposition(
            currentByIdentity[item.identity],
            source,
          );
          if (liveDisposition == RestoreMergeDisposition.conflict &&
              !conflictChoices.containsKey(item.identity)) {
            throw const PortableBackupException(
              PortableBackupFailureKind.unresolvedConflicts,
              'Current data changed and now requires a restore choice.',
            );
          }
          final useBackup = switch (liveDisposition) {
            RestoreMergeDisposition.add ||
            RestoreMergeDisposition.useBackup => true,
            RestoreMergeDisposition.keepLocal => false,
            RestoreMergeDisposition.conflict =>
              conflictChoices[item.identity] == RestoreConflictChoice.useBackup,
          };
          if (!useBackup) {
            unchanged++;
            continue;
          }
          _replaceByIdentity(
            merged[item.identity.table]!,
            item.identity,
            source,
          );
          applied.add(
            RestoreSynchronizationIntent(
              identity: item.identity,
              row: Map.unmodifiable(source),
            ),
          );
        }
        _validateDataset(merged);
        for (final table in _logicalTables) {
          final tableIntents = applied.where(
            (intent) => intent.identity.table == table,
          );
          for (final intent in tableIntents) {
            _upsert(table, intent.row);
          }
        }
        _intentSink.recordFreshIntents(List.unmodifiable(applied));
        return PortableRestoreResult(
          applied: applied.length,
          unchanged: unchanged,
        );
      });
    } on PortableBackupException {
      rethrow;
    } on Object catch (error) {
      throw PortableBackupException(
        PortableBackupFailureKind.applyFailed,
        'The restore failed and no changes were applied.',
        cause: error,
      );
    }
  }

  Future<_DecodedBackup> _decryptAndValidate(
    List<int> encryptedBytes,
    String passphrase,
  ) async {
    final plaintext = await _crypto.decrypt(
      containerBytes: encryptedBytes,
      passphrase: passphrase,
    );
    try {
      final value = jsonDecode(utf8.decode(plaintext));
      if (value is! Map<String, dynamic>) throw const FormatException();
      final raw = Map<String, Object?>.from(value);
      final checksum = raw.remove('checksum_sha256');
      if (checksum is! String) throw const FormatException();
      final digest = await Sha256().hash(utf8.encode(canonicalJson(raw)));
      if (!_constantTimeEquals(base64Url.decode(checksum), digest.bytes)) {
        throw const PortableBackupException(
          PortableBackupFailureKind.checksumMismatch,
          'The backup checksum is invalid.',
        );
      }
      final migrated = migrator.migrate(raw);
      final sourceVersion = migrated['source_database_schema_version'];
      if (sourceVersion is! int) throw const FormatException();
      if (sourceVersion > DatabaseMigrationRunner.latestVersion) {
        throw const PortableBackupException(
          PortableBackupFailureKind.unsupportedNewerVersion,
          'The backup contains a newer unsupported data schema.',
        );
      }
      if (migrated['payload_version'] != _payloadVersion) {
        throw const PortableBackupException(
          PortableBackupFailureKind.unsupportedOlderVersion,
          'The backup payload version is unsupported.',
        );
      }
      final owner = _uuid(migrated['student_id'] as String);
      if (owner != _studentId) {
        throw const PortableBackupException(
          PortableBackupFailureKind.ownerMismatch,
          'The backup belongs to a different Student.',
        );
      }
      final created = DateTime.parse(
        migrated['created_at_utc'] as String,
      ).toUtc();
      final tables = _decodeTables(migrated['tables']);
      _validateDataset(tables);
      return _DecodedBackup(owner, created, tables);
    } on PortableBackupException {
      rethrow;
    } on Object catch (error) {
      throw PortableBackupException(
        PortableBackupFailureKind.invalidRecord,
        'The backup contains invalid application records.',
        cause: error,
      );
    } finally {
      plaintext.fillRange(0, plaintext.length, 0);
    }
  }

  Map<String, List<Map<String, Object?>>> _readCurrentTables() => {
    for (final table in _logicalTables)
      table: database
          .select(
            'SELECT * FROM $table WHERE student_id = ? ORDER BY ${_primaryKeys[table]!.join(', ')}',
            [_studentId],
          )
          .map((row) => Map<String, Object?>.from(row))
          .toList(growable: false),
  };

  void _validateDataset(Map<String, List<Map<String, Object?>>> tables) {
    if (tables.keys.toSet().difference(_logicalTables.toSet()).isNotEmpty ||
        _logicalTables.toSet().difference(tables.keys.toSet()).isNotEmpty) {
      throw const PortableBackupException(
        PortableBackupFailureKind.invalidRecord,
        'The backup table set is invalid.',
      );
    }
    final validation = sqlite3.openInMemory();
    try {
      DatabaseMigrationRunner().migrate(validation, 0);
      validation.execute('PRAGMA foreign_keys = ON');
      validation.execute('BEGIN');
      try {
        for (final table in _logicalTables) {
          final expectedColumns = validation
              .select('PRAGMA table_info($table)')
              .map((row) => row['name'] as String)
              .toSet();
          for (final row in tables[table]!) {
            if (row.keys.toSet().difference(expectedColumns).isNotEmpty ||
                expectedColumns.difference(row.keys.toSet()).isNotEmpty) {
              throw const FormatException('Unexpected table columns.');
            }
            if (row['student_id'] != _studentId) {
              throw const PortableBackupException(
                PortableBackupFailureKind.ownerMismatch,
                'The backup contains records owned by another Student.',
              );
            }
            _validateUuidColumns(row);
            _insert(validation, table, row);
          }
        }
        _validateHardInvariants(validation);
        validation.execute('COMMIT');
      } catch (_) {
        validation.execute('ROLLBACK');
        rethrow;
      }
    } on PortableBackupException {
      rethrow;
    } on Object catch (error) {
      throw PortableBackupException(
        PortableBackupFailureKind.invalidRecord,
        'The backup violates the current application schema.',
        cause: error,
      );
    } finally {
      validation.close();
    }
  }

  void _validateHardInvariants(Database db) {
    final profiles =
        db.select(
              'SELECT count(*) AS count FROM student_profiles WHERE student_id = ?',
              [_studentId],
            ).single['count']
            as int;
    if (profiles != 1) throw const FormatException('Student Profile missing.');
    final foreignKeys = db.select('PRAGMA foreign_key_check');
    if (foreignKeys.isNotEmpty) {
      throw const FormatException('Foreign key failure.');
    }
    final invalidWork = db.select(
      "SELECT 1 FROM commitments WHERE commitment_type = 'work_shift' AND lifecycle_state != 'scheduled' LIMIT 1",
    );
    if (invalidWork.isNotEmpty) {
      throw const FormatException('Invalid Work Shift.');
    }
    final invalidWindow = db.select(
      '''SELECT 1 FROM commitments c JOIN clinical_placements p
         ON p.id = c.placement_id AND p.student_id = c.student_id
         WHERE c.commitment_type = 'clinical_session'
         AND (c.planned_start_date < p.start_date OR c.planned_end_date > p.completion_deadline)
         LIMIT 1''',
    );
    if (invalidWindow.isNotEmpty) {
      throw const FormatException('Invalid placement window.');
    }
    final overlaps = db.select('''WITH active AS (
           SELECT id,
             CASE WHEN commitment_type = 'clinical_session' AND lifecycle_state = 'completed'
               THEN actual_start_utc ELSE planned_start_utc END AS start_utc,
             CASE WHEN commitment_type = 'clinical_session' AND lifecycle_state = 'completed'
               THEN actual_end_utc ELSE planned_end_utc END AS end_utc
           FROM commitments WHERE deleted_at_utc IS NULL
             AND NOT (commitment_type = 'clinical_session' AND lifecycle_state IN ('cancelled','missed'))
         ) SELECT 1 FROM active a JOIN active b ON a.id < b.id
           AND a.start_utc < b.end_utc AND b.start_utc < a.end_utc LIMIT 1''');
    if (overlaps.isNotEmpty) throw const FormatException('Schedule Conflict.');
    final protectedConflict = db.select('''WITH active AS (
           SELECT id,
             CASE WHEN commitment_type = 'clinical_session' AND lifecycle_state = 'completed'
               THEN actual_start_date ELSE planned_start_date END AS start_date,
             CASE WHEN commitment_type = 'clinical_session' AND lifecycle_state = 'completed'
               THEN actual_end_date ELSE planned_end_date END AS end_date,
             CASE WHEN commitment_type = 'clinical_session' AND lifecycle_state = 'completed'
               THEN actual_start_minutes ELSE planned_start_minutes END AS start_minutes,
             CASE WHEN commitment_type = 'clinical_session' AND lifecycle_state = 'completed'
               THEN actual_end_minutes ELSE planned_end_minutes END AS end_minutes
           FROM commitments WHERE deleted_at_utc IS NULL
             AND NOT (commitment_type = 'clinical_session' AND lifecycle_state IN ('cancelled','missed'))
         ) SELECT 1 FROM active a JOIN protected_days p
           ON p.deleted_at_utc IS NULL
           AND (p.local_date > a.start_date OR (p.local_date = a.start_date AND a.start_minutes < 1440))
           AND (p.local_date < a.end_date OR (p.local_date = a.end_date AND a.end_minutes > 0))
         LIMIT 1''');
    if (protectedConflict.isNotEmpty) {
      throw const FormatException('Protected Day conflict.');
    }
  }

  void _upsert(String table, Map<String, Object?> row) {
    final entityType = switch (table) {
      'preceptors' => 'preceptor',
      'clinical_placements' => 'clinical_placement',
      'commitments' =>
        row['commitment_type'] == 'work_shift'
            ? 'work_shift'
            : 'clinical_session',
      'protected_days' => 'protected_day',
      'historical_hours_entries' => 'historical_hours_entry',
      'evaluation_plans' => 'evaluation_plan',
      'schedule_templates' => 'schedule_template',
      'reminder_state' => 'reminder_state',
      _ => null,
    };
    if (entityType != null &&
        database.select(
          'SELECT 1 FROM permanent_purge_markers WHERE student_id = ? '
          'AND entity_type = ? AND entity_id = ?',
          [_studentId, entityType, row['id']],
        ).isNotEmpty) {
      throw const PortableBackupException(
        PortableBackupFailureKind.invalidRecord,
        'A backup cannot restore a permanently deleted identity.',
      );
    }
    final columns = row.keys.toList(growable: false);
    final keys = _primaryKeys[table]!;
    final updates = columns
        .where((column) => !keys.contains(column))
        .map((column) => '$column = excluded.$column')
        .join(', ');
    database.execute(
      'INSERT INTO $table (${columns.join(', ')}) VALUES (${List.filled(columns.length, '?').join(', ')}) '
      'ON CONFLICT(${keys.join(', ')}) DO UPDATE SET $updates',
      columns.map((column) => row[column]).toList(growable: false),
    );
  }
}

final class _DecodedBackup {
  const _DecodedBackup(this.studentId, this.createdAtUtc, this.tables);
  final String studentId;
  final DateTime createdAtUtc;
  final Map<String, List<Map<String, Object?>>> tables;
}

Map<String, Object?> _encodeTables(
  Map<String, List<Map<String, Object?>>> tables,
) => {
  for (final table in _logicalTables)
    table: tables[table]!.map(_encodeRow).toList(growable: false),
};

Map<String, Object?> _encodeRow(Map<String, Object?> row) => {
  for (final entry in row.entries) entry.key: _encodeCell(entry.value),
};

Object? _encodeCell(Object? value) {
  if (value is Uint8List || value is List<int>) {
    return <String, Object?>{
      'binary_base64': base64Url.encode(value as List<int>),
    };
  }
  return value;
}

Map<String, List<Map<String, Object?>>> _decodeTables(Object? value) {
  if (value is! Map<String, dynamic>) throw const FormatException();
  if (value.keys.any(excludedPortableBackupTables.contains)) {
    throw const FormatException('Operational table included.');
  }
  return {for (final table in _logicalTables) table: _decodeRows(value[table])};
}

List<Map<String, Object?>> _decodeRows(Object? value) {
  if (value is! List) throw const FormatException();
  return value
      .map((row) {
        if (row is! Map<String, dynamic>) throw const FormatException();
        return <String, Object?>{
          for (final entry in row.entries) entry.key: _decodeCell(entry.value),
        };
      })
      .toList(growable: false);
}

Object? _decodeCell(Object? value) {
  if (value is Map<String, dynamic> &&
      value.length == 1 &&
      value['binary_base64'] is String) {
    return Uint8List.fromList(
      base64Url.decode(value['binary_base64'] as String),
    );
  }
  if (value is Map || value is List) throw const FormatException();
  return value;
}

Map<BackupRecordIdentity, Map<String, Object?>> _byIdentity(
  String table,
  List<Map<String, Object?>> rows,
) => {for (final row in rows) _identity(table, row): row};

BackupRecordIdentity _identity(String table, Map<String, Object?> row) =>
    BackupRecordIdentity(
      table: table,
      key: {for (final key in _primaryKeys[table]!) key: row[key]},
    );

RestoreMergeDisposition _disposition(
  Map<String, Object?>? local,
  Map<String, Object?> backup,
) {
  if (local == null) return RestoreMergeDisposition.add;
  if (canonicalJson(_encodeRow(local)) == canonicalJson(_encodeRow(backup))) {
    return RestoreMergeDisposition.keepLocal;
  }
  final localRevision = _revision(local);
  final backupRevision = _revision(backup);
  if (localRevision != null && backupRevision != null) {
    if (backupRevision > localRevision) {
      return RestoreMergeDisposition.useBackup;
    }
    if (backupRevision < localRevision) {
      return RestoreMergeDisposition.keepLocal;
    }
  }
  return RestoreMergeDisposition.conflict;
}

int? _revision(Map<String, Object?>? row) => row?['revision'] as int?;

void _replaceByIdentity(
  List<Map<String, Object?>> rows,
  BackupRecordIdentity identity,
  Map<String, Object?> replacement,
) {
  final index = rows.indexWhere(
    (row) => _identity(identity.table, row) == identity,
  );
  if (index < 0) {
    rows.add(Map<String, Object?>.from(replacement));
  } else {
    rows[index] = Map<String, Object?>.from(replacement);
  }
}

void _insert(Database db, String table, Map<String, Object?> row) {
  final columns = row.keys.toList(growable: false);
  db.execute(
    'INSERT INTO $table (${columns.join(', ')}) VALUES (${List.filled(columns.length, '?').join(', ')})',
    columns.map((column) => row[column]).toList(growable: false),
  );
}

void _validateUuidColumns(Map<String, Object?> row) {
  for (final entry in row.entries) {
    if ((entry.key == 'id' || entry.key.endsWith('_id')) &&
        entry.value != null) {
      _uuid(entry.value as String);
    }
  }
}

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

String _uuid(String value) {
  if (!_uuidPattern.hasMatch(value)) {
    throw const FormatException('Invalid UUID.');
  }
  return value.toLowerCase();
}

bool _constantTimeEquals(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  var difference = 0;
  for (var index = 0; index < left.length; index++) {
    difference |= left[index] ^ right[index];
  }
  return difference == 0;
}
