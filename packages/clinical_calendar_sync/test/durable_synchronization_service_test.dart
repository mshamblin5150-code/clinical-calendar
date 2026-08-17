import 'dart:convert';
import 'dart:io';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:clinical_calendar_sync/synchronization.dart';
import 'package:test/test.dart';

const _studentId = '00000000-0000-4000-8000-000000000001';
const _preceptorId = '00000000-0000-4000-8000-000000000002';
const _placementId = '00000000-0000-4000-8000-000000000003';
const _planId = '00000000-0000-4000-8000-000000000004';
const _key =
    '0123456789abcdef0123456789abcdef'
    '0123456789abcdef0123456789abcdef';
final _baseTime = DateTime.utc(2026, 8, 3, 12);

void main() {
  late Directory temporaryDirectory;
  late _Device first;
  late _Device second;
  late _ServerTransport server;
  late _Clock clock;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'clinical-calendar-sync-',
    );
    clock = _Clock(_baseTime);
    server = _ServerTransport();
    first = await _Device.open(
      temporaryDirectory,
      'first.db',
      identifiers: _Identifiers(100),
    );
    second = await _Device.open(
      temporaryDirectory,
      'second.db',
      identifiers: _Identifiers(500),
    );
  });

  tearDown(() async {
    await first.close();
    await second.close();
    await temporaryDirectory.delete(recursive: true);
  });

  test('two devices push once and pull the same durable record', () async {
    await _putPreceptor(first.registry, 'First Device', 1, clock.nowUtc());
    final firstSync = _service(first, server, clock);
    final secondSync = _service(second, server, clock);

    expect(
      (await firstSync.afterLocalSave()).disposition,
      SynchronizationDisposition.synchronized,
    );
    expect(server.feed, hasLength(1));
    expect(
      (await secondSync.onLaunchOrResume()).disposition,
      SynchronizationDisposition.synchronized,
    );
    expect(await _preceptorName(second.registry), 'First Device');
    expect(await _cursor(second.registry), 1);
    expect((await secondSync.health()).pendingCount, 0);
  });

  test('shutdown cancels work and never touches a closed repository', () async {
    final scheduler = _Scheduler();
    final service = _service(first, server, clock, scheduler: scheduler);

    await service.shutdown();
    await first.registry.close();

    expect(
      (await service.syncNow()).disposition,
      SynchronizationDisposition.offline,
    );
    expect(
      (await service.onConnectivityChanged(true)).disposition,
      SynchronizationDisposition.offline,
    );
    expect(scheduler.callback, isNull);
  });

  test(
    'fresh devices share one canonical Settings aggregate identity',
    () async {
      await _putSettings(first.registry, DateTime.monday, 90, clock.nowUtc());
      await _putSettings(second.registry, DateTime.sunday, 91, clock.nowUtc());

      expect(await _settingsIdentity(first), _studentId);
      expect(await _settingsIdentity(second), _studentId);

      await _service(first, server, clock).syncNow();
      final secondResult = await _service(second, server, clock).syncNow();

      expect(secondResult.disposition, SynchronizationDisposition.deferred);
      expect(server.records.keys.where((key) => key.startsWith('settings/')), [
        'settings/$_studentId',
      ]);
      expect(await _settingsRowCount(first), 1);
      expect(await _settingsRowCount(second), 1);
      expect(await _cursor(second.registry), 1);
    },
  );

  test(
    'unknown theme and Enhanced accessibility synchronize without normalization',
    () async {
      await _putSettings(
        first.registry,
        DateTime.monday,
        92,
        clock.nowUtc(),
        themeId: 'future-theme',
        enhancedAccessibility: true,
      );

      await _service(first, server, clock).syncNow();
      await _service(second, server, clock).syncNow();

      final synchronized = await second.registry.read((repositories) {
        final support = repositories as SupportLocalReadRepositories;
        return support.studentSettings.find(studentId: _studentId)!.value;
      });
      expect(synchronized.themeId, 'future-theme');
      expect(synchronized.enhancedAccessibility, isTrue);
    },
  );

  test(
    'legacy synchronized theme resolves and persists as variant-f',
    () async {
      final payload = jsonEncode({
        'schema_version': 1,
        'entity_type': 'settings',
        'entity_id': _studentId,
        'student_id': _studentId,
        'revision': 1,
        'created_at_utc': _baseTime.toIso8601String(),
        'updated_at_utc': _baseTime.toIso8601String(),
        'deleted_at_utc': null,
        'value': {
          'week_start': DateTime.sunday,
          'time_display': 'military',
          'theme': 'borg_tactical',
          'synchronization_mode': 'enabled',
          'notification_preferences_json': '{}',
          'active_placement_id': null,
        },
      });
      server.feed.add(
        RemoteSynchronizationChange(
          cursor: 1,
          entityType: 'settings',
          entityId: _studentId,
          revision: 1,
          operationType: OutboxOperationType.upsert,
          payloadJson: payload,
        ),
      );

      await _service(second, server, clock).syncNow();

      final row = second.database.select('SELECT * FROM settings').single;
      expect(row['theme'], StudentSettings.variantFThemeId);
      expect(row['enhanced_accessibility'], 0);
    },
  );

  test(
    'termination after push response replays one idempotent operation',
    () async {
      await _putPreceptor(first.registry, 'Durable Push', 2, clock.nowUtc());
      final observer = _TerminateOnce(
        SynchronizationBoundary.afterPushBeforeLocalCommit,
      );
      await expectLater(
        _service(first, server, clock, boundary: observer).syncNow(),
        throwsA(isA<_SimulatedTermination>()),
      );
      expect(server.feed, hasLength(1));
      expect(await _pendingCount(first.registry, clock.nowUtc()), 1);

      await _service(first, server, clock).onLaunchOrResume();
      expect(server.feed, hasLength(1));
      expect(server.pushCalls, 2);
      expect(await _pendingCount(first.registry, clock.nowUtc()), 0);
      expect(await _cursor(first.registry), 1);
    },
  );

  test('termination around pull is cursor-idempotent on restart', () async {
    await _putPreceptor(first.registry, 'Remote Record', 3, clock.nowUtc());
    await _service(first, server, clock).syncNow();

    await expectLater(
      _service(
        second,
        server,
        clock,
        boundary: _TerminateOnce(
          SynchronizationBoundary.afterPullBeforeLocalCommit,
        ),
      ).onLaunchOrResume(),
      throwsA(isA<_SimulatedTermination>()),
    );
    expect(await _cursor(second.registry), 0);
    expect(await _preceptorName(second.registry), isNull);

    await _service(second, server, clock).onLaunchOrResume();
    expect(await _cursor(second.registry), 1);
    expect(await _preceptorName(second.registry), 'Remote Record');

    server.deliverDuplicates = true;
    await _service(second, server, clock).onRealtimeHint();
    expect(await _cursor(second.registry), 1);
    expect(await _preceptorName(second.registry), 'Remote Record');
  });

  for (final boundary in [
    SynchronizationBoundary.beforePush,
    SynchronizationBoundary.afterPushLocalCommit,
  ]) {
    test(
      'termination at ${boundary.name} recovers the push boundary',
      () async {
        await _putPreceptor(
          first.registry,
          'Push Boundary',
          30,
          clock.nowUtc(),
        );
        await expectLater(
          _service(
            first,
            server,
            clock,
            boundary: _TerminateOnce(boundary),
          ).syncNow(),
          throwsA(isA<_SimulatedTermination>()),
        );

        await _service(first, server, clock).onLaunchOrResume();
        expect(server.feed, hasLength(1));
        expect(await _pendingCount(first.registry, clock.nowUtc()), 0);
        expect(await _cursor(first.registry), 1);
      },
    );
  }

  for (final boundary in [
    SynchronizationBoundary.beforePull,
    SynchronizationBoundary.afterPullLocalCommit,
  ]) {
    test(
      'termination at ${boundary.name} recovers the pull boundary',
      () async {
        await _putPreceptor(
          first.registry,
          'Pull Boundary',
          31,
          clock.nowUtc(),
        );
        await _service(first, server, clock).syncNow();
        await expectLater(
          _service(
            second,
            server,
            clock,
            boundary: _TerminateOnce(boundary),
          ).onLaunchOrResume(),
          throwsA(isA<_SimulatedTermination>()),
        );

        await _service(second, server, clock).onLaunchOrResume();
        expect(await _cursor(second.registry), 1);
        expect(await _preceptorName(second.registry), 'Pull Boundary');
      },
    );
  }

  test('reordered duplicate delivery sorts and recovers the cursor', () async {
    await _putPreceptor(first.registry, 'Revision One', 4, clock.nowUtc());
    await _service(first, server, clock).syncNow();
    clock.advance(const Duration(minutes: 1));
    await _putPreceptor(first.registry, 'Revision Two', 5, clock.nowUtc());
    await _service(first, server, clock).syncNow();

    server
      ..reversePull = true
      ..deliverDuplicates = true;
    await _service(second, server, clock).onLaunchOrResume();
    expect(await _cursor(second.registry), 2);
    expect(await _preceptorName(second.registry), 'Revision Two');
  });

  test(
    'transient failure persists backoff and recovers without data loss',
    () async {
      await _putPreceptor(first.registry, 'Retry Me', 6, clock.nowUtc());
      final scheduler = _Scheduler();
      final service = _service(first, server, clock, scheduler: scheduler);
      server.nextPushError = const SynchronizationTransportException(
        'server_unavailable',
        offline: false,
      );

      expect(
        (await service.afterLocalSave()).disposition,
        SynchronizationDisposition.deferred,
      );
      final failed = await service.health();
      expect(failed.disposition, SynchronizationHealthDisposition.failed);
      expect(failed.pendingCount, 1);
      expect(
        failed.continuousFailureForAtLeast(
          clock.nowUtc(),
          const Duration(hours: 1),
        ),
        isFalse,
      );
      expect(
        scheduler.scheduledAt,
        clock.nowUtc().add(const Duration(seconds: 5)),
      );

      final restartedScheduler = _Scheduler();
      final restarted = _service(
        first,
        server,
        clock,
        scheduler: restartedScheduler,
      );
      expect(
        (await restarted.onLaunchOrResume()).disposition,
        SynchronizationDisposition.deferred,
      );
      expect(
        (await restarted.health()).disposition,
        SynchronizationHealthDisposition.failed,
      );
      expect(
        restartedScheduler.scheduledAt,
        clock.nowUtc().add(const Duration(seconds: 5)),
      );

      clock.advance(const Duration(hours: 1));
      server.nextPushError = const SynchronizationTransportException(
        'server_unavailable',
        offline: false,
      );
      await restartedScheduler.fire();
      expect(
        (await restarted.health()).continuousFailureForAtLeast(
          clock.nowUtc(),
          const Duration(hours: 1),
        ),
        isTrue,
      );
      expect(
        restartedScheduler.scheduledAt,
        clock.nowUtc().add(const Duration(seconds: 10)),
      );
      clock.advance(const Duration(seconds: 10));
      await restartedScheduler.fire();
      expect(
        (await restarted.health()).disposition,
        SynchronizationHealthDisposition.synced,
      );
      expect(await _pendingCount(first.registry, clock.nowUtc()), 0);
      expect(server.feed, hasLength(1));
    },
  );

  test(
    'explicit Sync Now retries queued changes before backoff expires',
    () async {
      await _putPreceptor(first.registry, 'Retry Now', 60, clock.nowUtc());
      final service = _service(first, server, clock);
      server.nextPushError = const SynchronizationTransportException(
        'server_unavailable',
        offline: false,
      );

      expect(
        (await service.afterLocalSave()).disposition,
        SynchronizationDisposition.deferred,
      );
      expect((await service.health()).pendingCount, 1);
      expect(server.pushCalls, 1);

      expect(
        (await service.syncNow()).disposition,
        SynchronizationDisposition.synchronized,
      );
      expect((await service.health()).pendingCount, 0);
      expect(server.pushCalls, 2);
    },
  );

  test('offline and twenty-four-hour pending health remain truthful', () async {
    await _putPreceptor(first.registry, 'Offline Save', 7, clock.nowUtc());
    final service = _service(first, server, clock);
    await service.onConnectivityChanged(false);
    final offline = await service.health();
    expect(offline.disposition, SynchronizationHealthDisposition.offline);
    expect(offline.pendingCount, 1);
    expect(offline.failureStartedAtUtc, isNull);

    clock.advance(const Duration(hours: 24));
    expect(
      (await service.health()).pendingForAtLeast(
        clock.nowUtc(),
        const Duration(hours: 24),
      ),
      isTrue,
    );
    await service.onConnectivityChanged(true);
    expect(
      (await service.health()).disposition,
      SynchronizationHealthDisposition.synced,
    );
  });

  test('two offline edits preserve a durable terminal Sync Conflict', () async {
    await _putPreceptor(first.registry, 'Shared', 8, clock.nowUtc());
    await _service(first, server, clock).syncNow();
    await _service(second, server, clock).syncNow();

    clock.advance(const Duration(minutes: 1));
    await _putPreceptor(first.registry, 'First Wins', 9, clock.nowUtc());
    await _putPreceptor(
      second.registry,
      'Second Preserved',
      10,
      clock.nowUtc(),
    );
    await _service(first, server, clock).syncNow();
    final secondResult = await _service(second, server, clock).syncNow();

    expect(secondResult.disposition, SynchronizationDisposition.deferred);
    final health = await _service(second, server, clock).health();
    expect(
      health.disposition,
      SynchronizationHealthDisposition.conflictNeedsAttention,
    );
    expect(health.unresolvedConflictCount, 1);
    expect(health.pendingCount, 0);
    expect(
      second.database
          .select(
            'SELECT terminal_rejection_code '
            'FROM outbox_operations WHERE terminal_rejection_code IS NOT NULL',
          )
          .single['terminal_rejection_code'],
      'stale_revision',
    );
    final conflict = second.database
        .select('SELECT * FROM sync_conflicts')
        .single;
    expect(conflict['local_snapshot_json'], contains('Second Preserved'));
    expect(await _preceptorName(second.registry), 'Second Preserved');
  });

  test(
    'two offline originals survive resolution and both devices converge',
    () async {
      await _putPreceptor(first.registry, 'Shared', 40, clock.nowUtc());
      await _service(first, server, clock).syncNow();
      await _service(second, server, clock).syncNow();

      clock.advance(const Duration(minutes: 1));
      await _putPreceptor(first.registry, 'First Original', 41, clock.nowUtc());
      await _putPreceptor(
        second.registry,
        'Second Original',
        42,
        clock.nowUtc(),
      );
      await _service(first, server, clock).syncNow();
      await _service(second, server, clock).syncNow();

      final open = await second.registry.read((repositories) {
        final sync = repositories as SynchronizationLocalReadRepositories;
        return sync.synchronization.listConflicts(studentId: _studentId);
      });
      expect(open, hasLength(1));
      expect(open.single.localSnapshotJson, contains('Second Original'));
      expect(open.single.remoteSnapshotJson, contains('First Original'));
      expect(open.single.rejectionCode, 'stale_revision');

      clock.advance(const Duration(minutes: 1));
      final receipt = await second.registry.mutate((repositories) {
        final sync = repositories as SynchronizationLocalWriteRepositories;
        return sync.synchronization.resolveConflict(
          studentId: _studentId,
          conflictId: open.single.id,
          choice: SynchronizationConflictResolutionChoice.localVersion,
          mutation: MutationToken(
            operationId: _id(9900),
            idempotencyKey: _id(9901),
            occurredAtUtc: clock.nowUtc(),
          ),
        );
      });
      expect(receipt.operation.type, OutboxOperationType.resolveConflict);
      expect(receipt.operation.baseRevision, 2);
      expect(receipt.conflict.isResolved, isTrue);
      expect(receipt.conflict.localSnapshotJson, contains('Second Original'));
      expect(receipt.conflict.remoteSnapshotJson, contains('First Original'));

      await _service(second, server, clock).syncNow();
      await _service(first, server, clock).syncNow();
      expect(await _preceptorName(first.registry), 'Second Original');
      expect(await _preceptorName(second.registry), 'Second Original');
      expect(server.records['preceptor/$_preceptorId']!['revision'], 3);
      expect(
        await second.registry.read((repositories) {
          final sync = repositories as SynchronizationLocalReadRepositories;
          return sync.synchronization.listConflicts(studentId: _studentId);
        }),
        isEmpty,
      );
    },
  );

  test(
    'legacy Evaluation Plan without an association stops at its cursor after restart',
    () async {
      server.feed.addAll([
        _remoteChange(
          cursor: 1,
          entityType: 'preceptor',
          entityId: _preceptorId,
          revision: 1,
          value: {'name': 'Primary'},
        ),
        _remoteChange(
          cursor: 2,
          entityType: 'clinical_placement',
          entityId: _placementId,
          revision: 1,
          value: {
            'name': 'Family Medicine',
            'target_minutes': 16200,
            'start_date': '2026-08-01',
            'completion_deadline': '2026-12-31',
            'lifecycle_state': 'active',
            'primary_preceptor_id': _preceptorId,
            'attached_preceptor_ids': [_preceptorId],
            'evaluation_plan_id': _planId,
          },
        ),
        _remoteChange(
          cursor: 3,
          entityType: 'evaluation_plan',
          entityId: _planId,
          revision: 1,
          value: {
            'configuration': {
              'initial_self_assessment_required': false,
              'interim_review_cadence_minutes': 5400,
              'final_self_assessment_required': false,
              'final_placement_review_required': false,
            },
            'requirements': <Object?>[],
          },
        ),
      ]);

      final firstAttempt = await _service(second, server, clock).syncNow();
      expect(firstAttempt.disposition, SynchronizationDisposition.deferred);
      expect(await _cursor(second.registry), 2);
      expect(second.database.select('SELECT * FROM evaluation_plans'), isEmpty);

      final afterRestart = await _service(
        second,
        server,
        clock,
      ).onLaunchOrResume();
      expect(afterRestart.disposition, SynchronizationDisposition.deferred);
      expect(await _cursor(second.registry), 2);
      expect(
        (await _service(second, server, clock).health()).failureCode,
        'cursor_or_payload_failure',
      );
    },
  );

  test(
    'incomplete aggregate pull stays invisible until its manifest is complete',
    () async {
      const secondPreceptorId = '00000000-0000-4000-8000-000000000099';
      const interleavedPreceptorId = '00000000-0000-4000-8000-000000000097';
      const aggregateId = '00000000-0000-4000-8000-000000000098';
      final manifest = {
        'preceptor:$_preceptorId': 0,
        'preceptor:$secondPreceptorId': 0,
      };
      server.feed.add(
        _remoteChange(
          cursor: 1,
          entityType: 'preceptor',
          entityId: _preceptorId,
          revision: 1,
          value: {'name': 'First aggregate member'},
          aggregateMutationId: aggregateId,
          aggregateManifest: manifest,
        ),
      );

      final incomplete = await _service(second, server, clock).syncNow();
      expect(incomplete.disposition, SynchronizationDisposition.deferred);
      expect(await _cursor(second.registry), 0);
      expect(await _preceptorName(second.registry), isNull);
      expect(
        (await _service(
          second,
          server,
          clock,
        ).health()).unresolvedConflictCount,
        1,
      );

      server.feed.addAll([
        _remoteChange(
          cursor: 2,
          entityType: 'preceptor',
          entityId: interleavedPreceptorId,
          revision: 1,
          value: {'name': 'Interleaved independent member'},
        ),
        _remoteChange(
          cursor: 3,
          entityType: 'preceptor',
          entityId: secondPreceptorId,
          revision: 1,
          value: {'name': 'Second aggregate member'},
          aggregateMutationId: aggregateId,
          aggregateManifest: manifest,
        ),
      ]);
      final complete = await _service(
        second,
        server,
        clock,
        pageSize: 1,
      ).syncNow();
      expect(complete.disposition, SynchronizationDisposition.synchronized);
      expect(await _cursor(second.registry), 3);
      expect(
        (await _service(
          second,
          server,
          clock,
        ).health()).unresolvedConflictCount,
        0,
      );
      await second.registry.read((repositories) {
        expect(
          repositories.preceptors
              .find(studentId: _studentId, id: _preceptorId)!
              .value
              .name,
          'First aggregate member',
        );
        expect(
          repositories.preceptors
              .find(studentId: _studentId, id: secondPreceptorId)!
              .value
              .name,
          'Second aggregate member',
        );
        expect(
          repositories.preceptors
              .find(studentId: _studentId, id: interleavedPreceptorId)!
              .value
              .name,
          'Interleaved independent member',
        );
      });
    },
  );
}

RemoteSynchronizationChange _remoteChange({
  required int cursor,
  required String entityType,
  required String entityId,
  required int revision,
  required Map<String, Object?> value,
  String? aggregateMutationId,
  Map<String, int>? aggregateManifest,
}) {
  final payload = jsonEncode({
    'schema_version': 1,
    'entity_type': entityType,
    'entity_id': entityId,
    'student_id': _studentId,
    'revision': revision,
    'created_at_utc': _baseTime.toIso8601String(),
    'updated_at_utc': _baseTime.toIso8601String(),
    'deleted_at_utc': null,
    'value': value,
    'aggregate_mutation_id': ?aggregateMutationId,
    'expected_member_manifest': ?aggregateManifest,
  });
  return RemoteSynchronizationChange(
    cursor: cursor,
    entityType: entityType,
    entityId: entityId,
    revision: revision,
    operationType: OutboxOperationType.upsert,
    payloadJson: payload,
  );
}

DurableSynchronizationService _service(
  _Device device,
  SynchronizationTransport transport,
  Clock clock, {
  SynchronizationRetryScheduler? scheduler,
  SynchronizationBoundaryObserver? boundary,
  int pageSize = 100,
}) => DurableSynchronizationService(
  repositories: device.registry,
  transport: transport,
  retryScheduler: scheduler ?? _Scheduler(),
  clock: clock,
  studentId: _studentId,
  boundaryObserver: boundary ?? const NoopSynchronizationBoundaryObserver(),
  pageSize: pageSize,
);

Future<void> _putPreceptor(
  SqliteRepositoryRegistry registry,
  String name,
  int sequence,
  DateTime atUtc,
) async {
  final existing = await registry.read(
    (repositories) =>
        repositories.preceptors.find(studentId: _studentId, id: _preceptorId),
  );
  await registry.mutate(
    (repositories) => repositories.preceptors.put(
      studentId: _studentId,
      value: Preceptor(id: _preceptorId, name: name),
      expectedRevision: existing?.revision ?? 0,
      mutation: MutationToken(
        operationId: _id(1000 + sequence * 2),
        idempotencyKey: _id(1001 + sequence * 2),
        occurredAtUtc: atUtc,
      ),
    ),
  );
}

Future<void> _putSettings(
  SqliteRepositoryRegistry registry,
  int weekStart,
  int sequence,
  DateTime atUtc, {
  String themeId = StudentSettings.variantFThemeId,
  bool enhancedAccessibility = false,
}) async {
  await registry.mutate((repositories) {
    final support = repositories as SupportLocalWriteRepositories;
    support.studentSettings.put(
      studentId: _studentId,
      settings: StudentSettings(
        weekStart: weekStart,
        themeId: themeId,
        enhancedAccessibility: enhancedAccessibility,
      ),
      expectedRevision: 0,
      mutation: MutationToken(
        operationId: _id(1000 + sequence * 2),
        idempotencyKey: _id(1001 + sequence * 2),
        occurredAtUtc: atUtc,
      ),
    );
  });
}

Future<String> _settingsIdentity(_Device device) async =>
    device.database.select('SELECT id FROM settings').single['id'] as String;

Future<int> _settingsRowCount(_Device device) async =>
    device.database
            .select('SELECT count(*) AS count FROM settings')
            .single['count']
        as int;

Future<String?> _preceptorName(SqliteRepositoryRegistry registry) =>
    registry.read(
      (repositories) => repositories.preceptors
          .find(studentId: _studentId, id: _preceptorId)
          ?.value
          .name,
    );

Future<int> _cursor(SqliteRepositoryRegistry registry) => registry.read(
  (repositories) =>
      repositories.syncCursors
          .find(studentId: _studentId, remoteScope: 'student-calendar')
          ?.serverCursor ??
      0,
);

Future<int> _pendingCount(
  SqliteRepositoryRegistry registry,
  DateTime asOfUtc,
) => registry.read(
  (repositories) => repositories.outbox
      .pending(studentId: _studentId, asOfUtc: asOfUtc)
      .length,
);

final class _Device {
  _Device(this.database, this.registry);

  final ClinicalCalendarDatabase database;
  final SqliteRepositoryRegistry registry;

  static Future<_Device> open(
    Directory directory,
    String name, {
    required IdentifierGenerator identifiers,
  }) async {
    final database = await ClinicalCalendarDatabase.open(
      path: '${directory.path}${Platform.pathSeparator}$name',
      secureStorage: _Storage(),
    );
    final registry = SqliteRepositoryRegistry(
      studentId: _studentId,
      database: database,
      identifierGenerator: identifiers,
    );
    await registry.initialize();
    return _Device(database, registry);
  }

  Future<void> close() => database.close();
}

final class _ServerTransport implements SynchronizationTransport {
  final Map<String, SynchronizationPushResult> receipts = {};
  final Map<String, Map<String, dynamic>> records = {};
  final List<RemoteSynchronizationChange> feed = [];
  SynchronizationTransportException? nextPushError;
  bool reversePull = false;
  bool deliverDuplicates = false;
  int pushCalls = 0;

  @override
  Future<SynchronizationPushResult> push(OutboxOperation operation) async {
    pushCalls++;
    final error = nextPushError;
    nextPushError = null;
    if (error != null) throw error;
    final prior = receipts[operation.mutation.idempotencyKey];
    if (prior != null) return prior;
    final key = '${operation.entityType}/${operation.entityId}';
    final current = records[key];
    final currentRevision = current?['revision'] as int? ?? 0;
    if (operation.baseRevision != currentRevision) {
      final result = SynchronizationPushResult.rejected(
        code: 'stale_revision',
        rejectionJson: jsonEncode({
          'code': 'stale_revision',
          'current_revision': currentRevision,
        }),
      );
      receipts[operation.mutation.idempotencyKey] = result;
      return result;
    }
    final payload = jsonDecode(operation.payloadJson) as Map<String, dynamic>;
    final cursor = feed.length + 1;
    records[key] = payload;
    feed.add(
      RemoteSynchronizationChange(
        cursor: cursor,
        entityType: operation.entityType,
        entityId: operation.entityId,
        revision: payload['revision'] as int,
        operationType: operation.type,
        payloadJson: operation.payloadJson,
      ),
    );
    final result = SynchronizationPushResult.accepted(
      cursor: cursor,
      revision: payload['revision'] as int,
    );
    receipts[operation.mutation.idempotencyKey] = result;
    return result;
  }

  @override
  Future<List<RemoteSynchronizationChange>> pull({
    required int afterCursor,
    required int limit,
  }) async {
    var result = feed
        .where((change) => change.cursor > afterCursor)
        .take(limit)
        .toList();
    if (deliverDuplicates && result.isNotEmpty) {
      result = [...result, result.first];
    }
    if (reversePull) result = result.reversed.toList();
    return result;
  }
}

final class _Scheduler implements SynchronizationRetryScheduler {
  DateTime? scheduledAt;
  Future<void> Function()? callback;

  @override
  void cancel() {
    scheduledAt = null;
    callback = null;
  }

  @override
  void schedule(DateTime atUtc, Future<void> Function() value) {
    scheduledAt = atUtc;
    callback = value;
  }

  Future<void> fire() async {
    final value = callback;
    scheduledAt = null;
    callback = null;
    await value?.call();
  }
}

final class _TerminateOnce implements SynchronizationBoundaryObserver {
  _TerminateOnce(this.target);
  final SynchronizationBoundary target;
  bool terminated = false;

  @override
  void reached(SynchronizationBoundary boundary) {
    if (!terminated && boundary == target) {
      terminated = true;
      throw const _SimulatedTermination();
    }
  }
}

final class _SimulatedTermination implements Exception {
  const _SimulatedTermination();
}

final class _Clock implements Clock {
  _Clock(this.value);
  DateTime value;

  void advance(Duration duration) => value = value.add(duration);

  @override
  DateTime nowUtc() => value;
}

final class _Identifiers implements IdentifierGenerator {
  _Identifiers(this.next);
  int next;

  @override
  String nextIdentifier() => _id(next++);
}

String _id(int value) =>
    '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';

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
