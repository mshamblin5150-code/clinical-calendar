import 'dart:convert';
import 'dart:io';

import 'package:clinical_calendar_vertical_slice/data/encrypted_schedule_store.dart';
import 'package:clinical_calendar_vertical_slice/domain/scheduling.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SQLCipher data survives close and offline reopen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'clinical-calendar-',
    );
    final path = '${directory.path}${Platform.pathSeparator}schedule.db';
    const key =
        '0123456789abcdef0123456789abcdef'
        '0123456789abcdef0123456789abcdef';

    final first = await EncryptedScheduleStore.open(
      keyStore: FixedEncryptionKeyStore(key),
      databasePath: path,
    );
    expect(first.cipherVersion, isNotEmpty);
    await first.save(
      ScheduleCommitment(
        id: 'persisted-session',
        date: DateTime(2026, 8, 4),
        startMinutes: 7 * 60,
        endMinutes: 19 * 60,
        timeZone: 'America/New_York',
      ),
    );
    await first.close();

    final header = await File(path).openRead(0, 16).first;
    expect(
      utf8.decode(header, allowMalformed: true),
      isNot('SQLite format 3\u0000'),
    );

    final reopened = await EncryptedScheduleStore.open(
      keyStore: FixedEncryptionKeyStore(key),
      databasePath: path,
    );
    final sessions = await reopened.loadAll();
    expect(sessions, hasLength(1));
    expect(sessions.single.id, 'persisted-session');
    expect(sessions.single.durationMinutes, 12 * 60);
    await reopened.close();

    await directory.delete(recursive: true);
  });

  test('the wrong key cannot open an existing database', () async {
    final directory = await Directory.systemTemp.createTemp(
      'clinical-calendar-',
    );
    final path = '${directory.path}${Platform.pathSeparator}schedule.db';
    const key =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

    final store = await EncryptedScheduleStore.open(
      keyStore: FixedEncryptionKeyStore(key),
      databasePath: path,
    );
    await store.save(
      ScheduleCommitment(
        id: 'protected-session',
        date: DateTime(2026, 8, 4),
        startMinutes: 7 * 60,
        endMinutes: 19 * 60,
        timeZone: 'America/New_York',
      ),
    );
    await store.close();

    await expectLater(
      EncryptedScheduleStore.open(
        keyStore: FixedEncryptionKeyStore(List.filled(64, 'b').join()),
        databasePath: path,
      ),
      throwsA(anything),
    );

    await directory.delete(recursive: true);
  });
}
