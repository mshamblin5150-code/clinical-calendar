import 'dart:async';
import 'dart:convert';

import 'package:clinical_calendar/browser_runtime_contracts.dart';
import 'package:clinical_calendar/config/app_environment.dart';
import 'package:clinical_calendar/main_web.dart' as web;
import 'package:clinical_calendar/web_credential_storage.dart';
import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_identity_presentation.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:clinical_calendar_sync/clinical_calendar_sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  testWidgets('web opens to emailed-code sign-in with no local-copy option', (
    tester,
  ) async {
    await tester.pumpWidget(
      web.buildWebRoot(
        browserRuntime: _BrowserRuntime(),
        secureStorage: _MemorySecureStorage(),
        identifiers: _Identifiers(),
        clock: const _Clock(),
        environment: _environment,
        identityGateway: _IdentityGateway(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PasswordlessSignInSurface), findsOneWidget);
    expect(
      find.textContaining('No password or Google account'),
      findsOneWidget,
    );
    expect(find.textContaining('local copy'), findsNothing);
    final toggle = find.byKey(const Key('signed-out-enhanced-accessibility'));
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    await tester.tap(toggle);
    await tester.pump();
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
  });

  testWidgets('remembered web sign-in downloads without asking for a code', (
    tester,
  ) async {
    final browser = _BrowserRuntime();
    browser._store.values[PasswordlessIdentityService.sessionStorageKey] =
        jsonEncode({'refresh_token': 'refresh'});
    browser._store.values[PasswordlessIdentityService.deviceIdStorageKey] =
        _deviceId;
    final storage = WebCredentialStorage(browser.credentials);
    var buildChecks = 0;
    final coordinator = WebBuildVersionCoordinator(
      currentBuildNumber: web.currentSyncBuildNumber,
      deployedBuildNumber: () async {
        buildChecks++;
        return web.currentSyncBuildNumber;
      },
      hasUnsentChanges: () async => false,
      unsentChangesDrained: const Stream<void>.empty(),
      reload: () async {},
    );

    await tester.pumpWidget(
      web.buildWebRoot(
        browserRuntime: browser,
        secureStorage: storage,
        identifiers: _Identifiers(),
        clock: const _Clock(),
        environment: _environment,
        identityGateway: _IdentityGateway(),
        synchronizationTransport: _Transport(),
        connectivitySource: _Connectivity(),
        retryScheduler: _RetryScheduler(),
        buildVersionCoordinator: coordinator,
      ),
    );
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(ClinicalCalendarApp).evaluate().isNotEmpty) break;
    }

    expect(find.byType(ClinicalCalendarApp), findsOneWidget);
    expect(find.byType(PasswordlessSignInSurface), findsNothing);
    expect(buildChecks, 1);
    expect(
      browser._store.values.keys,
      unorderedEquals(WebCredentialStorage.allowedKeys),
    );
    expect(
      jsonDecode(
        browser._store.values[PasswordlessIdentityService.sessionStorageKey]!,
      ),
      {'refresh_token': 'refresh'},
    );
    await coordinator.dispose();
  });

  testWidgets('remembered web sign-in fails closed when download is offline', (
    tester,
  ) async {
    final browser = _BrowserRuntime();
    browser._store.values[PasswordlessIdentityService.sessionStorageKey] =
        jsonEncode({'refresh_token': 'refresh'});
    browser._store.values[PasswordlessIdentityService.deviceIdStorageKey] =
        _deviceId;

    await tester.pumpWidget(
      web.buildWebRoot(
        browserRuntime: browser,
        identifiers: _Identifiers(),
        clock: const _Clock(),
        environment: _environment,
        identityGateway: _IdentityGateway(),
        synchronizationTransport: _Transport(),
        connectivitySource: _Connectivity(connected: false),
        retryScheduler: _RetryScheduler(),
      ),
    );
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (find.byKey(const Key('web-startup-failure')).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.byKey(const Key('web-startup-failure')), findsOneWidget);
    expect(find.byType(ClinicalCalendarApp), findsNothing);
  });

  testWidgets(
    'offline commit warns immediately and pushes when connectivity returns',
    (tester) async {
      final storage = _MemorySecureStorage();
      final identifiers = _Identifiers();
      final clock = const _Clock();
      final browser = _BrowserRuntime();
      final gateway = _IdentityGateway();
      final identity = PasswordlessIdentityService(
        gateway: gateway,
        secureStorage: storage,
        identifiers: identifiers,
        clock: clock,
        currentDevice: DeviceDescriptor(
          name: 'Chrome on Windows',
          platform: DevicePlatform.web,
        ),
      );
      final session = await gateway.verifySignInCode(
        'student@example.com',
        '123456',
      );
      final connectivity = _Connectivity();
      final transport = _Transport();
      LocalDeviceCopyController? localCopy;
      final application = await web.buildWebApplication(
        session: session,
        identity: identity,
        secureStorage: storage,
        identifiers: identifiers,
        clock: clock,
        environment: _environment,
        browser: browser,
        synchronizationTransport: transport,
        retryScheduler: _RetryScheduler(),
        connectivitySource: connectivity,
        onLocalCopyControllerReady: (controller) => localCopy = controller,
      );
      await tester.pumpWidget(application);
      await tester.pump();
      transport.pushed.clear();

      await application.onConnectivityChanged!(false);
      await application.dependencies.repositories.mutate(
        (repositories) => repositories.preceptors.put(
          studentId: _studentId,
          value: Preceptor(id: _preceptorId, name: 'Offline Preceptor'),
          expectedRevision: 0,
          mutation: MutationToken(
            operationId: _operationId,
            idempotencyKey: _idempotencyKey,
            occurredAtUtc: clock.nowUtc(),
          ),
        ),
      );
      for (var attempt = 0; attempt < 20; attempt++) {
        await tester.pump(const Duration(milliseconds: 10));
        if (find.text('Not yet synced – 1 change').evaluate().isNotEmpty) {
          break;
        }
      }

      expect(find.text('Not yet synced – 1 change'), findsOneWidget);
      expect(browser.guard.states, contains(true));
      expect(transport.pushed, isEmpty);

      await application.onConnectivityChanged!(true);
      for (var attempt = 0; attempt < 50; attempt++) {
        await tester.pump(const Duration(milliseconds: 20));
        if (transport.pushed.any(
          (operation) => operation.entityId == _preceptorId,
        )) {
          break;
        }
      }
      await tester.pump();

      expect(
        transport.pushed.any((operation) => operation.entityId == _preceptorId),
        isTrue,
      );
      expect(find.byKey(const Key('not-yet-synced-banner')), findsNothing);
      expect(browser.guard.states.last, isFalse);

      Object? removalError;
      var removalComplete = false;
      unawaited(
        localCopy!.removeLocalCopy().then(
          (_) => removalComplete = true,
          onError: (Object error) => removalError = error,
        ),
      );
      for (var attempt = 0; attempt < 20 && !removalComplete; attempt++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(removalError, isNull);
      expect(removalComplete, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await connectivity.controller.close();
    },
  );

  testWidgets('initial web sync downloads another Connected Device data', (
    tester,
  ) async {
    final identifiers = _Identifiers();
    final clock = const _Clock();
    final gateway = _IdentityGateway();
    final storage = _MemorySecureStorage();
    final identity = PasswordlessIdentityService(
      gateway: gateway,
      secureStorage: storage,
      identifiers: identifiers,
      clock: clock,
      currentDevice: DeviceDescriptor(
        name: 'Safari on iPhone',
        platform: DevicePlatform.web,
      ),
    );
    final session = await gateway.verifySignInCode(
      'student@example.com',
      '123456',
    );
    final transport = _Transport()
      ..remote.add(
        RemoteSynchronizationChange(
          cursor: 1,
          entityType: 'preceptor',
          entityId: _preceptorId,
          revision: 1,
          operationType: OutboxOperationType.upsert,
          payloadJson: jsonEncode({
            'schema_version': 1,
            'entity_type': 'preceptor',
            'entity_id': _preceptorId,
            'student_id': _studentId,
            'revision': 1,
            'created_at_utc': clock.nowUtc().toIso8601String(),
            'updated_at_utc': clock.nowUtc().toIso8601String(),
            'deleted_at_utc': null,
            'value': {
              'name': 'Synced Preceptor',
              'organization_or_site': null,
              'phone': null,
              'email': null,
              'scheduling_notes': null,
            },
          }),
        ),
      );

    final application = await web.buildWebApplication(
      session: session,
      identity: identity,
      secureStorage: storage,
      identifiers: identifiers,
      clock: clock,
      environment: _environment,
      browser: _BrowserRuntime(),
      synchronizationTransport: transport,
      retryScheduler: _RetryScheduler(),
      connectivitySource: _Connectivity(),
    );

    expect(application.workScheduleTimeZone, TimeZoneId('America/New_York'));
    final preceptors = await application.dependencies.repositories.read(
      (repositories) => repositories.preceptors.list(studentId: _studentId),
    );
    expect(preceptors.single.value.name, 'Synced Preceptor');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

const _environment = AppEnvironment(
  name: 'test',
  supabaseUrl: 'https://project.supabase.co',
  supabasePublishableKey: 'public-key',
);
const _studentId = '10000000-0000-4000-8000-000000000001';
const _sessionId = '20000000-0000-4000-8000-000000000001';
const _deviceId = '30000000-0000-4000-8000-000000000001';
const _preceptorId = '40000000-0000-4000-8000-000000000001';
const _operationId = '50000000-0000-4000-8000-000000000001';
const _idempotencyKey = '60000000-0000-4000-8000-000000000001';

final class _BrowserRuntime implements BrowserRuntime {
  final _store = _BrowserStore();
  final guard = _Guard();

  @override
  BrowserKeyValueStore get credentials => _store;

  @override
  UnsentChangesGuard createUnsentChangesGuard() => guard;

  @override
  String get deviceName => 'Chrome on Windows';

  @override
  String get timeZoneName => 'America/New_York';

  @override
  Future<CommonDatabase> openInMemorySqlite() async => sqlite3.openInMemory();
}

final class _BrowserStore implements BrowserKeyValueStore {
  final values = <String, String>{};

  @override
  void delete(String key) => values.remove(key);

  @override
  String? read(String key) => values[key];

  @override
  void write(String key, String value) => values[key] = value;
}

final class _Guard implements UnsentChangesGuard {
  final states = <bool>[];

  @override
  Future<void> dispose() async {}

  @override
  void update(bool hasUnsentChanges) => states.add(hasUnsentChanges);
}

final class _MemorySecureStorage implements SecureStorage {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

final class _Identifiers implements IdentifierGenerator {
  int _next = 10;

  @override
  String nextIdentifier() =>
      '00000000-0000-4000-8000-${(_next++).toString().padLeft(12, '0')}';
}

final class _Clock implements Clock {
  const _Clock();

  @override
  DateTime nowUtc() => DateTime.utc(2026, 9, 27, 13);
}

final class _IdentityGateway implements PasswordlessIdentityGateway {
  @override
  Future<AccountErasureCancellationStatus> cancelPendingAccountErasure(
    String accessToken,
  ) async => AccountErasureCancellationStatus.notPending;

  @override
  Future<List<ConnectedDevice>> listConnectedDevices(
    String accessToken,
  ) async => const [];

  @override
  Future<bool> markCurrentDeviceSynchronized(String accessToken) async => true;

  @override
  Future<IdentitySession> refreshSession(String refreshToken) async => _session;

  @override
  Future<bool> registerCurrentDevice({
    required String accessToken,
    required String deviceId,
    required DeviceDescriptor descriptor,
  }) async => true;

  @override
  Future<AccountErasureRequest> requestAccountErasure(
    String accessToken,
    AccountErasureBackupChoice backupChoice,
  ) async => throw StateError('not expected');

  @override
  Future<void> requestEmailChange(String accessToken, String newEmail) async {}

  @override
  Future<String> revokeConnectedDevice(
    String accessToken,
    String deviceId,
  ) async => 'revoked';

  @override
  Future<void> sendSignInCode(String email) async {}

  @override
  Future<void> signOutCurrentSession(String accessToken) async {}

  @override
  Future<IdentitySession> verifySignInCode(String email, String code) async =>
      IdentitySession(
        accessToken: 'access',
        refreshToken: 'refresh',
        studentId: _studentId,
        sessionId: _sessionId,
        email: email,
        expiresAtUtc: DateTime.utc(2026, 9, 27, 14),
      );
}

final class _Transport implements SynchronizationTransport {
  int _cursor = 0;
  final pushed = <OutboxOperation>[];
  final remote = <RemoteSynchronizationChange>[];

  @override
  Future<List<RemoteSynchronizationChange>> pull({
    required int afterCursor,
    required int limit,
  }) async => remote
      .where((change) => change.cursor > afterCursor)
      .take(limit)
      .toList(growable: false);

  @override
  Future<SynchronizationPushResult> push(OutboxOperation operation) async {
    pushed.add(operation);
    for (final change in remote) {
      if (change.cursor > _cursor) _cursor = change.cursor;
    }
    return SynchronizationPushResult.accepted(
      cursor: ++_cursor,
      revision: operation.baseRevision + 1,
    );
  }
}

final class _RetryScheduler implements SynchronizationRetryScheduler {
  @override
  void cancel() {}

  @override
  void schedule(DateTime atUtc, Future<void> Function() callback) {}
}

final class _Connectivity implements web.WebConnectivityStatusSource {
  _Connectivity({this.connected = true});

  final bool connected;
  final controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> get changes => controller.stream;

  @override
  Future<bool> current() async => connected;
}

final _session = IdentitySession(
  accessToken: 'access',
  refreshToken: 'refresh',
  studentId: _studentId,
  sessionId: _sessionId,
  email: 'student@example.com',
  expiresAtUtc: DateTime.utc(2026, 9, 27, 14),
);
