import 'dart:async';
import 'dart:convert';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';

import 'synchronization_transport.dart';
import 'production_synchronization_triggers.dart';

enum SynchronizationTrigger {
  localSave,
  reconnection,
  launchOrResume,
  explicit,
  realtimeHint,
  retry,
}

final class DurableSynchronizationService
    implements SynchronizationService, SynchronizationTriggerTarget {
  DurableSynchronizationService({
    required this._repositories,
    required this._transport,
    required this._retryScheduler,
    required this._clock,
    required this._studentId,
    this.remoteScope = 'student-calendar',
    SynchronizationBoundaryObserver boundaryObserver =
        const NoopSynchronizationBoundaryObserver(),
    bool initiallyConnected = true,
    this.pageSize = 100,
  }) : _boundary = boundaryObserver,
       _connected = initiallyConnected {
    if (pageSize <= 0) throw ArgumentError.value(pageSize, 'pageSize');
    if (_repositories is SynchronizationTriggeringRepositoryRegistry) {
      throw ArgumentError.value(
        _repositories,
        'repositories',
        'must be the undecorated base registry',
      );
    }
  }

  static const maximumBackoff = Duration(hours: 1);

  final RepositoryRegistry _repositories;
  final SynchronizationTransport _transport;
  final SynchronizationRetryScheduler _retryScheduler;
  final Clock _clock;
  final String _studentId;
  final SynchronizationBoundaryObserver _boundary;
  final String remoteScope;
  final int pageSize;

  bool _connected;
  bool _shutDown = false;
  bool _rerunRequested = false;
  bool _explicitRerunRequested = false;
  Future<SynchronizationResult>? _active;

  Future<SynchronizationHealthSnapshot> health() => _repositories.read(
    (repositories) => _syncRepository(
      repositories,
    ).inspect(studentId: _studentId, remoteScope: remoteScope),
  );

  @override
  Future<SynchronizationResult> synchronize() =>
      request(SynchronizationTrigger.explicit);

  @override
  Future<SynchronizationResult> afterLocalSave() =>
      request(SynchronizationTrigger.localSave);

  @override
  Future<SynchronizationResult> onLaunchOrResume() =>
      request(SynchronizationTrigger.launchOrResume);

  @override
  Future<SynchronizationResult> onRealtimeHint() =>
      request(SynchronizationTrigger.realtimeHint);

  @override
  Future<SynchronizationResult> syncNow() =>
      request(SynchronizationTrigger.explicit);

  @override
  Future<SynchronizationResult> onConnectivityChanged(bool connected) async {
    if (_shutDown) {
      return const SynchronizationResult(SynchronizationDisposition.offline);
    }
    _connected = connected;
    if (connected) return request(SynchronizationTrigger.reconnection);
    _retryScheduler.cancel();
    final now = _now();
    await _markHealth(
      SynchronizationHealthDisposition.offline,
      attemptedAtUtc: now,
    );
    return const SynchronizationResult(SynchronizationDisposition.offline);
  }

  Future<SynchronizationResult> request(SynchronizationTrigger trigger) {
    if (_shutDown) {
      return Future.value(
        const SynchronizationResult(SynchronizationDisposition.offline),
      );
    }
    final active = _active;
    if (active != null) {
      _rerunRequested = true;
      _explicitRerunRequested |= trigger == SynchronizationTrigger.explicit;
      return active;
    }
    final completer = Completer<SynchronizationResult>();
    _active = completer.future;
    unawaited(
      _drain(trigger)
          .then(completer.complete, onError: completer.completeError)
          .whenComplete(() => _active = null),
    );
    return completer.future;
  }

  /// Stops new synchronization work, cancels retries, and waits for any
  /// in-flight transaction to finish before a local database is closed.
  Future<void> shutdown() async {
    if (_shutDown) return;
    _shutDown = true;
    _connected = false;
    _rerunRequested = false;
    _explicitRerunRequested = false;
    _retryScheduler.cancel();
    await _active;
  }

  Future<SynchronizationResult> _drain(
    SynchronizationTrigger initialTrigger,
  ) async {
    var trigger = initialTrigger;
    SynchronizationResult result;
    do {
      _rerunRequested = false;
      result = await _runOneCycle(trigger);
      trigger = _explicitRerunRequested
          ? SynchronizationTrigger.explicit
          : SynchronizationTrigger.retry;
      _explicitRerunRequested = false;
    } while (_rerunRequested && _connected);
    return result;
  }

  Future<SynchronizationResult> _runOneCycle(
    SynchronizationTrigger trigger,
  ) async {
    final startedAt = _now();
    if (!_connected) {
      await _markHealth(
        SynchronizationHealthDisposition.offline,
        attemptedAtUtc: startedAt,
      );
      return const SynchronizationResult(SynchronizationDisposition.offline);
    }
    _retryScheduler.cancel();
    await _markHealth(
      SynchronizationHealthDisposition.syncing,
      attemptedAtUtc: startedAt,
    );

    String? terminalFailure;
    while (true) {
      final pending = await _repositories.read(
        (repositories) => repositories.outbox.pending(
          studentId: _studentId,
          asOfUtc: trigger == SynchronizationTrigger.explicit
              ? _manualRetryCutoffUtc
              : _now(),
          limit: pageSize,
        ),
      );
      if (pending.isEmpty) break;
      var stopPush = false;
      for (final operation in pending) {
        final result = await _push(operation);
        if (result.disposition == _PushDisposition.retryScheduled) {
          return _failureResult();
        }
        if (result.disposition == _PushDisposition.terminalFailure) {
          terminalFailure = result.rejectionCode ?? 'terminal_rejection';
          stopPush = true;
          break;
        }
        if (result.disposition == _PushDisposition.conflict) {
          stopPush = true;
          break;
        }
      }
      if (stopPush || pending.length < pageSize) break;
    }

    try {
      await _pullAll();
    } on SynchronizationTransportException catch (error) {
      await _recordCycleFailure(error.code, offline: error.offline);
      return _failureResult(offline: error.offline);
    } on RepositoryException catch (error) {
      await _recordCycleFailure('cursor_or_payload_failure', offline: false);
      return SynchronizationResult(
        SynchronizationDisposition.deferred,
        detail: error.message,
      );
    }

    final completedAt = _now();
    final snapshot = await health();
    final disposition = snapshot.unresolvedConflictCount > 0
        ? SynchronizationHealthDisposition.conflictNeedsAttention
        : terminalFailure != null
        ? SynchronizationHealthDisposition.failed
        : snapshot.pendingCount > 0
        ? SynchronizationHealthDisposition.failed
        : SynchronizationHealthDisposition.synced;
    final failureCode =
        terminalFailure ??
        (snapshot.pendingCount > 0
            ? snapshot.failureCode ?? 'retry_deferred'
            : null);
    await _markHealth(
      disposition,
      attemptedAtUtc: completedAt,
      succeededAtUtc: completedAt,
      failureCode: failureCode,
    );
    if (snapshot.pendingCount > 0 && snapshot.nextRetryAtUtc != null) {
      _scheduleRetry(snapshot.nextRetryAtUtc!);
    }
    return SynchronizationResult(
      disposition == SynchronizationHealthDisposition.synced
          ? SynchronizationDisposition.synchronized
          : SynchronizationDisposition.deferred,
      detail: disposition == SynchronizationHealthDisposition.synced
          ? null
          : disposition.name,
    );
  }

  Future<_PushOutcome> _push(OutboxOperation operation) async {
    _boundary.reached(SynchronizationBoundary.beforePush);
    SynchronizationPushResult response;
    try {
      response = await _transport.push(operation);
    } on SynchronizationTransportException catch (error) {
      await _recordOperationFailure(operation, error.code, error.offline);
      return const _PushOutcome(_PushDisposition.retryScheduled);
    }
    _boundary.reached(SynchronizationBoundary.afterPushBeforeLocalCommit);
    if (response.accepted) {
      final cursor = response.cursor;
      if (cursor == null || cursor <= 0) {
        await _recordOperationFailure(
          operation,
          'invalid_push_response',
          false,
        );
        return const _PushOutcome(_PushDisposition.retryScheduled);
      }
      await _repositories.mutate(
        (repositories) => repositories.outbox.acknowledge(
          studentId: _studentId,
          operationId: operation.mutation.operationId,
          serverCursor: cursor,
          acknowledgedAtUtc: _now(),
        ),
      );
      _boundary.reached(SynchronizationBoundary.afterPushLocalCommit);
      return const _PushOutcome(_PushDisposition.accepted);
    }

    final code = response.rejectionCode ?? 'invalid_push_response';
    if (code == 'unauthenticated') {
      await _recordOperationFailure(operation, code, false);
      return const _PushOutcome(_PushDisposition.retryScheduled);
    }
    final conflict = _conflictCodes.contains(code);
    await _repositories.mutate((repositories) {
      _syncRepository(repositories).recordTerminalRejection(
        studentId: _studentId,
        operation: operation,
        rejectionCode: code,
        rejectionJson: response.rejectionJson ?? '{"code":"$code"}',
        rejectedAtUtc: _now(),
        createsConflict: conflict,
      );
    });
    _boundary.reached(SynchronizationBoundary.afterPushLocalCommit);
    return _PushOutcome(
      conflict ? _PushDisposition.conflict : _PushDisposition.terminalFailure,
      rejectionCode: code,
    );
  }

  Future<void> _pullAll() async {
    final cursor = await _repositories.read(
      (repositories) =>
          repositories.syncCursors
              .find(studentId: _studentId, remoteScope: remoteScope)
              ?.serverCursor ??
          0,
    );
    var fetchCursor = cursor;
    final fetched = <RemoteSynchronizationChange>[];
    while (true) {
      _boundary.reached(SynchronizationBoundary.beforePull);
      final page = await _transport.pull(
        afterCursor: fetchCursor,
        limit: pageSize,
      );
      _boundary.reached(SynchronizationBoundary.afterPullBeforeLocalCommit);
      final ordered =
          {for (final change in page) change.cursor: change}.values.toList()
            ..sort((left, right) => left.cursor.compareTo(right.cursor));
      fetched.addAll(ordered.where((change) => change.cursor > fetchCursor));
      if (ordered.isNotEmpty) fetchCursor = ordered.last.cursor;
      if (page.length < pageSize) break;
    }

    final pending = <RemoteSynchronizationChange>[
      ...{for (final change in fetched) change.cursor: change}.values,
    ]..sort((left, right) => left.cursor.compareTo(right.cursor));
    final aggregateBatches =
        <
          String,
          ({
            _AggregateEnvelope envelope,
            List<RemoteSynchronizationChange> changes,
          })
        >{};
    for (final change in pending) {
      final envelope = _aggregateEnvelope(change);
      if (envelope == null) continue;
      aggregateBatches
          .putIfAbsent(
            envelope.mutationId,
            () => (envelope: envelope, changes: []),
          )
          .changes
          .add(change);
    }
    for (final batch in aggregateBatches.values) {
      final aggregate = batch.envelope;
      final changes = batch.changes;
      final actual = {
        for (final change in changes) '${change.entityType}:${change.entityId}',
      };
      if (actual.length != aggregate.expectedMembers.length ||
          !actual.containsAll(aggregate.expectedMembers)) {
        await _repositories.mutate((repositories) {
          final synchronization = _syncRepository(repositories);
          if (synchronization
              case final AggregateSynchronizationLocalRepository
                  aggregateRepository) {
            aggregateRepository.recordIncompleteAggregatePull(
              studentId: _studentId,
              firstMember: changes.first,
              aggregateMutationId: aggregate.mutationId,
              detectedAtUtc: _now(),
            );
          }
        });
        throw const SynchronizationTransportException(
          'incomplete_aggregate_batch',
          offline: false,
        );
      }
    }
    final lastIndexByAggregate = {
      for (final entry in aggregateBatches.entries)
        entry.key: pending.indexOf(entry.value.changes.last),
    };
    var index = 0;
    while (index < pending.length) {
      var endIndex = index;
      var scanIndex = index;
      while (scanIndex <= endIndex) {
        final envelope = _aggregateEnvelope(pending[scanIndex]);
        if (envelope != null) {
          final aggregateEnd = lastIndexByAggregate[envelope.mutationId]!;
          if (aggregateEnd > endIndex) endIndex = aggregateEnd;
        }
        scanIndex++;
      }
      final visibleBatch = pending.sublist(index, endIndex + 1);
      await _repositories.mutate((repositories) {
        final synchronization = _syncRepository(repositories);
        if (synchronization
            case final AggregateSynchronizationLocalRepository
                aggregateRepository) {
          final resolved = <String>{};
          for (final change in visibleBatch) {
            final envelope = _aggregateEnvelope(change);
            if (envelope != null && resolved.add(envelope.mutationId)) {
              aggregateRepository.resolveIncompleteAggregatePull(
                studentId: _studentId,
                aggregateMutationId: envelope.mutationId,
                resolvedAtUtc: _now(),
              );
            }
          }
        }
        for (final change in visibleBatch) {
          synchronization.applyRemoteAndAdvanceCursor(
            studentId: _studentId,
            remoteScope: remoteScope,
            change: change,
            appliedAtUtc: _now(),
          );
        }
      });
      _boundary.reached(SynchronizationBoundary.afterPullLocalCommit);
      index = endIndex + 1;
    }
  }

  _AggregateEnvelope? _aggregateEnvelope(RemoteSynchronizationChange change) {
    final decoded = jsonDecode(change.payloadJson);
    if (decoded is! Map<String, dynamic>) return null;
    final mutationId = decoded['aggregate_mutation_id'];
    final manifest = decoded['expected_member_manifest'];
    if (mutationId is! String || manifest is! Map<String, dynamic>) return null;
    return _AggregateEnvelope(mutationId, manifest.keys.toSet());
  }

  Future<void> _recordOperationFailure(
    OutboxOperation operation,
    String code,
    bool offline,
  ) async {
    final attemptedAt = _now();
    final nextAttempt = attemptedAt.add(_backoff(operation.attemptCount + 1));
    await _repositories.mutate(
      (repositories) => repositories.outbox.recordFailedAttempt(
        studentId: _studentId,
        operationId: operation.mutation.operationId,
        attemptedAtUtc: attemptedAt,
        nextAttemptAtUtc: nextAttempt,
        failureCode: code,
      ),
    );
    await _recordCycleFailure(code, offline: offline);
    _scheduleRetry(nextAttempt);
  }

  void _scheduleRetry(DateTime retryAtUtc) {
    _retryScheduler.schedule(
      retryAtUtc,
      () async => request(SynchronizationTrigger.retry),
    );
  }

  Future<void> _recordCycleFailure(String code, {required bool offline}) async {
    await _markHealth(
      offline
          ? SynchronizationHealthDisposition.offline
          : SynchronizationHealthDisposition.failed,
      attemptedAtUtc: _now(),
      failureCode: code,
    );
  }

  Future<void> _markHealth(
    SynchronizationHealthDisposition disposition, {
    required DateTime attemptedAtUtc,
    DateTime? succeededAtUtc,
    String? failureCode,
  }) => _repositories.mutate(
    (repositories) => _syncRepository(repositories).markHealth(
      studentId: _studentId,
      disposition: disposition,
      attemptedAtUtc: attemptedAtUtc,
      succeededAtUtc: succeededAtUtc,
      failureCode: failureCode,
    ),
  );

  Future<SynchronizationResult> _failureResult({bool offline = false}) async {
    final snapshot = await health();
    return SynchronizationResult(
      offline ||
              snapshot.disposition == SynchronizationHealthDisposition.offline
          ? SynchronizationDisposition.offline
          : SynchronizationDisposition.deferred,
      detail: snapshot.failureCode,
    );
  }

  DateTime _now() {
    final value = _clock.nowUtc();
    if (!value.isUtc) throw StateError('Clock must return UTC.');
    return value;
  }
}

final _manualRetryCutoffUtc = DateTime.utc(9999, 12, 31, 23, 59, 59);

enum _PushDisposition { accepted, conflict, terminalFailure, retryScheduled }

final class _PushOutcome {
  const _PushOutcome(this.disposition, {this.rejectionCode});

  final _PushDisposition disposition;
  final String? rejectionCode;
}

final class _AggregateEnvelope {
  const _AggregateEnvelope(this.mutationId, this.expectedMembers);

  final String mutationId;
  final Set<String> expectedMembers;
}

const _conflictCodes = {
  'stale_revision',
  'relationship_violation',
  'schedule_conflict',
  'protected_day_violation',
};

Duration _backoff(int attempt) {
  final exponent = attempt.clamp(1, 11) - 1;
  final seconds = 5 * (1 << exponent);
  final capped =
      seconds > DurableSynchronizationService.maximumBackoff.inSeconds
      ? DurableSynchronizationService.maximumBackoff.inSeconds
      : seconds;
  return Duration(seconds: capped);
}

SynchronizationLocalRepository _syncRepository(
  LocalReadRepositories repositories,
) {
  if (repositories case final SynchronizationLocalReadRepositories sync) {
    return sync.synchronization;
  }
  throw const RepositoryException(
    RepositoryFailureKind.uninitialized,
    'Synchronization repositories are unavailable.',
  );
}
