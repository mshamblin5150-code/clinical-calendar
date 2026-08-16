import 'dart:convert';
import 'dart:io';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:test/test.dart';

const _key =
    '0123456789abcdef0123456789abcdef'
    '0123456789abcdef0123456789abcdef';
const _studentId = '00000000-0000-4000-8000-000000000001';
const _firstId = '00000000-0000-4000-8000-000000000002';
const _secondId = '00000000-0000-4000-8000-000000000003';
const _protectedId = '00000000-0000-4000-8000-000000000004';
final _now = DateTime.utc(2026, 8, 3, 12);

void main() {
  late Directory directory;
  late ClinicalCalendarDatabase database;
  late SqliteRepositoryRegistry registry;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'clinical-calendar-conflict-repository-',
    );
    database = await ClinicalCalendarDatabase.open(
      path: '${directory.path}${Platform.pathSeparator}calendar.db',
      secureStorage: _Storage(),
    );
    registry = SqliteRepositoryRegistry(
      studentId: _studentId,
      database: database,
      identifierGenerator: _Identifiers(100),
    );
    await registry.initialize();
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('Schedule Conflict exposes every overlapping record', () async {
    await registry.mutate((repositories) {
      repositories.workShifts.put(
        studentId: _studentId,
        value: WorkShift(id: _firstId, plannedInterval: _interval(9, 11)),
        expectedRevision: 0,
        mutation: _mutation(10),
      );
      repositories.workShifts.put(
        studentId: _studentId,
        value: WorkShift(id: _secondId, plannedInterval: _interval(10, 12)),
        expectedRevision: 0,
        mutation: _mutation(20),
      );
    });
    final operation = await _operation(registry, _secondId);

    await registry.mutate((repositories) {
      final sync = repositories as SynchronizationLocalWriteRepositories;
      sync.synchronization.recordTerminalRejection(
        studentId: _studentId,
        operation: operation,
        rejectionCode: 'schedule_conflict',
        rejectionJson: '{"code":"schedule_conflict"}',
        rejectedAtUtc: _now.add(const Duration(minutes: 30)),
        createsConflict: true,
      );
    });

    final conflicts = await _conflicts(registry);
    expect(conflicts, hasLength(1));
    expect(
      conflicts.single.affectedRecords.map((record) => record.entityId),
      containsAll([_firstId, _secondId]),
    );
    expect(conflicts.single.planningWeekStartDate, LocalDate(2026, 8, 2));
    expect(conflicts.single.keepsPlanningIncomplete, isTrue);
  });

  test(
    'legacy malformed local snapshot resolves through complete remote version',
    () async {
      await registry.mutate((repositories) {
        repositories.workShifts.put(
          studentId: _studentId,
          value: WorkShift(id: _firstId, plannedInterval: _interval(9, 11)),
          expectedRevision: 0,
          mutation: _mutation(25),
        );
      });
      final operation = await _operation(registry, _firstId);
      final legacyOperation = OutboxOperation(
        mutation: operation.mutation,
        studentId: operation.studentId,
        entityType: operation.entityType,
        entityId: operation.entityId,
        type: operation.type,
        baseRevision: operation.baseRevision,
        payloadJson: '[]',
      );
      final remoteEnvelope =
          jsonDecode(operation.payloadJson) as Map<String, dynamic>;
      remoteEnvelope['revision'] = 1;
      remoteEnvelope['current_revision'] = 1;

      await registry.mutate((repositories) {
        final sync = repositories as SynchronizationLocalWriteRepositories;
        sync.synchronization.recordTerminalRejection(
          studentId: _studentId,
          operation: legacyOperation,
          rejectionCode: 'stale_revision',
          rejectionJson: jsonEncode(remoteEnvelope),
          rejectedAtUtc: _now.add(const Duration(minutes: 26)),
          createsConflict: true,
        );
      });

      final conflict = (await _conflicts(registry)).single;

      expect(conflict.entityType, 'work_shift');
      expect(conflict.entityId, _firstId);
      expect(conflict.affectedRecords, hasLength(1));
      expect(conflict.affectedRecords.single.entityId, _firstId);

      await registry.mutate((repositories) {
        final sync = repositories as SynchronizationLocalWriteRepositories;
        sync.synchronization.resolveConflict(
          studentId: _studentId,
          conflictId: conflict.id,
          choice: SynchronizationConflictResolutionChoice.remoteVersion,
          mutation: _mutation(27),
        );
      });

      expect(await _conflicts(registry), isEmpty);
    },
  );

  for (final legacyRemoteCase in [
    ('non-object', '[]'),
    ('partial envelope', '{"schema_version":1,"value":{}}'),
    ('floating-point revision', null),
  ]) {
    test('valid remote change repairs legacy remote snapshot '
        '${legacyRemoteCase.$1}', () async {
      await registry.mutate((repositories) {
        repositories.workShifts.put(
          studentId: _studentId,
          value: WorkShift(id: _firstId, plannedInterval: _interval(9, 11)),
          expectedRevision: 0,
          mutation: _mutation(28),
        );
      });
      final operation = await _operation(registry, _firstId);
      final legacyRemoteSnapshot =
          legacyRemoteCase.$2 ??
          jsonEncode(
            (jsonDecode(operation.payloadJson) as Map<String, dynamic>)
              ..['revision'] = 1.0,
          );
      final legacyOperation = OutboxOperation(
        mutation: operation.mutation,
        studentId: operation.studentId,
        entityType: operation.entityType,
        entityId: operation.entityId,
        type: operation.type,
        baseRevision: 1,
        payloadJson: operation.payloadJson,
      );
      await registry.mutate((repositories) {
        final sync = repositories as SynchronizationLocalWriteRepositories;
        sync.synchronization.recordTerminalRejection(
          studentId: _studentId,
          operation: legacyOperation,
          rejectionCode: 'stale_revision',
          rejectionJson: legacyRemoteSnapshot,
          rejectedAtUtc: _now.add(const Duration(minutes: 29)),
          createsConflict: true,
        );
      });
      expect(
        (await _conflicts(registry)).single.remoteSnapshotJson,
        legacyRemoteSnapshot,
      );
      final remoteEnvelope =
          jsonDecode(operation.payloadJson) as Map<String, dynamic>;
      remoteEnvelope['revision'] = 1;

      await registry.mutate((repositories) {
        final sync = repositories as SynchronizationLocalWriteRepositories;
        sync.synchronization.applyRemoteAndAdvanceCursor(
          studentId: _studentId,
          remoteScope: 'account',
          change: RemoteSynchronizationChange(
            cursor: 1,
            entityType: operation.entityType,
            entityId: operation.entityId,
            revision: 1,
            operationType: OutboxOperationType.upsert,
            payloadJson: jsonEncode(remoteEnvelope),
          ),
          appliedAtUtc: _now.add(const Duration(minutes: 30)),
        );
      });

      final repaired =
          jsonDecode((await _conflicts(registry)).single.remoteSnapshotJson)
              as Map<String, dynamic>;
      expect(repaired['schema_version'], 1);
      expect(repaired['revision'], 1);
    });
  }

  test(
    'Protected Day conflict keeps the exact week Planning Incomplete',
    () async {
      await registry.mutate((repositories) {
        repositories.workShifts.put(
          studentId: _studentId,
          value: WorkShift(id: _firstId, plannedInterval: _interval(9, 11)),
          expectedRevision: 0,
          mutation: _mutation(30),
        );
        repositories.protectedDays.put(
          studentId: _studentId,
          value: ProtectedDay(id: _protectedId, date: LocalDate(2026, 8, 4)),
          expectedRevision: 0,
          mutation: _mutation(40),
        );
      });
      final operation = await _operation(registry, _protectedId);

      await registry.mutate((repositories) {
        final sync = repositories as SynchronizationLocalWriteRepositories;
        sync.synchronization.recordTerminalRejection(
          studentId: _studentId,
          operation: operation,
          rejectionCode: 'protected_day_violation',
          rejectionJson:
              '{"code":"protected_day_violation","reason":"commitment_touches_day"}',
          rejectedAtUtc: _now.add(const Duration(minutes: 50)),
          createsConflict: true,
        );
      });

      final conflict = (await _conflicts(registry)).single;
      expect(conflict.keepsPlanningIncomplete, isTrue);
      expect(conflict.planningWeekStartDate, LocalDate(2026, 8, 2));
      expect(
        conflict.affectedRecords.map((record) => record.entityId),
        containsAll([_firstId, _protectedId]),
      );
    },
  );

  test(
    'resolution retains both originals and stores content-free history metadata',
    () async {
      await registry.mutate((repositories) {
        repositories.preceptors.put(
          studentId: _studentId,
          value: Preceptor(id: _firstId, name: 'Private Preceptor Name'),
          expectedRevision: 0,
          mutation: _mutation(60),
        );
      });
      final operation = await _operation(registry, _firstId);
      await registry.mutate((repositories) {
        final sync = repositories as SynchronizationLocalWriteRepositories;
        sync.synchronization.recordTerminalRejection(
          studentId: _studentId,
          operation: operation,
          rejectionCode: 'stale_revision',
          rejectionJson: '{"code":"stale_revision","current_revision":1}',
          rejectedAtUtc: _now.add(const Duration(minutes: 61)),
          createsConflict: true,
        );
      });
      final original = (await _conflicts(registry)).single;

      final receipt = await registry.mutate((repositories) {
        final sync = repositories as SynchronizationLocalWriteRepositories;
        return sync.synchronization.resolveConflict(
          studentId: _studentId,
          conflictId: original.id,
          choice: SynchronizationConflictResolutionChoice.localVersion,
          mutation: _mutation(62),
        );
      });

      expect(receipt.operation.type, OutboxOperationType.resolveConflict);
      expect(receipt.operation.baseRevision, 1);
      expect(receipt.conflict.localSnapshotJson, original.localSnapshotJson);
      expect(receipt.conflict.remoteSnapshotJson, original.remoteSnapshotJson);
      expect(receipt.conflict.resolutionJson, isNot(contains('Private')));
      expect(receipt.conflict.resolutionJson, contains('localVersion'));
      expect(receipt.conflict.keepsPlanningIncomplete, isFalse);
      expect(await _conflicts(registry), isEmpty);
      final history = await registry.read((repositories) {
        final sync = repositories as SynchronizationLocalReadRepositories;
        return sync.synchronization.listConflicts(
          studentId: _studentId,
          includeResolved: true,
        );
      });
      expect(
        history.single.localSnapshotJson,
        contains('Private Preceptor Name'),
      );
      expect(history.single.remoteSnapshotJson, original.remoteSnapshotJson);
    },
  );

  test(
    'delete resolution writes a synchronized tombstone atomically',
    () async {
      await registry.mutate((repositories) {
        repositories.workShifts.put(
          studentId: _studentId,
          value: WorkShift(id: _firstId, plannedInterval: _interval(9, 11)),
          expectedRevision: 0,
          mutation: _mutation(70),
        );
      });
      final operation = await _operation(registry, _firstId);
      await registry.mutate((repositories) {
        final sync = repositories as SynchronizationLocalWriteRepositories;
        sync.synchronization.recordTerminalRejection(
          studentId: _studentId,
          operation: operation,
          rejectionCode: 'schedule_conflict',
          rejectionJson: '{"code":"schedule_conflict","current_revision":0}',
          rejectedAtUtc: _now.add(const Duration(minutes: 71)),
          createsConflict: true,
        );
      });
      final conflict = (await _conflicts(registry)).single;

      final receipt = await registry.mutate((repositories) {
        final sync = repositories as SynchronizationLocalWriteRepositories;
        return sync.synchronization.resolveConflict(
          studentId: _studentId,
          conflictId: conflict.id,
          choice: SynchronizationConflictResolutionChoice.deleteVersion,
          mutation: _mutation(72),
        );
      });

      expect(receipt.conflict.isResolved, isTrue);
      expect(receipt.operation.type, OutboxOperationType.delete);
      expect(receipt.operation.payloadJson, contains('deleted_at_utc'));
      final deleted = await registry.read(
        (repositories) => repositories.workShifts.find(
          studentId: _studentId,
          id: _firstId,
          includeDeleted: true,
        ),
      );
      expect(deleted, isNotNull);
      expect(deleted!.isDeleted, isTrue);
      expect(deleted.deletedAtUtc, _now.add(const Duration(minutes: 72)));
    },
  );

  test(
    'inbound tombstones create cross-device Trash once and restore normally',
    () async {
      await registry.mutate((repositories) {
        repositories.preceptors.put(
          studentId: _studentId,
          value: Preceptor(id: _firstId, name: 'Remote deletion'),
          expectedRevision: 0,
          mutation: _mutation(80),
        );
      });
      final localOperation = await _operation(registry, _firstId);
      await registry.mutate((repositories) {
        repositories.outbox.acknowledge(
          studentId: _studentId,
          operationId: localOperation.mutation.operationId,
          serverCursor: 1,
          acknowledgedAtUtc: _now.add(const Duration(minutes: 80)),
        );
      });
      final deletedAt = _now.add(const Duration(minutes: 81));
      final payload = jsonEncode({
        'schema_version': 1,
        'entity_type': 'preceptor',
        'entity_id': _firstId,
        'student_id': _studentId,
        'revision': 2,
        'created_at_utc': _mutation(80).occurredAtUtc.toIso8601String(),
        'updated_at_utc': deletedAt.toIso8601String(),
        'deleted_at_utc': deletedAt.toIso8601String(),
        'value': {
          'name': 'Remote deletion',
          'organization_or_site': null,
          'phone': null,
          'email': null,
          'scheduling_notes': null,
        },
      });
      final change = RemoteSynchronizationChange(
        cursor: 1,
        entityType: 'preceptor',
        entityId: _firstId,
        revision: 2,
        operationType: OutboxOperationType.delete,
        payloadJson: payload,
      );

      final first = await registry.mutate((repositories) {
        final sync = repositories as SynchronizationLocalWriteRepositories;
        return sync.synchronization.applyRemoteAndAdvanceCursor(
          studentId: _studentId,
          remoteScope: 'account',
          change: change,
          appliedAtUtc: deletedAt,
        );
      });
      expect(first, RemoteSynchronizationApplyDisposition.applied);
      final trash = await registry.listTrash(nowUtc: deletedAt);
      expect(trash, hasLength(1));
      expect(
        trash.single.purgeAfterUtc,
        deletedAt.add(const Duration(days: 30)),
      );

      final duplicate = await registry.mutate((repositories) {
        final sync = repositories as SynchronizationLocalWriteRepositories;
        return sync.synchronization.applyRemoteAndAdvanceCursor(
          studentId: _studentId,
          remoteScope: 'account',
          change: change,
          appliedAtUtc: deletedAt.add(const Duration(seconds: 1)),
        );
      });
      expect(duplicate, RemoteSynchronizationApplyDisposition.duplicate);
      expect(await registry.listTrash(nowUtc: deletedAt), hasLength(1));

      await registry.restoreTrash(
        trashId: trash.single.id,
        restoredAtUtc: deletedAt.add(const Duration(minutes: 1)),
        mutation: _mutation(82),
      );
      final restored = await registry.read(
        (repositories) =>
            repositories.preceptors.find(studentId: _studentId, id: _firstId),
      );
      expect(restored?.revision, 3);
      expect(await registry.listTrash(nowUtc: deletedAt), isEmpty);
    },
  );

  test(
    'inbound permanent purge converges and blocks identity resurrection',
    () async {
      await registry.mutate((repositories) {
        repositories.preceptors.put(
          studentId: _studentId,
          value: Preceptor(id: _firstId, name: 'Purged remotely'),
          expectedRevision: 0,
          mutation: _mutation(90),
        );
      });
      final localOperation = await _operation(registry, _firstId);
      await registry.mutate((repositories) {
        repositories.outbox.acknowledge(
          studentId: _studentId,
          operationId: localOperation.mutation.operationId,
          serverCursor: 1,
          acknowledgedAtUtc: _now.add(const Duration(minutes: 90)),
        );
      });
      final createdAt = _mutation(90).occurredAtUtc.toIso8601String();
      final deletedAt = _now.add(const Duration(minutes: 91));
      final deleteEnvelope = {
        'schema_version': 1,
        'entity_type': 'preceptor',
        'entity_id': _firstId,
        'student_id': _studentId,
        'revision': 2,
        'created_at_utc': createdAt,
        'updated_at_utc': deletedAt.toIso8601String(),
        'deleted_at_utc': deletedAt.toIso8601String(),
        'value': {
          'name': 'Purged remotely',
          'organization_or_site': null,
          'phone': null,
          'email': null,
          'scheduling_notes': null,
        },
      };
      await registry.mutate((repositories) {
        final sync = repositories as SynchronizationLocalWriteRepositories;
        return sync.synchronization.applyRemoteAndAdvanceCursor(
          studentId: _studentId,
          remoteScope: 'account',
          change: RemoteSynchronizationChange(
            cursor: 1,
            entityType: 'preceptor',
            entityId: _firstId,
            revision: 2,
            operationType: OutboxOperationType.delete,
            payloadJson: jsonEncode(deleteEnvelope),
          ),
          appliedAtUtc: deletedAt,
        );
      });
      expect(await registry.listTrash(nowUtc: deletedAt), hasLength(1));

      final purgedAt = deletedAt.add(const Duration(minutes: 1));
      final purgeEnvelope = {
        'schema_version': 1,
        'entity_type': 'preceptor',
        'entity_id': _firstId,
        'student_id': _studentId,
        'revision': 3,
        'created_at_utc': createdAt,
        'updated_at_utc': purgedAt.toIso8601String(),
        'deleted_at_utc': deletedAt.toIso8601String(),
        'purged_at_utc': purgedAt.toIso8601String(),
        'value': <String, Object?>{},
      };
      final disposition = await registry.mutate((repositories) {
        final sync = repositories as SynchronizationLocalWriteRepositories;
        return sync.synchronization.applyRemoteAndAdvanceCursor(
          studentId: _studentId,
          remoteScope: 'account',
          change: RemoteSynchronizationChange(
            cursor: 2,
            entityType: 'preceptor',
            entityId: _firstId,
            revision: 3,
            operationType: OutboxOperationType.purge,
            payloadJson: jsonEncode(purgeEnvelope),
          ),
          appliedAtUtc: purgedAt,
        );
      });
      expect(disposition, RemoteSynchronizationApplyDisposition.applied);
      expect(await registry.listTrash(nowUtc: purgedAt), isEmpty);
      expect(
        database.select('SELECT 1 FROM preceptors WHERE id = ?', [_firstId]),
        isEmpty,
      );
      expect(
        database.select(
          'SELECT revision FROM permanent_purge_markers WHERE entity_id = ?',
          [_firstId],
        ).single['revision'],
        3,
      );
      await expectLater(
        registry.mutate(
          (repositories) => repositories.preceptors.put(
            studentId: _studentId,
            value: Preceptor(id: _firstId, name: 'Resurrection'),
            expectedRevision: 0,
            mutation: _mutation(92),
          ),
        ),
        throwsA(isA<RepositoryException>()),
      );
    },
  );
}

Future<OutboxOperation> _operation(
  SqliteRepositoryRegistry registry,
  String entityId,
) => registry.read(
  (repositories) => repositories.outbox
      .pending(
        studentId: _studentId,
        asOfUtc: _now.add(const Duration(days: 1)),
      )
      .singleWhere((operation) => operation.entityId == entityId),
);

Future<List<SynchronizationConflictRecord>> _conflicts(
  SqliteRepositoryRegistry registry,
) => registry.read((repositories) {
  final sync = repositories as SynchronizationLocalReadRepositories;
  return sync.synchronization.listConflicts(studentId: _studentId);
});

MutationToken _mutation(int sequence) => MutationToken(
  operationId: _id(1000 + sequence * 2),
  idempotencyKey: _id(1001 + sequence * 2),
  occurredAtUtc: _now.add(Duration(minutes: sequence)),
);

ZonedInterval _interval(int startHour, int endHour) => ZonedInterval(
  startDate: LocalDate(2026, 8, 4),
  startTime: LocalTime(startHour, 0),
  endTime: LocalTime(endHour, 0),
  timeZone: TimeZoneId('America/New_York'),
  startOffset: UtcOffset.inMinutes(-4 * 60),
  endOffset: UtcOffset.inMinutes(-4 * 60),
);

String _id(int value) =>
    '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';

final class _Identifiers implements IdentifierGenerator {
  _Identifiers(this.next);
  int next;

  @override
  String nextIdentifier() => _id(next++);
}

final class _Storage implements SecureStorage {
  final values = <String, String>{
    ClinicalCalendarDatabase.encryptionKeyStorageKey: _key,
  };

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
