import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:test/test.dart';

void main() {
  final created = DateTime.utc(2026, 8, 3, 12);
  const operationId = '123e4567-e89b-42d3-a456-426614174000';
  const idempotencyKey = '123e4567-e89b-42d3-a456-426614174001';

  test('RepositoryException exposes an adapter-independent failure kind', () {
    const error = RepositoryException(
      RepositoryFailureKind.concurrentModification,
      'Expected revision did not match.',
    );

    expect(error.kind, RepositoryFailureKind.concurrentModification);
    expect(error.toString(), contains('concurrentModification'));
  });

  group('StoredDomainRecord', () {
    test('retains domain values and valid synchronization metadata', () {
      final record = StoredDomainRecord<String>(
        value: 'domain value',
        studentId: 'student-1',
        revision: 0,
        createdAtUtc: created,
        updatedAtUtc: created,
      );

      expect(record.value, 'domain value');
      expect(record.isDeleted, isFalse);
    });

    test('rejects invalid revisions and timestamps', () {
      expect(
        () => StoredDomainRecord<String>(
          value: 'value',
          studentId: 'student-1',
          revision: -1,
          createdAtUtc: created,
          updatedAtUtc: created,
        ),
        throwsArgumentError,
      );
      expect(
        () => StoredDomainRecord<String>(
          value: 'value',
          studentId: 'student-1',
          revision: 0,
          createdAtUtc: created,
          updatedAtUtc: DateTime(2026, 8, 3, 12),
        ),
        throwsArgumentError,
      );
      expect(
        () => StoredDomainRecord<String>(
          value: 'value',
          studentId: 'student-1',
          revision: 0,
          createdAtUtc: created,
          updatedAtUtc: created,
          deletedAtUtc: created.add(const Duration(seconds: 1)),
        ),
        throwsArgumentError,
      );
    });
  });

  group('MutationToken', () {
    test('accepts UUID identifiers and a UTC timestamp', () {
      final token = MutationToken(
        operationId: operationId.toUpperCase(),
        idempotencyKey: idempotencyKey,
        occurredAtUtc: created,
      );

      expect(token.operationId, operationId);
      expect(token.idempotencyKey, idempotencyKey);
      expect(token.occurredAtUtc, created);
    });

    test('rejects non-UUID identifiers and local timestamps', () {
      expect(
        () => MutationToken(
          operationId: 'not-a-uuid',
          idempotencyKey: idempotencyKey,
          occurredAtUtc: created,
        ),
        throwsArgumentError,
      );
      expect(
        () => MutationToken(
          operationId: operationId,
          idempotencyKey: idempotencyKey,
          occurredAtUtc: DateTime(2026, 8, 3),
        ),
        throwsArgumentError,
      );
    });
  });

  test('OutboxOperation enforces acknowledgement and counter invariants', () {
    final mutation = MutationToken(
      operationId: operationId,
      idempotencyKey: idempotencyKey,
      occurredAtUtc: created,
    );

    expect(
      () => OutboxOperation(
        mutation: mutation,
        studentId: 'student-1',
        entityType: 'work_shift',
        entityId: 'shift-1',
        type: OutboxOperationType.upsert,
        baseRevision: 0,
        payloadJson: '{}',
        acknowledgedCursor: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => OutboxOperation(
        mutation: mutation,
        studentId: 'student-1',
        entityType: 'work_shift',
        entityId: 'shift-1',
        type: OutboxOperationType.upsert,
        baseRevision: 0,
        payloadJson: '{}',
        attemptCount: -1,
      ),
      throwsArgumentError,
    );
  });

  test('SyncCursor requires a nonnegative cursor and UTC update time', () {
    expect(
      () => SyncCursor(
        studentId: 'student-1',
        remoteScope: 'calendar',
        serverCursor: -1,
        updatedAtUtc: created,
      ),
      throwsArgumentError,
    );
    expect(
      () => SyncCursor(
        studentId: 'student-1',
        remoteScope: 'calendar',
        serverCursor: 0,
        updatedAtUtc: DateTime(2026, 8, 3),
      ),
      throwsArgumentError,
    );
  });
}
