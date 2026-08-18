import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clinical_calendar/main.dart' as app;
import 'package:clinical_calendar/config/app_environment.dart';
import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:clinical_calendar_platform/clinical_calendar_platform.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_identity_presentation.dart';
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
    'production backup picker previews and safely reapplies encrypted data',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'clinical-calendar-portable-restore-',
      );
      final databasePath =
          '${directory.path}${Platform.pathSeparator}clinical_calendar.sqlite3';
      final storage = _MemorySecureStorage();
      final saver = _NativeSaver();
      final picker = _BackupPicker();
      SqliteRepositoryRegistry? registry;
      try {
        final root = await app.buildProductionApplication(
          secureStorage: storage,
          identifiers: const _Identifiers(_identityStudentId),
          accountBackupFileSaver: saver,
          portableBackupFilePicker: picker,
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
        final workflows = root.portableBackupWorkflows!;
        expect(await workflows.create('correct horse battery staple'), isTrue);
        picker.bytes = saver.request!.bytes;

        final preview = await workflows.choose('correct horse battery staple');
        expect(preview, isNotNull);
        expect(preview!.localRecordsKept, greaterThan(0));
        expect(preview.conflicts, isEmpty);
        await workflows.apply(const {});
        expect(picker.calls, 1);

        await expectLater(
          workflows.choose('wrong passphrase'),
          throwsA(isA<PortableBackupException>()),
        );
      } finally {
        await registry?.close();
        if (await directory.exists()) await directory.delete(recursive: true);
      }
    },
  );

  test(
    'configured authenticated composition preserves Clinical Placement Trash workflow',
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

      final placements = PlacementApplicationService(
        repositories: root.dependencies.repositories,
        clock: _FixedClock(),
        identifiers: const _Identifiers(studentId),
        studentId: studentId,
      );
      final preview = await placements.previewDeletion(
        clinicalPlacementId: studentId,
      );
      expect(preview.clinicalPlacementName, 'Family Medicine');
      await placements.moveToTrash(preview: preview);
      await decorated.waitForSynchronizationIdle();
      expect(repositories.deletionPreviewCalls, 1);
      expect(repositories.deletionMoveCalls, 1);
    },
  );

  test(
    'configured authenticated Sync Now flushes a deferred queue before Clinical Placement Trash',
    () async {
      const studentId = '00000000-0000-4000-8000-000000000021';
      final directory = await Directory.systemTemp.createTemp(
        'clinical-calendar-authenticated-sync-',
      );
      final databasePath =
          '${directory.path}${Platform.pathSeparator}clinical_calendar.sqlite3';
      final storage = _MemorySecureStorage();
      final identifiers = _SequentialIdentifiers(100);
      final connectivity = _ConnectivitySource(initial: true);
      final transport = _RecoveringTransport();
      SqliteRepositoryRegistry? registry;
      DurableSynchronizationService? synchronization;
      try {
        final root = await app.buildProductionApplication(
          secureStorage: storage,
          identifiers: identifiers,
          authenticatedStudentId: studentId,
          repositoryBootstrap: (owner, secureStorage, generator) async {
            final database = await ClinicalCalendarDatabase.open(
              path: databasePath,
              secureStorage: secureStorage,
            );
            registry = SqliteRepositoryRegistry(
              studentId: owner,
              database: database,
              identifierGenerator: generator,
            );
            await registry!.initialize();
            final placements = PlacementApplicationService(
              repositories: registry!,
              clock: _FixedClock(),
              identifiers: generator,
              studentId: owner,
            );
            final preceptor = await placements.createPreceptor(
              name: 'Dr. Rivera',
            );
            final placement = await placements.createPlacement(
              CreatePlacementRequest(
                name: 'Internal Medicine',
                targetHours: TargetHours.fromWholeHours(90),
                startDate: LocalDate(2026, 8, 1),
                completionDeadline: LocalDate(2026, 12, 31),
                primaryPreceptorId: preceptor.id,
                evaluationPlanConfiguration: EvaluationPlanConfiguration(
                  initialSelfAssessmentRequired: false,
                  interimReviewCadenceMinutes: 6000,
                  finalSelfAssessmentRequired: false,
                  finalPlacementReviewRequired: false,
                ),
              ),
            );
            final session = ClinicalSession.schedule(
              id: generator.nextIdentifier(),
              clinicalPlacementId: placement.placement.id,
              preceptorId: preceptor.id,
              plannedInterval: ZonedInterval(
                startDate: LocalDate(2026, 8, 4),
                startTime: LocalTime(9, 0),
                endTime: LocalTime(12, 0),
                timeZone: TimeZoneId('America/New_York'),
                startOffset: UtcOffset.inMinutes(-4 * 60),
                endOffset: UtcOffset.inMinutes(-4 * 60),
              ),
              asOfUtc: _FixedClock().nowUtc(),
            );
            await registry!.mutate(
              (repositories) => repositories.clinicalSessions.put(
                studentId: owner,
                value: session,
                expectedRevision: 0,
                mutation: MutationToken(
                  operationId: generator.nextIdentifier(),
                  idempotencyKey: generator.nextIdentifier(),
                  occurredAtUtc: _FixedClock().nowUtc(),
                ),
              ),
            );
            return registry!;
          },
          environment: const AppEnvironment(
            name: 'test',
            supabaseUrl: 'https://project.supabase.co',
            supabasePublishableKey: 'public-client-key',
          ),
          accessTokenProvider: () async => 'current-access-token',
          synchronizationTransport: transport,
          retryScheduler: _RetryScheduler(),
          connectivitySource: connectivity,
          onSynchronizationFailure: (_, _) {},
          clock: _FixedClock(),
        );
        synchronization =
            root.dependencies.synchronization as DurableSynchronizationService;

        expect(
          (await synchronization.syncNow()).disposition,
          SynchronizationDisposition.deferred,
        );
        expect((await synchronization.health()).pendingCount, greaterThan(0));

        expect(
          (await synchronization.syncNow()).disposition,
          SynchronizationDisposition.synchronized,
        );
        expect((await synchronization.health()).pendingCount, 0);

        final placements = PlacementApplicationService(
          repositories: root.dependencies.repositories,
          clock: _FixedClock(),
          identifiers: identifiers,
          studentId: studentId,
        );
        final placement = (await placements.placements()).single;
        final preview = await placements.previewDeletion(
          clinicalPlacementId: placement.placement.id,
        );
        expect(preview.hasUnresolvedSynchronizationConflicts, isFalse);
        expect(preview.clinicalSessionCount, 1);
        expect(preview.evaluationRequirementCount, 0);
        expect(preview.attachedPreceptorRelationshipCount, 1);
        expect(preview.clearsActivePlacementSelection, isTrue);

        // Cancelling the impact preview performs no mutation.
        expect(await placements.placements(), hasLength(1));
        expect(
          await registry!.listTrash(nowUtc: _FixedClock().nowUtc()),
          isEmpty,
        );

        await placements.moveToTrash(preview: preview);
        final decorated =
            root.dependencies.repositories
                as SynchronizationTriggeringRepositoryRegistry;
        await decorated.waitForSynchronizationIdle();

        expect(await placements.placements(), isEmpty);
        final trash = await registry!.listTrash(nowUtc: _FixedClock().nowUtc());
        expect(trash, hasLength(1));
        expect(trash.single.displayName, 'Internal Medicine');
        expect(trash.single.entityType, 'clinical_placement_aggregate');
        expect(trash.single.dependentRecordCount, 2);
        expect(trash.single.isExpiredAt(_FixedClock().nowUtc()), isFalse);

        final restoredAt = _FixedClock().nowUtc().add(
          const Duration(minutes: 1),
        );
        await registry!.restoreTrash(
          trashId: trash.single.id,
          restoredAtUtc: restoredAt,
          mutation: MutationToken(
            operationId: identifiers.nextIdentifier(),
            idempotencyKey: identifiers.nextIdentifier(),
            occurredAtUtc: restoredAt,
          ),
        );
        expect(await placements.placements(), hasLength(1));
        expect(await registry!.listTrash(nowUtc: restoredAt), isEmpty);
      } finally {
        await synchronization?.shutdown();
        await registry?.close();
        await connectivity.controller.close();
        if (await directory.exists()) await directory.delete(recursive: true);
      }
    },
  );

  test(
    'configured authenticated conflict choice decrements durable attention',
    () async {
      const studentId = '00000000-0000-4000-8000-000000000021';
      const preceptorId = '00000000-0000-4000-8000-000000000022';
      final directory = await Directory.systemTemp.createTemp(
        'clinical-calendar-authenticated-conflict-resolution-',
      );
      final databasePath =
          '${directory.path}${Platform.pathSeparator}clinical_calendar.sqlite3';
      final identifiers = _SequentialIdentifiers(400);
      final connectivity = _ConnectivitySource(initial: true);
      final transport = _RevisionedTransport();
      SqliteRepositoryRegistry? registry;
      DurableSynchronizationService? synchronization;
      Future<void> putLocal(String name) async {
        final current = await registry!.read(
          (repositories) => repositories.preceptors.find(
            studentId: studentId,
            id: preceptorId,
          ),
        );
        await registry!.mutate(
          (repositories) => repositories.preceptors.put(
            studentId: studentId,
            value: Preceptor(id: preceptorId, name: name),
            expectedRevision: current?.revision ?? 0,
            mutation: MutationToken(
              operationId: identifiers.nextIdentifier(),
              idempotencyKey: identifiers.nextIdentifier(),
              occurredAtUtc: _FixedClock().nowUtc(),
            ),
          ),
        );
      }

      try {
        final root = await app.buildProductionApplication(
          secureStorage: _MemorySecureStorage(),
          identifiers: identifiers,
          authenticatedStudentId: studentId,
          repositoryBootstrap: (owner, secureStorage, generator) async {
            final database = await ClinicalCalendarDatabase.open(
              path: databasePath,
              secureStorage: secureStorage,
            );
            registry = SqliteRepositoryRegistry(
              studentId: owner,
              database: database,
              identifierGenerator: generator,
            );
            await registry!.initialize();
            return registry!;
          },
          environment: const AppEnvironment(
            name: 'test',
            supabaseUrl: 'https://project.supabase.co',
            supabasePublishableKey: 'public-client-key',
          ),
          accessTokenProvider: () async => 'current-access-token',
          synchronizationTransport: transport,
          retryScheduler: _RetryScheduler(),
          connectivitySource: connectivity,
          onSynchronizationFailure: (_, _) {},
          clock: _FixedClock(),
        );
        synchronization =
            root.dependencies.synchronization as DurableSynchronizationService;

        await putLocal('Shared');
        await synchronization.syncNow();
        await putLocal('Tablet first original');
        transport.putRemotePreceptor(
          studentId: studentId,
          preceptorId: preceptorId,
          name: 'Other device revision 2',
        );
        await synchronization.syncNow();
        await putLocal('Tablet second original');
        transport.putRemotePreceptor(
          studentId: studentId,
          preceptorId: preceptorId,
          name: 'Other device revision 3',
        );
        await synchronization.syncNow();
        transport.putRemotePreceptor(
          studentId: studentId,
          preceptorId: preceptorId,
          name: 'Other device revision 4',
        );
        await synchronization.syncNow();

        final conflicts = ConflictResolutionApplicationService(
          repositories: root.dependencies.repositories,
          clock: _FixedClock(),
          identifiers: identifiers,
          studentId: studentId,
          synchronization: synchronization,
        );
        final before = await conflicts.load();
        expect(before.items, hasLength(2));
        expect(
          before.items.first.local.values['name'],
          'Tablet first original',
        );

        await conflicts.resolve(
          conflictId: before.items.first.record.id,
          choice: SynchronizationConflictResolutionChoice.localVersion,
        );
        final after = await conflicts.load();

        expect(after.items, hasLength(1));
        expect((await synchronization.health()).unresolvedConflictCount, 1);
        expect(transport.currentName(preceptorId), 'Tablet first original');
      } finally {
        await synchronization?.shutdown();
        await registry?.close();
        await connectivity.controller.close();
        if (await directory.exists()) await directory.delete(recursive: true);
      }
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
      const cleartextProduction = AppEnvironment(
        name: 'production',
        supabaseUrl: 'http://project.supabase.co',
        supabasePublishableKey: 'public-client-key',
      );
      const cleartextRemoteTest = AppEnvironment(
        name: 'test',
        supabaseUrl: 'http://project.example.test',
        supabasePublishableKey: 'public-client-key',
      );
      const localEmulator = AppEnvironment(
        name: 'local',
        supabaseUrl: 'http://127.0.0.1:54321',
        supabasePublishableKey: 'public-client-key',
      );

      expect(valid.hasSynchronizationConfiguration, isTrue);
      expect(valid.synchronizationProjectUri?.host, 'project.supabase.co');
      expect(missingKey.hasSynchronizationConfiguration, isFalse);
      expect(invalidUri.hasSynchronizationConfiguration, isFalse);
      expect(cleartextProduction.hasSynchronizationConfiguration, isFalse);
      expect(cleartextRemoteTest.hasSynchronizationConfiguration, isFalse);
      expect(localEmulator.hasSynchronizationConfiguration, isTrue);
    },
  );

  test('Android release builds require private signing material', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
    expect(gradle, contains('signingConfigs.getByName("release")'));
    expect(gradle, contains('CLINICAL_CALENDAR_ANDROID_KEYSTORE_PATH'));
    expect(gradle, contains('releaseSigningConfigured'));
  });

  test('Windows release workflow requires signed versioned MSIX output', () {
    final workflow = File(
      '../../.github/workflows/windows-release.yml',
    ).readAsStringSync();
    final packager = File(
      '../../tool/windows/package_msix.ps1',
    ).readAsStringSync();
    final verifier = File(
      '../../tool/windows/verify_release_bundle.ps1',
    ).readAsStringSync();
    final manifest = File(
      '../../tool/windows/AppxManifest.template.xml',
    ).readAsStringSync();

    expect(workflow, contains('runner: windows-2025'));
    expect(workflow, contains('flutter: 3.44.8'));
    expect(workflow, contains('windows_sdk: 10.0.26100.0'));
    expect(workflow, contains(r'flutter-version: ${{ matrix.flutter }}'));
    expect(workflow, contains('WINDOWS_SIGNING_PFX_BASE64'));
    expect(workflow, contains('WINDOWS_SIGNING_PFX_PASSWORD'));
    expect(workflow, contains('WINDOWS_SIGNING_PUBLISHER'));
    expect(
      workflow,
      contains('CLINICAL_CALENDAR_ENVIRONMENT: private-release'),
    );
    expect(workflow, contains('vars.CLINICAL_CALENDAR_SUPABASE_URL'));
    expect(
      workflow,
      contains('secrets.CLINICAL_CALENDAR_SUPABASE_PUBLISHABLE_KEY'),
    );
    expect(workflow, contains('Import-PfxCertificate'));
    expect(workflow, contains('Remove ephemeral signing certificate'));
    expect(workflow, contains(r'Cert:\CurrentUser\TrustedPeople'));
    expect(workflow, contains('imported_thumbprints'));
    expect(workflow, contains('trust_thumbprint'));
    expect(workflow, isNot(contains('-AllowUnsigned')));
    expect(packager, contains("throw 'A CurrentUser signing certificate"));
    expect(packager, contains('Publisher must exactly match'));
    expect(packager, contains('signtool.exe'));
    expect(packager, contains('verify /pa /all /v'));
    expect(packager, contains('MSIX_SIGNER_CERTIFICATE'));
    expect(packager, contains('Get-ClinicalCalendarReleaseFlutterArguments'));
    expect(
      packager,
      contains(r'''$suffix = if ($certificate) { '' } else { '.unsigned' }'''),
    );
    expect(verifier, contains('makeappx.exe'));
    expect(verifier, contains('AppxManifest.xml'));
    expect(verifier, contains("GetAttribute('Name')"));
    expect(verifier, contains("GetAttribute('Publisher')"));
    expect(verifier, contains("GetAttribute('Version')"));
    expect(verifier, contains("GetAttribute('ProcessorArchitecture')"));
    expect(verifier, contains('*.msix.cer'));
    expect(manifest, contains('Name="ClinicalCalendar"'));
    expect(manifest, contains('Version="__VERSION__"'));
    expect(manifest, contains('uap10:PackageIntegrity'));
    expect(manifest, contains('rescap:Capability Name="runFullTrust"'));
    expect(manifest, contains('Assets\\AppIcon44.png'));
    expect(manifest, contains('Assets\\AppIcon150.png'));
  });

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
      authoritativePresentationSettingsLoader: (_, _, _, _) async =>
          (themeId: 'future-theme', enhancedAccessibility: false),
      graphiteAssetPreflight: () async {},
      currentDevice: DeviceDescriptor(
        name: 'Test device',
        platform: DevicePlatform.windows,
      ),
    );
    await tester.pumpWidget(root);

    expect(
      Theme.of(
        tester.element(find.byType(PasswordlessSignInSurface)),
      ).colorScheme.primary,
      GraphiteColors.primary,
    );
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
    final verify = find.byKey(const Key('verify-identity-code'));
    await tester.ensureVisible(verify);
    await tester.pump();
    await tester.tap(verify);
    for (var attempt = 0; attempt < 50; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(ClinicalCalendarApp).evaluate().isNotEmpty) break;
    }

    expect(find.byKey(const Key('identity-email')), findsNothing);
    expect(find.text('Clinical Calendar could not start.'), findsNothing);
    expect(
      find.byKey(const Key('graphite-presentation-unavailable')),
      findsNothing,
    );
    final application = tester.widget<ClinicalCalendarApp>(
      find.byType(ClinicalCalendarApp),
    );
    expect(application.identity, isNotNull);
    expect(application.identityEmail, 'student@example.com');
    expect(application.themeId, 'future-theme');
    expect(find.byType(GraphiteApplicationShell), findsOneWidget);
    expect(application.onLocalCopyRemoved, isNotNull);
    expect(storage.values[StableStudentOwner.storageKey], _identityStudentId);
    expect(
      storage.values,
      contains(PasswordlessIdentityService.sessionStorageKey),
    );
  });

  testWidgets(
    'signed-out Enhanced is device-local and account preference takes authority',
    (tester) async {
      final storage = _MemorySecureStorage();
      storage.values['clinical_calendar.device.enhanced_accessibility'] =
          'true';
      final root = await app.buildProductionRoot(
        secureStorage: storage,
        identifiers: const _Identifiers(_deviceId),
        clock: _FixedClock(),
        environment: const AppEnvironment(
          name: 'test',
          supabaseUrl: 'https://project.supabase.co',
          supabasePublishableKey: 'public-client-key',
        ),
        identityGateway: _IdentityGateway(),
        connectivitySource: _ConnectivitySource(initial: false),
        repositoryBootstrap: (_, _, _) async => _Repositories(),
        authoritativePresentationSettingsLoader: (_, _, _, _) async =>
            (themeId: variantFThemeId, enhancedAccessibility: true),
        graphiteAssetPreflight: () async {},
        currentDevice: DeviceDescriptor(
          name: 'Test device',
          platform: DevicePlatform.windows,
        ),
      );
      await tester.pumpWidget(root);
      await tester.pumpAndSettle();

      final signedOutToggle = find.byKey(
        const Key('signed-out-enhanced-accessibility'),
      );
      expect(tester.widget<SwitchListTile>(signedOutToggle).value, isTrue);
      expect(
        Theme.of(
          tester.element(signedOutToggle),
        ).extension<ClinicalCalendarAccessibilityTokens>()?.enhanced,
        isTrue,
      );

      await tester.tap(signedOutToggle);
      await tester.pumpAndSettle();
      expect(
        storage.values['clinical_calendar.device.enhanced_accessibility'],
        'false',
      );

      await _completePasswordlessSignIn(tester);
      for (var attempt = 0; attempt < 50; attempt++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(ClinicalCalendarApp).evaluate().isNotEmpty) break;
      }

      final application = tester.widget<ClinicalCalendarApp>(
        find.byType(ClinicalCalendarApp),
      );
      expect(application.enhancedAccessibility, isTrue);
      expect(
        storage.values['clinical_calendar.device.enhanced_accessibility'],
        'false',
      );
    },
  );

  testWidgets(
    'signed-out Enhanced serializes startup and rapid device writes',
    (tester) async {
      final storage = _DelayedDeviceSecureStorage();
      final root = await app.buildProductionRoot(
        secureStorage: storage,
        identifiers: const _Identifiers(_deviceId),
        clock: _FixedClock(),
        environment: const AppEnvironment(
          name: 'test',
          supabaseUrl: 'https://project.supabase.co',
          supabasePublishableKey: 'public-client-key',
        ),
        identityGateway: _IdentityGateway(),
        connectivitySource: _ConnectivitySource(initial: false),
        repositoryBootstrap: (_, _, _) async => _Repositories(),
        graphiteAssetPreflight: () async {},
        currentDevice: DeviceDescriptor(
          name: 'Test device',
          platform: DevicePlatform.windows,
        ),
      );
      await tester.pumpWidget(root);
      await tester.pump();
      final toggle = find.byKey(const Key('signed-out-enhanced-accessibility'));

      await tester.tap(toggle);
      await tester.pump();
      storage.deviceRead.complete('false');
      await tester.pump();
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

      await tester.tap(toggle);
      await tester.pump();
      expect(storage.deviceWrites, hasLength(1));
      storage.deviceWrites.first.completion.complete();
      await tester.pump();
      expect(storage.deviceWrites, hasLength(2));
      storage.deviceWrites.last.completion.complete();
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      expect(
        storage.values['clinical_calendar.device.enhanced_accessibility'],
        'false',
      );
    },
  );

  testWidgets('authenticated shell stays hidden when settings cannot load', (
    tester,
  ) async {
    final root = await app.buildProductionRoot(
      secureStorage: _MemorySecureStorage(),
      identifiers: const _Identifiers(_deviceId),
      clock: _FixedClock(),
      environment: const AppEnvironment(
        name: 'test',
        supabaseUrl: 'https://project.supabase.co',
        supabasePublishableKey: 'public-client-key',
      ),
      identityGateway: _IdentityGateway(),
      connectivitySource: _ConnectivitySource(initial: false),
      repositoryBootstrap: (_, _, _) async => _Repositories(),
      currentDevice: DeviceDescriptor(
        name: 'Test device',
        platform: DevicePlatform.windows,
      ),
    );
    await tester.pumpWidget(root);
    await _completePasswordlessSignIn(tester);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('authoritative-settings-unavailable')),
      findsOneWidget,
    );
    expect(find.byType(ClinicalCalendarApp), findsNothing);
    expect(find.text('Retry settings'), findsOneWidget);
    expect(find.textContaining(_identityStudentId), findsNothing);
  });

  testWidgets('Graphite decode failure reaches code-only recovery', (
    tester,
  ) async {
    final root = await app.buildProductionRoot(
      secureStorage: _MemorySecureStorage(),
      identifiers: const _Identifiers(_deviceId),
      clock: _FixedClock(),
      environment: const AppEnvironment(
        name: 'test',
        supabaseUrl: 'https://project.supabase.co',
        supabasePublishableKey: 'public-client-key',
      ),
      identityGateway: _IdentityGateway(),
      connectivitySource: _ConnectivitySource(initial: false),
      repositoryBootstrap: (_, _, _) async => _Repositories(),
      authoritativePresentationSettingsLoader: (_, _, _, _) async =>
          (themeId: 'future-theme', enhancedAccessibility: false),
      graphiteAssetPreflight: () async => throw StateError('bad PNG'),
      currentDevice: DeviceDescriptor(
        name: 'Test device',
        platform: DevicePlatform.windows,
      ),
    );
    await tester.pumpWidget(root);
    await _completePasswordlessSignIn(tester);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('graphite-presentation-unavailable')),
      findsOneWidget,
    );
    expect(find.byType(ClinicalCalendarApp), findsNothing);
    expect(find.text('Restart'), findsOneWidget);
    expect(find.textContaining('bad PNG'), findsNothing);
    expect(find.textContaining(_identityStudentId), findsNothing);
  });
}

Future<void> _completePasswordlessSignIn(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('identity-email')),
    'student@example.com',
  );
  await tester.tap(find.byKey(const Key('send-identity-code')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('identity-otp')), '123456');
  final verify = find.byKey(const Key('verify-identity-code'));
  await tester.ensureVisible(verify);
  await tester.pump();
  await tester.tap(verify);
  await tester.pump();
}

class _MemorySecureStorage implements SecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

final class _DelayedDeviceSecureStorage extends _MemorySecureStorage {
  final deviceRead = Completer<String?>();
  final deviceWrites = <({String value, Completer<void> completion})>[];

  @override
  Future<String?> read(String key) {
    if (key == 'clinical_calendar.device.enhanced_accessibility') {
      return deviceRead.future;
    }
    return super.read(key);
  }

  @override
  Future<void> write(String key, String value) async {
    if (key != 'clinical_calendar.device.enhanced_accessibility') {
      return super.write(key, value);
    }
    final completion = Completer<void>();
    deviceWrites.add((value: value, completion: completion));
    await completion.future;
    values[key] = value;
  }
}

final class _Identifiers implements IdentifierGenerator {
  const _Identifiers(this.value);

  final String value;

  @override
  String nextIdentifier() => value;
}

final class _SequentialIdentifiers implements IdentifierGenerator {
  _SequentialIdentifiers(this.next);

  int next;

  @override
  String nextIdentifier() =>
      '00000000-0000-4000-8000-${(next++).toString().padLeft(12, '0')}';
}

final class _Repositories
    implements RepositoryRegistry, ClinicalPlacementAggregateDeletionStore {
  int deletionPreviewCalls = 0;
  int deletionMoveCalls = 0;

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

  @override
  Future<ClinicalPlacementDeletionPreview> previewClinicalPlacementDeletion({
    required String clinicalPlacementId,
    required int unsavedSchedulingDraftCount,
  }) async {
    deletionPreviewCalls++;
    return ClinicalPlacementDeletionPreview(
      clinicalPlacementId: clinicalPlacementId,
      clinicalPlacementName: 'Family Medicine',
      clinicalPlacementState: ClinicalPlacementState.active,
      memberRevisions: const {},
      scheduledClinicalSessionCount: 0,
      awaitingConfirmationClinicalSessionCount: 0,
      completedClinicalSessionCount: 0,
      cancelledClinicalSessionCount: 0,
      missedClinicalSessionCount: 0,
      clinicalSessionCompletedMinutes: 0,
      historicalHoursEntryCount: 0,
      historicalCompletedMinutes: 0,
      evaluationRequirementCount: 0,
      documentedEvaluationRequirementCount: 0,
      scheduleTemplateCount: 0,
      reminderStateCount: 0,
      attachedPreceptorRelationshipCount: 1,
      unsavedSchedulingDraftCount: unsavedSchedulingDraftCount,
      clearsActivePlacementSelection: true,
      hasUnresolvedSynchronizationConflicts: false,
    );
  }

  @override
  Future<void> moveClinicalPlacementAggregateToTrash({
    required ClinicalPlacementDeletionPreview preview,
    required String aggregateMutationId,
    required DateTime deletedAtUtc,
  }) async {
    deletionMoveCalls++;
  }
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

final class _RecoveringTransport implements SynchronizationTransport {
  bool failNextPush = true;
  int cursor = 0;
  final changes = <RemoteSynchronizationChange>[];
  Map<String, dynamic>? placementPayload;

  @override
  Future<List<RemoteSynchronizationChange>> pull({
    required int afterCursor,
    required int limit,
  }) async => changes
      .where((change) => change.cursor > afterCursor)
      .take(limit)
      .toList();

  @override
  Future<SynchronizationPushResult> push(OutboxOperation operation) async {
    if (failNextPush) {
      failNextPush = false;
      throw const SynchronizationTransportException(
        'server_unavailable',
        offline: false,
      );
    }
    final acceptedCursor = ++cursor;
    changes.add(
      RemoteSynchronizationChange(
        cursor: acceptedCursor,
        entityType: operation.entityType,
        entityId: operation.entityId,
        revision: operation.baseRevision + 1,
        operationType: operation.type,
        payloadJson: operation.payloadJson,
      ),
    );
    if (operation.entityType == 'clinical_placement') {
      placementPayload = jsonDecode(operation.payloadJson);
    } else if (operation.entityType == 'clinical_session' &&
        placementPayload != null) {
      final revisedPlacement = Map<String, dynamic>.from(placementPayload!)
        ..['revision'] = 2
        ..['updated_at_utc'] = '2026-08-03T12:01:00.000Z';
      changes.add(
        RemoteSynchronizationChange(
          cursor: ++cursor,
          entityType: 'clinical_placement',
          entityId: revisedPlacement['entity_id'] as String,
          revision: 2,
          operationType: OutboxOperationType.upsert,
          payloadJson: jsonEncode(revisedPlacement),
        ),
      );
      placementPayload = null;
    }
    return SynchronizationPushResult.accepted(
      cursor: acceptedCursor,
      revision: operation.baseRevision + 1,
    );
  }
}

final class _RevisionedTransport implements SynchronizationTransport {
  final records = <String, Map<String, dynamic>>{};
  final changes = <RemoteSynchronizationChange>[];
  int cursor = 0;

  void putRemotePreceptor({
    required String studentId,
    required String preceptorId,
    required String name,
  }) {
    final key = 'preceptor/$preceptorId';
    final current = records[key];
    final revision = (current?['revision'] as int? ?? 0) + 1;
    final payload = <String, dynamic>{
      'schema_version': 1,
      'entity_type': 'preceptor',
      'entity_id': preceptorId,
      'student_id': studentId,
      'revision': revision,
      'created_at_utc':
          current?['created_at_utc'] ??
          _FixedClock().nowUtc().toIso8601String(),
      'updated_at_utc': _FixedClock().nowUtc().toIso8601String(),
      'deleted_at_utc': null,
      'value': {
        'name': name,
        'organization_or_site': null,
        'phone': null,
        'email': null,
        'scheduling_notes': null,
      },
    };
    records[key] = payload;
    changes.add(
      RemoteSynchronizationChange(
        cursor: ++cursor,
        entityType: 'preceptor',
        entityId: preceptorId,
        revision: revision,
        operationType: OutboxOperationType.upsert,
        payloadJson: jsonEncode(payload),
      ),
    );
  }

  String? currentName(String preceptorId) =>
      (records['preceptor/$preceptorId']?['value']
              as Map<String, dynamic>?)?['name']
          as String?;

  @override
  Future<List<RemoteSynchronizationChange>> pull({
    required int afterCursor,
    required int limit,
  }) async => changes
      .where((change) => change.cursor > afterCursor)
      .take(limit)
      .toList();

  @override
  Future<SynchronizationPushResult> push(OutboxOperation operation) async {
    final key = '${operation.entityType}/${operation.entityId}';
    final currentRevision = records[key]?['revision'] as int? ?? 0;
    if (operation.baseRevision != currentRevision) {
      return SynchronizationPushResult.rejected(
        code: 'stale_revision',
        rejectionJson: jsonEncode({
          'code': 'stale_revision',
          'current_revision': currentRevision,
        }),
      );
    }
    final payload = jsonDecode(operation.payloadJson) as Map<String, dynamic>;
    records[key] = payload;
    final acceptedCursor = ++cursor;
    changes.add(
      RemoteSynchronizationChange(
        cursor: acceptedCursor,
        entityType: operation.entityType,
        entityId: operation.entityId,
        revision: payload['revision'] as int,
        operationType: operation.type,
        payloadJson: operation.payloadJson,
      ),
    );
    return SynchronizationPushResult.accepted(
      cursor: acceptedCursor,
      revision: payload['revision'] as int,
    );
  }
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

final class _BackupPicker implements BackupByteFilePicker {
  List<int>? bytes;
  var calls = 0;

  @override
  Future<List<int>?> pickBackupBytes() async {
    calls++;
    return bytes;
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
