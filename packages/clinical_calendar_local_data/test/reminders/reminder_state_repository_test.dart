import 'dart:convert';
import 'dart:io';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
// ignore: implementation_imports
// ignore: implementation_imports
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:test/test.dart';

const _key =
    '0123456789abcdef0123456789abcdef'
    '0123456789abcdef0123456789abcdef';
const _studentId = '00000000-0000-4000-8000-000000000001';
const _reminderId = '00000000-0000-4000-8000-000000000002';
const _remoteReminderId = '00000000-0000-4000-8000-000000000003';
final _now = DateTime.utc(2026, 8, 4, 12);

void main() {
  late Directory directory;
  late ClinicalCalendarDatabase database;
  late SqliteRepositoryRegistry registry;
  late _MemorySecureStorage secureStorage;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'clinical-calendar-reminders-',
    );
    secureStorage = _MemorySecureStorage(_key);
    database = await ClinicalCalendarDatabase.open(
      path: '${directory.path}${Platform.pathSeparator}calendar.db',
      secureStorage: secureStorage,
    );
    registry = _registry(database);
    await registry.initialize();
  });

  tearDown(() async {
    await database.close();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test(
    'snooze persists across restart and enqueues synchronized state',
    () async {
      final service = ReminderStateApplicationService(registry);
      final snoozedUntil = _now.add(const Duration(hours: 1));
      await service.put(
        studentId: _studentId,
        value: ReminderState(
          id: _reminderId,
          occurrenceKey: 'clinicalConfirmation:session:base',
          kind: ReminderKind.clinicalConfirmation,
          subjectEntityId: 'session',
          scheduledForUtc: _now,
          snoozedUntilUtc: snoozedUntil,
        ),
        expectedRevision: 0,
        mutation: _mutation(1),
      );

      final outbox = database
          .select('SELECT entity_type, payload_json FROM outbox_operations')
          .single;
      expect(outbox['entity_type'], 'reminder_state');
      expect(
        (jsonDecode(outbox['payload_json']! as String)
            as Map<String, dynamic>)['value']['snoozed_until_utc'],
        snoozedUntil.toIso8601String(),
      );

      final path = database.path;
      await database.close();
      database = await ClinicalCalendarDatabase.open(
        path: path,
        secureStorage: secureStorage,
      );
      registry = _registry(database);
      await registry.initialize();
      expect(
        await ReminderStateApplicationService(
          registry,
        ).synchronizedSnoozes(studentId: _studentId),
        {'clinicalConfirmation:session:base': snoozedUntil},
      );
    },
  );

  test(
    'remote synchronized snooze is applied to local reminder truth',
    () async {
      final snoozedUntil = _now.add(const Duration(days: 3));
      final envelope = jsonEncode({
        'schema_version': 1,
        'entity_type': 'reminder_state',
        'entity_id': _remoteReminderId,
        'student_id': _studentId,
        'revision': 1,
        'created_at_utc': _now.toIso8601String(),
        'updated_at_utc': _now.toIso8601String(),
        'deleted_at_utc': null,
        'value': {
          'reminder_type': 'protectedDayPlanning',
          'subject_entity_id': 'week',
          'scheduled_for_utc': _now.toIso8601String(),
          'snoozed_until_utc': snoozedUntil.toIso8601String(),
          'resolved_at_utc': null,
          'resolution_source': null,
          'occurrence_key': 'protectedDayPlanning:week:base',
        },
      });
      await registry.mutate((repositories) {
        final sync = repositories as SynchronizationLocalWriteRepositories;
        expect(
          sync.synchronization.applyRemoteAndAdvanceCursor(
            studentId: _studentId,
            remoteScope: 'student',
            change: RemoteSynchronizationChange(
              cursor: 1,
              entityType: 'reminder_state',
              entityId: _remoteReminderId,
              revision: 1,
              operationType: OutboxOperationType.upsert,
              payloadJson: envelope,
            ),
            appliedAtUtc: _now,
          ),
          RemoteSynchronizationApplyDisposition.applied,
        );
      });
      expect(
        await ReminderStateApplicationService(
          registry,
        ).synchronizedSnoozes(studentId: _studentId),
        {'protectedDayPlanning:week:base': snoozedUntil},
      );
    },
  );
}

SqliteRepositoryRegistry _registry(ClinicalCalendarDatabase database) =>
    SqliteRepositoryRegistry(
      studentId: _studentId,
      database: database,
      identifierGenerator: _Identifiers(),
    );

MutationToken _mutation(int value) => MutationToken(
  operationId: _id(100 + value * 2),
  idempotencyKey: _id(101 + value * 2),
  occurredAtUtc: _now,
);

String _id(int value) =>
    '00000000-0000-4000-8000-${value.toRadixString(16).padLeft(12, '0')}';

final class _Identifiers implements IdentifierGenerator {
  int next = 1000;
  @override
  String nextIdentifier() => _id(next++);
}

final class _MemorySecureStorage implements SecureStorage {
  _MemorySecureStorage(String key) {
    values[ClinicalCalendarDatabase.encryptionKeyStorageKey] = key;
  }
  final Map<String, String> values = {};
  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
