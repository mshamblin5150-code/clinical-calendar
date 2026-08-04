import 'dart:convert';
import 'dart:io';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_platform/clinical_calendar_platform.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/export_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const encoder = DartExportEncoder();

  test(
    'PDF fixtures cover zero, typical, over-target, and non-ASCII data',
    () async {
      final fixtures = {
        'zero': placementExportFixture(includeRecords: false),
        'typical': placementExportFixture(),
        'over-target': placementExportFixture(overTarget: true),
      };
      final output = Directory('build/export_fixtures')
        ..createSync(recursive: true);
      for (final entry in fixtures.entries) {
        final artifact = await encoder.encodePlacementPdf(entry.value);
        expect(artifact.bytes.take(5), [37, 80, 68, 70, 45]);
        expect(artifact.bytes.length, greaterThan(1500));
        File(
          '${output.path}/placement-report-${entry.key}.pdf',
        ).writeAsBytesSync(artifact.bytes);
      }
    },
  );

  test('CSV has stable columns and exact machine-readable values', () async {
    final artifact = await encoder.encodePlacementCsv(placementExportFixture());
    final csv = utf8.decode(artifact.bytes);
    final lines = const LineSplitter().convert(csv);

    expect(lines.first, PlacementCsvSchema.columns.join(','));
    expect(csv, contains('clinical_session'));
    expect(csv, contains('2026-08-02'));
    expect(csv, contains('08:17'));
    expect(csv, contains('15:53'));
    expect(csv, contains('456'));
    expect(csv, contains('America/New_York'));
    expect(csv, contains('-240'));
    expect(csv, contains('José Álvarez'));
    expect(csv, contains('Zoë Müller'));
    expect(csv, contains('Unattributed'));
  });

  test(
    'JSON is indented, versioned, non-ASCII safe, and adds no secrets',
    () async {
      final snapshot = PortableExportSnapshot(
        schemaName: PortableExportSnapshot.currentSchemaName,
        schemaVersion: PortableExportSnapshot.currentSchemaVersion,
        exportedAtUtc: fixtureTime,
        studentId: fixtureId(100),
        document: {
          'schema_name': PortableExportSnapshot.currentSchemaName,
          'schema_version': PortableExportSnapshot.currentSchemaVersion,
          'records': {
            'preceptors': [
              {'name': 'Zoë Müller'},
            ],
            'historical_hours_entries': [
              {'preceptor_id': null, 'completed_minutes': 47},
            ],
          },
        },
      );
      final artifact = await encoder.encodeCompleteJson(snapshot);
      final text = utf8.decode(artifact.bytes);
      final decoded = jsonDecode(text) as Map<String, Object?>;

      expect(decoded['schema_version'], 1);
      expect(text, contains('Zoë Müller'));
      expect(text, isNot(contains('encryption_key')));
      expect(text, isNot(contains('service_role')));
      expect(text, isNot(contains('access_token')));
    },
  );
}
