import 'dart:convert';
import 'dart:io';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

const _key =
    '0123456789abcdef0123456789abcdef'
    '0123456789abcdef0123456789abcdef';
const _studentId = '00000000-0000-4000-8000-000000000001';
const _profileId = '00000000-0000-4000-8000-000000000002';
final _baseTime = DateTime.utc(2026, 8, 3, 12);

void main() {
  late Directory temporaryDirectory;
  late String databasePath;
  late ClinicalCalendarDatabase database;
  late SqliteRepositoryRegistry registry;
  late DeterministicIdentifierGenerator identifiers;
  var databaseIsOpen = false;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'clinical-calendar-repositories-',
    );
    databasePath =
        '${temporaryDirectory.path}${Platform.pathSeparator}calendar.db';
    database = await ClinicalCalendarDatabase.open(
      path: databasePath,
      secureStorage: MemorySecureStorage(_key),
    );
    databaseIsOpen = true;
    identifiers = DeterministicIdentifierGenerator();
    registry = _registry(database, identifiers);
  });

  tearDown(() async {
    if (databaseIsOpen) {
      await database.close();
    }
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('local removal preview is FIFO-safe and close is final', () async {
    await registry.initialize();

    final preview = await registry.localRemovalPreview();
    expect(preview.count, 0);
    expect(preview.oldestAtUtc, isNull);
    expect(registry.databasePath, databasePath);

    await registry.close();
    databaseIsOpen = false;
    await expectLater(
      registry.read((_) => null),
      throwsA(_repositoryFailure(RepositoryFailureKind.closed)),
    );
  });

  test(
    'local removal preview excludes only rejected audit rows with accepted replacements',
    () async {
      await registry.initialize();
      const entityId = '00000000-0000-4000-8000-000000000091';
      const payload = '{"entity_id":"$entityId"}';
      const rejectedAt = '2026-08-03T12:00:00.000Z';
      const liveCreatedAt = '2026-08-03T13:00:00.000Z';
      database.execute(
        '''INSERT INTO outbox_operations
          (id, student_id, idempotency_key, entity_type, entity_id,
           operation_type, base_revision, payload_json, created_at_utc,
           terminal_rejection_code, terminal_rejected_at_utc)
          VALUES
          ('00000000-0000-4000-8000-000000000092', ?,
           '00000000-0000-4000-8000-000000000093', 'evaluation_plan', ?,
           'upsert', 0, ?, ?, 'relationship_violation', ?),
          ('00000000-0000-4000-8000-000000000094', ?,
           '00000000-0000-4000-8000-000000000095', 'evaluation_plan', ?,
           'upsert', 0, ?, ?, NULL, NULL),
          ('00000000-0000-4000-8000-000000000096', ?,
           '00000000-0000-4000-8000-000000000097', 'settings', ?,
           'upsert', 1, '{"entity_id":"$_studentId"}', ?, NULL, NULL)''',
        [
          _studentId,
          entityId,
          payload,
          rejectedAt,
          rejectedAt,
          _studentId,
          entityId,
          payload,
          rejectedAt,
          _studentId,
          _studentId,
          liveCreatedAt,
        ],
      );
      database.execute(
        '''UPDATE outbox_operations
          SET acknowledged_cursor = 8, acknowledged_at_utc = ?
          WHERE id = '00000000-0000-4000-8000-000000000094' ''',
        ['2026-08-03T12:05:00.000Z'],
      );
      database.execute(
        '''INSERT INTO outbox_operations
          (id, student_id, idempotency_key, entity_type, entity_id,
           operation_type, base_revision, payload_json, created_at_utc,
           acknowledged_cursor, acknowledged_at_utc,
           terminal_rejection_code, terminal_rejected_at_utc)
          VALUES
          ('00000000-0000-4000-8000-000000000098', ?,
           '00000000-0000-4000-8000-000000000099', 'settings', ?,
           'upsert', 0, '{"entity_id":"$_studentId","revision":1}', ?,
           NULL, NULL, 'stale_revision', ?),
          ('00000000-0000-4000-8000-000000000100', ?,
           '00000000-0000-4000-8000-000000000101', 'settings', ?,
           'upsert', 1, '{"entity_id":"$_studentId","revision":2}', ?,
           9, ?, NULL, NULL)''',
        [
          _studentId,
          _studentId,
          '2026-08-03T11:00:00.000Z',
          '2026-08-03T11:01:00.000Z',
          _studentId,
          _studentId,
          '2026-08-03T12:00:00.000Z',
          '2026-08-03T12:05:00.000Z',
        ],
      );

      final preview = await registry.localRemovalPreview();

      expect(preview.count, 1);
      expect(preview.oldestAtUtc, DateTime.parse(liveCreatedAt));
    },
  );

  test(
    'initialize gates access and all eight domain types round-trip',
    () async {
      await expectLater(
        registry.read((_) => null),
        throwsA(_repositoryFailure(RepositoryFailureKind.uninitialized)),
      );

      await registry.initialize();
      await registry.initialize();
      final fixture = _DomainFixture();
      final mutations = <String, MutationToken>{};

      await registry.mutate((repositories) {
        void put<T>(
          MutableRepository<T> repository,
          T value,
          String id,
          int sequence,
        ) {
          final mutation = _mutation(sequence);
          mutations[id] = mutation;
          final receipt = repository.put(
            studentId: _studentId,
            value: value,
            expectedRevision: 0,
            mutation: mutation,
          );
          expect(receipt.replayed, isFalse);
          _expectMetadata(receipt.record, mutation.occurredAtUtc);
        }

        put(
          repositories.preceptors,
          fixture.preceptor,
          fixture.preceptor.id,
          1,
        );
        put(
          repositories.clinicalPlacements,
          fixture.placement,
          fixture.placement.id,
          2,
        );
        put(
          repositories.evaluationPlans,
          fixture.evaluationPlan,
          fixture.evaluationPlan.id,
          3,
        );
        put(
          repositories.workShifts,
          fixture.workShift,
          fixture.workShift.id,
          4,
        );
        put(
          repositories.clinicalSessions,
          fixture.clinicalSession,
          fixture.clinicalSession.id,
          5,
        );
        put(
          repositories.protectedDays,
          fixture.protectedDay,
          fixture.protectedDay.id,
          6,
        );
        put(
          repositories.scheduleTemplates,
          fixture.scheduleTemplate,
          fixture.scheduleTemplate.id,
          7,
        );
        put(
          repositories.historicalHoursEntries,
          fixture.historicalHoursEntry,
          fixture.historicalHoursEntry.id,
          8,
        );
      });

      await registry.read((repositories) {
        void expectRoundTrip<T extends Object>(
          ReadRepository<T> repository,
          String id,
          Object expected,
        ) {
          final record = repository.find(studentId: _studentId, id: id);
          expect(record, isNotNull);
          expect(_domainSnapshot(record!.value), _domainSnapshot(expected));
          _expectMetadata(record, mutations[id]!.occurredAtUtc);
        }

        expectRoundTrip(
          repositories.preceptors,
          fixture.preceptor.id,
          fixture.preceptor,
        );
        expectRoundTrip(
          repositories.clinicalPlacements,
          fixture.placement.id,
          fixture.placement,
        );
        expectRoundTrip(
          repositories.evaluationPlans,
          fixture.evaluationPlan.id,
          fixture.evaluationPlan,
        );
        expectRoundTrip(
          repositories.workShifts,
          fixture.workShift.id,
          fixture.workShift,
        );
        expectRoundTrip(
          repositories.clinicalSessions,
          fixture.clinicalSession.id,
          fixture.clinicalSession,
        );
        expectRoundTrip(
          repositories.protectedDays,
          fixture.protectedDay.id,
          fixture.protectedDay,
        );
        expectRoundTrip(
          repositories.scheduleTemplates,
          fixture.scheduleTemplate.id,
          fixture.scheduleTemplate,
        );
        expectRoundTrip(
          repositories.historicalHoursEntries,
          fixture.historicalHoursEntry.id,
          fixture.historicalHoursEntry,
        );
        final pending = repositories.outbox.pending(
          studentId: _studentId,
          asOfUtc: _baseTime.add(const Duration(hours: 1)),
        );
        expect(pending, hasLength(8));
        expect(pending.map((operation) => operation.entityType).toSet(), {
          'preceptor',
          'clinical_placement',
          'evaluation_plan',
          'work_shift',
          'clinical_session',
          'protected_day',
          'schedule_template',
          'historical_hours_entry',
        });
        expect(
          pending.every((operation) => operation.baseRevision == 0),
          isTrue,
        );
      });
    },
  );

  test(
    'one mutation commits multiple entities and their outboxes atomically',
    () async {
      await registry.initialize();
      final first = Preceptor(id: _id(20), name: 'First Preceptor');
      final second = Preceptor(id: _id(21), name: 'Second Preceptor');

      await registry.mutate((repositories) {
        repositories.preceptors.put(
          studentId: _studentId,
          value: first,
          expectedRevision: 0,
          mutation: _mutation(20),
        );
        repositories.preceptors.put(
          studentId: _studentId,
          value: second,
          expectedRevision: 0,
          mutation: _mutation(21),
        );
      });

      await registry.read((repositories) {
        expect(
          repositories.preceptors.list(studentId: _studentId),
          hasLength(2),
        );
        expect(
          repositories.outbox.pending(
            studentId: _studentId,
            asOfUtc: _baseTime.add(const Duration(hours: 1)),
          ),
          hasLength(2),
        );
      });
    },
  );

  test('Clinical Session Preceptor reassignment survives restart', () async {
    await registry.initialize();
    final fixture = _DomainFixture();
    final alternate = Preceptor(id: _id(18), name: 'Taylor Morgan');
    final placement = ClinicalPlacement.create(
      id: fixture.placement.id,
      name: fixture.placement.name,
      targetHours: fixture.placement.targetHours,
      startDate: fixture.placement.startDate,
      completionDeadline: fixture.placement.completionDeadline,
      attachedPreceptorIds: [fixture.preceptor.id, alternate.id],
      primaryPreceptorId: fixture.preceptor.id,
      evaluationPlanId: fixture.evaluationPlan.id,
    );
    final session = ClinicalSession.schedule(
      id: fixture.clinicalSession.id,
      clinicalPlacementId: placement.id,
      preceptorId: fixture.preceptor.id,
      plannedInterval: fixture.clinicalSession.plannedInterval,
      asOfUtc: _baseTime,
    );
    await registry.mutate((repositories) {
      repositories.preceptors.put(
        studentId: _studentId,
        value: fixture.preceptor,
        expectedRevision: 0,
        mutation: _mutation(110),
      );
      repositories.preceptors.put(
        studentId: _studentId,
        value: alternate,
        expectedRevision: 0,
        mutation: _mutation(111),
      );
      repositories.clinicalPlacements.put(
        studentId: _studentId,
        value: placement,
        expectedRevision: 0,
        mutation: _mutation(112),
      );
      repositories.evaluationPlans.put(
        studentId: _studentId,
        value: fixture.evaluationPlan,
        expectedRevision: 0,
        mutation: _mutation(113),
      );
      repositories.clinicalSessions.put(
        studentId: _studentId,
        value: session,
        expectedRevision: 0,
        mutation: _mutation(114),
      );
    });
    final service = SchedulingApplicationService(
      registry,
      _FixedClock(_baseTime.add(const Duration(hours: 3))),
      identifiers,
    );

    final result = await service.reviseClinicalSession(
      studentId: _studentId,
      id: session.id,
      plannedInterval: session.plannedInterval,
      preceptorId: alternate.id,
    );
    expect(result.records.single.value.preceptorId, alternate.id);

    await database.close();
    databaseIsOpen = false;
    database = await ClinicalCalendarDatabase.open(
      path: databasePath,
      secureStorage: MemorySecureStorage(_key),
    );
    databaseIsOpen = true;
    registry = _registry(database, identifiers);
    await registry.initialize();

    await registry.read((repositories) {
      final reloaded = repositories.clinicalSessions.find(
        studentId: _studentId,
        id: session.id,
      )!;
      expect(reloaded.value.id, session.id);
      expect(reloaded.value.clinicalPlacementId, placement.id);
      expect(reloaded.value.preceptorId, alternate.id);
      expect(reloaded.value.state, ClinicalSessionState.scheduled);
    });
  });

  test('pending outbox orders relationship owners before dependents', () async {
    await registry.initialize();
    final fixture = _DomainFixture();

    await registry.mutate((repositories) {
      repositories.preceptors.put(
        studentId: _studentId,
        value: fixture.preceptor,
        expectedRevision: 0,
        mutation: _mutation(3),
      );
      repositories.clinicalPlacements.put(
        studentId: _studentId,
        value: fixture.placement,
        expectedRevision: 0,
        mutation: _mutation(2),
      );
      repositories.evaluationPlans.put(
        studentId: _studentId,
        value: fixture.evaluationPlan,
        expectedRevision: 0,
        mutation: _mutation(1),
      );
    });

    await registry.read((repositories) {
      expect(
        repositories.outbox
            .pending(
              studentId: _studentId,
              asOfUtc: _baseTime.add(const Duration(hours: 1)),
            )
            .map((operation) => operation.entityType),
        ['preceptor', 'clinical_placement', 'evaluation_plan'],
      );
    });
  });

  test(
    'foreign-key failure rolls back earlier entity and outbox writes',
    () async {
      await registry.initialize();
      final workShift = WorkShift(
        id: _id(30),
        plannedInterval: _interval(10, 12),
      );
      final invalidSession = ClinicalSession.schedule(
        id: _id(31),
        clinicalPlacementId: _id(32),
        preceptorId: _id(33),
        plannedInterval: _interval(13, 15),
        asOfUtc: _baseTime,
      );

      await expectLater(
        registry.mutate((repositories) {
          repositories.workShifts.put(
            studentId: _studentId,
            value: workShift,
            expectedRevision: 0,
            mutation: _mutation(30),
          );
          repositories.clinicalSessions.put(
            studentId: _studentId,
            value: invalidSession,
            expectedRevision: 0,
            mutation: _mutation(31),
          );
        }),
        throwsA(_repositoryFailure(RepositoryFailureKind.persistenceFailure)),
      );

      await registry.read((repositories) {
        expect(
          repositories.workShifts.find(studentId: _studentId, id: workShift.id),
          isNull,
        );
        expect(
          repositories.outbox.pending(
            studentId: _studentId,
            asOfUtc: _baseTime.add(const Duration(hours: 1)),
          ),
          isEmpty,
        );
      });
    },
  );

  test(
    'expected-revision failure rolls back earlier entity and outbox writes',
    () async {
      await registry.initialize();
      final existing = Preceptor(id: _id(40), name: 'Existing');
      await registry.mutate((repositories) {
        repositories.preceptors.put(
          studentId: _studentId,
          value: existing,
          expectedRevision: 0,
          mutation: _mutation(40),
        );
      });
      final rolledBack = WorkShift(
        id: _id(41),
        plannedInterval: _interval(8, 9),
      );

      await expectLater(
        registry.mutate((repositories) {
          repositories.workShifts.put(
            studentId: _studentId,
            value: rolledBack,
            expectedRevision: 0,
            mutation: _mutation(41),
          );
          repositories.preceptors.put(
            studentId: _studentId,
            value: Preceptor(id: existing.id, name: 'Stale update'),
            expectedRevision: 0,
            mutation: _mutation(42),
          );
        }),
        throwsA(
          _repositoryFailure(RepositoryFailureKind.concurrentModification),
        ),
      );

      await registry.read((repositories) {
        expect(
          repositories.workShifts.find(
            studentId: _studentId,
            id: rolledBack.id,
          ),
          isNull,
        );
        expect(
          repositories.outbox.pending(
            studentId: _studentId,
            asOfUtc: _baseTime.add(const Duration(hours: 1)),
          ),
          hasLength(1),
        );
      });
    },
  );

  test(
    'restart preserves pending intent and exact token replay is idempotent',
    () async {
      await registry.initialize();
      final preceptor = Preceptor(id: _id(50), name: 'Restart Preceptor');
      final mutation = _mutation(50);
      final first = await registry.mutate(
        (repositories) => repositories.preceptors.put(
          studentId: _studentId,
          value: preceptor,
          expectedRevision: 0,
          mutation: mutation,
        ),
      );
      expect(first.record.revision, 1);

      await database.close();
      databaseIsOpen = false;
      database = await ClinicalCalendarDatabase.open(
        path: databasePath,
        secureStorage: MemorySecureStorage(_key),
      );
      databaseIsOpen = true;
      registry = _registry(database, identifiers);
      await registry.initialize();

      final replay = await registry.mutate(
        (repositories) => repositories.preceptors.put(
          studentId: _studentId,
          value: preceptor,
          expectedRevision: 0,
          mutation: mutation,
        ),
      );
      expect(replay.replayed, isTrue);
      expect(replay.record.revision, 1);
      await registry.read((repositories) {
        expect(
          repositories.outbox.pending(
            studentId: _studentId,
            asOfUtc: _baseTime.add(const Duration(hours: 1)),
          ),
          hasLength(1),
        );
      });

      await expectLater(
        registry.mutate(
          (repositories) => repositories.preceptors.put(
            studentId: _studentId,
            value: Preceptor(id: preceptor.id, name: 'Different payload'),
            expectedRevision: 0,
            mutation: MutationToken(
              operationId: _id(51),
              idempotencyKey: mutation.idempotencyKey,
              occurredAtUtc: mutation.occurredAtUtc,
            ),
          ),
        ),
        throwsA(_repositoryFailure(RepositoryFailureKind.idempotencyConflict)),
      );
    },
  );

  test('concurrent mutation Futures execute in FIFO request order', () async {
    await registry.initialize();
    final observedOrder = <int>[];

    Future<int> enqueue(int sequence) => registry.mutate((repositories) {
      observedOrder.add(sequence);
      repositories.preceptors.put(
        studentId: _studentId,
        value: Preceptor(id: _id(60 + sequence), name: 'Preceptor $sequence'),
        expectedRevision: 0,
        mutation: _mutation(60 + sequence),
      );
      return sequence;
    });

    final futures = [enqueue(1), enqueue(2), enqueue(3)];
    expect(await Future.wait(futures), [1, 2, 3]);
    expect(observedOrder, [1, 2, 3]);
    await registry.read((repositories) {
      expect(repositories.preceptors.list(studentId: _studentId), hasLength(3));
    });
  });

  test('repositories expire when their callback ends', () async {
    await registry.initialize();
    late LocalWriteRepositories escaped;
    await registry.mutate((repositories) {
      escaped = repositories;
    });

    expect(
      () => escaped.preceptors.list(studentId: _studentId),
      throwsA(_repositoryFailure(RepositoryFailureKind.closed)),
    );
    expect(
      () => escaped.syncCursors.put(
        SyncCursor(
          studentId: _studentId,
          remoteScope: 'escaped-callback',
          serverCursor: 1,
          updatedAtUtc: _baseTime,
        ),
      ),
      throwsA(_repositoryFailure(RepositoryFailureKind.closed)),
    );
  });

  test('tombstone is hidden, retained in Trash, and put restores it', () async {
    await registry.initialize();
    final original = Preceptor(id: _id(70), name: 'Restorable Preceptor');
    await registry.mutate((repositories) {
      repositories.preceptors.put(
        studentId: _studentId,
        value: original,
        expectedRevision: 0,
        mutation: _mutation(70),
      );
    });
    final deleted = await registry.mutate(
      (repositories) => repositories.preceptors.tombstone(
        studentId: _studentId,
        id: original.id,
        expectedRevision: 1,
        mutation: _mutation(71),
      ),
    );
    expect(deleted.record.revision, 2);
    expect(deleted.record.isDeleted, isTrue);

    await registry.read((repositories) {
      expect(
        repositories.preceptors.find(studentId: _studentId, id: original.id),
        isNull,
      );
      expect(repositories.preceptors.list(studentId: _studentId), isEmpty);
      expect(
        repositories.preceptors
            .find(studentId: _studentId, id: original.id, includeDeleted: true)!
            .isDeleted,
        isTrue,
      );
    });
    final activeTrash = database.select(
      'SELECT * FROM trash WHERE student_id = ? AND entity_type = ? '
      'AND entity_id = ?',
      [_studentId, 'preceptor', original.id],
    ).single;
    expect(activeTrash['permanently_deleted_at_utc'], isNull);
    expect(activeTrash['deleted_snapshot_json'], contains(original.name));

    final restoredValue = Preceptor(
      id: original.id,
      name: 'Restored Preceptor',
    );
    final restored = await registry.mutate(
      (repositories) => repositories.preceptors.put(
        studentId: _studentId,
        value: restoredValue,
        expectedRevision: 2,
        mutation: _mutation(72),
      ),
    );
    expect(restored.record.revision, 3);
    expect(restored.record.isDeleted, isFalse);
    await registry.read((repositories) {
      expect(
        repositories.preceptors
            .find(studentId: _studentId, id: original.id)!
            .value
            .name,
        'Restored Preceptor',
      );
    });
    final resolvedTrash = database.select(
      'SELECT * FROM trash WHERE student_id = ? AND entity_type = ? '
      'AND entity_id = ?',
      [_studentId, 'preceptor', original.id],
    ).single;
    expect(resolvedTrash['deleted_at_utc'], isNotNull);
    expect(resolvedTrash['permanently_deleted_at_utc'], isNotNull);
  });

  test(
    'outbox failure backoff and acknowledgement maintenance persist',
    () async {
      await registry.initialize();
      final operation = _mutation(80);
      await registry.mutate((repositories) {
        repositories.preceptors.put(
          studentId: _studentId,
          value: Preceptor(id: _id(80), name: 'Outbox Preceptor'),
          expectedRevision: 0,
          mutation: operation,
        );
      });
      final attemptedAt = _baseTime.add(const Duration(minutes: 20));
      final retryAt = attemptedAt.add(const Duration(minutes: 5));
      await registry.mutate((repositories) {
        repositories.outbox.recordFailedAttempt(
          studentId: _studentId,
          operationId: operation.operationId,
          attemptedAtUtc: attemptedAt,
          nextAttemptAtUtc: retryAt,
          failureCode: 'offline',
        );
      });

      await registry.read((repositories) {
        expect(
          repositories.outbox.pending(
            studentId: _studentId,
            asOfUtc: retryAt.subtract(const Duration(microseconds: 1)),
          ),
          isEmpty,
        );
        final due = repositories.outbox
            .pending(studentId: _studentId, asOfUtc: retryAt)
            .single;
        expect(due.attemptCount, 1);
        expect(due.nextAttemptAtUtc, retryAt);
        expect(due.lastFailureCode, 'offline');
      });

      final acknowledgedAt = retryAt.add(const Duration(minutes: 1));
      await registry.mutate((repositories) {
        repositories.outbox.acknowledge(
          studentId: _studentId,
          operationId: operation.operationId,
          serverCursor: 123,
          acknowledgedAtUtc: acknowledgedAt,
        );
      });
      await registry.read((repositories) {
        expect(
          repositories.outbox.pending(
            studentId: _studentId,
            asOfUtc: acknowledgedAt,
          ),
          isEmpty,
        );
      });
      final row = database.select(
        'SELECT * FROM outbox_operations WHERE id = ?',
        [operation.operationId],
      ).single;
      expect(row['acknowledged_cursor'], 123);
      expect(row['acknowledged_at_utc'], acknowledgedAt.toIso8601String());
      expect(row['last_failure_code'], isNull);
    },
  );

  test('synchronization cursor survives close and reopen', () async {
    await registry.initialize();
    final cursor = SyncCursor(
      studentId: _studentId,
      remoteScope: 'student-calendar',
      serverCursor: 456,
      updatedAtUtc: _baseTime,
    );
    await registry.mutate(
      (repositories) => repositories.syncCursors.put(cursor),
    );
    await database.close();
    databaseIsOpen = false;

    database = await ClinicalCalendarDatabase.open(
      path: databasePath,
      secureStorage: MemorySecureStorage(_key),
    );
    databaseIsOpen = true;
    registry = _registry(database, identifiers);
    await registry.initialize();
    await registry.read((repositories) {
      final restored = repositories.syncCursors.find(
        studentId: _studentId,
        remoteScope: cursor.remoteScope,
      );
      expect(restored, isNotNull);
      expect(restored!.studentId, cursor.studentId);
      expect(restored.remoteScope, cursor.remoteScope);
      expect(restored.serverCursor, cursor.serverCursor);
      expect(restored.updatedAtUtc, cursor.updatedAtUtc);
    });
  });

  test(
    'Student settings preserve an unknown theme and Enhanced accessibility independently',
    () async {
      await registry.initialize();

      final saved = await registry.mutate(
        (repositories) =>
            (repositories as SupportLocalWriteRepositories).studentSettings.put(
              studentId: _studentId,
              settings: StudentSettings(
                themeId: 'future-theme',
                enhancedAccessibility: true,
              ),
              expectedRevision: 0,
              mutation: _mutation(100),
            ),
      );

      expect(saved.record.value.themeId, 'future-theme');
      expect(saved.record.value.enhancedAccessibility, isTrue);

      await database.close();
      databaseIsOpen = false;
      database = await ClinicalCalendarDatabase.open(
        path: databasePath,
        secureStorage: MemorySecureStorage(_key),
      );
      databaseIsOpen = true;
      registry = _registry(database, identifiers);
      await registry.initialize();

      await registry.read((repositories) {
        final support = repositories as SupportLocalReadRepositories;
        final restored = support.studentSettings.find(studentId: _studentId);
        expect(restored!.value.themeId, 'future-theme');
        expect(restored.value.enhancedAccessibility, isTrue);

        final operation = repositories.outbox
            .pending(
              studentId: _studentId,
              asOfUtc: _baseTime.add(const Duration(days: 1)),
            )
            .single;
        expect(operation.payloadJson, contains('"theme":"future-theme"'));
        expect(
          operation.payloadJson,
          contains('"enhanced_accessibility":true'),
        );
        expect(operation.payloadJson, isNot(contains('preview')));
        expect(operation.payloadJson, isNot(contains('asset')));
      });
    },
  );

  test(
    'settings-inclusive export preserves theme and Enhanced accessibility only',
    () async {
      await registry.initialize();
      await registry.mutate(
        (repositories) =>
            (repositories as SupportLocalWriteRepositories).studentSettings.put(
              studentId: _studentId,
              settings: StudentSettings(
                themeId: 'future-theme',
                enhancedAccessibility: true,
              ),
              expectedRevision: 0,
              mutation: _mutation(101),
            ),
      );
      const clock = _FixedClock();
      final placementService = PlacementApplicationService(
        repositories: registry,
        clock: clock,
        identifiers: identifiers,
        studentId: _studentId,
      );
      final export = await ExportDataService(
        registry,
        placementService,
        clock,
        _studentId,
      ).completePortableData();

      final records = export.document['records']! as Map<String, Object?>;
      final settingsRecord =
          records['student_settings']! as Map<String, Object?>;
      final settings = settingsRecord['value']! as Map<String, Object?>;
      expect(settings['theme_id'], 'future-theme');
      expect(settings['enhanced_accessibility'], isTrue);
      expect(settings.keys, isNot(contains('preview_theme_id')));
      expect(settings.keys, isNot(contains('theme_assets')));
    },
  );

  test(
    'repository works after opening and migrating a real v2 fixture',
    () async {
      await database.close();
      databaseIsOpen = false;
      await File(databasePath).delete();
      await _createFixture(databasePath, version: 2);

      database = await ClinicalCalendarDatabase.open(
        path: databasePath,
        secureStorage: MemorySecureStorage(_key),
      );
      databaseIsOpen = true;
      expect(database.schemaVersion, DatabaseMigrationRunner.latestVersion);
      registry = _registry(database, identifiers);
      await registry.initialize();
      final shift = WorkShift(id: _id(90), plannedInterval: _interval(7, 8));
      await registry.mutate((repositories) {
        repositories.workShifts.put(
          studentId: _studentId,
          value: shift,
          expectedRevision: 0,
          mutation: _mutation(90),
        );
      });

      await registry.read((repositories) {
        expect(
          repositories.workShifts
              .find(studentId: _studentId, id: shift.id)!
              .value
              .plannedMinutes,
          60,
        );
        expect(
          repositories.outbox.pending(
            studentId: _studentId,
            asOfUtc: _baseTime.add(const Duration(hours: 1)),
          ),
          hasLength(1),
        );
      });
    },
  );

  test(
    'active Clinical Placement selection is durable and synchronized',
    () async {
      await registry.initialize();
      final fixture = _DomainFixture();
      final selectionMutation = _mutation(103);
      await registry.mutate((repositories) {
        repositories.preceptors.put(
          studentId: _studentId,
          value: fixture.preceptor,
          expectedRevision: 0,
          mutation: _mutation(100),
        );
        repositories.clinicalPlacements.put(
          studentId: _studentId,
          value: fixture.placement,
          expectedRevision: 0,
          mutation: _mutation(101),
        );
        repositories.evaluationPlans.put(
          studentId: _studentId,
          value: fixture.evaluationPlan,
          expectedRevision: 0,
          mutation: _mutation(102),
        );
        final selected = repositories.activePlacementSelection.put(
          studentId: _studentId,
          clinicalPlacementId: fixture.placement.id,
          expectedRevision: 0,
          mutation: selectionMutation,
        );
        expect(selected.record.value, fixture.placement.id);
        expect(selected.record.revision, 1);
        expect(
          (repositories as SupportLocalWriteRepositories).studentSettings
              .find(studentId: _studentId)!
              .value
              .themeId,
          StudentSettings.graphiteThemeId,
        );
      });

      final replay = await registry.mutate(
        (repositories) => repositories.activePlacementSelection.put(
          studentId: _studentId,
          clinicalPlacementId: fixture.placement.id,
          expectedRevision: 0,
          mutation: selectionMutation,
        ),
      );
      expect(replay.replayed, isTrue);
      expect(replay.record.revision, 1);

      final cleared = await registry.mutate(
        (repositories) => repositories.activePlacementSelection.put(
          studentId: _studentId,
          clinicalPlacementId: null,
          expectedRevision: 1,
          mutation: _mutation(104),
        ),
      );
      expect(cleared.record.value, isNull);
      expect(cleared.record.revision, 2);

      await database.close();
      databaseIsOpen = false;
      database = await ClinicalCalendarDatabase.open(
        path: databasePath,
        secureStorage: MemorySecureStorage(_key),
      );
      databaseIsOpen = true;
      registry = _registry(database, identifiers);
      await registry.initialize();
      await registry.read((repositories) {
        final selection = repositories.activePlacementSelection.find(
          studentId: _studentId,
        );
        expect(selection, isNotNull);
        expect(selection!.value, isNull);
        expect(selection.revision, 2);
        expect(
          repositories.outbox
              .pending(
                studentId: _studentId,
                asOfUtc: _baseTime.add(const Duration(days: 1)),
              )
              .where((operation) => operation.entityType == 'settings'),
          hasLength(2),
        );
      });
    },
  );

  test(
    'Clinical Placement deletion is grouped, stale-safe, and restores atomically',
    () async {
      await registry.initialize();
      final fixture = _DomainFixture();
      final session = ClinicalSession.schedule(
        id: _id(180),
        clinicalPlacementId: fixture.placement.id,
        preceptorId: fixture.preceptor.id,
        plannedInterval: _interval(8, 12),
        asOfUtc: _baseTime,
      );
      final history = HistoricalHoursEntry(
        id: _id(181),
        clinicalPlacementId: fixture.placement.id,
        completedMinutes: 90,
        effectiveDate: LocalDate(2026, 8, 3),
        preceptorId: fixture.preceptor.id,
      );
      await registry.mutate((repositories) {
        final reminderRepositories =
            repositories as ReminderLocalWriteRepositories;
        repositories.preceptors.put(
          studentId: _studentId,
          value: fixture.preceptor,
          expectedRevision: 0,
          mutation: _mutation(180),
        );
        repositories.clinicalPlacements.put(
          studentId: _studentId,
          value: fixture.placement,
          expectedRevision: 0,
          mutation: _mutation(181),
        );
        repositories.evaluationPlans.put(
          studentId: _studentId,
          value: fixture.evaluationPlan,
          expectedRevision: 0,
          mutation: _mutation(182),
        );
        repositories.clinicalSessions.put(
          studentId: _studentId,
          value: session,
          expectedRevision: 0,
          mutation: _mutation(183),
        );
        repositories.historicalHoursEntries.put(
          studentId: _studentId,
          value: history,
          expectedRevision: 0,
          mutation: _mutation(184),
        );
        repositories.activePlacementSelection.put(
          studentId: _studentId,
          clinicalPlacementId: fixture.placement.id,
          expectedRevision: 0,
          mutation: _mutation(185),
        );
        reminderRepositories.reminderStates.put(
          studentId: _studentId,
          value: ReminderState(
            id: _id(187),
            occurrenceKey:
                'protectedDayPlanning:${fixture.placement.id}:lead-742',
            kind: ReminderKind.protectedDayPlanning,
            subjectEntityId: '${fixture.placement.id}:lead-742',
            scheduledForUtc: _baseTime.add(const Duration(days: 1)),
          ),
          expectedRevision: 0,
          mutation: _mutation(186),
        );
      });
      final service = PlacementApplicationService(
        repositories: registry,
        clock: _FixedClock(_baseTime.add(const Duration(hours: 4))),
        identifiers: identifiers,
        studentId: _studentId,
      );

      var preview = await service.previewDeletion(
        clinicalPlacementId: fixture.placement.id,
        unsavedSchedulingDraftCount: 2,
      );
      expect(preview.clinicalPlacementName, fixture.placement.name);
      expect(preview.scheduledClinicalSessionCount, 1);
      expect(preview.historicalHoursEntryCount, 1);
      expect(preview.historicalCompletedMinutes, 90);
      expect(preview.unsavedSchedulingDraftCount, 2);
      expect(preview.clearsActivePlacementSelection, isTrue);

      await registry.mutate((repositories) {
        repositories.historicalHoursEntries.put(
          studentId: _studentId,
          value: HistoricalHoursEntry(
            id: history.id,
            clinicalPlacementId: history.clinicalPlacementId,
            completedMinutes: history.completedMinutes,
            effectiveDate: history.effectiveDate,
            preceptorId: history.preceptorId,
            note: 'Changed after preview',
          ),
          expectedRevision: 1,
          mutation: MutationToken(
            operationId: _id(1880),
            idempotencyKey: _id(1881),
            occurredAtUtc: _baseTime.add(const Duration(hours: 3, minutes: 30)),
          ),
        );
      });
      await expectLater(
        service.moveToTrash(preview: preview),
        throwsA(
          _repositoryFailure(RepositoryFailureKind.concurrentModification),
        ),
      );
      expect(await service.placements(), hasLength(1));
      expect(
        await registry.listTrash(
          nowUtc: _baseTime.add(const Duration(hours: 4)),
        ),
        isEmpty,
      );
      preview = await service.previewDeletion(
        clinicalPlacementId: fixture.placement.id,
        unsavedSchedulingDraftCount: 2,
      );

      await service.moveToTrash(preview: preview);
      expect(await service.placements(), isEmpty);
      expect(await service.activePlacement(), isNull);
      final trash = await registry.listTrash(
        nowUtc: _baseTime.add(const Duration(hours: 4)),
      );
      expect(trash, hasLength(1));
      expect(trash.single.entityType, 'clinical_placement_aggregate');
      expect(trash.single.displayName, fixture.placement.name);
      expect(trash.single.dependentRecordCount, 3);
      final deletePayloads = database
          .select(
            '''SELECT payload_json FROM outbox_operations
               WHERE student_id = ? AND operation_type = 'delete'
                 AND created_at_utc = ?''',
            [
              _studentId,
              _baseTime.add(const Duration(hours: 4)).toIso8601String(),
            ],
          )
          .map(
            (row) =>
                jsonDecode(row['payload_json']! as String)
                    as Map<String, Object?>,
          )
          .toList();
      expect(deletePayloads, hasLength(4));
      expect(
        deletePayloads
            .map((payload) => payload['aggregate_mutation_id'])
            .toSet(),
        hasLength(1),
      );
      expect(
        deletePayloads.every(
          (payload) => payload['expected_member_manifest'] is Map,
        ),
        isTrue,
      );

      final snapshotPayload = await registry.runPortableBackupExclusive(
        (service) => service.createOperationalSnapshotPayload(
          createdAtUtc: _baseTime.add(const Duration(hours: 4)),
        ),
      );
      final incompleteSnapshot =
          jsonDecode(snapshotPayload) as Map<String, dynamic>;
      final snapshotTables =
          incompleteSnapshot['tables'] as Map<String, dynamic>;
      final snapshotTrash = (snapshotTables['trash'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      snapshotTables['trash'] = snapshotTrash.sublist(1);
      await expectLater(
        registry.runPortableBackupExclusive(
          (service) => service.previewOperationalRestore(
            payloadJson: jsonEncode(incompleteSnapshot),
          ),
        ),
        throwsA(isA<PortableBackupException>()),
      );

      database.execute(
        '''UPDATE historical_hours_entries SET revision = revision + 1
           WHERE student_id = ? AND id = ?''',
        [_studentId, history.id],
      );
      await expectLater(
        registry.restoreTrash(
          trashId: trash.single.id,
          restoredAtUtc: _baseTime.add(const Duration(hours: 5)),
          mutation: MutationToken(
            operationId: _id(1890),
            idempotencyKey: _id(1891),
            occurredAtUtc: _baseTime.add(const Duration(hours: 5)),
          ),
        ),
        throwsA(isA<RecoveryException>()),
      );
      expect(await service.placements(), isEmpty);
      database.execute(
        '''UPDATE historical_hours_entries SET revision = revision - 1
           WHERE student_id = ? AND id = ?''',
        [_studentId, history.id],
      );

      try {
        await registry.restoreTrash(
          trashId: trash.single.id,
          restoredAtUtc: _baseTime.add(const Duration(hours: 5)),
          mutation: MutationToken(
            operationId: _id(1900),
            idempotencyKey: _id(1901),
            occurredAtUtc: _baseTime.add(const Duration(hours: 5)),
          ),
        );
      } on RecoveryException catch (error) {
        fail('${error.safeMessage} cause=${error.cause}');
      }
      expect(await service.placements(), hasLength(1));
      expect(
        (await service.activePlacement())!.placement.id,
        fixture.placement.id,
      );
      await registry.read((repositories) {
        final reminderRepositories =
            repositories as ReminderLocalReadRepositories;
        expect(
          repositories.clinicalSessions.find(
            studentId: _studentId,
            id: session.id,
          ),
          isNotNull,
        );
        expect(
          repositories.historicalHoursEntries.find(
            studentId: _studentId,
            id: history.id,
          ),
          isNotNull,
        );
        expect(
          reminderRepositories.reminderStates.find(
            studentId: _studentId,
            id: _id(187),
          ),
          isNotNull,
        );
      });
    },
  );

  test(
    'Clinical Placement without activity can move to grouped Trash',
    () async {
      await registry.initialize();
      final service = PlacementApplicationService(
        repositories: registry,
        clock: const _FixedClock(),
        identifiers: identifiers,
        studentId: _studentId,
      );
      final preceptor = await service.createPreceptor(name: 'Dr. Rivera');
      final created = await service.createPlacement(
        CreatePlacementRequest(
          name: 'Pediatrics',
          targetHours: TargetHours.fromWholeHours(90),
          startDate: LocalDate(2026, 8, 1),
          completionDeadline: LocalDate(2026, 12, 31),
          primaryPreceptorId: preceptor.id,
          evaluationPlanConfiguration: EvaluationPlanConfiguration(
            initialSelfAssessmentRequired: false,
            interimReviewCadenceMinutes: 6000,
            finalSelfAssessmentRequired: false,
            finalPlacementReviewRequired: false,
          ),
        ),
      );

      final preview = await service.previewDeletion(
        clinicalPlacementId: created.placement.id,
      );
      expect(preview.clinicalSessionCount, 0);
      expect(preview.historicalHoursEntryCount, 0);
      expect(preview.scheduleTemplateCount, 0);
      expect(preview.reminderStateCount, 0);
      await service.moveToTrash(preview: preview);

      expect(await service.placements(), isEmpty);
      final trash = await registry.listTrash(nowUtc: _baseTime);
      expect(trash, hasLength(1));
      expect(trash.single.displayName, 'Pediatrics');

      await registry.permanentlyDelete(
        trashId: trash.single.id,
        deletedAtUtc: _baseTime.add(const Duration(hours: 1)),
        mutation: MutationToken(
          operationId: _id(1950),
          idempotencyKey: _id(1951),
          occurredAtUtc: _baseTime.add(const Duration(hours: 1)),
        ),
      );
      final purgePayload =
          jsonDecode(
                database
                        .select(
                          '''SELECT payload_json FROM outbox_operations
                     WHERE operation_type = 'purge' AND entity_id = ?''',
                          [created.placement.id],
                        )
                        .single['payload_json']
                    as String,
              )
              as Map<String, Object?>;
      expect(purgePayload['aggregate_mutation_id'], isA<String>());
      expect(purgePayload['expected_member_manifest'], isA<Map>());
    },
  );
}

SqliteRepositoryRegistry _registry(
  ClinicalCalendarDatabase database,
  IdentifierGenerator identifiers,
) => SqliteRepositoryRegistry(
  studentId: _studentId,
  database: database,
  identifierGenerator: identifiers,
);

Matcher _repositoryFailure(RepositoryFailureKind kind) =>
    isA<RepositoryException>().having((error) => error.kind, 'kind', kind);

void _expectMetadata<T>(StoredDomainRecord<T> record, DateTime occurredAtUtc) {
  expect(record.studentId, _studentId);
  expect(record.revision, 1);
  expect(record.createdAtUtc, occurredAtUtc);
  expect(record.updatedAtUtc, occurredAtUtc);
  expect(record.deletedAtUtc, isNull);
}

MutationToken _mutation(int sequence) => MutationToken(
  operationId: _id(1000 + sequence * 2),
  idempotencyKey: _id(1001 + sequence * 2),
  occurredAtUtc: _baseTime.add(Duration(minutes: sequence)),
);

String _id(int value) =>
    '00000000-0000-4000-8000-${value.toRadixString(16).padLeft(12, '0')}';

ZonedInterval _interval(int startHour, int endHour) => ZonedInterval(
  startDate: LocalDate(2026, 8, 4),
  startTime: LocalTime(startHour, 0),
  endTime: LocalTime(endHour, 0),
  timeZone: TimeZoneId('America/New_York'),
  startOffset: UtcOffset.inMinutes(-4 * 60),
  endOffset: UtcOffset.inMinutes(-4 * 60),
);

Object? _domainSnapshot(Object value) => switch (value) {
  WorkShift(:final id, :final plannedInterval) => {
    'id': id,
    'plannedInterval': _intervalSnapshot(plannedInterval),
  },
  ClinicalSession(
    :final id,
    :final clinicalPlacementId,
    :final preceptorId,
    :final plannedInterval,
    :final state,
    :final actualInterval,
  ) =>
    {
      'id': id,
      'clinicalPlacementId': clinicalPlacementId,
      'preceptorId': preceptorId,
      'plannedInterval': _intervalSnapshot(plannedInterval),
      'state': state,
      'actualInterval': actualInterval == null
          ? null
          : _intervalSnapshot(actualInterval),
    },
  ProtectedDay(:final id, :final date) => {'id': id, 'date': date.toString()},
  ScheduleTemplate(
    :final id,
    :final name,
    :final type,
    :final startTime,
    :final endTime,
    :final clinicalPlacementId,
    :final preceptorId,
  ) =>
    {
      'id': id,
      'name': name,
      'type': type,
      'startTime': startTime.minutesSinceMidnight,
      'endTime': endTime.minutesSinceMidnight,
      'clinicalPlacementId': clinicalPlacementId,
      'preceptorId': preceptorId,
    },
  Preceptor(
    :final id,
    :final name,
    :final organizationOrSite,
    :final phone,
    :final email,
    :final schedulingNotes,
  ) =>
    {
      'id': id,
      'name': name,
      'organizationOrSite': organizationOrSite,
      'phone': phone,
      'email': email,
      'schedulingNotes': schedulingNotes,
    },
  ClinicalPlacement(
    :final id,
    :final name,
    :final targetHours,
    :final startDate,
    :final completionDeadline,
    :final attachedPreceptorIds,
    :final primaryPreceptorId,
    :final evaluationPlanId,
    :final state,
  ) =>
    {
      'id': id,
      'name': name,
      'targetMinutes': targetHours.minutes,
      'startDate': startDate.toString(),
      'completionDeadline': completionDeadline.toString(),
      'attachedPreceptorIds': attachedPreceptorIds.toList()..sort(),
      'primaryPreceptorId': primaryPreceptorId,
      'evaluationPlanId': evaluationPlanId,
      'state': state,
    },
  HistoricalHoursEntry(
    :final id,
    :final clinicalPlacementId,
    :final completedMinutes,
    :final effectiveDate,
    :final preceptorId,
    :final note,
  ) =>
    {
      'id': id,
      'clinicalPlacementId': clinicalPlacementId,
      'completedMinutes': completedMinutes,
      'effectiveDate': effectiveDate.toString(),
      'preceptorId': preceptorId,
      'note': note,
    },
  EvaluationPlan(:final id, :final configuration, :final requirements) => {
    'id': id,
    'configuration': {
      'initial': configuration.initialSelfAssessmentRequired,
      'cadence': configuration.interimReviewCadenceMinutes,
      'finalSelf': configuration.finalSelfAssessmentRequired,
      'finalPlacement': configuration.finalPlacementReviewRequired,
    },
    'requirements': requirements.map(_requirementSnapshot).toList(),
  },
  _ => throw ArgumentError.value(value, 'value', 'unsupported domain type'),
};

Object _intervalSnapshot(ZonedInterval value) => {
  'startDate': value.startDate.toString(),
  'endDate': value.endDate.toString(),
  'startTime': value.startTime.minutesSinceMidnight,
  'endTime': value.endTime.minutesSinceMidnight,
  'timeZone': value.timeZone.value,
  'startOffset': value.startOffset.minutes,
  'endOffset': value.endOffset.minutes,
  'startUtc': value.startInstantUtc,
  'endUtc': value.endInstantUtc,
};

Object _requirementSnapshot(EvaluationRequirement requirement) => {
  'identity': requirement.identity.stableValue,
  'isCurrentlyRequired': requirement.isCurrentlyRequired,
  'primaryPreceptorId': requirement.primaryPreceptorId,
  'documentation': requirement.documentation == null
      ? null
      : {
          'date': requirement.documentation!.dateDocumented.toString(),
          'location': requirement.documentation!.location,
          'referenceOrNote': requirement.documentation!.referenceOrNote,
        },
};

final class _DomainFixture {
  _DomainFixture() {
    preceptor = Preceptor(
      id: _id(10),
      name: 'Jordan Lee',
      organizationOrSite: 'Family Health Center',
      phone: '555-0100',
      email: 'jordan@example.test',
      schedulingNotes: 'Available on Tuesdays.',
    );
    evaluationPlan = EvaluationPlan.restore(
      id: _id(12),
      configuration: EvaluationPlanConfiguration(
        interimReviewCadenceMinutes: 5400,
        finalPlacementReviewRequired: true,
      ),
      requirements: [
        EvaluationRequirement.restore(
          identity: EvaluationRequirementIdentity(
            evaluationPlanId: _id(12),
            kind: EvaluationRequirementKind.initialSelfAssessment,
          ),
          isCurrentlyRequired: true,
        ),
        EvaluationRequirement.restore(
          identity: EvaluationRequirementIdentity(
            evaluationPlanId: _id(12),
            kind:
                EvaluationRequirementKind.interimPrimaryPreceptorReviewsStudent,
            thresholdMinutes: 5400,
          ),
          isCurrentlyRequired: true,
          primaryPreceptorId: preceptor.id,
          documentation: EvaluationDocumentation(
            dateDocumented: LocalDate(2026, 8, 2),
            location: 'Medatrax',
            referenceOrNote: 'Interim review uploaded.',
          ),
        ),
      ],
    );
    placement = ClinicalPlacement.create(
      id: _id(11),
      name: 'Family Medicine',
      targetHours: TargetHours.fromWholeHours(270),
      startDate: LocalDate(2026, 8, 1),
      completionDeadline: LocalDate(2026, 12, 31),
      attachedPreceptorIds: [preceptor.id],
      primaryPreceptorId: preceptor.id,
      evaluationPlanId: evaluationPlan.id,
    );
    workShift = WorkShift(id: _id(13), plannedInterval: _interval(7, 9));
    clinicalSession = ClinicalSession.schedule(
      id: _id(14),
      clinicalPlacementId: placement.id,
      preceptorId: preceptor.id,
      plannedInterval: _interval(9, 12),
      asOfUtc: _baseTime,
    );
    protectedDay = ProtectedDay(id: _id(15), date: LocalDate(2026, 8, 9));
    scheduleTemplate = ScheduleTemplate(
      id: _id(16),
      name: 'Tuesday clinic',
      type: ScheduleTemplateType.clinicalSession,
      startTime: LocalTime(9, 0),
      endTime: LocalTime(12, 0),
      clinicalPlacementId: placement.id,
      preceptorId: preceptor.id,
    );
    historicalHoursEntry = HistoricalHoursEntry(
      id: _id(17),
      clinicalPlacementId: placement.id,
      completedMinutes: 360,
      effectiveDate: LocalDate(2026, 8, 2),
      preceptorId: preceptor.id,
      note: 'Hours completed before adoption.',
    );
  }

  late final Preceptor preceptor;
  late final ClinicalPlacement placement;
  late final EvaluationPlan evaluationPlan;
  late final WorkShift workShift;
  late final ClinicalSession clinicalSession;
  late final ProtectedDay protectedDay;
  late final ScheduleTemplate scheduleTemplate;
  late final HistoricalHoursEntry historicalHoursEntry;
}

final class _FixedClock implements Clock {
  const _FixedClock([this.value]);

  final DateTime? value;

  @override
  DateTime nowUtc() => value ?? _baseTime;
}

final class DeterministicIdentifierGenerator implements IdentifierGenerator {
  int _next = 900000;

  @override
  String nextIdentifier() => _id(_next++);
}

final class MemorySecureStorage implements SecureStorage {
  MemorySecureStorage([String? initialValue]) {
    if (initialValue != null) {
      values[ClinicalCalendarDatabase.encryptionKeyStorageKey] = initialValue;
    }
  }

  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

Database _openRaw(String path) {
  final database = sqlite3.open(path);
  database.execute('PRAGMA key = "x\'$_key\'"');
  return database;
}

Future<void> _createFixture(String path, {required int version}) async {
  final database = _openRaw(path);
  final runner = DatabaseMigrationRunner.forTesting((targetVersion, raw) {
    if (targetVersion == version + 1) {
      throw StateError('stop after fixture version');
    }
  });
  try {
    runner.migrate(database, 0);
  } on ClinicalCalendarDatabaseException catch (error) {
    expect(error.kind, DatabaseFailureKind.migrationFailed);
  }
  expect(database.userVersion, version);
  database.execute(
    '''INSERT INTO student_profiles
       (id, student_id, revision, created_at_utc, updated_at_utc, display_name)
       VALUES (?, ?, 0, ?, ?, ?)''',
    [
      _profileId,
      _studentId,
      _baseTime.toIso8601String(),
      _baseTime.toIso8601String(),
      'Fixture v$version',
    ],
  );
  database.close();
}
