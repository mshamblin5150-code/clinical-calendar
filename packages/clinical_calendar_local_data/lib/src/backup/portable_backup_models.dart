import 'dart:collection';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';

enum PortableBackupFailureKind {
  weakPassphrase,
  tooLarge,
  invalidContainer,
  wrongPassphraseOrDamaged,
  checksumMismatch,
  unsupportedNewerVersion,
  unsupportedOlderVersion,
  ownerMismatch,
  invalidRecord,
  unresolvedConflicts,
  applyFailed,
}

final class PortableBackupException implements Exception {
  const PortableBackupException(this.kind, this.safeMessage, {this.cause});

  final PortableBackupFailureKind kind;
  final String safeMessage;
  final Object? cause;

  @override
  String toString() => 'PortableBackupException(${kind.name}): $safeMessage';
}

final class PortableBackupCryptoPolicy {
  const PortableBackupCryptoPolicy({
    this.memoryKib = 64 * 1024,
    this.iterations = 3,
    this.parallelism = 2,
    this.minimumPassphraseCharacters = 12,
    this.maximumContainerBytes = 48 * 1024 * 1024,
    this.maximumPlaintextBytes = 32 * 1024 * 1024,
  }) : assert(memoryKib > 0),
       assert(iterations > 0),
       assert(parallelism > 0),
       assert(minimumPassphraseCharacters > 0),
       assert(maximumContainerBytes > 0),
       assert(maximumPlaintextBytes > 0);

  final int memoryKib;
  final int iterations;
  final int parallelism;
  final int minimumPassphraseCharacters;
  final int maximumContainerBytes;
  final int maximumPlaintextBytes;
}

final class PortableBackupDatasetLimits {
  const PortableBackupDatasetLimits({
    this.maximumRows = 100000,
    this.maximumFieldsPerRow = 128,
    this.maximumStringCellCharacters = 64 * 1024,
    this.maximumBinaryCellBytes = 1024 * 1024,
    this.maximumAggregateBinaryBytes = 8 * 1024 * 1024,
  }) : assert(maximumRows > 0),
       assert(maximumFieldsPerRow > 0),
       assert(maximumStringCellCharacters > 0),
       assert(maximumBinaryCellBytes > 0),
       assert(maximumAggregateBinaryBytes > 0);

  final int maximumRows;
  final int maximumFieldsPerRow;
  final int maximumStringCellCharacters;
  final int maximumBinaryCellBytes;
  final int maximumAggregateBinaryBytes;
}

final class BackupRecordIdentity implements Comparable<BackupRecordIdentity> {
  BackupRecordIdentity({required this.table, required Map<String, Object?> key})
    : key = UnmodifiableMapView(Map<String, Object?>.from(key));

  final String table;
  final Map<String, Object?> key;

  String get stableValue =>
      '$table/${key.entries.map((e) => '${e.key}=${e.value}').join('&')}';

  @override
  int compareTo(BackupRecordIdentity other) =>
      stableValue.compareTo(other.stableValue);

  @override
  bool operator ==(Object other) =>
      other is BackupRecordIdentity && stableValue == other.stableValue;

  @override
  int get hashCode => stableValue.hashCode;
}

enum RestoreMergeDisposition { add, keepLocal, useBackup, conflict }

enum RestoreConflictChoice { keepLocal, useBackup }

final class RestoreMergeItem {
  const RestoreMergeItem({
    required this.identity,
    required this.disposition,
    required this.localRevision,
    required this.backupRevision,
  });

  final BackupRecordIdentity identity;
  final RestoreMergeDisposition disposition;
  final int? localRevision;
  final int? backupRevision;
}

final class PortableRestorePreview {
  PortableRestorePreview.validated({
    required this.studentId,
    required this.createdAtUtc,
    required this.items,
    required Map<String, List<Map<String, Object?>>> decodedTables,
  }) : decodedTables = UnmodifiableMapView({
         for (final entry in decodedTables.entries)
           entry.key: List.unmodifiable(
             entry.value.map(
               (row) => UnmodifiableMapView(Map<String, Object?>.from(row)),
             ),
           ),
       });

  final String studentId;
  final DateTime createdAtUtc;
  final List<RestoreMergeItem> items;
  final Map<String, List<Map<String, Object?>>> decodedTables;

  Iterable<RestoreMergeItem> get conflicts => items.where(
    (item) => item.disposition == RestoreMergeDisposition.conflict,
  );

  int get additions => items
      .where((item) => item.disposition == RestoreMergeDisposition.add)
      .length;
  int get backupUpdates => items
      .where((item) => item.disposition == RestoreMergeDisposition.useBackup)
      .length;
}

final class RestoreSynchronizationIntent {
  const RestoreSynchronizationIntent({
    required this.identity,
    required this.row,
  });

  final BackupRecordIdentity identity;
  final Map<String, Object?> row;
}

/// Integration seam for fresh outbox intent. It is invoked inside the same
/// SQLite transaction as restored rows and must remain synchronous.
abstract interface class RestoreSynchronizationIntentSink {
  void recordFreshIntents(List<RestoreSynchronizationIntent> intents);
}

final class PortableRestoreResult {
  const PortableRestoreResult({required this.applied, required this.unchanged});

  final int applied;
  final int unchanged;
}

abstract interface class PortableBackupMigrator {
  Map<String, Object?> migrate(Map<String, Object?> payload);
}

final class DefaultPortableBackupMigrator implements PortableBackupMigrator {
  const DefaultPortableBackupMigrator();

  @override
  Map<String, Object?> migrate(Map<String, Object?> payload) {
    final copy = Map<String, Object?>.from(payload);
    final version = copy['payload_version'];
    if (version == 2) return _migrateDatabaseRows(copy);
    if (version == null && copy['schema_version'] == 1) {
      copy
        ..remove('schema_version')
        ..['payload_version'] = 2;
      return _migrateDatabaseRows(copy);
    }
    if (version is int && version > 2) {
      throw const PortableBackupException(
        PortableBackupFailureKind.unsupportedNewerVersion,
        'This backup was created by a newer unsupported application version.',
      );
    }
    throw const PortableBackupException(
      PortableBackupFailureKind.unsupportedOlderVersion,
      'This backup version cannot be migrated.',
    );
  }

  Map<String, Object?> _migrateDatabaseRows(Map<String, Object?> payload) {
    final sourceVersion = payload['source_database_schema_version'];
    if (sourceVersion is! int) return payload;
    final tables = payload['tables'];
    if (sourceVersion < 4 && tables is Map<dynamic, dynamic>) {
      final requirements = tables['evaluation_requirements'];
      if (requirements is List) {
        for (final row in requirements) {
          if (row is Map) row.putIfAbsent('is_currently_required', () => 1);
        }
      }
      payload['source_database_schema_version'] = 4;
    }
    if (sourceVersion == 12 && tables is Map<dynamic, dynamic>) {
      final settings = tables['settings'];
      if (settings is List) {
        for (final row in settings) {
          if (row is Map) {
            final theme = row['theme'];
            if (theme == 'borg_tactical' ||
                theme is String && theme.trim().isEmpty) {
              row['theme'] = StudentSettings.variantFThemeId;
            }
            row.putIfAbsent('enhanced_accessibility', () => 0);
          }
        }
      }
      payload['source_database_schema_version'] = 13;
    }
    if (sourceVersion < 15 && tables is Map<dynamic, dynamic>) {
      tables.putIfAbsent('academic_assignments', () => <Object?>[]);
      payload['source_database_schema_version'] = 15;
    }
    if (sourceVersion < 16 && tables is Map<dynamic, dynamic>) {
      tables.putIfAbsent('class_catalog_entries', () => <Object?>[]);
      final assignments = tables['academic_assignments'];
      if (assignments is List) {
        for (final row in assignments) {
          if (row is Map) row.putIfAbsent('course_id', () => null);
        }
      }
      payload['source_database_schema_version'] = 16;
    }
    return payload;
  }
}
