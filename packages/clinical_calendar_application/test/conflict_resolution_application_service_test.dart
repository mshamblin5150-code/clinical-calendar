import 'dart:convert';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

const _studentId = '00000000-0000-4000-8000-000000000001';
const _entityId = '00000000-0000-4000-8000-000000000002';
const _conflictId = '00000000-0000-4000-8000-000000000003';
const _placementId = '00000000-0000-4000-8000-000000000005';
const _preceptorId = '00000000-0000-4000-8000-000000000006';
final _now = DateTime.utc(2026, 8, 3, 12);

void main() {
  test('loads both complete originals side by side', () async {
    final repository = _ConflictRepository(_sameRecordConflict());
    final service = _service(repository);

    final snapshot = await service.load();

    expect(snapshot.items, hasLength(1));
    expect(snapshot.items.single.local.values['name'], 'This Device');
    expect(snapshot.items.single.remote.values['name'], 'Other Device');
    expect(snapshot.items.single.supportsSideBySideResolution, isTrue);
    expect(repository.record.localSnapshotJson, contains('This Device'));
    expect(repository.record.remoteSnapshotJson, contains('Other Device'));
  });

  test('resolution is a revisioned resolve-conflict mutation', () async {
    final repository = _ConflictRepository(_sameRecordConflict());
    final synchronization = _Synchronization();
    final service = _service(repository, synchronization: synchronization);

    final receipt = await service.resolve(
      conflictId: _conflictId,
      choice: SynchronizationConflictResolutionChoice.correctedVersion,
      correctedValues: {'name': 'Corrected'},
    );

    expect(receipt.operation.type, OutboxOperationType.resolveConflict);
    expect(receipt.operation.baseRevision, 2);
    expect(receipt.operation.mutation.occurredAtUtc, _now);
    expect(jsonDecode(repository.correctedValueJson!)['name'], 'Corrected');
    expect(repository.record.isResolved, isTrue);
    expect(repository.record.localSnapshotJson, contains('This Device'));
    expect(repository.record.remoteSnapshotJson, contains('Other Device'));
    expect(synchronization.calls, 1);
  });

  test('corrected same-record version must satisfy its domain model', () async {
    final repository = _ConflictRepository(_sameRecordConflict());
    final service = _service(repository);

    expect(
      () => service.resolve(
        conflictId: _conflictId,
        choice: SynchronizationConflictResolutionChoice.correctedVersion,
        correctedValues: {'name': '   '},
      ),
      throwsA(isA<ConflictResolutionException>()),
    );
    expect(repository.record.isResolved, isFalse);
    expect(repository.correctedValueJson, isNull);
  });

  test('Protected Day conflict keeps its week Planning Incomplete', () async {
    final repository = _ConflictRepository(_protectedDayConflict());
    final snapshot = await _service(repository).load();

    expect(snapshot.planningIncompleteCount, 1);
    expect(snapshot.items.single.planningIncomplete, isTrue);
    expect(
      snapshot.items.single.record.affectedRecords.map(
        (record) => record.entityId,
      ),
      containsAll([_entityId, _affectedId]),
    );
  });

  test(
    'cross-record Clinical Session actions enforce lifecycle rules',
    () async {
      final repository = _ConflictRepository(
        _scheduleConflict(lifecycleState: 'scheduled'),
      );
      final service = _service(repository);
      final conflict = (await service.load()).items.single;

      await service.resolveCrossRecord(
        conflict: conflict,
        action: CrossRecordResolutionAction.cancel,
      );

      expect(
        jsonDecode(repository.correctedValueJson!)['lifecycle_state'],
        'cancelled',
      );
      expect(
        jsonDecode(repository.correctedValueJson!)['actual_start_utc'],
        isNull,
      );

      final missedRepository = _ConflictRepository(
        _scheduleConflict(lifecycleState: 'scheduled'),
      );
      final missedConflict = (await _service(
        missedRepository,
      ).load()).items.single;
      expect(
        () => _service(missedRepository).resolveCrossRecord(
          conflict: missedConflict,
          action: CrossRecordResolutionAction.missed,
        ),
        throwsA(isA<ConflictResolutionException>()),
      );
    },
  );

  test('eligible deletion creates an explicit tombstone resolution', () async {
    final repository = _ConflictRepository(_scheduleConflict());
    final service = _service(repository);
    final conflict = (await service.load()).items.single;

    final receipt = await service.resolveCrossRecord(
      conflict: conflict,
      action: CrossRecordResolutionAction.deleteIfEligible,
    );

    expect(receipt.operation.type, OutboxOperationType.delete);
    expect(
      repository.lastChoice,
      SynchronizationConflictResolutionChoice.deleteVersion,
    );
    expect(repository.record.isResolved, isTrue);
  });

  test(
    'move normalizes redundant instants and rejects malformed corrections',
    () async {
      final repository = _ConflictRepository(_scheduleConflict());
      final service = _service(repository);
      final conflict = (await service.load()).items.single;

      await service.resolveCrossRecord(
        conflict: conflict,
        action: CrossRecordResolutionAction.move,
        movedValues: {'planned_start_minutes': 720, 'planned_end_minutes': 780},
      );

      final corrected = jsonDecode(repository.correctedValueJson!) as Map;
      expect(corrected['planned_start_utc'], '2026-08-05T16:00:00.000Z');
      expect(corrected['planned_end_utc'], '2026-08-05T17:00:00.000Z');
      expect(corrected['actual_start_utc'], isNull);
      expect(corrected['lifecycle_state'], 'scheduled');

      final invalidRepository = _ConflictRepository(_scheduleConflict());
      final invalidService = _service(invalidRepository);
      final invalidConflict = (await invalidService.load()).items.single;
      expect(
        () => invalidService.resolveCrossRecord(
          conflict: invalidConflict,
          action: CrossRecordResolutionAction.move,
          movedValues: {'planned_start_minutes': 'not-a-time'},
        ),
        throwsA(isA<ConflictResolutionException>()),
      );
      expect(invalidRepository.record.isResolved, isFalse);
    },
  );
}

ConflictResolutionApplicationService _service(
  _ConflictRepository repository, {
  SynchronizationService? synchronization,
}) => ConflictResolutionApplicationService(
  repositories: _Registry(_Repositories(repository)),
  clock: _Clock(),
  identifiers: _Identifiers(),
  studentId: _studentId,
  synchronization: synchronization,
);

SynchronizationConflictRecord _sameRecordConflict() =>
    SynchronizationConflictRecord(
      id: _conflictId,
      studentId: _studentId,
      entityType: 'preceptor',
      entityId: _entityId,
      localRevision: 2,
      remoteRevision: 2,
      localSnapshotJson: _envelope('preceptor', {'name': 'This Device'}),
      remoteSnapshotJson: _envelope('preceptor', {'name': 'Other Device'}),
      rejectionCode: 'stale_revision',
      rejectionJson: '{"code":"stale_revision"}',
      detectedAtUtc: _now,
      affectedRecords: [
        SynchronizationConflictEntityReference(
          entityType: 'preceptor',
          entityId: _entityId,
        ),
      ],
    );

const _affectedId = '00000000-0000-4000-8000-000000000004';

SynchronizationConflictRecord _protectedDayConflict() =>
    SynchronizationConflictRecord(
      id: _conflictId,
      studentId: _studentId,
      entityType: 'protected_day',
      entityId: _entityId,
      localRevision: 1,
      remoteRevision: 0,
      localSnapshotJson: _envelope('protected_day', {
        'local_date': '2026-08-05',
        'week_start_date': '2026-08-03',
      }, revision: 1),
      remoteSnapshotJson: _envelope('protected_day', {
        'local_date': '2026-08-05',
        'week_start_date': '2026-08-03',
      }, revision: 0),
      rejectionCode: 'protected_day_violation',
      rejectionJson: '{"code":"protected_day_violation"}',
      detectedAtUtc: _now,
      planningWeekStartDate:
          // Keep the domain date explicit rather than deriving product truth
          // from a display label.
          LocalDate(2026, 8, 3),
      affectedRecords: [
        SynchronizationConflictEntityReference(
          entityType: 'protected_day',
          entityId: _entityId,
        ),
        SynchronizationConflictEntityReference(
          entityType: 'work_shift',
          entityId: _affectedId,
        ),
      ],
    );

SynchronizationConflictRecord _scheduleConflict({
  String lifecycleState = 'awaiting_confirmation',
}) => SynchronizationConflictRecord(
  id: _conflictId,
  studentId: _studentId,
  entityType: 'clinical_session',
  entityId: _entityId,
  localRevision: 2,
  remoteRevision: 2,
  localSnapshotJson: _envelope('clinical_session', {
    'commitment_type': 'clinical_session',
    'lifecycle_state': lifecycleState,
    'placement_id': _placementId,
    'preceptor_id': _preceptorId,
    'planned_start_date': '2026-08-05',
    'planned_end_date': '2026-08-05',
    'planned_start_minutes': 540,
    'planned_end_minutes': 660,
    'time_zone': 'America/New_York',
    'planned_start_offset_minutes': -240,
    'planned_end_offset_minutes': -240,
    'actual_start_utc': '2026-08-05T13:00:00.000Z',
  }),
  remoteSnapshotJson: _envelope('clinical_session', {
    'commitment_type': 'clinical_session',
    'lifecycle_state': lifecycleState,
    'placement_id': _placementId,
    'preceptor_id': _preceptorId,
    'planned_start_date': '2026-08-05',
    'planned_end_date': '2026-08-05',
    'planned_start_minutes': 540,
    'planned_end_minutes': 660,
    'time_zone': 'America/New_York',
    'planned_start_offset_minutes': -240,
    'planned_end_offset_minutes': -240,
  }),
  rejectionCode: 'schedule_conflict',
  rejectionJson: '{"code":"schedule_conflict"}',
  detectedAtUtc: _now,
  affectedRecords: [
    SynchronizationConflictEntityReference(
      entityType: 'clinical_session',
      entityId: _entityId,
    ),
  ],
);

String _envelope(
  String entityType,
  Map<String, Object?> value, {
  int revision = 2,
}) => jsonEncode({
  'schema_version': 1,
  'entity_type': entityType,
  'entity_id': _entityId,
  'student_id': _studentId,
  'revision': revision,
  'created_at_utc': _now.toIso8601String(),
  'updated_at_utc': _now.toIso8601String(),
  'deleted_at_utc': null,
  'value': value,
});

final class _Registry implements RepositoryRegistry {
  _Registry(this.repositories);
  final _Repositories repositories;

  @override
  Future<void> initialize() async {}

  @override
  Future<R> read<R>(
    R Function(LocalReadRepositories repositories) callback,
  ) async => callback(repositories);

  @override
  Future<R> mutate<R>(
    R Function(LocalWriteRepositories repositories) callback,
  ) async => callback(repositories);
}

final class _Repositories implements SynchronizationLocalWriteRepositories {
  _Repositories(this.synchronization);

  @override
  final SynchronizationLocalRepository synchronization;

  @override
  final MutableRepository<WorkShift> workShifts = _EmptyMutable<WorkShift>();

  @override
  final MutableRepository<ClinicalSession> clinicalSessions =
      _EmptyMutable<ClinicalSession>();

  @override
  final MutableRepository<ProtectedDay> protectedDays =
      _EmptyMutable<ProtectedDay>();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _EmptyMutable<T> implements MutableRepository<T> {
  @override
  StoredDomainRecord<T>? find({
    required String studentId,
    required String id,
    bool includeDeleted = false,
  }) => null;

  @override
  List<StoredDomainRecord<T>> list({
    required String studentId,
    bool includeDeleted = false,
  }) => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ConflictRepository implements SynchronizationLocalRepository {
  _ConflictRepository(this.record);
  SynchronizationConflictRecord record;
  String? correctedValueJson;
  SynchronizationConflictResolutionChoice? lastChoice;

  @override
  SynchronizationConflictRecord? findConflict({
    required String studentId,
    required String conflictId,
  }) => record.id == conflictId ? record : null;

  @override
  List<SynchronizationConflictRecord> listConflicts({
    required String studentId,
    bool includeResolved = false,
  }) => record.isResolved && !includeResolved ? [] : [record];

  @override
  SynchronizationConflictResolutionReceipt resolveConflict({
    required String studentId,
    required String conflictId,
    required SynchronizationConflictResolutionChoice choice,
    String? correctedValueJson,
    required MutationToken mutation,
  }) {
    lastChoice = choice;
    this.correctedValueJson = correctedValueJson;
    final resolution = jsonEncode({'choice': choice.name});
    record = SynchronizationConflictRecord(
      id: record.id,
      studentId: record.studentId,
      entityType: record.entityType,
      entityId: record.entityId,
      localRevision: record.localRevision,
      remoteRevision: record.remoteRevision,
      localSnapshotJson: record.localSnapshotJson,
      remoteSnapshotJson: record.remoteSnapshotJson,
      rejectionCode: record.rejectionCode,
      rejectionJson: record.rejectionJson,
      detectedAtUtc: record.detectedAtUtc,
      affectedRecords: record.affectedRecords,
      planningWeekStartDate: record.planningWeekStartDate,
      resolvedAtUtc: mutation.occurredAtUtc,
      resolutionJson: resolution,
    );
    return SynchronizationConflictResolutionReceipt(
      conflict: record,
      operation: OutboxOperation(
        mutation: mutation,
        studentId: studentId,
        entityType: record.entityType,
        entityId: record.entityId,
        type: choice == SynchronizationConflictResolutionChoice.deleteVersion
            ? OutboxOperationType.delete
            : OutboxOperationType.resolveConflict,
        baseRevision: record.remoteRevision,
        payloadJson: correctedValueJson ?? record.localSnapshotJson,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Clock implements Clock {
  @override
  DateTime nowUtc() => _now;
}

final class _Identifiers implements IdentifierGenerator {
  int next = 10;

  @override
  String nextIdentifier() =>
      '00000000-0000-4000-8000-${(next++).toString().padLeft(12, '0')}';
}

final class _Synchronization implements SynchronizationService {
  int calls = 0;

  @override
  Future<SynchronizationResult> synchronize() async {
    calls++;
    return const SynchronizationResult(SynchronizationDisposition.synchronized);
  }
}
