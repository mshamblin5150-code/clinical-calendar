/// Stable, content-free categories that callers may safely record in logs.
enum DatabaseFailureKind {
  missingEncryptionKey,
  invalidEncryptionKey,
  sqlCipherUnavailable,
  unsupportedSchemaVersion,
  migrationFailed,
  authenticationOrCorruption,
}

/// A sanitized database-open failure.
///
/// This exception deliberately never retains the SQLCipher key, a SQLite error,
/// SQL text, row values, or any other Student-owned content.
final class ClinicalCalendarDatabaseException implements Exception {
  const ClinicalCalendarDatabaseException._(this.kind, this.safeMessage);

  factory ClinicalCalendarDatabaseException.missingEncryptionKey() =>
      const ClinicalCalendarDatabaseException._(
        DatabaseFailureKind.missingEncryptionKey,
        'The existing local database has no encryption key.',
      );

  factory ClinicalCalendarDatabaseException.invalidEncryptionKey() =>
      const ClinicalCalendarDatabaseException._(
        DatabaseFailureKind.invalidEncryptionKey,
        'The local database encryption key is invalid.',
      );

  factory ClinicalCalendarDatabaseException.sqlCipherUnavailable() =>
      const ClinicalCalendarDatabaseException._(
        DatabaseFailureKind.sqlCipherUnavailable,
        'The SQLite runtime does not provide SQLCipher.',
      );

  factory ClinicalCalendarDatabaseException.unsupportedSchemaVersion() =>
      const ClinicalCalendarDatabaseException._(
        DatabaseFailureKind.unsupportedSchemaVersion,
        'The local database schema is newer than this application supports.',
      );

  factory ClinicalCalendarDatabaseException.migrationFailed() =>
      const ClinicalCalendarDatabaseException._(
        DatabaseFailureKind.migrationFailed,
        'The local database migration failed and was rolled back.',
      );

  factory ClinicalCalendarDatabaseException.authenticationOrCorruption() =>
      const ClinicalCalendarDatabaseException._(
        DatabaseFailureKind.authenticationOrCorruption,
        'The local database could not be authenticated or is corrupted.',
      );

  final DatabaseFailureKind kind;
  final String safeMessage;

  @override
  String toString() =>
      'ClinicalCalendarDatabaseException(${kind.name}): $safeMessage';
}
