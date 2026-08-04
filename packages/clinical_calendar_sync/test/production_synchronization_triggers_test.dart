import 'dart:async';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_sync/synchronization.dart';
import 'package:test/test.dart';

const _synchronized = SynchronizationResult(
  SynchronizationDisposition.synchronized,
);

void main() {
  test('coalesces a burst of successful commits into one wake', () async {
    final base = _Registry();
    final target = _TriggerTarget();
    final failures = <Object>[];
    final registry = SynchronizationTriggeringRepositoryRegistry(
      base: base,
      synchronization: target,
      onTriggerFailure: (error, _) => failures.add(error),
    );

    await Future.wait([
      registry.mutate((_) => 1),
      registry.mutate((_) => 2),
      registry.mutate((_) => 3),
    ]);
    await registry.waitForSynchronizationIdle();

    expect(target.afterLocalSaveCalls, 1);
    expect(base.mutationCount, 3);
    expect(failures, isEmpty);
  });

  test('commits during synchronization coalesce into one follow-up', () async {
    final base = _Registry();
    final target = _TriggerTarget();
    final firstRun = Completer<SynchronizationResult>();
    target.afterLocalSaveHandler = () => target.afterLocalSaveCalls == 1
        ? firstRun.future
        : Future.value(_synchronized);
    final registry = SynchronizationTriggeringRepositoryRegistry(
      base: base,
      synchronization: target,
      onTriggerFailure: (_, _) {},
    );

    await registry.mutate((_) => 1);
    await Future<void>.delayed(Duration.zero);
    expect(target.afterLocalSaveCalls, 1);

    await Future.wait([
      registry.mutate((_) => 2),
      registry.mutate((_) => 3),
      registry.mutate((_) => 4),
    ]);
    expect(target.afterLocalSaveCalls, 1);

    firstRun.complete(_synchronized);
    await registry.waitForSynchronizationIdle();
    expect(target.afterLocalSaveCalls, 2);
  });

  test('failed mutation does not wake synchronization', () async {
    final base = _Registry()..failNextMutation = true;
    final target = _TriggerTarget();
    final registry = SynchronizationTriggeringRepositoryRegistry(
      base: base,
      synchronization: target,
      onTriggerFailure: (_, _) {},
    );

    await expectLater(registry.mutate((_) => 1), throwsStateError);
    await Future<void>.delayed(Duration.zero);
    expect(target.afterLocalSaveCalls, 0);
  });

  test(
    'trigger failure is observed after the committed mutation returns',
    () async {
      final base = _Registry();
      final target = _TriggerTarget()
        ..afterLocalSaveHandler = () => Future.error(StateError('network'));
      final failures = <Object>[];
      final registry = SynchronizationTriggeringRepositoryRegistry(
        base: base,
        synchronization: target,
        onTriggerFailure: (error, _) => failures.add(error),
      );

      expect(await registry.mutate((_) => 1), 1);
      expect(base.mutationCount, 1);
      await registry.waitForSynchronizationIdle();
      expect(failures, [isA<StateError>()]);
    },
  );

  test('synchronization work on the base registry cannot recurse', () async {
    final base = _Registry();
    final target = _TriggerTarget();
    target.afterLocalSaveHandler = () async {
      await base.mutate((_) => null);
      return _synchronized;
    };
    final registry = SynchronizationTriggeringRepositoryRegistry(
      base: base,
      synchronization: target,
      onTriggerFailure: (_, _) {},
    );

    await registry.mutate((_) => null);
    await registry.waitForSynchronizationIdle();

    expect(target.afterLocalSaveCalls, 1);
    expect(base.mutationCount, 2);
  });

  test('durable service rejects the triggering decorator as its ledger', () {
    final base = _Registry();
    final target = _TriggerTarget();
    final decorated = SynchronizationTriggeringRepositoryRegistry(
      base: base,
      synchronization: target,
      onTriggerFailure: (_, _) {},
    );

    expect(
      () => DurableSynchronizationService(
        repositories: decorated,
        transport: _Transport(),
        retryScheduler: _RetryScheduler(),
        clock: _Clock(),
        studentId: '00000000-0000-4000-8000-000000000001',
      ),
      throwsArgumentError,
    );
  });

  test('coordinator exposes every production non-save trigger', () async {
    final target = _TriggerTarget();
    final coordinator = SynchronizationTriggerCoordinator(target);

    await coordinator.onLaunchOrResume();
    await coordinator.onConnectivityChanged(false);
    await coordinator.onConnectivityChanged(true);
    await coordinator.syncNow();
    await coordinator.onRealtimeHint();

    expect(target.launchCalls, 1);
    expect(target.connectivityValues, [false, true]);
    expect(target.syncNowCalls, 1);
    expect(target.realtimeCalls, 1);
  });
}

final class _Registry implements RepositoryRegistry {
  int initializeCount = 0;
  int readCount = 0;
  int mutationCount = 0;
  bool failNextMutation = false;

  @override
  Future<void> initialize() async => initializeCount++;

  @override
  Future<R> read<R>(R Function(LocalReadRepositories repositories) callback) {
    readCount++;
    throw UnimplementedError('The callback is outside this seam fixture.');
  }

  @override
  Future<R> mutate<R>(
    R Function(LocalWriteRepositories repositories) callback,
  ) async {
    mutationCount++;
    if (failNextMutation) {
      failNextMutation = false;
      throw StateError('local commit failed');
    }
    if (R == int) return mutationCount as R;
    return null as R;
  }
}

final class _TriggerTarget implements SynchronizationTriggerTarget {
  int afterLocalSaveCalls = 0;
  int launchCalls = 0;
  int syncNowCalls = 0;
  int realtimeCalls = 0;
  final connectivityValues = <bool>[];
  Future<SynchronizationResult> Function()? afterLocalSaveHandler;

  @override
  Future<SynchronizationResult> afterLocalSave() {
    afterLocalSaveCalls++;
    return afterLocalSaveHandler?.call() ?? Future.value(_synchronized);
  }

  @override
  Future<SynchronizationResult> onConnectivityChanged(bool connected) async {
    connectivityValues.add(connected);
    return _synchronized;
  }

  @override
  Future<SynchronizationResult> onLaunchOrResume() async {
    launchCalls++;
    return _synchronized;
  }

  @override
  Future<SynchronizationResult> onRealtimeHint() async {
    realtimeCalls++;
    return _synchronized;
  }

  @override
  Future<SynchronizationResult> syncNow() async {
    syncNowCalls++;
    return _synchronized;
  }
}

final class _Transport implements SynchronizationTransport {
  @override
  Future<List<RemoteSynchronizationChange>> pull({
    required int afterCursor,
    required int limit,
  }) => throw UnimplementedError();

  @override
  Future<SynchronizationPushResult> push(OutboxOperation operation) =>
      throw UnimplementedError();
}

final class _RetryScheduler implements SynchronizationRetryScheduler {
  @override
  void cancel() {}

  @override
  void schedule(DateTime atUtc, Future<void> Function() callback) {}
}

final class _Clock implements Clock {
  @override
  DateTime nowUtc() => DateTime.utc(2026, 8, 3);
}
