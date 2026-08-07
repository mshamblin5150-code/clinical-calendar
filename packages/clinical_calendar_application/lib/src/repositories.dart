import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import 'support/support_models.dart';
import 'reminders/reminder_state.dart';

export 'support/support_models.dart';
export 'reminders/reminder_state.dart';

enum RepositoryFailureKind {
  notFound,
  ownershipMismatch,
  concurrentModification,
  idempotencyConflict,
  corruptData,
  persistenceFailure,
  closed,
  uninitialized,
}

/// A persistence failure expressed without leaking an adapter-specific error.
final class RepositoryException implements Exception {
  const RepositoryException(this.kind, this.message, {this.cause});

  final RepositoryFailureKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => 'RepositoryException(${kind.name}): $message';
}

/// A domain value together with its local synchronization metadata.
final class StoredDomainRecord<T> {
  StoredDomainRecord({
    required this.value,
    required String studentId,
    required this.revision,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    DateTime? deletedAtUtc,
  }) : studentId = _requireText(studentId, 'Student id'),
       createdAtUtc = _requireUtc(createdAtUtc, 'Created time'),
       updatedAtUtc = _requireUtc(updatedAtUtc, 'Updated time'),
       deletedAtUtc = deletedAtUtc == null
           ? null
           : _requireUtc(deletedAtUtc, 'Deleted time') {
    if (revision < 0) {
      throw ArgumentError.value(revision, 'revision', 'must not be negative');
    }
    if (updatedAtUtc.isBefore(createdAtUtc)) {
      throw ArgumentError.value(
        updatedAtUtc,
        'updatedAtUtc',
        'must not be before createdAtUtc',
      );
    }
    if (deletedAtUtc != null &&
        (deletedAtUtc.isBefore(createdAtUtc) ||
            deletedAtUtc.isAfter(updatedAtUtc))) {
      throw ArgumentError.value(
        deletedAtUtc,
        'deletedAtUtc',
        'must be between createdAtUtc and updatedAtUtc',
      );
    }
  }

  final T value;
  final String studentId;
  final int revision;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final DateTime? deletedAtUtc;

  bool get isDeleted => deletedAtUtc != null;
}

/// Identifies one idempotent local mutation and when it occurred.
final class MutationToken {
  MutationToken({
    required String operationId,
    required String idempotencyKey,
    required DateTime occurredAtUtc,
  }) : operationId = _requireUuid(operationId, 'Operation id'),
       idempotencyKey = _requireUuid(idempotencyKey, 'Idempotency key'),
       occurredAtUtc = _requireUtc(occurredAtUtc, 'Occurrence time');

  final String operationId;
  final String idempotencyKey;
  final DateTime occurredAtUtc;
}

/// The durable result of an idempotent mutation.
final class MutationReceipt<T> {
  const MutationReceipt({required this.record, required this.replayed});

  final StoredDomainRecord<T> record;
  final bool replayed;
}

abstract interface class ReadRepository<T> {
  StoredDomainRecord<T>? find({
    required String studentId,
    required String id,
    bool includeDeleted = false,
  });

  List<StoredDomainRecord<T>> list({
    required String studentId,
    bool includeDeleted = false,
  });
}

/// Local writes use optimistic revision checks and durably enqueue their
/// [MutationToken] in the same transaction as the domain record.
abstract interface class MutableRepository<T> implements ReadRepository<T> {
  MutationReceipt<T> put({
    required String studentId,
    required T value,
    required int expectedRevision,
    required MutationToken mutation,
  });

  MutationReceipt<T> tombstone({
    required String studentId,
    required String id,
    required int expectedRevision,
    required MutationToken mutation,
  });
}

enum OutboxOperationType { upsert, delete, resolveConflict, purge }

/// A mutation waiting to be delivered to synchronization infrastructure.
final class OutboxOperation {
  OutboxOperation({
    required this.mutation,
    required String studentId,
    required String entityType,
    required String entityId,
    required this.type,
    required this.baseRevision,
    required String payloadJson,
    this.attemptCount = 0,
    DateTime? nextAttemptAtUtc,
    this.acknowledgedCursor,
    DateTime? acknowledgedAtUtc,
    this.lastFailureCode,
    this.terminalRejectionCode,
    DateTime? terminalRejectedAtUtc,
  }) : studentId = _requireText(studentId, 'Student id'),
       entityType = _requireText(entityType, 'Entity type'),
       entityId = _requireText(entityId, 'Entity id'),
       payloadJson = _requireText(payloadJson, 'Payload JSON'),
       nextAttemptAtUtc = nextAttemptAtUtc == null
           ? null
           : _requireUtc(nextAttemptAtUtc, 'Next attempt time'),
       acknowledgedAtUtc = acknowledgedAtUtc == null
           ? null
           : _requireUtc(acknowledgedAtUtc, 'Acknowledgement time'),
       terminalRejectedAtUtc = terminalRejectedAtUtc == null
           ? null
           : _requireUtc(terminalRejectedAtUtc, 'Terminal rejection time') {
    if (baseRevision < 0) {
      throw ArgumentError.value(
        baseRevision,
        'baseRevision',
        'must not be negative',
      );
    }
    if (attemptCount < 0) {
      throw ArgumentError.value(
        attemptCount,
        'attemptCount',
        'must not be negative',
      );
    }
    if (acknowledgedCursor != null && acknowledgedCursor! < 0) {
      throw ArgumentError.value(
        acknowledgedCursor,
        'acknowledgedCursor',
        'must not be negative',
      );
    }
    if ((acknowledgedCursor == null) != (acknowledgedAtUtc == null)) {
      throw ArgumentError(
        'Acknowledged cursor and acknowledgement time must be supplied together.',
      );
    }
    if ((terminalRejectionCode == null) != (terminalRejectedAtUtc == null)) {
      throw ArgumentError(
        'Terminal rejection code and time must be supplied together.',
      );
    }
    if (acknowledgedAtUtc != null && terminalRejectedAtUtc != null) {
      throw ArgumentError(
        'An operation cannot be both acknowledged and terminally rejected.',
      );
    }
  }

  final MutationToken mutation;
  final String studentId;
  final String entityType;
  final String entityId;
  final OutboxOperationType type;
  final int baseRevision;
  final String payloadJson;
  final int attemptCount;
  final DateTime? nextAttemptAtUtc;
  final int? acknowledgedCursor;
  final DateTime? acknowledgedAtUtc;
  final String? lastFailureCode;
  final String? terminalRejectionCode;
  final DateTime? terminalRejectedAtUtc;

  bool get isAcknowledged => acknowledgedAtUtc != null;
  bool get isTerminallyRejected => terminalRejectedAtUtc != null;
}

abstract interface class OutboxReadRepository {
  List<OutboxOperation> pending({
    required String studentId,
    required DateTime asOfUtc,
    int limit = 100,
  });
}

abstract interface class OutboxMaintenanceRepository
    implements OutboxReadRepository {
  void recordFailedAttempt({
    required String studentId,
    required String operationId,
    required DateTime attemptedAtUtc,
    required DateTime nextAttemptAtUtc,
    required String failureCode,
  });

  void acknowledge({
    required String studentId,
    required String operationId,
    required int serverCursor,
    required DateTime acknowledgedAtUtc,
  });
}

final class SyncCursor {
  SyncCursor({
    required String studentId,
    required String remoteScope,
    required this.serverCursor,
    required DateTime updatedAtUtc,
  }) : studentId = _requireText(studentId, 'Student id'),
       remoteScope = _requireText(remoteScope, 'Remote scope'),
       updatedAtUtc = _requireUtc(updatedAtUtc, 'Updated time') {
    if (serverCursor < 0) {
      throw ArgumentError.value(
        serverCursor,
        'serverCursor',
        'must not be negative',
      );
    }
  }

  final String studentId;
  final String remoteScope;
  final int serverCursor;
  final DateTime updatedAtUtc;
}

abstract interface class SyncCursorReadRepository {
  SyncCursor? find({required String studentId, required String remoteScope});
}

abstract interface class SyncCursorRepository
    implements SyncCursorReadRepository {
  void put(SyncCursor cursor);
}

enum SynchronizationHealthDisposition {
  synced,
  offline,
  syncing,
  conflictNeedsAttention,
  failed,
}

final class SynchronizationHealthSnapshot {
  const SynchronizationHealthSnapshot({
    required this.disposition,
    required this.pendingCount,
    required this.unresolvedConflictCount,
    this.lastSuccessAtUtc,
    this.lastAttemptAtUtc,
    this.failureStartedAtUtc,
    this.failureCode,
    this.oldestPendingAtUtc,
    this.nextRetryAtUtc,
  });

  final SynchronizationHealthDisposition disposition;
  final int pendingCount;
  final int unresolvedConflictCount;
  final DateTime? lastSuccessAtUtc;
  final DateTime? lastAttemptAtUtc;
  final DateTime? failureStartedAtUtc;
  final String? failureCode;
  final DateTime? oldestPendingAtUtc;
  final DateTime? nextRetryAtUtc;

  bool continuousFailureForAtLeast(DateTime nowUtc, Duration duration) =>
      failureStartedAtUtc != null &&
      !nowUtc.difference(failureStartedAtUtc!).isNegative &&
      nowUtc.difference(failureStartedAtUtc!) >= duration;

  bool pendingForAtLeast(DateTime nowUtc, Duration duration) =>
      oldestPendingAtUtc != null &&
      !nowUtc.difference(oldestPendingAtUtc!).isNegative &&
      nowUtc.difference(oldestPendingAtUtc!) >= duration;
}

final class RemoteSynchronizationChange {
  RemoteSynchronizationChange({
    required this.cursor,
    required String entityType,
    required String entityId,
    required this.revision,
    required this.operationType,
    required String payloadJson,
  }) : entityType = _requireText(entityType, 'Entity type'),
       entityId = _requireUuid(entityId, 'Entity id'),
       payloadJson = _requireText(payloadJson, 'Payload JSON') {
    if (cursor <= 0) {
      throw ArgumentError.value(cursor, 'cursor', 'must be positive');
    }
    if (revision <= 0) {
      throw ArgumentError.value(revision, 'revision', 'must be positive');
    }
  }

  final int cursor;
  final String entityType;
  final String entityId;
  final int revision;
  final OutboxOperationType operationType;
  final String payloadJson;
}

enum RemoteSynchronizationApplyDisposition {
  applied,
  duplicate,
  keptNewerLocal,
  conflict,
}

enum SynchronizationConflictResolutionChoice {
  localVersion,
  remoteVersion,
  correctedVersion,
  deleteVersion,
}

final class SynchronizationConflictEntityReference {
  SynchronizationConflictEntityReference({
    required String entityType,
    required String entityId,
  }) : entityType = _requireText(entityType, 'Entity type'),
       entityId = _requireUuid(entityId, 'Entity id');

  final String entityType;
  final String entityId;
}

/// The immutable evidence for one synchronization conflict. Resolution marks
/// this record complete but never replaces either original snapshot.
final class SynchronizationConflictRecord {
  SynchronizationConflictRecord({
    required String id,
    required String studentId,
    required String entityType,
    required String entityId,
    required this.localRevision,
    required this.remoteRevision,
    required String localSnapshotJson,
    required String remoteSnapshotJson,
    required String rejectionCode,
    required String rejectionJson,
    required DateTime detectedAtUtc,
    required List<SynchronizationConflictEntityReference> affectedRecords,
    this.planningWeekStartDate,
    DateTime? resolvedAtUtc,
    String? resolutionJson,
  }) : id = _requireUuid(id, 'Conflict id'),
       studentId = _requireUuid(studentId, 'Student id'),
       entityType = _requireText(entityType, 'Entity type'),
       entityId = _requireUuid(entityId, 'Entity id'),
       localSnapshotJson = _requireText(
         localSnapshotJson,
         'Local snapshot JSON',
       ),
       remoteSnapshotJson = _requireText(
         remoteSnapshotJson,
         'Remote snapshot JSON',
       ),
       rejectionCode = _requireText(rejectionCode, 'Rejection code'),
       rejectionJson = _requireText(rejectionJson, 'Rejection JSON'),
       detectedAtUtc = _requireUtc(detectedAtUtc, 'Detected time'),
       affectedRecords = List.unmodifiable(affectedRecords),
       resolvedAtUtc = resolvedAtUtc == null
           ? null
           : _requireUtc(resolvedAtUtc, 'Resolved time'),
       resolutionJson = resolutionJson == null
           ? null
           : _requireText(resolutionJson, 'Resolution JSON') {
    if (localRevision < 0 || remoteRevision < 0) {
      throw ArgumentError('Conflict revisions must not be negative.');
    }
  }

  final String id;
  final String studentId;
  final String entityType;
  final String entityId;
  final int localRevision;
  final int remoteRevision;
  final String localSnapshotJson;
  final String remoteSnapshotJson;
  final String rejectionCode;
  final String rejectionJson;
  final DateTime detectedAtUtc;
  final List<SynchronizationConflictEntityReference> affectedRecords;
  final LocalDate? planningWeekStartDate;
  final DateTime? resolvedAtUtc;
  final String? resolutionJson;

  bool get isResolved => resolvedAtUtc != null;
  bool get keepsPlanningIncomplete =>
      !isResolved && planningWeekStartDate != null;
}

final class SynchronizationConflictResolutionReceipt {
  const SynchronizationConflictResolutionReceipt({
    required this.conflict,
    required this.operation,
  });

  final SynchronizationConflictRecord conflict;
  final OutboxOperation operation;
}

/// Local synchronization persistence used only inside a registry callback.
/// Implementations atomically pair inbound record application with cursor
/// advancement and pair terminal outbox rejection with conflict persistence.
abstract interface class SynchronizationLocalRepository {
  SynchronizationHealthSnapshot inspect({
    required String studentId,
    required String remoteScope,
  });

  void markHealth({
    required String studentId,
    required SynchronizationHealthDisposition disposition,
    required DateTime attemptedAtUtc,
    DateTime? succeededAtUtc,
    String? failureCode,
  });

  void recordTerminalRejection({
    required String studentId,
    required OutboxOperation operation,
    required String rejectionCode,
    required String rejectionJson,
    required DateTime rejectedAtUtc,
    required bool createsConflict,
  });

  RemoteSynchronizationApplyDisposition applyRemoteAndAdvanceCursor({
    required String studentId,
    required String remoteScope,
    required RemoteSynchronizationChange change,
    required DateTime appliedAtUtc,
  });

  List<SynchronizationConflictRecord> listConflicts({
    required String studentId,
    bool includeResolved = false,
  });

  SynchronizationConflictRecord? findConflict({
    required String studentId,
    required String conflictId,
  });

  SynchronizationConflictResolutionReceipt resolveConflict({
    required String studentId,
    required String conflictId,
    required SynchronizationConflictResolutionChoice choice,
    String? correctedValueJson,
    required MutationToken mutation,
  });
}

/// Optional capability so existing repository fakes remain source-compatible.
abstract interface class SynchronizationLocalReadRepositories
    implements LocalReadRepositories {
  SynchronizationLocalRepository get synchronization;
}

abstract interface class SynchronizationLocalWriteRepositories
    implements LocalWriteRepositories, SynchronizationLocalReadRepositories {
  @override
  SynchronizationLocalRepository get synchronization;
}

/// The one persisted Clinical Placement selection shared by management,
/// progress, and scheduling defaults. A null value means no active selection.
abstract interface class ActivePlacementSelectionReadRepository {
  StoredDomainRecord<String?>? find({required String studentId});
}

abstract interface class ActivePlacementSelectionRepository
    implements ActivePlacementSelectionReadRepository {
  MutationReceipt<String?> put({
    required String studentId,
    required String? clinicalPlacementId,
    required int expectedRevision,
    required MutationToken mutation,
  });
}

abstract interface class StudentProfileReadRepository {
  StoredDomainRecord<StudentProfile>? find({required String studentId});
}

abstract interface class StudentProfileRepository
    implements StudentProfileReadRepository {
  MutationReceipt<StudentProfile> put({
    required String studentId,
    required StudentProfile profile,
    required int expectedRevision,
    required MutationToken mutation,
  });
}

abstract interface class StudentSettingsReadRepository {
  StoredDomainRecord<StudentSettings>? find({required String studentId});
}

abstract interface class StudentSettingsRepository
    implements StudentSettingsReadRepository {
  MutationReceipt<StudentSettings> put({
    required String studentId,
    required StudentSettings settings,
    required int expectedRevision,
    required MutationToken mutation,
  });
}

abstract interface class LocalReadRepositories {
  ReadRepository<WorkShift> get workShifts;
  ReadRepository<ClinicalSession> get clinicalSessions;
  ReadRepository<ProtectedDay> get protectedDays;
  ReadRepository<ScheduleTemplate> get scheduleTemplates;
  ReadRepository<Preceptor> get preceptors;
  ReadRepository<ClinicalPlacement> get clinicalPlacements;
  ReadRepository<HistoricalHoursEntry> get historicalHoursEntries;
  ReadRepository<EvaluationPlan> get evaluationPlans;
  OutboxReadRepository get outbox;
  SyncCursorReadRepository get syncCursors;
  ActivePlacementSelectionReadRepository get activePlacementSelection;
}

abstract interface class LocalWriteRepositories
    implements LocalReadRepositories {
  @override
  MutableRepository<WorkShift> get workShifts;
  @override
  MutableRepository<ClinicalSession> get clinicalSessions;
  @override
  MutableRepository<ProtectedDay> get protectedDays;
  @override
  MutableRepository<ScheduleTemplate> get scheduleTemplates;
  @override
  MutableRepository<Preceptor> get preceptors;
  @override
  MutableRepository<ClinicalPlacement> get clinicalPlacements;
  @override
  MutableRepository<HistoricalHoursEntry> get historicalHoursEntries;
  @override
  MutableRepository<EvaluationPlan> get evaluationPlans;
  @override
  OutboxMaintenanceRepository get outbox;
  @override
  SyncCursorRepository get syncCursors;
  @override
  ActivePlacementSelectionRepository get activePlacementSelection;
}

/// Optional support capability kept separate so existing use-case fakes remain
/// source-compatible while support surfaces are integrated incrementally.
abstract interface class SupportLocalReadRepositories
    implements LocalReadRepositories {
  StudentProfileReadRepository get studentProfile;
  StudentSettingsReadRepository get studentSettings;
}

abstract interface class SupportLocalWriteRepositories
    implements LocalWriteRepositories, SupportLocalReadRepositories {
  @override
  StudentProfileRepository get studentProfile;
  @override
  StudentSettingsRepository get studentSettings;
}

/// Optional synchronized reminder capability. Native permission, preview, and
/// delivery records remain per-device and are intentionally not exposed here.
abstract interface class ReminderLocalReadRepositories
    implements LocalReadRepositories {
  ReadRepository<ReminderState> get reminderStates;
}

abstract interface class ReminderLocalWriteRepositories
    implements LocalWriteRepositories, ReminderLocalReadRepositories {
  @override
  MutableRepository<ReminderState> get reminderStates;
}

/// Owns local repository transactions.
///
/// Callbacks and every repository operation are deliberately synchronous: no
/// network await can occur while an implementation's database transaction is
/// open. The returned futures allow implementations to serialize callers
/// before invoking a callback.
abstract interface class RepositoryRegistry {
  Future<void> initialize();

  Future<R> read<R>(R Function(LocalReadRepositories repositories) callback);

  Future<R> mutate<R>(R Function(LocalWriteRepositories repositories) callback);
}

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

String _requireUuid(String value, String fieldName) {
  final normalized = value.trim();
  if (!_uuidPattern.hasMatch(normalized)) {
    throw ArgumentError.value(value, fieldName, 'must be a UUID');
  }
  return normalized.toLowerCase();
}

String _requireText(String value, String fieldName) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be empty');
  }
  return normalized;
}

DateTime _requireUtc(DateTime value, String fieldName) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, fieldName, 'must be UTC');
  }
  return value;
}
