import '../repositories.dart';

enum RecoveryFailureKind {
  notFound,
  expired,
  confirmationRequired,
  authenticationFailed,
  invariantViolation,
  concurrentModification,
}

final class RecoveryException implements Exception {
  const RecoveryException(this.kind, this.safeMessage, {this.cause});

  final RecoveryFailureKind kind;
  final String safeMessage;
  final Object? cause;
}

final class TrashEntry {
  const TrashEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.deletedAtUtc,
    required this.purgeAfterUtc,
    this.displayName,
    this.dependentRecordCount = 0,
  });

  final String id;
  final String entityType;
  final String entityId;
  final DateTime deletedAtUtc;
  final DateTime purgeAfterUtc;
  final String? displayName;
  final int dependentRecordCount;

  bool isExpiredAt(DateTime nowUtc) => !purgeAfterUtc.isAfter(nowUtc);
}

final class OperationalSnapshotSummary {
  const OperationalSnapshotSummary({
    required this.id,
    required this.snapshotDate,
    required this.createdAtUtc,
    required this.expiresAtUtc,
  });

  final String id;
  final String snapshotDate;
  final DateTime createdAtUtc;
  final DateTime expiresAtUtc;
}

enum RecoveryMergeDisposition { add, keepCurrent, useSnapshot, conflict }

final class RecoveryMergeItem {
  const RecoveryMergeItem({required this.identity, required this.disposition});

  final String identity;
  final RecoveryMergeDisposition disposition;
}

final class OperationalRecoveryPreview {
  const OperationalRecoveryPreview({
    required this.snapshot,
    required this.items,
  });

  final OperationalSnapshotSummary snapshot;
  final List<RecoveryMergeItem> items;

  int get additions => items
      .where((item) => item.disposition == RecoveryMergeDisposition.add)
      .length;
  int get snapshotUpdates => items
      .where((item) => item.disposition == RecoveryMergeDisposition.useSnapshot)
      .length;
  Iterable<RecoveryMergeItem> get conflicts => items.where(
    (item) => item.disposition == RecoveryMergeDisposition.conflict,
  );
}

enum RecoveryConflictChoice { keepCurrent, useSnapshot }

final class RecoveryApplyResult {
  const RecoveryApplyResult({required this.applied, required this.unchanged});

  final int applied;
  final int unchanged;
}

abstract interface class RecoveryStore {
  Future<List<TrashEntry>> listTrash({required DateTime nowUtc});

  Future<void> restoreTrash({
    required String trashId,
    required DateTime restoredAtUtc,
    required MutationToken mutation,
  });

  Future<void> permanentlyDelete({
    required String trashId,
    required DateTime deletedAtUtc,
    required MutationToken mutation,
  });

  Future<int> clearTrash({
    required DateTime deletedAtUtc,
    required List<MutationToken> mutations,
  });

  Future<int> purgeExpired({required DateTime nowUtc});

  Future<OperationalSnapshotSummary> createDailySnapshot({
    required DateTime nowUtc,
  });

  Future<List<OperationalSnapshotSummary>> listSnapshots({
    required DateTime nowUtc,
  });

  Future<OperationalRecoveryPreview> previewSnapshot({
    required String snapshotId,
    required DateTime nowUtc,
  });

  Future<RecoveryApplyResult> restoreSnapshot({
    required String snapshotId,
    required Map<String, RecoveryConflictChoice> choices,
    required DateTime nowUtc,
  });
}

abstract interface class RecoveryReauthenticationGate {
  Future<bool> reauthenticate({required String reason});
}

/// A single-use proof bridge between a fresh interactive authentication flow
/// and the application operation it authorizes.
final class OneShotRecoveryReauthenticationGate
    implements RecoveryReauthenticationGate {
  bool _granted = false;

  void grantOnce() => _granted = true;

  @override
  Future<bool> reauthenticate({required String reason}) async {
    final granted = _granted;
    _granted = false;
    return granted;
  }
}
