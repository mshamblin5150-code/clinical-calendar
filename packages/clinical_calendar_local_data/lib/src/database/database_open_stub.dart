import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:sqlite3/common.dart';

import 'schema_migrations.dart';

Future<({CommonDatabase database, String cipherVersion})>
openEncryptedDatabase({
  required String path,
  required SecureStorage secureStorage,
  required DatabaseMigrationRunner migrationRunner,
  required String encryptionKeyStorageKey,
  required RegExp validKey,
}) => throw UnsupportedError('Encrypted file databases are native-only.');
