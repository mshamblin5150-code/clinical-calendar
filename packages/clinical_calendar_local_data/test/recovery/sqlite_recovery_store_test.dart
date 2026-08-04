import 'dart:io';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:test/test.dart';

const _key =
    '0123456789abcdef0123456789abcdef'
    '0123456789abcdef0123456789abcdef';
const _studentId = '00000000-0000-4000-8000-000000000001';
const _preceptorId = '00000000-0000-4000-8000-000000000002';
const _protectedId = '00000000-0000-4000-8000-000000000003';
const _workId = '00000000-0000-4000-8000-000000000004';
final _now = DateTime.utc(2026, 8, 4, 12);

void main() {
  late Directory directory;
  late ClinicalCalendarDatabase database;
  late SqliteRepositoryRegistry registry;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('calendar-recovery-');
    database = await ClinicalCalendarDatabase.open(
      path: '${directory.path}${Platform.pathSeparator}calendar.db',
      secureStorage: _Storage(_key),
    );
    registry = SqliteRepositoryRegistry(
      studentId: _studentId,
      database: database,
      identifierGenerator: _Identifiers(),
    );
    await registry.initialize();
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'Trash restore is revisioned, synchronized, and expires after 30 days',
    () async {
      await registry.mutate((repositories) {
        repositories.preceptors.put(
          studentId: _studentId,
          value: Preceptor(id: _preceptorId, name: 'Seven of Nine'),
          expectedRevision: 0,
          mutation: _mutation(1),
        );
        repositories.preceptors.tombstone(
          studentId: _studentId,
          id: _preceptorId,
          expectedRevision: 1,
          mutation: _mutation(2),
        );
      });

      final trash = await registry.listTrash(nowUtc: _now);
      expect(trash, hasLength(1));
      expect(
        trash.single.purgeAfterUtc,
        _mutation(2).occurredAtUtc.add(const Duration(days: 30)),
      );

      await registry.restoreTrash(
        trashId: trash.single.id,
        restoredAtUtc: _now,
        mutation: _mutation(3),
      );
      await registry.read((repositories) {
        final restored = repositories.preceptors.find(
          studentId: _studentId,
          id: _preceptorId,
        );
        expect(restored?.revision, 3);
        expect(
          repositories.outbox
              .pending(
                studentId: _studentId,
                asOfUtc: _now.add(const Duration(days: 1)),
              )
              .where((operation) => operation.entityId == _preceptorId)
              .map((operation) => operation.type),
          [
            OutboxOperationType.upsert,
            OutboxOperationType.delete,
            OutboxOperationType.upsert,
          ],
        );
      });
      expect(await registry.listTrash(nowUtc: _now), isEmpty);
    },
  );

  test(
    'restore validates current invariants and rolls back prohibited merge',
    () async {
      final protected = ProtectedDay(
        id: _protectedId,
        date: LocalDate(2026, 8, 5),
      );
      await registry.mutate((repositories) {
        repositories.protectedDays.put(
          studentId: _studentId,
          value: protected,
          expectedRevision: 0,
          mutation: _mutation(4),
        );
        repositories.protectedDays.tombstone(
          studentId: _studentId,
          id: _protectedId,
          expectedRevision: 1,
          mutation: _mutation(5),
        );
        repositories.workShifts.put(
          studentId: _studentId,
          value: WorkShift(
            id: _workId,
            plannedInterval: ZonedInterval(
              startDate: LocalDate(2026, 8, 5),
              startTime: LocalTime(8, 0),
              endTime: LocalTime(16, 0),
              timeZone: TimeZoneId('America/New_York'),
              startOffset: UtcOffset.inMinutes(-240),
              endOffset: UtcOffset.inMinutes(-240),
            ),
          ),
          expectedRevision: 0,
          mutation: _mutation(6),
        );
      });
      final trash = (await registry.listTrash(nowUtc: _now)).single;

      await expectLater(
        registry.restoreTrash(
          trashId: trash.id,
          restoredAtUtc: _now,
          mutation: _mutation(7),
        ),
        throwsA(
          isA<RecoveryException>().having(
            (error) => error.kind,
            'kind',
            RecoveryFailureKind.invariantViolation,
          ),
        ),
      );
      expect(await registry.listTrash(nowUtc: _now), hasLength(1));
      await registry.read((repositories) {
        expect(
          repositories.protectedDays.find(
            studentId: _studentId,
            id: _protectedId,
          ),
          isNull,
        );
      });
    },
  );

  test('expired Trash is purged exactly at the 30-day boundary', () async {
    await registry.mutate((repositories) {
      repositories.preceptors.put(
        studentId: _studentId,
        value: Preceptor(id: _preceptorId, name: 'Expiring record'),
        expectedRevision: 0,
        mutation: _mutation(10),
      );
      repositories.preceptors.tombstone(
        studentId: _studentId,
        id: _preceptorId,
        expectedRevision: 1,
        mutation: _mutation(11),
      );
    });
    final expiry = _mutation(11).occurredAtUtc.add(const Duration(days: 30));

    expect(
      await registry.listTrash(
        nowUtc: expiry.subtract(const Duration(microseconds: 1)),
      ),
      hasLength(1),
    );
    expect(await registry.listTrash(nowUtc: expiry), isEmpty);
    await registry.read((repositories) {
      expect(
        repositories.preceptors.find(
          studentId: _studentId,
          id: _preceptorId,
          includeDeleted: true,
        ),
        isNull,
      );
    });
  });

  test('permanent deletion queues a content-free synchronized purge', () async {
    await registry.mutate((repositories) {
      repositories.preceptors.put(
        studentId: _studentId,
        value: Preceptor(id: _preceptorId, name: 'Must not leak'),
        expectedRevision: 0,
        mutation: _mutation(12),
      );
      repositories.preceptors.tombstone(
        studentId: _studentId,
        id: _preceptorId,
        expectedRevision: 1,
        mutation: _mutation(13),
      );
    });
    final trash = (await registry.listTrash(nowUtc: _now)).single;

    await registry.permanentlyDelete(
      trashId: trash.id,
      deletedAtUtc: _now,
      mutation: _mutation(14),
    );

    expect(await registry.listTrash(nowUtc: _now), isEmpty);
    final marker = database.select(
      'SELECT * FROM permanent_purge_markers WHERE entity_id = ?',
      [_preceptorId],
    );
    expect(marker.single['revision'], 3);
    await registry.read((repositories) {
      final purge = repositories.outbox
          .pending(
            studentId: _studentId,
            asOfUtc: _now.add(const Duration(days: 1)),
          )
          .singleWhere(
            (operation) => operation.type == OutboxOperationType.purge,
          );
      expect(purge.baseRevision, 2);
      expect(purge.payloadJson, isNot(contains('Must not leak')));
      expect(purge.payloadJson, contains('"value":{}'));
    });
    await expectLater(
      registry.mutate(
        (repositories) => repositories.preceptors.put(
          studentId: _studentId,
          value: Preceptor(id: _preceptorId, name: 'Reused identity'),
          expectedRevision: 0,
          mutation: _mutation(15),
        ),
      ),
      throwsA(isA<RepositoryException>()),
    );
  });

  test('daily snapshots retain 30 days and merge only after preview', () async {
    await registry.mutate((repositories) {
      repositories.preceptors.put(
        studentId: _studentId,
        value: Preceptor(id: _preceptorId, name: 'Snapshot Preceptor'),
        expectedRevision: 0,
        mutation: _mutation(8),
      );
    });
    final snapshot = await registry.createDailySnapshot(nowUtc: _now);
    database.execute('DELETE FROM preceptors WHERE id = ?', [_preceptorId]);

    final preview = await registry.previewSnapshot(
      snapshotId: snapshot.id,
      nowUtc: _now.add(const Duration(hours: 1)),
    );
    expect(preview.additions, greaterThanOrEqualTo(1));
    await registry.read((repositories) {
      expect(
        repositories.preceptors.find(studentId: _studentId, id: _preceptorId),
        isNull,
      );
    });

    final result = await registry.restoreSnapshot(
      snapshotId: snapshot.id,
      choices: const {},
      nowUtc: _now.add(const Duration(hours: 1)),
    );
    expect(result.applied, greaterThanOrEqualTo(1));
    await registry.read((repositories) {
      expect(
        repositories.preceptors
            .find(studentId: _studentId, id: _preceptorId)
            ?.value
            .name,
        'Snapshot Preceptor',
      );
    });

    expect(
      await registry.listSnapshots(nowUtc: _now.add(const Duration(days: 30))),
      isEmpty,
    );
  });
}

MutationToken _mutation(int value) => MutationToken(
  operationId: _id(100 + value * 2),
  idempotencyKey: _id(101 + value * 2),
  occurredAtUtc: _now.subtract(Duration(minutes: 20 - value)),
);

String _id(int value) =>
    '00000000-0000-4000-8000-${value.toRadixString(16).padLeft(12, '0')}';

final class _Identifiers implements IdentifierGenerator {
  var _next = 900;

  @override
  String nextIdentifier() => _id(_next++);
}

final class _Storage implements SecureStorage {
  _Storage(String value) {
    _values[ClinicalCalendarDatabase.encryptionKeyStorageKey] = value;
  }

  final _values = <String, String>{};

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}
