import 'dart:io';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:clinical_calendar_platform/clinical_calendar_identity_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late String databasePath;
  late _Storage storage;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('identity-removal-');
    databasePath =
        '${directory.path}${Platform.pathSeparator}clinical_calendar.sqlite3';
    for (final path in [
      databasePath,
      '$databasePath-wal',
      '$databasePath-shm',
    ]) {
      await File(path).writeAsString('private');
    }
    await File(
      '${directory.path}${Platform.pathSeparator}keep.txt',
    ).writeAsString('keep');
    storage = _Storage({'db-key': 'secret', 'session': 'secret'});
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test(
    'closes first then deletes only exact database files and keys',
    () async {
      var closed = false;
      final controller = ProductionLocalDeviceCopyController(
        databasePath: databasePath,
        secureStorage: storage,
        preview: () async => const LocalRemovalPreview(pendingChangeCount: 3),
        stopLifecycleAndCloseDatabase: () async => closed = true,
        credentialKeys: const ['db-key', 'session'],
      );

      expect((await controller.previewRemoval()).pendingChangeCount, 3);
      await controller.removeLocalCopy();

      expect(closed, isTrue);
      expect(await File(databasePath).exists(), isFalse);
      expect(await File('$databasePath-wal').exists(), isFalse);
      expect(await File('$databasePath-shm').exists(), isFalse);
      expect(
        await File(
          '${directory.path}${Platform.pathSeparator}keep.txt',
        ).readAsString(),
        'keep',
      );
      expect(storage.values, isEmpty);
    },
  );

  test('shutdown failure preserves every file and credential', () async {
    final controller = ProductionLocalDeviceCopyController(
      databasePath: databasePath,
      secureStorage: storage,
      preview: () async => const LocalRemovalPreview(pendingChangeCount: 0),
      stopLifecycleAndCloseDatabase: () async => throw StateError('busy'),
      credentialKeys: const ['db-key', 'session'],
    );

    await expectLater(controller.removeLocalCopy(), throwsStateError);

    expect(await File(databasePath).exists(), isTrue);
    expect(await File('$databasePath-wal').exists(), isTrue);
    expect(await File('$databasePath-shm').exists(), isTrue);
    expect(storage.values.keys, containsAll(['db-key', 'session']));
  });

  test('rejects any path other than the resolved app database name', () {
    expect(
      () => ProductionLocalDeviceCopyController(
        databasePath:
            '${directory.path}${Platform.pathSeparator}another.sqlite3',
        secureStorage: storage,
        preview: () async => const LocalRemovalPreview(pendingChangeCount: 0),
        stopLifecycleAndCloseDatabase: () async {},
        credentialKeys: const ['session'],
      ),
      throwsArgumentError,
    );
  });
}

final class _Storage implements SecureStorage {
  _Storage(this.values);
  final Map<String, String> values;
  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
