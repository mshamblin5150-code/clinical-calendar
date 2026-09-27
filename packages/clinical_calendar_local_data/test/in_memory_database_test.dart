import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('in-memory database applies the production schema without a file', () {
    final database = ClinicalCalendarDatabase.openInMemory(
      sqlite3.openInMemory(),
    );
    addTearDown(database.close);

    expect(database.path, ':memory:');
    expect(database.cipherVersion, isEmpty);
    expect(database.schemaVersion, DatabaseMigrationRunner.latestVersion);
    expect(
      database
          .select(
            "SELECT name FROM sqlite_schema WHERE type = 'table' "
            "AND name = 'outbox_operations'",
          )
          .single['name'],
      'outbox_operations',
    );
  });
}
