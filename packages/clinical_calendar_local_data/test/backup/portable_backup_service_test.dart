import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';

const _studentId = '00000000-0000-4000-8000-000000000001';
const _preceptorId = '00000000-0000-4000-8000-000000000002';
const _operationId = '00000000-0000-4000-8000-000000000003';
const _reminderId = '00000000-0000-4000-8000-000000000004';
const _placementId = '00000000-0000-4000-8000-000000000005';
const _evaluationPlanId = '00000000-0000-4000-8000-000000000006';
const _requirementId = '00000000-0000-4000-8000-000000000007';
const _passphrase = 'correct horse battery staple';
const _createdAt = '2026-08-03T12:00:00.000Z';
const _key =
    '0123456789abcdef0123456789abcdef'
    '0123456789abcdef0123456789abcdef';

void main() {
  late Directory temporaryDirectory;
  late ClinicalCalendarDatabase source;
  late ClinicalCalendarDatabase target;
  late PortableBackupCrypto crypto;
  late _IntentSink sink;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'clinical-calendar-portable-backup-',
    );
    source = await _open(temporaryDirectory, 'source.db');
    target = await _open(temporaryDirectory, 'target.db');
    crypto = PortableBackupCrypto(
      policy: const PortableBackupCryptoPolicy(
        memoryKib: 64,
        iterations: 1,
        parallelism: 1,
        minimumPassphraseCharacters: 1,
      ),
      secureRandom: Random(42),
    );
    sink = _IntentSink();
    _insertProfile(source, name: 'Backup Student', revision: 2);
    _insertProfile(target, name: 'Local Student', revision: 1);
  });

  tearDown(() async {
    await source.close();
    await target.close();
    await temporaryDirectory.delete(recursive: true);
  });

  test(
    'encrypted round trip previews and applies permanent identities',
    () async {
      _insertPreceptor(source, name: 'Dr. Backup', revision: 3);
      final encrypted = await _service(source, sink, crypto)
          .createEncryptedBackup(
            passphrase: _passphrase,
            createdAtUtc: DateTime.parse(_createdAt),
          );

      expect(utf8.decode(encrypted), isNot(contains('Dr. Backup')));
      final preview = await _service(
        target,
        sink,
        crypto,
      ).previewRestore(encryptedBytes: encrypted, passphrase: _passphrase);
      expect(preview.additions, 1);
      expect(preview.backupUpdates, 1);
      expect(preview.conflicts, isEmpty);

      final result = await _service(
        target,
        sink,
        crypto,
      ).applyRestore(preview: preview);
      expect(result.applied, 2);
      expect(
        target.select('SELECT name FROM preceptors WHERE id = ?', [
          _preceptorId,
        ]).single['name'],
        'Dr. Backup',
      );
      expect(
        sink.intents.map((intent) => intent.identity.table),
        containsAll(['student_profiles', 'preceptors']),
      );
    },
  );

  test('unique salt and nonce make identical backups different', () async {
    final service = _service(source, sink, crypto);
    final first = await service.createEncryptedBackup(
      passphrase: _passphrase,
      createdAtUtc: DateTime.parse(_createdAt),
    );
    final second = await service.createEncryptedBackup(
      passphrase: _passphrase,
      createdAtUtc: DateTime.parse(_createdAt),
    );
    expect(second, isNot(orderedEquals(first)));
  });

  test(
    'wrong passphrase and damaged ciphertext leave current data untouched',
    () async {
      final encrypted = await _service(source, sink, crypto)
          .createEncryptedBackup(
            passphrase: _passphrase,
            createdAtUtc: DateTime.parse(_createdAt),
          );
      await expectLater(
        _service(target, sink, crypto).previewRestore(
          encryptedBytes: encrypted,
          passphrase: 'incorrect but long passphrase',
        ),
        throwsA(_failure(PortableBackupFailureKind.wrongPassphraseOrDamaged)),
      );
      final damaged = List<int>.from(encrypted);
      damaged[damaged.length ~/ 2] ^= 1;
      await expectLater(
        _service(
          target,
          sink,
          crypto,
        ).previewRestore(encryptedBytes: damaged, passphrase: _passphrase),
        throwsA(
          anyOf(
            _failure(PortableBackupFailureKind.wrongPassphraseOrDamaged),
            _failure(PortableBackupFailureKind.invalidContainer),
          ),
        ),
      );
      expect(_profileName(target), 'Local Student');
    },
  );

  test(
    'unauthenticated KDF cost changes are rejected before derivation',
    () async {
      final encrypted = await crypto.encrypt(
        plaintext: utf8.encode('{"safe":true}'),
        passphrase: _passphrase,
      );
      final container =
          jsonDecode(utf8.decode(encrypted)) as Map<String, dynamic>;
      container['memory_kib'] = 65;

      await expectLater(
        crypto.decrypt(
          containerBytes: utf8.encode(jsonEncode(container)),
          passphrase: _passphrase,
        ),
        throwsA(_failure(PortableBackupFailureKind.invalidContainer)),
      );
    },
  );

  test('backup container and decoded row budgets fail closed', () async {
    final boundedCrypto = PortableBackupCrypto(
      policy: const PortableBackupCryptoPolicy(
        memoryKib: 64,
        iterations: 1,
        parallelism: 1,
        minimumPassphraseCharacters: 1,
        maximumContainerBytes: 128,
        maximumPlaintextBytes: 64,
      ),
      secureRandom: Random(42),
    );
    await expectLater(
      boundedCrypto.decrypt(
        containerBytes: List<int>.filled(129, 0),
        passphrase: _passphrase,
      ),
      throwsA(_failure(PortableBackupFailureKind.tooLarge)),
    );

    _insertPreceptor(source, name: 'Dr. Backup', revision: 1);
    final encrypted = await _service(source, sink, crypto)
        .createEncryptedBackup(
          passphrase: _passphrase,
          createdAtUtc: DateTime.parse(_createdAt),
        );
    await expectLater(
      _service(
        target,
        sink,
        crypto,
        datasetLimits: const PortableBackupDatasetLimits(maximumRows: 1),
      ).previewRestore(encryptedBytes: encrypted, passphrase: _passphrase),
      throwsA(_failure(PortableBackupFailureKind.tooLarge)),
    );
    expect(_profileName(target), 'Local Student');
  });

  test('checksum and record validation happen before current writes', () async {
    final current = await _service(source, sink, crypto).createEncryptedBackup(
      passphrase: _passphrase,
      createdAtUtc: DateTime.parse(_createdAt),
    );
    final checksumMismatch = await _rewritePayloadWithoutChecksumUpdate(
      crypto,
      current,
      (payload) => payload['created_at_utc'] = '2026-08-04T12:00:00.000Z',
    );
    await expectLater(
      _service(target, sink, crypto).previewRestore(
        encryptedBytes: checksumMismatch,
        passphrase: _passphrase,
      ),
      throwsA(_failure(PortableBackupFailureKind.checksumMismatch)),
    );

    final invalidRecord = await _rewritePayload(crypto, current, (payload) {
      final tables = payload['tables'] as Map<String, dynamic>;
      final profiles = tables['student_profiles'] as List<dynamic>;
      final profile = profiles.single as Map<String, dynamic>;
      profile['id'] = 'not-a-uuid';
    });
    await expectLater(
      _service(
        target,
        sink,
        crypto,
      ).previewRestore(encryptedBytes: invalidRecord, passphrase: _passphrase),
      throwsA(_failure(PortableBackupFailureKind.invalidRecord)),
    );
    expect(_profileName(target), 'Local Student');
  });

  test(
    'newer payload is rejected and supported version one migrates',
    () async {
      final current = await _service(source, sink, crypto)
          .createEncryptedBackup(
            passphrase: _passphrase,
            createdAtUtc: DateTime.parse(_createdAt),
          );
      final newer = await _rewritePayload(crypto, current, (payload) {
        payload['payload_version'] = 999;
      });
      await expectLater(
        _service(
          target,
          sink,
          crypto,
        ).previewRestore(encryptedBytes: newer, passphrase: _passphrase),
        throwsA(_failure(PortableBackupFailureKind.unsupportedNewerVersion)),
      );
      expect(_profileName(target), 'Local Student');

      final older = await _rewritePayload(crypto, current, (payload) {
        payload['schema_version'] = 1;
        payload.remove('payload_version');
      });
      final preview = await _service(
        target,
        sink,
        crypto,
      ).previewRestore(encryptedBytes: older, passphrase: _passphrase);
      expect(preview.studentId, _studentId);
    },
  );

  test(
    'pre-catalog backup settings migrate to variant-f and Standard',
    () async {
      source.execute(
        '''INSERT INTO settings
        (id, student_id, revision, created_at_utc, updated_at_utc,
         theme, enhanced_accessibility)
        VALUES (?, ?, 1, ?, ?, 'variant-f', 0)''',
        [_studentId, _studentId, _createdAt, _createdAt],
      );
      final current = await _service(source, sink, crypto)
          .createEncryptedBackup(
            passphrase: _passphrase,
            createdAtUtc: DateTime.parse(_createdAt),
          );
      final legacy = await _rewritePayload(crypto, current, (payload) {
        payload['source_database_schema_version'] = 12;
        final tables = payload['tables'] as Map<String, dynamic>;
        final settings =
            (tables['settings'] as List<dynamic>).single
                as Map<String, dynamic>;
        settings
          ..['theme'] = 'borg_tactical'
          ..remove('enhanced_accessibility');
      });

      final preview = await _service(
        target,
        sink,
        crypto,
      ).previewRestore(encryptedBytes: legacy, passphrase: _passphrase);
      await _service(target, sink, crypto).applyRestore(preview: preview);

      final restored = target.select('SELECT * FROM settings').single;
      expect(restored['theme'], StudentSettings.variantFThemeId);
      expect(restored['enhanced_accessibility'], 0);
    },
  );

  test(
    'equal revision with different content requires an explicit choice',
    () async {
      _insertPreceptor(source, name: 'Backup Name', revision: 1);
      _insertPreceptor(target, name: 'Local Name', revision: 1);
      final encrypted = await _service(source, sink, crypto)
          .createEncryptedBackup(
            passphrase: _passphrase,
            createdAtUtc: DateTime.parse(_createdAt),
          );
      final preview = await _service(
        target,
        sink,
        crypto,
      ).previewRestore(encryptedBytes: encrypted, passphrase: _passphrase);
      final conflict = preview.conflicts.singleWhere(
        (item) => item.identity.table == 'preceptors',
      );
      await expectLater(
        _service(target, sink, crypto).applyRestore(preview: preview),
        throwsA(_failure(PortableBackupFailureKind.unresolvedConflicts)),
      );
      await _service(target, sink, crypto).applyRestore(
        preview: preview,
        conflictChoices: {conflict.identity: RestoreConflictChoice.useBackup},
      );
      expect(
        target.select('SELECT name FROM preceptors WHERE id = ?', [
          _preceptorId,
        ]).single['name'],
        'Backup Name',
      );
    },
  );

  test('intent failure rolls back every restored row', () async {
    _insertPreceptor(source, name: 'Must Roll Back', revision: 1);
    final encrypted = await _service(source, sink, crypto)
        .createEncryptedBackup(
          passphrase: _passphrase,
          createdAtUtc: DateTime.parse(_createdAt),
        );
    final throwingSink = _IntentSink(throwOnRecord: true);
    final service = _service(target, throwingSink, crypto);
    final preview = await service.previewRestore(
      encryptedBytes: encrypted,
      passphrase: _passphrase,
    );
    await expectLater(
      service.applyRestore(preview: preview),
      throwsA(_failure(PortableBackupFailureKind.applyFailed)),
    );
    expect(target.select('SELECT * FROM preceptors'), isEmpty);
    expect(_profileName(target), 'Local Student');
  });

  test(
    'operational, device, credential, and retry state is excluded',
    () async {
      source.execute(
        '''INSERT INTO outbox_operations
         (id, student_id, idempotency_key, entity_type, entity_id,
          operation_type, base_revision, payload_json, created_at_utc)
         VALUES (?, ?, ?, 'preceptor', ?, 'upsert', 0, '{}', ?)''',
        [_operationId, _studentId, _operationId, _preceptorId, _createdAt],
      );
      source.execute(
        '''INSERT INTO sync_cursors
         (student_id, remote_scope, server_cursor, updated_at_utc)
         VALUES (?, 'supabase', 99, ?)''',
        [_studentId, _createdAt],
      );
      source.execute(
        '''INSERT INTO device_metadata
         (id, student_id, revision, created_at_utc, updated_at_utc,
          device_name, platform)
         VALUES (?, ?, 1, ?, ?, 'Private Device', 'windows')''',
        [_operationId, _studentId, _createdAt, _createdAt],
      );
      final encrypted = await _service(source, sink, crypto)
          .createEncryptedBackup(
            passphrase: _passphrase,
            createdAtUtc: DateTime.parse(_createdAt),
          );
      final plaintext = await crypto.decrypt(
        containerBytes: encrypted,
        passphrase: _passphrase,
      );
      final decoded =
          jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
      final tables = decoded['tables'] as Map<String, dynamic>;
      expect(tables.keys.toSet(), {
        'student_profiles',
        'preceptors',
        'clinical_placements',
        'placement_preceptors',
        'commitments',
        'protected_days',
        'historical_hours_entries',
        'evaluation_plans',
        'evaluation_requirements',
        'schedule_templates',
        'academic_assignments',
        'settings',
        'reminder_state',
        'trash',
      });
      expect(tables.keys, isNot(contains(anyOf(excludedPortableBackupTables))));
      expect(utf8.decode(plaintext), isNot(contains(_operationId)));
      expect(
        utf8.decode(plaintext),
        isNot(contains(ClinicalCalendarDatabase.encryptionKeyStorageKey)),
      );
      expect(utf8.decode(plaintext), isNot(contains('Private Device')));
    },
  );

  test('registry holds asynchronous backup work inside its FIFO', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    final events = <String>[];
    final registry = SqliteRepositoryRegistry(
      studentId: _studentId,
      database: target,
      identifierGenerator: _Identifiers(),
    );
    await registry.initialize();

    final exclusive = registry.runPortableBackupExclusive((_) async {
      events.add('backup-start');
      entered.complete();
      await release.future;
      events.add('backup-end');
    });
    await entered.future;
    var readCompleted = false;
    final queuedRead = registry.read((_) => events.add('read')).then((_) {
      readCompleted = true;
    });
    await Future<void>.delayed(Duration.zero);
    expect(readCompleted, isFalse);

    release.complete();
    await Future.wait([exclusive, queuedRead]);
    expect(events, ['backup-start', 'backup-end', 'read']);
  });

  test(
    'registry restore writes canonical fresh outbox and replay is idempotent',
    () async {
      _insertPreceptor(source, name: 'Dr. Backup', revision: 3);
      _insertPlacementAggregate(source);
      _insertReminder(source);
      final encrypted = await _service(source, sink, crypto)
          .createEncryptedBackup(
            passphrase: _passphrase,
            createdAtUtc: DateTime.parse(_createdAt),
          );
      final registry = SqliteRepositoryRegistry(
        studentId: _studentId,
        database: target,
        identifierGenerator: _Identifiers(),
      );
      await registry.initialize();
      final preview = await registry.runPortableBackupExclusive(
        (service) => service.previewRestore(
          encryptedBytes: encrypted,
          passphrase: _passphrase,
        ),
        crypto: crypto,
      );
      final first = await registry.runPortableBackupExclusive(
        (service) => service.applyRestore(preview: preview),
        crypto: crypto,
      );
      expect(first.applied, 7);

      final outbox = target.select(
        'SELECT * FROM outbox_operations ORDER BY entity_type',
      );
      expect(outbox.map((row) => row['entity_type']), [
        'clinical_placement',
        'evaluation_plan',
        'preceptor',
        'student_profile',
      ]);
      for (final row in outbox) {
        expect(row['id'], isNot(anyOf(_preceptorId, _studentId, _operationId)));
        expect(
          row['idempotency_key'],
          isNot(anyOf(_preceptorId, _studentId, _operationId)),
        );
        final payload =
            jsonDecode(row['payload_json'] as String) as Map<String, dynamic>;
        expect(payload['schema_version'], 1);
        expect(payload['entity_type'], row['entity_type']);
        expect(payload['entity_id'], row['entity_id']);
        expect(payload['student_id'], _studentId);
        expect(payload['value'], isA<Map<String, dynamic>>());
      }
      expect(
        target.select('SELECT * FROM reminder_state').single['id'],
        _reminderId,
      );
      expect(outbox.where((row) => row['entity_id'] == _reminderId), isEmpty);
      expect(
        outbox.map((row) => row['entity_type']),
        isNot(contains(anyOf('placement_preceptor', 'evaluation_requirement'))),
      );
      final placementPayload =
          jsonDecode(
                outbox.singleWhere(
                      (row) => row['entity_type'] == 'clinical_placement',
                    )['payload_json']
                    as String,
              )
              as Map<String, dynamic>;
      expect(
        (placementPayload['value']
            as Map<String, dynamic>)['attached_preceptor_ids'],
        [_preceptorId],
      );
      final planPayload =
          jsonDecode(
                outbox.singleWhere(
                      (row) => row['entity_type'] == 'evaluation_plan',
                    )['payload_json']
                    as String,
              )
              as Map<String, dynamic>;
      expect(
        (planPayload['value'] as Map<String, dynamic>)['requirements'],
        hasLength(1),
      );
      final pendingTypes = await registry.read(
        (repositories) => repositories.outbox
            .pending(studentId: _studentId, asOfUtc: DateTime.utc(2026, 8, 4))
            .map((operation) => operation.entityType)
            .toList(),
      );
      expect(pendingTypes, [
        'student_profile',
        'preceptor',
        'clinical_placement',
        'evaluation_plan',
      ]);

      final second = await registry.runPortableBackupExclusive(
        (service) => service.applyRestore(preview: preview),
        crypto: crypto,
      );
      expect(second.applied, 0);
      expect(target.select('SELECT * FROM outbox_operations'), hasLength(4));
    },
  );

  test(
    'portable backup restores unknown theme and Enhanced accessibility',
    () async {
      source.execute(
        '''INSERT INTO settings
          (id, student_id, revision, created_at_utc, updated_at_utc,
           theme, enhanced_accessibility)
          VALUES (?, ?, 1, ?, ?, 'future-theme', 1)''',
        [_studentId, _studentId, _createdAt, _createdAt],
      );
      final encrypted = await _service(source, sink, crypto)
          .createEncryptedBackup(
            passphrase: _passphrase,
            createdAtUtc: DateTime.parse(_createdAt),
          );
      final registry = SqliteRepositoryRegistry(
        studentId: _studentId,
        database: target,
        identifierGenerator: _Identifiers(),
      );
      await registry.initialize();
      final preview = await registry.runPortableBackupExclusive(
        (service) => service.previewRestore(
          encryptedBytes: encrypted,
          passphrase: _passphrase,
        ),
        crypto: crypto,
      );
      await registry.runPortableBackupExclusive(
        (service) => service.applyRestore(preview: preview),
        crypto: crypto,
      );

      await registry.read((repositories) {
        final support = repositories as SupportLocalReadRepositories;
        final restored = support.studentSettings
            .find(studentId: _studentId)!
            .value;
        expect(restored.themeId, 'future-theme');
        expect(restored.enhancedAccessibility, isTrue);

        final settingsIntent = repositories.outbox
            .pending(studentId: _studentId, asOfUtc: DateTime.utc(2026, 8, 4))
            .singleWhere((operation) => operation.entityType == 'settings');
        expect(
          settingsIntent.payloadJson,
          contains('"enhanced_accessibility":true'),
        );
        expect(settingsIntent.payloadJson, isNot(contains('preview')));
        expect(settingsIntent.payloadJson, isNot(contains('asset')));
      });
    },
  );

  test(
    'production outbox failure rolls back restored rows and intents',
    () async {
      _insertPreceptor(source, name: 'Must Roll Back', revision: 1);
      final encrypted = await _service(source, sink, crypto)
          .createEncryptedBackup(
            passphrase: _passphrase,
            createdAtUtc: DateTime.parse(_createdAt),
          );
      final registry = SqliteRepositoryRegistry(
        studentId: _studentId,
        database: target,
        identifierGenerator: _ThrowingIdentifiers(),
      );
      await registry.initialize();
      final preview = await registry.runPortableBackupExclusive(
        (service) => service.previewRestore(
          encryptedBytes: encrypted,
          passphrase: _passphrase,
        ),
        crypto: crypto,
      );

      await expectLater(
        registry.runPortableBackupExclusive(
          (service) => service.applyRestore(preview: preview),
          crypto: crypto,
        ),
        throwsA(_failure(PortableBackupFailureKind.applyFailed)),
      );
      expect(target.select('SELECT * FROM preceptors'), isEmpty);
      expect(target.select('SELECT * FROM outbox_operations'), isEmpty);
      expect(_profileName(target), 'Local Student');
    },
  );
}

PortableBackupService _service(
  ClinicalCalendarDatabase database,
  RestoreSynchronizationIntentSink sink,
  PortableBackupCrypto crypto, {
  PortableBackupDatasetLimits datasetLimits =
      const PortableBackupDatasetLimits(),
}) => PortableBackupService(
  database: database,
  studentId: _studentId,
  synchronizationIntentSink: sink,
  crypto: crypto,
  datasetLimits: datasetLimits,
);

Future<ClinicalCalendarDatabase> _open(Directory directory, String name) =>
    ClinicalCalendarDatabase.open(
      path: '${directory.path}${Platform.pathSeparator}$name',
      secureStorage: _MemorySecureStorage(),
    );

void _insertProfile(
  ClinicalCalendarDatabase database, {
  required String name,
  required int revision,
}) {
  database.execute(
    '''INSERT INTO student_profiles
       (id, student_id, revision, created_at_utc, updated_at_utc, display_name)
       VALUES (?, ?, ?, ?, ?, ?)''',
    [_studentId, _studentId, revision, _createdAt, _createdAt, name],
  );
}

void _insertPreceptor(
  ClinicalCalendarDatabase database, {
  required String name,
  required int revision,
}) {
  database.execute(
    '''INSERT INTO preceptors
       (id, student_id, revision, created_at_utc, updated_at_utc, name)
       VALUES (?, ?, ?, ?, ?, ?)''',
    [_preceptorId, _studentId, revision, _createdAt, _createdAt, name],
  );
}

void _insertReminder(ClinicalCalendarDatabase database) {
  database.execute(
    '''INSERT INTO reminder_state
       (id, student_id, revision, created_at_utc, updated_at_utc,
        deleted_at_utc, reminder_type)
       VALUES (?, ?, 1, ?, ?, NULL, 'backup_age')''',
    [_reminderId, _studentId, _createdAt, _createdAt],
  );
}

void _insertPlacementAggregate(ClinicalCalendarDatabase database) {
  database.transaction(() {
    database.execute(
      '''INSERT INTO clinical_placements
         (id, student_id, revision, created_at_utc, updated_at_utc,
          deleted_at_utc, name, target_minutes, start_date,
          completion_deadline, lifecycle_state, primary_preceptor_id)
         VALUES (?, ?, 2, ?, ?, NULL, 'Family Medicine', 16200,
                 '2026-08-01', '2026-12-31', 'active', ?)''',
      [_placementId, _studentId, _createdAt, _createdAt, _preceptorId],
    );
    database.execute(
      '''INSERT INTO placement_preceptors
         (placement_id, preceptor_id, student_id, attached_at_utc)
         VALUES (?, ?, ?, ?)''',
      [_placementId, _preceptorId, _studentId, _createdAt],
    );
    database.execute(
      '''INSERT INTO evaluation_plans
         (id, student_id, revision, created_at_utc, updated_at_utc,
          deleted_at_utc, placement_id, interim_cadence_minutes,
          initial_self_assessment_required, final_self_assessment_required,
          final_placement_review_required)
         VALUES (?, ?, 2, ?, ?, NULL, ?, 5400, 1, 1, 1)''',
      [_evaluationPlanId, _studentId, _createdAt, _createdAt, _placementId],
    );
    database.execute(
      '''INSERT INTO evaluation_requirements
         (id, student_id, revision, created_at_utc, updated_at_utc,
          deleted_at_utc, evaluation_plan_id, requirement_key,
          requirement_type, threshold_minutes, boundary, status,
          is_currently_required)
         VALUES (?, ?, 1, ?, ?, NULL, ?, ?, 'initial_self_assessment',
                 NULL, 'beginning', 'not_due', 1)''',
      [
        _requirementId,
        _studentId,
        _createdAt,
        _createdAt,
        _evaluationPlanId,
        '$_evaluationPlanId:initialSelfAssessment',
      ],
    );
  });
}

String _profileName(ClinicalCalendarDatabase database) =>
    database
            .select('SELECT display_name FROM student_profiles')
            .single['display_name']
        as String;

Future<List<int>> _rewritePayload(
  PortableBackupCrypto crypto,
  List<int> encrypted,
  void Function(Map<String, dynamic>) change,
) async {
  final plaintext = await crypto.decrypt(
    containerBytes: encrypted,
    passphrase: _passphrase,
  );
  final payload = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
  payload.remove('checksum_sha256');
  change(payload);
  final digest = await Sha256().hash(utf8.encode(canonicalJson(payload)));
  payload['checksum_sha256'] = base64Url.encode(digest.bytes);
  return crypto.encrypt(
    plaintext: utf8.encode(canonicalJson(payload)),
    passphrase: _passphrase,
  );
}

Future<List<int>> _rewritePayloadWithoutChecksumUpdate(
  PortableBackupCrypto crypto,
  List<int> encrypted,
  void Function(Map<String, dynamic>) change,
) async {
  final plaintext = await crypto.decrypt(
    containerBytes: encrypted,
    passphrase: _passphrase,
  );
  final payload = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
  change(payload);
  return crypto.encrypt(
    plaintext: utf8.encode(canonicalJson(payload)),
    passphrase: _passphrase,
  );
}

Matcher _failure(PortableBackupFailureKind kind) =>
    isA<PortableBackupException>().having((error) => error.kind, 'kind', kind);

final class _IntentSink implements RestoreSynchronizationIntentSink {
  _IntentSink({this.throwOnRecord = false});
  final bool throwOnRecord;
  final List<RestoreSynchronizationIntent> intents = [];

  @override
  void recordFreshIntents(List<RestoreSynchronizationIntent> values) {
    if (throwOnRecord) throw StateError('simulated outbox failure');
    intents.addAll(values);
  }
}

final class _Identifiers implements IdentifierGenerator {
  var _next = 100;

  @override
  String nextIdentifier() {
    final suffix = (_next++).toString().padLeft(12, '0');
    return '00000000-0000-4000-8000-$suffix';
  }
}

final class _ThrowingIdentifiers implements IdentifierGenerator {
  @override
  String nextIdentifier() => throw StateError('simulated identifier failure');
}

final class _MemorySecureStorage implements SecureStorage {
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
