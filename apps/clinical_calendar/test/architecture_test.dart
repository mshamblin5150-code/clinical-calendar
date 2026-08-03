import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inner packages do not import outer boundaries', () {
    final repositoryRoot = Directory.current.parent.parent;
    final forbiddenByPackage = <String, List<String>>{
      'clinical_calendar_domain': [
        'package:flutter/',
        'clinical_calendar_application',
        'clinical_calendar_local_data',
        'clinical_calendar_sync',
        'clinical_calendar_presentation',
        'clinical_calendar_platform',
      ],
      'clinical_calendar_application': [
        'package:flutter/',
        'clinical_calendar_local_data',
        'clinical_calendar_sync',
        'clinical_calendar_presentation',
        'clinical_calendar_platform',
      ],
    };

    for (final entry in forbiddenByPackage.entries) {
      final source = Directory(
        '${repositoryRoot.path}/packages/${entry.key}/lib',
      );
      final dartFiles = source
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      for (final file in dartFiles) {
        final contents = file.readAsStringSync();
        for (final forbidden in entry.value) {
          expect(
            contents,
            isNot(contains(forbidden)),
            reason: '${file.path} imports forbidden boundary $forbidden',
          );
        }
      }
    }
  });
}
