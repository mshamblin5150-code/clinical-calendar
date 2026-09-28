import 'dart:convert';
import 'dart:io';

import 'package:clinical_calendar/main_web.dart' as web;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web entrypoint excludes native-only startup dependencies', () {
    final entrypoint = File('lib/main.dart').readAsStringSync();
    final webStartup = File('lib/main_web.dart').readAsStringSync();

    expect(entrypoint, contains("import 'main_web.dart'"));
    expect(entrypoint, contains("if (dart.library.io) 'main_native.dart'"));
    expect(entrypoint, isNot(contains('dart:io')));
    expect(webStartup, isNot(contains('dart:io')));
    expect(webStartup, contains('clinical_calendar_local_data'));
    expect(
      webStartup,
      isNot(
        contains(
          "package:clinical_calendar_platform/clinical_calendar_platform.dart",
        ),
      ),
    );
    expect(
      webStartup,
      isNot(
        contains(
          "package:clinical_calendar_platform/clinical_calendar_identity_platform.dart",
        ),
      ),
    );
    expect(
      webStartup,
      contains(
        "package:clinical_calendar_platform/clinical_calendar_web_identity_platform.dart",
      ),
    );
    expect(webStartup, contains('clinical_calendar_web_platform'));
    expect(webStartup, isNot(contains('clinical_calendar_native_platform')));
    expect(webStartup, isNot(contains('main_native')));
  });

  test('web artifact build id matches the sync build number', () {
    final payload = jsonDecode(File('web/build-id.json').readAsStringSync());

    expect(payload, {'build_number': web.currentSyncBuildNumber});
  });

  test('web SQLite registers a memory-only default VFS before opening', () {
    final runtime = File('lib/browser_runtime_web.dart').readAsStringSync();
    final registerVfs = runtime.indexOf('registerVirtualFileSystem(');
    final openDatabase = runtime.indexOf('openInMemory()');

    expect(registerVfs, greaterThanOrEqualTo(0));
    expect(runtime, contains('InMemoryFileSystem()'));
    expect(runtime, contains('makeDefault: true'));
    expect(openDatabase, greaterThan(registerVfs));
  });

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
