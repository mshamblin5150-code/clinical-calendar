import 'dart:io';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_platform/clinical_calendar_platform.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Flutter secure storage service delegates without exposing values',
    () async {
      final backend = _FakeFlutterSecureStorage();
      final service = FlutterSecureStorageService(backend);

      await service.write(' owner ', 'secret');
      expect(await service.read('owner'), 'secret');
      await service.delete('owner');
      expect(await service.read('owner'), isNull);
      expect(() => service.read(' '), throwsArgumentError);
    },
  );

  test('Student owner is generated once and then remains stable', () async {
    final storage = _MemorySecureStorage();
    final identifiers = _Identifiers([
      '00000000-0000-4000-8000-000000000011',
      '00000000-0000-4000-8000-000000000012',
    ]);

    final created = await StableStudentOwner.loadOrCreate(
      secureStorage: storage,
      identifiers: identifiers,
    );
    final loaded = await StableStudentOwner.loadOrCreate(
      secureStorage: storage,
      identifiers: identifiers,
    );

    expect(created, '00000000-0000-4000-8000-000000000011');
    expect(loaded, created);
    expect(identifiers.calls, 1);
  });

  test(
    'invalid stored Student owner fails closed without replacement',
    () async {
      final storage = _MemorySecureStorage()
        ..values[StableStudentOwner.storageKey] = 'not-a-uuid';

      await expectLater(
        StableStudentOwner.loadOrCreate(
          secureStorage: storage,
          identifiers: _Identifiers(['00000000-0000-4000-8000-000000000013']),
        ),
        throwsStateError,
      );
      expect(storage.values[StableStudentOwner.storageKey], 'not-a-uuid');
      expect(storage.writeCount, 0);
    },
  );

  test(
    'database path is placed in an absolute application support directory',
    () async {
      final root = await Directory.systemTemp.createTemp('clinical_path_test_');
      addTearDown(() => root.delete(recursive: true));

      final path = await clinicalCalendarDatabasePath(
        applicationSupportDirectory: () async => root,
      );

      expect(
        path,
        '${root.path}${Platform.pathSeparator}clinical_calendar.sqlite3',
      );
    },
  );

  test(
    'Dart IO file service round-trips file URIs and rejects other schemes',
    () async {
      final root = await Directory.systemTemp.createTemp('clinical_file_test_');
      addTearDown(() => root.delete(recursive: true));
      final location = Uri.file(
        '${root.path}${Platform.pathSeparator}data.bin',
      );
      const service = DartIoFileService();

      await service.write(location, [0, 127, 255]);
      expect(await service.read(location), [0, 127, 255]);
      expect(
        () => service.read(Uri.parse('content://documents/item')),
        throwsArgumentError,
      );
      await expectLater(service.write(location, [256]), throwsArgumentError);
    },
  );
}

final class _FakeFlutterSecureStorage implements FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final key = invocation.namedArguments[#key] as String;
    if (invocation.memberName == #read) return Future.value(values[key]);
    if (invocation.memberName == #write) {
      final value = invocation.namedArguments[#value] as String?;
      if (value == null) {
        values.remove(key);
      } else {
        values[key] = value;
      }
      return Future<void>.value();
    }
    if (invocation.memberName == #delete) {
      values.remove(key);
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

final class _MemorySecureStorage implements SecureStorage {
  final Map<String, String> values = {};
  int writeCount = 0;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    writeCount++;
    values[key] = value;
  }
}

final class _Identifiers implements IdentifierGenerator {
  _Identifiers(this.values);

  final List<String> values;
  int calls = 0;

  @override
  String nextIdentifier() => values[calls++];
}
