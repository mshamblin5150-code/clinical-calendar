import 'dart:async';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';

/// The production synchronization entry points shared by composition seams.
abstract interface class SynchronizationTriggerTarget {
  Future<SynchronizationResult> afterLocalSave();

  Future<SynchronizationResult> onLaunchOrResume();

  Future<SynchronizationResult> onConnectivityChanged(bool connected);

  Future<SynchronizationResult> syncNow();

  Future<SynchronizationResult> onRealtimeHint();
}

typedef SynchronizationTriggerFailureObserver =
    void Function(Object error, StackTrace stackTrace);

/// Application-facing registry that wakes synchronization after local commits.
///
/// [base] must be the undecorated registry retained by the synchronization
/// service. This decorator is passed only to application services; otherwise
/// synchronization's own acknowledgement and cursor transactions would wake
/// synchronization recursively.
final class SynchronizationTriggeringRepositoryRegistry
    implements RepositoryRegistry, ClinicalPlacementAggregateDeletionStore {
  SynchronizationTriggeringRepositoryRegistry({
    required this.base,
    required this.synchronization,
    required this.onTriggerFailure,
  });

  final RepositoryRegistry base;
  final SynchronizationTriggerTarget synchronization;
  final SynchronizationTriggerFailureObserver onTriggerFailure;

  bool _scheduled = false;
  bool _running = false;
  bool _commitDuringRun = false;
  Completer<void>? _idle;

  @override
  Future<void> initialize() => base.initialize();

  @override
  Future<R> read<R>(R Function(LocalReadRepositories repositories) callback) =>
      base.read(callback);

  @override
  Future<R> mutate<R>(
    R Function(LocalWriteRepositories repositories) callback,
  ) async {
    final result = await base.mutate(callback);
    _wakeAfterCommit();
    return result;
  }

  ClinicalPlacementAggregateDeletionStore get _placementDeletionStore {
    if (base case ClinicalPlacementAggregateDeletionStore store) {
      return store;
    }
    throw const RepositoryException(
      RepositoryFailureKind.persistenceFailure,
      'Clinical Placement recovery is not available in this build.',
    );
  }

  @override
  Future<ClinicalPlacementDeletionPreview> previewClinicalPlacementDeletion({
    required String clinicalPlacementId,
    required int unsavedSchedulingDraftCount,
  }) => _placementDeletionStore.previewClinicalPlacementDeletion(
    clinicalPlacementId: clinicalPlacementId,
    unsavedSchedulingDraftCount: unsavedSchedulingDraftCount,
  );

  @override
  Future<void> moveClinicalPlacementAggregateToTrash({
    required ClinicalPlacementDeletionPreview preview,
    required String aggregateMutationId,
    required DateTime deletedAtUtc,
  }) async {
    await _placementDeletionStore.moveClinicalPlacementAggregateToTrash(
      preview: preview,
      aggregateMutationId: aggregateMutationId,
      deletedAtUtc: deletedAtUtc,
    );
    _wakeAfterCommit();
  }

  /// Completes after scheduled and coalesced commit triggers have settled.
  Future<void> waitForSynchronizationIdle() => _idle?.future ?? Future.value();

  void _wakeAfterCommit() {
    if (_running) {
      _commitDuringRun = true;
      return;
    }
    if (_scheduled) return;
    _scheduled = true;
    _idle ??= Completer<void>();
    scheduleMicrotask(_runTrigger);
  }

  Future<void> _runTrigger() async {
    _scheduled = false;
    _running = true;
    try {
      await synchronization.afterLocalSave();
    } on Object catch (error, stackTrace) {
      try {
        onTriggerFailure(error, stackTrace);
      } on Object {
        // Observability failures cannot change an already-committed mutation.
      }
    } finally {
      _running = false;
    }
    if (_commitDuringRun) {
      _commitDuringRun = false;
      _wakeAfterCommit();
      return;
    }
    _idle?.complete();
    _idle = null;
  }
}

/// Production entry points for lifecycle, connectivity, explicit, and hint
/// triggers. Realtime remains a wake hint; durable pull is authoritative.
final class SynchronizationTriggerCoordinator {
  const SynchronizationTriggerCoordinator(this._synchronization);

  final SynchronizationTriggerTarget _synchronization;

  Future<SynchronizationResult> onLaunchOrResume() =>
      _synchronization.onLaunchOrResume();

  Future<SynchronizationResult> onConnectivityChanged(bool connected) =>
      _synchronization.onConnectivityChanged(connected);

  Future<SynchronizationResult> syncNow() => _synchronization.syncNow();

  Future<SynchronizationResult> onRealtimeHint() =>
      _synchronization.onRealtimeHint();
}
