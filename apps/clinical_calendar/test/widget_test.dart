import 'dart:async';
import 'dart:io';

import 'package:clinical_calendar/main.dart' as app;
import 'package:clinical_calendar/config/app_environment.dart';
import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:clinical_calendar_platform/clinical_calendar_platform.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:clinical_calendar_sync/clinical_calendar_sync.dart';
import 'package:flutter/material.dart';
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
    'production local removal closes SQLCipher before deleting exact files',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'clinical-calendar-local-removal-',
      );
      final databasePath =
          '${directory.path}${Platform.pathSeparator}clinical_calendar.sqlite3';
      final storage = _MemorySecureStorage();
      LocalDeviceCopyController? localCopy;
      try {
        await storage.write(
          PasswordlessIdentityService.sessionStorageKey,
          'session',
        );
        await storage.write(
          PasswordlessIdentityService.deviceIdStorageKey,
          _deviceId,
        );
        await app.buildProductionApplication(
          secureStorage: storage,
          identifiers: const _Identifiers(_identityStudentId),
          repositoryBootstrap: (owner, secureStorage, identifiers) async {
            final database = await ClinicalCalendarDatabase.open(
              path: databasePath,
              secureStorage: secureStorage,
            );
            final registry = SqliteRepositoryRegistry(
              studentId: owner,
              database: database,
              identifierGenerator: identifiers,
            );
            await registry.initialize();
            return registry;
          },
          onLocalCopyControllerReady: (value) => localCopy = value,
        );
        await File(
          '${directory.path}${Platform.pathSeparator}keep.txt',
        ).writeAsString('keep');

        expect((await localCopy!.previewRemoval()).pendingChangeCount, 0);
        await localCopy!.removeLocalCopy();

        expect(await File(databasePath).exists(), isFalse);
        expect(await File('$databasePath-wal').exists(), isFalse);
        expect(await File('$databasePath-shm').exists(), isFalse);
        expect(
          await File(
            '${directory.path}${Platform.pathSeparator}keep.txt',
          ).readAsString(),
          'keep',
        );
        expect(
          storage.values,
          isNot(contains(ClinicalCalendarDatabase.encryptionKeyStorageKey)),
        );
        expect(storage.values, isNot(contains(StableStudentOwner.storageKey)));
        expect(
          storage.values,
          isNot(contains(PasswordlessIdentityService.sessionStorageKey)),
        );
        expect(
          storage.values,
          isNot(contains(PasswordlessIdentityService.deviceIdStorageKey)),
        );
      } finally {
        if (await directory.exists()) await directory.delete(recursive: true);
      }
    },
  );

  test('production account backup encrypts before native save', () async {
    final directory = await Directory.systemTemp.createTemp(
      'clinical-calendar-account-backup-',
    );
    final databasePath =
        '${directory.path}${Platform.pathSeparator}clinical_calendar.sqlite3';
    final storage = _MemorySecureStorage();
    final saver = _NativeSaver();
    SqliteRepositoryRegistry? registry;
    try {
      final root = await app.buildProductionApplication(
        secureStorage: storage,
        identifiers: const _Identifiers(_identityStudentId),
        accountBackupFileSaver: saver,
        repositoryBootstrap: (owner, secureStorage, identifiers) async {
          final database = await ClinicalCalendarDatabase.open(
            path: databasePath,
            secureStorage: secureStorage,
          );
          registry = SqliteRepositoryRegistry(
            studentId: owner,
            database: database,
            identifierGenerator: identifiers,
          );
          await registry!.initialize();
          return registry!;
        },
      );

      expect(root.createAccountBackup, isNotNull);
      expect(
        await root.createAccountBackup!('correct horse battery staple'),
        isTrue,
      );
      expect(saver.request, isNotNull);
      expect(saver.request!.suggestedFileName, endsWith('.ccbackup'));
      expect(saver.request!.mimeType, 'application/octet-stream');
      expect(saver.request!.bytes, isNotEmpty);
      expect(
        String.fromCharCodes(saver.request!.bytes),
        isNot(contains(_identityStudentId)),
      );
    } finally {
      await registry?.close();
      if (await directory.exists()) await directory.delete(recursive: true);
    }
  });

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
      // Native reminder reconciliation still runs on launch while durable
      // synchronization remains offline.
      expect(root.onLaunchOrResume, isNotNull);
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

  testWidgets('configured first launch requires passwordless email OTP', (
    tester,
  ) async {
    final storage = _MemorySecureStorage();
    final gateway = _IdentityGateway();
    final root = await app.buildProductionRoot(
      secureStorage: storage,
      identifiers: const _Identifiers(_deviceId),
      clock: _FixedClock(),
      environment: const AppEnvironment(
        name: 'test',
        supabaseUrl: 'https://project.supabase.co',
        supabasePublishableKey: 'public-client-key',
      ),
      identityGateway: gateway,
      connectivitySource: _ConnectivitySource(initial: false),
      repositoryBootstrap: (_, _, _) async => _Repositories(),
      currentDevice: DeviceDescriptor(
        name: 'Test device',
        platform: DevicePlatform.windows,
      ),
    );
    await tester.pumpWidget(root);

    expect(
      find.textContaining('No password or Google account'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('identity-email')),
      'student@example.com',
    );
    await tester.tap(find.byKey(const Key('send-identity-code')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('identity-otp')), '123456');
    await tester.tap(find.byKey(const Key('verify-identity-code')));
    for (var attempt = 0; attempt < 50; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(ClinicalCalendarApp).evaluate().isNotEmpty) break;
    }

    expect(find.byKey(const Key('identity-email')), findsNothing);
    expect(find.text('Clinical Calendar could not start.'), findsNothing);
    final application = tester.widget<ClinicalCalendarApp>(
      find.byType(ClinicalCalendarApp),
    );
    expect(application.identity, isNotNull);
    expect(application.identityEmail, 'student@example.com');
    expect(application.onLocalCopyRemoved, isNotNull);
    expect(storage.values[StableStudentOwner.storageKey], _identityStudentId);
    expect(
      storage.values,
      contains(PasswordlessIdentityService.sessionStorageKey),
    );
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

final class _FixedClock implements Clock {
  @override
  DateTime nowUtc() => DateTime.utc(2026, 8, 3, 12);
}

final class _NativeSaver implements NativeByteFileSaver {
  NativeFileSaveRequest? request;

  @override
  Future<NativeFileSaveOutcome> save(NativeFileSaveRequest request) async {
    this.request = request;
    return NativeFileSaveOutcome.saved;
  }
}

final class _IdentityGateway implements PasswordlessIdentityGateway {
  @override
  Future<void> sendSignInCode(String email) async {}

  @override
  Future<IdentitySession> verifySignInCode(String email, String code) async =>
      IdentitySession(
        accessToken: 'access',
        refreshToken: 'refresh',
        studentId: _identityStudentId,
        sessionId: _identitySessionId,
        email: email,
        expiresAtUtc: DateTime.utc(2026, 8, 3, 13),
      );

  @override
  Future<IdentitySession> refreshSession(String refreshToken) async =>
      throw const IdentityException('network_unavailable', offline: true);

  @override
  Future<bool> registerCurrentDevice({
    required String accessToken,
    required String deviceId,
    required DeviceDescriptor descriptor,
  }) async => true;

  @override
  Future<List<ConnectedDevice>> listConnectedDevices(
    String accessToken,
  ) async => const [];

  @override
  Future<String> revokeConnectedDevice(
    String accessToken,
    String deviceId,
  ) async => 'revoked';

  @override
  Future<void> requestEmailChange(String accessToken, String newEmail) async {}

  @override
  Future<void> signOutCurrentSession(String accessToken) async {}

  @override
  Future<bool> markCurrentDeviceSynchronized(String accessToken) async => true;

  @override
  Future<AccountErasureRequest> requestAccountErasure(
    String accessToken,
    AccountErasureBackupChoice backupChoice,
  ) async => throw const IdentityException('not_configured');

  @override
  Future<AccountErasureCancellationStatus> cancelPendingAccountErasure(
    String accessToken,
  ) async => throw const IdentityException('not_configured');
}

const _identityStudentId = '10000000-0000-4000-8000-000000000001';
const _identitySessionId = '20000000-0000-4000-8000-000000000001';
const _deviceId = '30000000-0000-4000-8000-000000000001';
