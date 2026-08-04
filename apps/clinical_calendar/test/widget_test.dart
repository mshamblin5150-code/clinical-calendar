import 'dart:async';

import 'package:clinical_calendar/main.dart' as app;
import 'package:clinical_calendar/config/app_environment.dart';
import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_platform/clinical_calendar_platform.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:clinical_calendar_sync/clinical_calendar_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'production composition uses one secure Student owner everywhere',
    () async {
      const studentId = '00000000-0000-4000-8000-000000000021';
      final storage = _MemorySecureStorage();
      final identifiers = _Identifiers(studentId);
      final repositories = _Repositories();
      String? repositoryStudentId;
      SecureStorage? repositoryStorage;

      final root = await app.buildProductionApplication(
        secureStorage: storage,
        identifiers: identifiers,
        repositoryBootstrap: (owner, secureStorage, generator) async {
          repositoryStudentId = owner;
          repositoryStorage = secureStorage;
          expect(generator, same(identifiers));
          return repositories;
        },
      );

      expect(root, isA<ClinicalCalendarApp>());
      expect(root.studentId, studentId);
      expect(root.dependencies.repositories, same(repositories));
      expect(
        root.dependencies.synchronization,
        isA<OfflineSynchronizationService>(),
      );
      expect(root.dependencies.secureStorage, same(storage));
      expect(root.dependencies.files, isA<DartIoFileService>());
      expect(repositoryStudentId, studentId);
      expect(repositoryStorage, same(storage));
      expect(storage.values[StableStudentOwner.storageKey], studentId);
    },
  );

  test(
    'configured authenticated composition decorates only application writes',
    () async {
      const studentId = '00000000-0000-4000-8000-000000000021';
      final repositories = _Repositories();
      final connectivity = _ConnectivitySource(initial: false);

      final root = await app.buildProductionApplication(
        secureStorage: _MemorySecureStorage(),
        identifiers: const _Identifiers(studentId),
        repositoryBootstrap: (_, _, _) async => repositories,
        environment: const AppEnvironment(
          name: 'test',
          supabaseUrl: 'https://project.supabase.co',
          supabasePublishableKey: 'public-client-key',
        ),
        accessTokenProvider: () async => 'current-access-token',
        synchronizationTransport: _Transport(),
        retryScheduler: _RetryScheduler(),
        connectivitySource: connectivity,
        onSynchronizationFailure: (_, _) {},
      );

      expect(
        root.dependencies.synchronization,
        isA<DurableSynchronizationService>(),
      );
      final decorated =
          root.dependencies.repositories
              as SynchronizationTriggeringRepositoryRegistry;
      expect(decorated.base, same(repositories));
      expect(root.onLaunchOrResume, isNotNull);
      expect(root.onConnectivityChanged, isNotNull);
      expect(root.onRealtimeHint, isNotNull);
      expect(root.connectivityChanges, isNotNull);
      expect(connectivity.currentCalls, 1);
    },
  );

  test(
    'missing or failed session stays offline without starting connectivity',
    () async {
      const studentId = '00000000-0000-4000-8000-000000000021';
      final connectivity = _ConnectivitySource(initial: true);
      final root = await app.buildProductionApplication(
        secureStorage: _MemorySecureStorage(),
        identifiers: const _Identifiers(studentId),
        repositoryBootstrap: (_, _, _) async => _Repositories(),
        environment: const AppEnvironment(
          name: 'test',
          supabaseUrl: 'https://project.supabase.co',
          supabasePublishableKey: 'public-client-key',
        ),
        accessTokenProvider: () async =>
            throw StateError('session unavailable'),
        connectivitySource: connectivity,
      );

      expect(
        root.dependencies.synchronization,
        isA<OfflineSynchronizationService>(),
      );
      expect(root.dependencies.repositories, isA<_Repositories>());
      expect(root.onLaunchOrResume, isNull);
      expect(root.connectivityChanges, isNull);
      expect(connectivity.currentCalls, 0);
    },
  );

  test(
    'AppEnvironment accepts only complete public synchronization config',
    () {
      const valid = AppEnvironment(
        name: 'production',
        supabaseUrl: 'https://project.supabase.co',
        supabasePublishableKey: 'public-client-key',
      );
      const missingKey = AppEnvironment(
        name: 'production',
        supabaseUrl: 'https://project.supabase.co',
      );
      const invalidUri = AppEnvironment(
        name: 'production',
        supabaseUrl: 'not a URI',
        supabasePublishableKey: 'public-client-key',
      );

      expect(valid.hasSynchronizationConfiguration, isTrue);
      expect(valid.synchronizationProjectUri?.host, 'project.supabase.co');
      expect(missingKey.hasSynchronizationConfiguration, isFalse);
      expect(invalidUri.hasSynchronizationConfiguration, isFalse);
    },
  );

  testWidgets('startup failure is sanitized and leaves recovery guidance', (
    tester,
  ) async {
    await app.runClinicalCalendar(
      () async => throw StateError('sensitive adapter detail'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Clinical Calendar could not start.'), findsOneWidget);
    expect(
      find.textContaining('local data was left unchanged'),
      findsOneWidget,
    );
    expect(find.textContaining('sensitive adapter detail'), findsNothing);
  });
}

final class _MemorySecureStorage implements SecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

final class _Identifiers implements IdentifierGenerator {
  const _Identifiers(this.value);

  final String value;

  @override
  String nextIdentifier() => value;
}

final class _Repositories implements RepositoryRegistry {
  @override
  Future<void> initialize() async {}

  @override
  Future<R> mutate<R>(
    R Function(LocalWriteRepositories repositories) callback,
  ) async => throw UnimplementedError();

  @override
  Future<R> read<R>(
    R Function(LocalReadRepositories repositories) callback,
  ) async => throw UnimplementedError();
}

final class _ConnectivitySource implements app.ConnectivityStatusSource {
  _ConnectivitySource({required this.initial});

  final bool initial;
  final controller = StreamController<bool>.broadcast();
  int currentCalls = 0;

  @override
  Stream<bool> get changes => controller.stream;

  @override
  Future<bool> current() async {
    currentCalls++;
    return initial;
  }
}

final class _Transport implements SynchronizationTransport {
  @override
  Future<List<RemoteSynchronizationChange>> pull({
    required int afterCursor,
    required int limit,
  }) async => const [];

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
