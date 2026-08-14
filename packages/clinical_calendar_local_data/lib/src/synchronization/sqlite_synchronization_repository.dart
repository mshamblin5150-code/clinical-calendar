import 'dart:convert';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import '../database/clinical_calendar_database.dart';

final class SqliteSynchronizationRepository
    implements
        SynchronizationLocalRepository,
        AggregateSynchronizationLocalRepository {
  SqliteSynchronizationRepository({
    required this._database,
    required this._identifiers,
    required String studentId,
  }) : _studentId = _uuid(studentId);

  final ClinicalCalendarDatabase _database;
  final IdentifierGenerator _identifiers;
  final String _studentId;

  @override
  SynchronizationHealthSnapshot inspect({
    required String studentId,
    required String remoteScope,
  }) {
    _owner(studentId);
    final stateRows = _database.select(
      'SELECT * FROM sync_state WHERE student_id = ?',
      [_studentId],
    );
    final pending = _database
        .select(
          '''SELECT count(*) AS count,
          min(created_at_utc) AS oldest,
          min(next_attempt_at_utc) AS next_retry
        FROM outbox_operations WHERE student_id = ?
        AND acknowledged_at_utc IS NULL
        AND terminal_rejected_at_utc IS NULL''',
          [_studentId],
        )
        .single;
    final conflictCount =
        _database
                .select(
                  '''SELECT count(*) AS count FROM sync_conflicts
        WHERE student_id = ? AND resolved_at_utc IS NULL''',
                  [_studentId],
                )
                .single['count']
            as int;
    final state = stateRows.isEmpty ? null : stateRows.single;
    var disposition = state == null
        ? SynchronizationHealthDisposition.offline
        : _healthDisposition(_text(state, 'disposition'));
    if (conflictCount > 0) {
      disposition = SynchronizationHealthDisposition.conflictNeedsAttention;
    }
    return SynchronizationHealthSnapshot(
      disposition: disposition,
      pendingCount: pending['count'] as int,
      unresolvedConflictCount: conflictCount,
      lastSuccessAtUtc: state == null
          ? null
          : _nullableDate(state, 'last_success_at_utc'),
      lastAttemptAtUtc: state == null
          ? null
          : _nullableDate(state, 'last_attempt_at_utc'),
      failureStartedAtUtc: state == null
          ? null
          : _nullableDate(state, 'failure_started_at_utc'),
      failureCode: state == null ? null : _nullableText(state, 'failure_code'),
      oldestPendingAtUtc: pending['oldest'] == null
          ? null
          : DateTime.parse(pending['oldest'] as String).toUtc(),
      nextRetryAtUtc: pending['next_retry'] == null
          ? null
          : DateTime.parse(pending['next_retry'] as String).toUtc(),
    );
  }

  @override
  void markHealth({
    required String studentId,
    required SynchronizationHealthDisposition disposition,
    required DateTime attemptedAtUtc,
    DateTime? succeededAtUtc,
    String? failureCode,
  }) {
    _owner(studentId);
    _requireUtc(attemptedAtUtc, 'attemptedAtUtc');
    if (succeededAtUtc != null) _requireUtc(succeededAtUtc, 'succeededAtUtc');
    final priorRows = _database.select(
      'SELECT * FROM sync_state WHERE student_id = ?',
      [_studentId],
    );
    final prior = priorRows.isEmpty ? null : priorRows.single;
    final priorFailureStarted = prior == null
        ? null
        : _nullableText(prior, 'failure_started_at_utc');
    final failureStarted = switch (disposition) {
      SynchronizationHealthDisposition.failed =>
        priorFailureStarted ?? attemptedAtUtc.toIso8601String(),
      SynchronizationHealthDisposition.syncing => priorFailureStarted,
      _ => null,
    };
    final effectiveFailureCode =
        disposition == SynchronizationHealthDisposition.syncing
        ? failureCode ??
              (prior == null ? null : _nullableText(prior, 'failure_code'))
        : failureCode;
    final lastSuccess =
        succeededAtUtc?.toIso8601String() ??
        (prior == null ? null : _nullableText(prior, 'last_success_at_utc'));
    _database.execute(
      '''INSERT INTO sync_state
        (student_id, disposition, last_success_at_utc, last_attempt_at_utc,
         failure_code, failure_started_at_utc)
        VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(student_id) DO UPDATE SET
          disposition = excluded.disposition,
          last_success_at_utc = excluded.last_success_at_utc,
          last_attempt_at_utc = excluded.last_attempt_at_utc,
          failure_code = excluded.failure_code,
          failure_started_at_utc = excluded.failure_started_at_utc''',
      [
        _studentId,
        _healthValue(disposition),
        lastSuccess,
        attemptedAtUtc.toIso8601String(),
        effectiveFailureCode,
        failureStarted,
      ],
    );
  }

  @override
  void recordTerminalRejection({
    required String studentId,
    required OutboxOperation operation,
    required String rejectionCode,
    required String rejectionJson,
    required DateTime rejectedAtUtc,
    required bool createsConflict,
  }) {
    _owner(studentId);
    _requireUtc(rejectedAtUtc, 'rejectedAtUtc');
    if (operation.studentId != _studentId) {
      throw const RepositoryException(
        RepositoryFailureKind.ownershipMismatch,
        'The outbox operation belongs to another Student.',
      );
    }
    final rows = _database.select(
      'SELECT * FROM outbox_operations WHERE student_id = ? AND id = ?',
      [_studentId, operation.mutation.operationId],
    );
    if (rows.length != 1) {
      throw const RepositoryException(
        RepositoryFailureKind.notFound,
        'The rejected outbox operation does not exist.',
      );
    }
    final row = rows.single;
    final priorCode = _nullableText(row, 'terminal_rejection_code');
    final priorAt = _nullableText(row, 'terminal_rejected_at_utc');
    if (priorCode != null || priorAt != null) {
      if (priorCode == rejectionCode &&
          priorAt == rejectedAtUtc.toIso8601String()) {
        return;
      }
      throw const RepositoryException(
        RepositoryFailureKind.idempotencyConflict,
        'The outbox operation was terminally rejected differently.',
      );
    }
    if (_nullableText(row, 'acknowledged_at_utc') != null) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'An acknowledged operation cannot be rejected.',
      );
    }
    _database.execute(
      '''UPDATE outbox_operations SET terminal_rejection_code = ?,
        terminal_rejected_at_utc = ?, last_failure_code = ?
        WHERE student_id = ? AND id = ?''',
      [
        rejectionCode,
        rejectedAtUtc.toIso8601String(),
        rejectionCode,
        _studentId,
        operation.mutation.operationId,
      ],
    );
    if (createsConflict) {
      final rejection = jsonDecode(rejectionJson);
      final remoteRevision =
          rejection is Map<String, dynamic> &&
              rejection['current_revision'] is int
          ? rejection['current_revision'] as int
          : operation.baseRevision;
      final payload = jsonDecode(operation.payloadJson);
      final localRevision =
          payload is Map<String, dynamic> && payload['revision'] is int
          ? payload['revision'] as int
          : operation.baseRevision + 1;
      _insertConflict(
        entityType: operation.entityType,
        entityId: operation.entityId,
        localRevision: localRevision,
        remoteRevision: remoteRevision,
        localSnapshotJson: operation.payloadJson,
        remoteSnapshotJson: rejectionJson,
        rejectionCode: rejectionCode,
        rejectionJson: rejectionJson,
        detectedAtUtc: rejectedAtUtc,
      );
    }
  }

  @override
  RemoteSynchronizationApplyDisposition applyRemoteAndAdvanceCursor({
    required String studentId,
    required String remoteScope,
    required RemoteSynchronizationChange change,
    required DateTime appliedAtUtc,
  }) {
    _owner(studentId);
    _requireUtc(appliedAtUtc, 'appliedAtUtc');
    final currentCursor = _cursor(remoteScope);
    if (change.cursor <= currentCursor) {
      return RemoteSynchronizationApplyDisposition.duplicate;
    }
    if (change.cursor != currentCursor + 1) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'The remote synchronization cursor has a gap.',
      );
    }
    final envelope = _decodeEnvelope(change);
    _enrichOpenConflict(change, appliedAtUtc);
    final table = _tableFor(change.entityType);
    final localRows = _database.select(
      'SELECT * FROM $table WHERE student_id = ? AND id = ?',
      [_studentId, change.entityId],
    );
    final localRevision = localRows.isEmpty
        ? 0
        : _integer(localRows.single, 'revision');
    final pending = _database.select(
      '''SELECT payload_json FROM outbox_operations
        WHERE student_id = ? AND entity_type = ? AND entity_id = ?
        AND acknowledged_at_utc IS NULL
        AND terminal_rejected_at_utc IS NULL
        ORDER BY created_at_utc DESC LIMIT 1''',
      [_studentId, change.entityType, change.entityId],
    );

    RemoteSynchronizationApplyDisposition disposition;
    if (pending.isNotEmpty &&
        _canonicalJson(jsonDecode(_text(pending.single, 'payload_json'))) !=
            _canonicalJson(envelope)) {
      _insertConflict(
        entityType: change.entityType,
        entityId: change.entityId,
        localRevision: localRevision,
        remoteRevision: change.revision,
        localSnapshotJson: _text(pending.single, 'payload_json'),
        remoteSnapshotJson: change.payloadJson,
        rejectionCode: 'concurrent_remote_change',
        rejectionJson: '{"code":"concurrent_remote_change"}',
        detectedAtUtc: appliedAtUtc,
      );
      disposition = RemoteSynchronizationApplyDisposition.conflict;
    } else if (localRevision > change.revision) {
      disposition = RemoteSynchronizationApplyDisposition.keptNewerLocal;
    } else if (localRevision == change.revision && localRows.isNotEmpty) {
      disposition = RemoteSynchronizationApplyDisposition.duplicate;
    } else {
      _applyEnvelope(change.entityType, change.entityId, envelope);
      disposition = RemoteSynchronizationApplyDisposition.applied;
    }
    _putCursor(remoteScope, change.cursor, appliedAtUtc);
    return disposition;
  }

  @override
  void recordIncompleteAggregatePull({
    required String studentId,
    required RemoteSynchronizationChange firstMember,
    required String aggregateMutationId,
    required DateTime detectedAtUtc,
  }) {
    _owner(studentId);
    _requireUtc(detectedAtUtc, 'detectedAtUtc');
    final table = _tableFor(firstMember.entityType);
    final rows = _database.select(
      'SELECT revision FROM $table WHERE student_id = ? AND id = ?',
      [_studentId, firstMember.entityId],
    );
    _insertConflict(
      entityType: firstMember.entityType,
      entityId: firstMember.entityId,
      localRevision: rows.isEmpty ? 0 : _integer(rows.single, 'revision'),
      remoteRevision: firstMember.revision,
      localSnapshotJson: _canonicalJson({
        'aggregate_mutation_id': aggregateMutationId,
        'state': 'prior_aggregate_preserved',
      }),
      remoteSnapshotJson: firstMember.payloadJson,
      rejectionCode: 'incomplete_aggregate_batch',
      rejectionJson: _canonicalJson({
        'code': 'incomplete_aggregate_batch',
        'aggregate_mutation_id': aggregateMutationId,
      }),
      detectedAtUtc: detectedAtUtc,
    );
  }

  @override
  void resolveIncompleteAggregatePull({
    required String studentId,
    required String aggregateMutationId,
    required DateTime resolvedAtUtc,
  }) {
    _owner(studentId);
    _requireUtc(resolvedAtUtc, 'resolvedAtUtc');
    _database.execute(
      '''UPDATE sync_conflicts SET revision = revision + 1,
           updated_at_utc = ?, resolved_at_utc = ?, resolution_json = ?
         WHERE student_id = ? AND resolved_at_utc IS NULL
           AND rejection_code = 'incomplete_aggregate_batch'
           AND json_extract(rejection_json, '\$.aggregate_mutation_id') = ?''',
      [
        resolvedAtUtc.toIso8601String(),
        resolvedAtUtc.toIso8601String(),
        _canonicalJson({'choice': 'complete_aggregate_received'}),
        _studentId,
        aggregateMutationId,
      ],
    );
  }

  @override
  List<SynchronizationConflictRecord> listConflicts({
    required String studentId,
    bool includeResolved = false,
  }) {
    _owner(studentId);
    final rows = _database.select(
      '''SELECT * FROM sync_conflicts WHERE student_id = ?
        ${includeResolved ? '' : 'AND resolved_at_utc IS NULL'}
        ORDER BY detected_at_utc, id''',
      [_studentId],
    );
    return rows.map(_conflictRecord).toList(growable: false);
  }

  @override
  SynchronizationConflictRecord? findConflict({
    required String studentId,
    required String conflictId,
  }) {
    _owner(studentId);
    final rows = _database.select(
      'SELECT * FROM sync_conflicts WHERE student_id = ? AND id = ?',
      [_studentId, _uuid(conflictId)],
    );
    return rows.isEmpty ? null : _conflictRecord(rows.single);
  }

  @override
  SynchronizationConflictResolutionReceipt resolveConflict({
    required String studentId,
    required String conflictId,
    required SynchronizationConflictResolutionChoice choice,
    String? correctedValueJson,
    required MutationToken mutation,
  }) {
    _owner(studentId);
    _requireUtc(mutation.occurredAtUtc, 'mutation.occurredAtUtc');
    final normalizedConflictId = _uuid(conflictId);
    final rows = _database.select(
      'SELECT * FROM sync_conflicts WHERE student_id = ? AND id = ?',
      [_studentId, normalizedConflictId],
    );
    if (rows.isEmpty) {
      throw const RepositoryException(
        RepositoryFailureKind.notFound,
        'The synchronization conflict does not exist.',
      );
    }
    final row = rows.single;
    if (_nullableText(row, 'resolved_at_utc') != null) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'The synchronization conflict is already resolved.',
      );
    }
    final local = _snapshot(_text(row, 'local_snapshot_json'));
    final remote = _snapshot(_text(row, 'remote_snapshot_json'));
    final selected = switch (choice) {
      SynchronizationConflictResolutionChoice.localVersion => local,
      SynchronizationConflictResolutionChoice.remoteVersion => remote,
      SynchronizationConflictResolutionChoice.correctedVersion => null,
      SynchronizationConflictResolutionChoice.deleteVersion => local,
    };
    if (choice == SynchronizationConflictResolutionChoice.remoteVersion &&
        !_isEnvelope(remote)) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'The remote version has not been received yet.',
      );
    }
    final value =
        choice == SynchronizationConflictResolutionChoice.correctedVersion
        ? _correctedValue(correctedValueJson)
        : _snapshotValue(selected!);
    final baseEnvelope = _isEnvelope(remote) ? remote : local;
    if (!_isEnvelope(baseEnvelope)) {
      throw const RepositoryException(
        RepositoryFailureKind.corruptData,
        'The conflict does not contain a complete record snapshot.',
      );
    }
    final entityType = _text(row, 'entity_type');
    final entityId = _text(row, 'entity_id');
    final remoteRevision = _integer(row, 'remote_revision');
    final envelope = <String, dynamic>{
      'schema_version': 1,
      'entity_type': entityType,
      'entity_id': entityId,
      'student_id': _studentId,
      'revision': remoteRevision + 1,
      'created_at_utc': baseEnvelope['created_at_utc'],
      'updated_at_utc': mutation.occurredAtUtc.toIso8601String(),
      'deleted_at_utc':
          choice == SynchronizationConflictResolutionChoice.deleteVersion
          ? mutation.occurredAtUtc.toIso8601String()
          : selected == null
          ? null
          : selected['deleted_at_utc'],
      'value': value,
    };
    final payloadJson = _canonicalJson(envelope);
    _applyEnvelope(entityType, entityId, envelope);
    final operationType =
        choice == SynchronizationConflictResolutionChoice.deleteVersion
        ? OutboxOperationType.delete
        : OutboxOperationType.resolveConflict;
    final operationTypeValue = operationType == OutboxOperationType.delete
        ? 'delete'
        : 'resolve_conflict';
    _database.execute(
      '''INSERT INTO outbox_operations
        (id, student_id, idempotency_key, entity_type, entity_id,
         operation_type, base_revision, payload_json, created_at_utc)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        mutation.operationId,
        _studentId,
        mutation.idempotencyKey,
        entityType,
        entityId,
        operationTypeValue,
        remoteRevision,
        payloadJson,
        mutation.occurredAtUtc.toIso8601String(),
      ],
    );
    final resolutionJson = _canonicalJson({
      'choice': choice.name,
      'operation_id': mutation.operationId,
      'local_revision': _integer(row, 'local_revision'),
      'remote_revision': remoteRevision,
    });
    _database.execute(
      '''UPDATE sync_conflicts SET revision = revision + 1,
        updated_at_utc = ?, resolved_at_utc = ?, resolution_json = ?
        WHERE student_id = ? AND id = ?''',
      [
        mutation.occurredAtUtc.toIso8601String(),
        mutation.occurredAtUtc.toIso8601String(),
        resolutionJson,
        _studentId,
        normalizedConflictId,
      ],
    );
    final operation = OutboxOperation(
      mutation: mutation,
      studentId: _studentId,
      entityType: entityType,
      entityId: entityId,
      type: operationType,
      baseRevision: remoteRevision,
      payloadJson: payloadJson,
    );
    return SynchronizationConflictResolutionReceipt(
      conflict: findConflict(
        studentId: _studentId,
        conflictId: normalizedConflictId,
      )!,
      operation: operation,
    );
  }

  int _cursor(String remoteScope) {
    final rows = _database.select(
      'SELECT server_cursor FROM sync_cursors WHERE student_id = ? '
      'AND remote_scope = ?',
      [_studentId, remoteScope],
    );
    return rows.isEmpty ? 0 : rows.single['server_cursor'] as int;
  }

  void _putCursor(String remoteScope, int cursor, DateTime updatedAtUtc) {
    _database.execute(
      '''INSERT INTO sync_cursors
        (student_id, remote_scope, server_cursor, updated_at_utc)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(student_id, remote_scope) DO UPDATE SET
          server_cursor = excluded.server_cursor,
          updated_at_utc = excluded.updated_at_utc''',
      [_studentId, remoteScope, cursor, updatedAtUtc.toIso8601String()],
    );
  }

  Map<String, dynamic> _decodeEnvelope(RemoteSynchronizationChange change) {
    final value = jsonDecode(change.payloadJson);
    if (value is! Map<String, dynamic> ||
        value['schema_version'] != 1 ||
        value['student_id'] != _studentId ||
        value['entity_type'] != change.entityType ||
        value['entity_id'] != change.entityId ||
        value['revision'] != change.revision ||
        value['value'] is! Map<String, dynamic>) {
      throw const RepositoryException(
        RepositoryFailureKind.corruptData,
        'The remote synchronization payload is invalid.',
      );
    }
    final deletedAt = value['deleted_at_utc'];
    final purgedAt = value['purged_at_utc'];
    if (change.operationType == OutboxOperationType.purge) {
      if (purgedAt is! String ||
          deletedAt is! String ||
          value['value'] is! Map) {
        throw const RepositoryException(
          RepositoryFailureKind.corruptData,
          'The remote permanent purge marker is invalid.',
        );
      }
    } else if ((change.operationType == OutboxOperationType.delete) !=
            (deletedAt != null) ||
        purgedAt != null) {
      throw const RepositoryException(
        RepositoryFailureKind.corruptData,
        'The remote synchronization tombstone is invalid.',
      );
    }
    return value;
  }

  void _applyEnvelope(
    String entityType,
    String entityId,
    Map<String, dynamic> envelope,
  ) {
    if (envelope['purged_at_utc'] != null) {
      _applyPermanentPurge(entityType, entityId, envelope);
      return;
    }
    final marker = _database.select(
      'SELECT 1 FROM permanent_purge_markers WHERE student_id = ? '
      'AND entity_type = ? AND entity_id = ?',
      [_studentId, entityType, entityId],
    );
    if (marker.isNotEmpty) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'A permanently deleted identity cannot be restored.',
      );
    }
    final value = envelope['value'] as Map<String, dynamic>;
    final common = <String, Object?>{
      'id': entityId,
      'student_id': _studentId,
      'revision': envelope['revision'],
      'created_at_utc': envelope['created_at_utc'],
      'updated_at_utc': envelope['updated_at_utc'],
      'deleted_at_utc': envelope['deleted_at_utc'],
    };
    switch (entityType) {
      case 'student_profile':
        _upsert('student_profiles', {
          ...common,
          'display_name': value['display_name'],
          'avatar_bytes': value['avatar_base64'] == null
              ? null
              : base64Decode(value['avatar_base64'] as String),
          'program': value['program'],
          'account_identity': value['account_identity'],
        });
      case 'preceptor':
        _upsert('preceptors', {
          ...common,
          'name': value['name'],
          'organization_or_site': value['organization_or_site'],
          'phone': value['phone'],
          'email': value['email'],
          'scheduling_notes': value['scheduling_notes'],
        });
      case 'work_shift' || 'clinical_session':
        _upsert('commitments', {
          ...common,
          for (final key in _commitmentColumns) key: value[key],
        });
      case 'protected_day':
        _upsert('protected_days', {
          ...common,
          'local_date': value['local_date'],
          'week_start_date': value['week_start_date'],
        });
      case 'schedule_template':
        _upsert('schedule_templates', {
          ...common,
          for (final key in _templateColumns) key: value[key],
        });
      case 'historical_hours_entry':
        _upsert('historical_hours_entries', {
          ...common,
          for (final key in _historyColumns) key: value[key],
        });
      case 'clinical_placement':
        _applyPlacement(common, entityId, value);
      case 'evaluation_plan':
        _applyEvaluationPlan(common, entityId, value);
      case 'settings':
        _upsert('settings', {
          ...common,
          for (final key in _settingsColumns)
            key: switch (key) {
              'theme' =>
                value[key] == 'borg_tactical'
                    ? StudentSettings.variantFThemeId
                    : value[key],
              'enhanced_accessibility' => value[key] ?? false,
              _ => value[key],
            },
        });
      case 'reminder_state':
        _upsert('reminder_state', {
          ...common,
          for (final key in _reminderColumns) key: value[key],
        });
      case 'academic_assignment':
        _upsert('academic_assignments', {
          ...common,
          for (final key in _academicAssignmentColumns) key: value[key],
        });
      case 'class_catalog_entry':
        _upsert('class_catalog_entries', {
          ...common,
          for (final key in _classCatalogEntryColumns) key: value[key],
        });
      default:
        throw const RepositoryException(
          RepositoryFailureKind.corruptData,
          'The remote entity type is unsupported.',
        );
    }
    _synchronizeTrash(entityType, entityId, envelope);
  }

  void _applyPermanentPurge(
    String entityType,
    String entityId,
    Map<String, dynamic> envelope,
  ) {
    final table = switch (entityType) {
      'work_shift' || 'clinical_session' => 'commitments',
      'protected_day' => 'protected_days',
      'schedule_template' => 'schedule_templates',
      'preceptor' => 'preceptors',
      'clinical_placement' => 'clinical_placements',
      'historical_hours_entry' => 'historical_hours_entries',
      'evaluation_plan' => 'evaluation_plans',
      'reminder_state' => 'reminder_state',
      'academic_assignment' => 'academic_assignments',
      'class_catalog_entry' => 'class_catalog_entries',
      _ => throw const RepositoryException(
        RepositoryFailureKind.corruptData,
        'The remote purge entity type is unsupported.',
      ),
    };
    if (entityType == 'evaluation_plan') {
      _database.execute(
        'DELETE FROM evaluation_requirements WHERE student_id = ? '
        'AND evaluation_plan_id = ?',
        [_studentId, entityId],
      );
    }
    if (entityType == 'clinical_placement') {
      _database.execute(
        'DELETE FROM placement_preceptors WHERE student_id = ? '
        'AND placement_id = ?',
        [_studentId, entityId],
      );
    }
    _database.execute('DELETE FROM $table WHERE student_id = ? AND id = ?', [
      _studentId,
      entityId,
    ]);
    _database.execute(
      'DELETE FROM trash WHERE student_id = ? AND entity_type = ? '
      'AND entity_id = ?',
      [_studentId, entityType, entityId],
    );
    _database.execute(
      '''INSERT INTO permanent_purge_markers
        (student_id, entity_type, entity_id, revision, purged_at_utc)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(student_id, entity_type, entity_id) DO UPDATE SET
          revision = max(revision, excluded.revision),
          purged_at_utc = max(purged_at_utc, excluded.purged_at_utc)''',
      [
        _studentId,
        entityType,
        entityId,
        envelope['revision'],
        envelope['purged_at_utc'],
      ],
    );
  }

  void _synchronizeTrash(
    String entityType,
    String entityId,
    Map<String, dynamic> envelope,
  ) {
    final deletedAtValue = envelope['deleted_at_utc'];
    if (deletedAtValue == null) {
      _database.execute(
        'DELETE FROM trash WHERE student_id = ? AND entity_type = ? '
        'AND entity_id = ?',
        [_studentId, entityType, entityId],
      );
      return;
    }
    if (entityType == 'student_profile' || entityType == 'settings') return;
    final deletedAt = DateTime.parse(deletedAtValue as String).toUtc();
    final existing = _database.select(
      'SELECT id, created_at_utc, revision FROM trash '
      'WHERE student_id = ? AND entity_type = ? AND entity_id = ?',
      [_studentId, entityType, entityId],
    );
    final id = existing.isEmpty
        ? _uuid(_identifiers.nextIdentifier())
        : existing.single['id'] as String;
    final createdAt = existing.isEmpty
        ? deletedAt.toIso8601String()
        : existing.single['created_at_utc'] as String;
    final revision = existing.isEmpty
        ? 1
        : (existing.single['revision'] as int) + 1;
    _database.execute(
      '''INSERT INTO trash
        (id, student_id, revision, created_at_utc, updated_at_utc,
         deleted_at_utc, entity_type, entity_id, deleted_snapshot_json,
         purge_after_utc, permanently_deleted_at_utc, aggregate_mutation_id,
         aggregate_root_id, aggregate_manifest_json, aggregate_recovery_json)
        VALUES (?, ?, ?, ?, ?, NULL, ?, ?, ?, ?, NULL, ?, ?, ?, ?)
        ON CONFLICT(student_id, entity_type, entity_id) DO UPDATE SET
          revision = excluded.revision,
          updated_at_utc = excluded.updated_at_utc,
          deleted_at_utc = NULL,
          deleted_snapshot_json = excluded.deleted_snapshot_json,
          purge_after_utc = excluded.purge_after_utc,
          permanently_deleted_at_utc = NULL,
          aggregate_mutation_id = excluded.aggregate_mutation_id,
          aggregate_root_id = excluded.aggregate_root_id,
          aggregate_manifest_json = excluded.aggregate_manifest_json,
          aggregate_recovery_json = excluded.aggregate_recovery_json''',
      [
        id,
        _studentId,
        revision,
        createdAt,
        deletedAt.toIso8601String(),
        entityType,
        entityId,
        _canonicalJson(envelope),
        deletedAt.add(const Duration(days: 30)).toIso8601String(),
        envelope['aggregate_mutation_id'],
        envelope['aggregate_root_id'],
        envelope['expected_member_manifest'] == null
            ? null
            : _canonicalJson(envelope['expected_member_manifest']),
        envelope['aggregate_recovery'] == null
            ? null
            : _canonicalJson(envelope['aggregate_recovery']),
      ],
    );
  }

  void _applyPlacement(
    Map<String, Object?> common,
    String entityId,
    Map<String, dynamic> value,
  ) {
    final attachments = value['attached_preceptor_ids'];
    if (attachments is! List || attachments.isEmpty) {
      throw const FormatException('Clinical Placement attachments missing.');
    }
    _upsert('clinical_placements', {
      ...common,
      'name': value['name'],
      'target_minutes': value['target_minutes'],
      'start_date': value['start_date'],
      'completion_deadline': value['completion_deadline'],
      'lifecycle_state': value['lifecycle_state'],
      'primary_preceptor_id': value['primary_preceptor_id'],
    });
    _database.execute(
      'DELETE FROM placement_preceptors WHERE student_id = ? '
      'AND placement_id = ?',
      [_studentId, entityId],
    );
    for (final preceptorId in attachments.cast<String>()) {
      _database.execute(
        '''INSERT INTO placement_preceptors
          (placement_id, preceptor_id, student_id, attached_at_utc)
          VALUES (?, ?, ?, ?)''',
        [entityId, _uuid(preceptorId), _studentId, common['updated_at_utc']],
      );
    }
  }

  void _applyEvaluationPlan(
    Map<String, Object?> common,
    String entityId,
    Map<String, dynamic> value,
  ) {
    final configuration = value['configuration'];
    final requirements = value['requirements'];
    if (configuration is! Map<String, dynamic> || requirements is! List) {
      throw const FormatException('Evaluation Plan payload is invalid.');
    }
    String? placementId = value['placement_id'] as String?;
    final existingPlan = _database.select(
      'SELECT placement_id FROM evaluation_plans WHERE student_id = ? '
      'AND id = ?',
      [_studentId, entityId],
    );
    placementId ??= existingPlan.isEmpty
        ? null
        : existingPlan.single['placement_id'] as String;
    final candidates = _database.select(
      'SELECT id FROM clinical_placements WHERE student_id = ?',
      [_studentId],
    );
    for (final candidate in candidates) {
      if (placementId != null) break;
      final outbox = _database.select(
        '''SELECT payload_json FROM outbox_operations
          WHERE student_id = ? AND entity_type = 'clinical_placement'
          AND entity_id = ? ORDER BY created_at_utc DESC LIMIT 1''',
        [_studentId, candidate['id']],
      );
      if (outbox.isNotEmpty) {
        final payload = jsonDecode(outbox.single['payload_json'] as String);
        if (payload is Map &&
            payload['value'] is Map &&
            (payload['value'] as Map)['evaluation_plan_id'] == entityId) {
          placementId = candidate['id'] as String;
          break;
        }
      }
    }
    if (placementId == null) {
      throw const RepositoryException(
        RepositoryFailureKind.corruptData,
        'The legacy Evaluation Plan feed row has no deterministic Clinical Placement association.',
      );
    }
    placementId = _uuid(placementId);
    _upsert('evaluation_plans', {
      ...common,
      'placement_id': placementId,
      'interim_cadence_minutes':
          configuration['interim_review_cadence_minutes'],
      'initial_self_assessment_required':
          configuration['initial_self_assessment_required'] == true ? 1 : 0,
      'final_self_assessment_required':
          configuration['final_self_assessment_required'] == true ? 1 : 0,
      'final_placement_review_required':
          configuration['final_placement_review_required'] == true ? 1 : 0,
    });
    final existing = _database.select(
      'SELECT * FROM evaluation_requirements WHERE student_id = ? '
      'AND evaluation_plan_id = ?',
      [_studentId, entityId],
    );
    final byKey = {for (final row in existing) row['requirement_key']: row};
    final retained = <String>{};
    for (final raw in requirements) {
      if (raw is! Map<String, dynamic>) throw const FormatException();
      final key = raw['identity'] as String;
      retained.add(key);
      final prior = byKey[key];
      final documentation = raw['documentation'];
      final kind = raw['kind'] as String;
      _upsert('evaluation_requirements', {
        'id': prior?['id'] ?? _uuid(_identifiers.nextIdentifier()),
        'student_id': _studentId,
        'revision': common['revision'],
        'created_at_utc': prior?['created_at_utc'] ?? common['created_at_utc'],
        'updated_at_utc': common['updated_at_utc'],
        'deleted_at_utc': common['deleted_at_utc'],
        'evaluation_plan_id': entityId,
        'requirement_key': key,
        'requirement_type': kind,
        'threshold_minutes': raw['threshold_minutes'],
        'boundary': _requirementBoundary(kind),
        'status': documentation == null ? 'not_due' : 'documented',
        'documented_at_utc': documentation is Map
            ? '${documentation['date_documented']}T00:00:00.000Z'
            : null,
        'documentation_location': documentation is Map
            ? documentation['location']
            : null,
        'documentation_reference': documentation is Map
            ? documentation['reference_or_note']
            : null,
        'documentation_note': null,
        'documented_preceptor_id': raw['primary_preceptor_id'],
        'is_currently_required': raw['is_currently_required'] == true ? 1 : 0,
      });
    }
    for (final prior in existing) {
      if (!retained.contains(prior['requirement_key'])) {
        _database.execute(
          'UPDATE evaluation_requirements SET revision = ?, '
          'updated_at_utc = ?, deleted_at_utc = ? WHERE id = ?',
          [
            common['revision'],
            common['updated_at_utc'],
            common['updated_at_utc'],
            prior['id'],
          ],
        );
      }
    }
  }

  void _upsert(String table, Map<String, Object?> values) {
    final columns = values.keys.toList(growable: false);
    final updates = columns
        .where((column) => column != 'id')
        .map((column) => '$column = excluded.$column')
        .join(', ');
    _database.execute(
      'INSERT INTO $table (${columns.join(', ')}) '
      'VALUES (${List.filled(columns.length, '?').join(', ')}) '
      'ON CONFLICT(id) DO UPDATE SET $updates',
      columns.map((column) => values[column]).toList(growable: false),
    );
  }

  void _enrichOpenConflict(
    RemoteSynchronizationChange change,
    DateTime appliedAtUtc,
  ) {
    final rows = _database.select(
      '''SELECT id, remote_snapshot_json FROM sync_conflicts
        WHERE student_id = ? AND entity_type = ? AND entity_id = ?
        AND remote_revision = ? AND resolved_at_utc IS NULL''',
      [_studentId, change.entityType, change.entityId, change.revision],
    );
    for (final row in rows) {
      final current = _snapshot(_text(row, 'remote_snapshot_json'));
      if (_isEnvelope(current)) continue;
      _database.execute(
        '''UPDATE sync_conflicts SET remote_snapshot_json = ?,
          updated_at_utc = ?, revision = revision + 1 WHERE id = ?''',
        [change.payloadJson, appliedAtUtc.toIso8601String(), _text(row, 'id')],
      );
    }
  }

  SynchronizationConflictRecord _conflictRecord(Map<Object?, Object?> row) {
    final entityType = _text(row, 'entity_type');
    final entityId = _text(row, 'entity_id');
    final rejectionCode = _text(row, 'rejection_code');
    final localSnapshotJson = _text(row, 'local_snapshot_json');
    final affected = _affectedRecords(
      entityType: entityType,
      entityId: entityId,
      rejectionCode: rejectionCode,
      localSnapshotJson: localSnapshotJson,
    );
    return SynchronizationConflictRecord(
      id: _text(row, 'id'),
      studentId: _studentId,
      entityType: entityType,
      entityId: entityId,
      localRevision: _integer(row, 'local_revision'),
      remoteRevision: _integer(row, 'remote_revision'),
      localSnapshotJson: localSnapshotJson,
      remoteSnapshotJson: _text(row, 'remote_snapshot_json'),
      rejectionCode: rejectionCode,
      rejectionJson: _text(row, 'rejection_json'),
      detectedAtUtc: DateTime.parse(_text(row, 'detected_at_utc')).toUtc(),
      affectedRecords: affected,
      planningWeekStartDate: _planningWeekStart(
        rejectionCode: rejectionCode,
        entityType: entityType,
        localSnapshotJson: localSnapshotJson,
        affected: affected,
      ),
      resolvedAtUtc: _nullableDate(row, 'resolved_at_utc'),
      resolutionJson: _nullableText(row, 'resolution_json'),
    );
  }

  List<SynchronizationConflictEntityReference> _affectedRecords({
    required String entityType,
    required String entityId,
    required String rejectionCode,
    required String localSnapshotJson,
  }) {
    final values = <String, SynchronizationConflictEntityReference>{};
    void add(String type, String id) {
      final normalized = _uuid(id);
      values['$type/$normalized'] = SynchronizationConflictEntityReference(
        entityType: type,
        entityId: normalized,
      );
    }

    add(entityType, entityId);
    final snapshot = _snapshot(localSnapshotJson);
    if (!_isEnvelope(snapshot)) return values.values.toList(growable: false);
    final value = _snapshotValue(snapshot);
    if (rejectionCode == 'schedule_conflict' &&
        (entityType == 'work_shift' || entityType == 'clinical_session')) {
      final start = value['lifecycle_state'] == 'completed'
          ? value['actual_start_utc']
          : value['planned_start_utc'];
      final end = value['lifecycle_state'] == 'completed'
          ? value['actual_end_utc']
          : value['planned_end_utc'];
      if (start is String && end is String) {
        final rows = _database.select(
          '''SELECT id, commitment_type FROM commitments
            WHERE student_id = ? AND id <> ? AND deleted_at_utc IS NULL
            AND lifecycle_state NOT IN ('cancelled', 'missed')
            AND (CASE WHEN lifecycle_state = 'completed'
              THEN actual_start_utc ELSE planned_start_utc END) < ?
            AND (CASE WHEN lifecycle_state = 'completed'
              THEN actual_end_utc ELSE planned_end_utc END) > ?''',
          [_studentId, entityId, end, start],
        );
        for (final row in rows) {
          add(_text(row, 'commitment_type'), _text(row, 'id'));
        }
      }
    }
    if (rejectionCode == 'protected_day_violation') {
      if (entityType == 'protected_day') {
        final date = value['local_date'];
        final weekStart = value['week_start_date'];
        if (date is String) {
          final rows = _database.select(
            '''SELECT id, commitment_type FROM commitments
              WHERE student_id = ? AND deleted_at_utc IS NULL
              AND lifecycle_state NOT IN ('cancelled', 'missed')
              AND (CASE WHEN lifecycle_state = 'completed'
                THEN actual_start_date ELSE planned_start_date END) <= ?
              AND (CASE WHEN lifecycle_state = 'completed'
                THEN actual_end_date ELSE planned_end_date END) >= ?''',
            [_studentId, date, date],
          );
          for (final row in rows) {
            add(_text(row, 'commitment_type'), _text(row, 'id'));
          }
        }
        if (weekStart is String) {
          final rows = _database.select(
            '''SELECT id FROM protected_days WHERE student_id = ?
              AND id <> ? AND week_start_date = ? AND deleted_at_utc IS NULL''',
            [_studentId, entityId, weekStart],
          );
          for (final row in rows) {
            add('protected_day', _text(row, 'id'));
          }
        }
      } else if (entityType == 'work_shift' ||
          entityType == 'clinical_session') {
        final startDate = value['lifecycle_state'] == 'completed'
            ? value['actual_start_date']
            : value['planned_start_date'];
        final endDate = value['lifecycle_state'] == 'completed'
            ? value['actual_end_date']
            : value['planned_end_date'];
        if (startDate is String && endDate is String) {
          final rows = _database.select(
            '''SELECT id FROM protected_days WHERE student_id = ?
              AND deleted_at_utc IS NULL AND local_date BETWEEN ? AND ?''',
            [_studentId, startDate, endDate],
          );
          for (final row in rows) {
            add('protected_day', _text(row, 'id'));
          }
        }
      }
    }
    return values.values.toList(growable: false);
  }

  LocalDate? _planningWeekStart({
    required String rejectionCode,
    required String entityType,
    required String localSnapshotJson,
    required List<SynchronizationConflictEntityReference> affected,
  }) {
    if (rejectionCode != 'protected_day_violation' &&
        rejectionCode != 'schedule_conflict') {
      return null;
    }
    final snapshot = _snapshot(localSnapshotJson);
    if (_isEnvelope(snapshot) &&
        (entityType == 'work_shift' || entityType == 'clinical_session')) {
      final value = _snapshotValue(snapshot);
      final date = value['lifecycle_state'] == 'completed'
          ? value['actual_start_date']
          : value['planned_start_date'];
      if (date is String) return _weekContaining(_localDate(date));
    }
    if (entityType == 'protected_day') {
      if (_isEnvelope(snapshot)) {
        final weekStart = _snapshotValue(snapshot)['week_start_date'];
        if (weekStart is String) return _localDate(weekStart);
      }
    }
    for (final record in affected) {
      if (record.entityType != 'protected_day') continue;
      final rows = _database.select(
        'SELECT week_start_date FROM protected_days '
        'WHERE student_id = ? AND id = ?',
        [_studentId, record.entityId],
      );
      if (rows.isNotEmpty) {
        return _localDate(_text(rows.single, 'week_start_date'));
      }
    }
    return null;
  }

  LocalDate _weekContaining(LocalDate date) {
    final rows = _database.select(
      'SELECT week_start FROM settings WHERE student_id = ?',
      [_studentId],
    );
    final weekStart = rows.isEmpty
        ? DateTime.sunday
        : _integer(rows.single, 'week_start');
    final weekday = DateTime(date.year, date.month, date.day).weekday;
    return date.addDays(-((weekday - weekStart + 7) % 7));
  }

  void _insertConflict({
    required String entityType,
    required String entityId,
    required int localRevision,
    required int remoteRevision,
    required String localSnapshotJson,
    required String remoteSnapshotJson,
    required String rejectionCode,
    required String rejectionJson,
    required DateTime detectedAtUtc,
  }) {
    final duplicate = _database.select(
      '''SELECT id, remote_snapshot_json FROM sync_conflicts WHERE student_id = ?
        AND entity_type = ? AND entity_id = ? AND local_revision = ?
        AND remote_revision = ? AND resolved_at_utc IS NULL LIMIT 1''',
      [_studentId, entityType, entityId, localRevision, remoteRevision],
    );
    if (duplicate.isNotEmpty) {
      final remote = _snapshot(remoteSnapshotJson);
      final prior = _snapshot(_text(duplicate.single, 'remote_snapshot_json'));
      if (_isEnvelope(remote) && !_isEnvelope(prior)) {
        _database.execute(
          '''UPDATE sync_conflicts SET remote_snapshot_json = ?,
            updated_at_utc = ?, revision = revision + 1 WHERE id = ?''',
          [
            remoteSnapshotJson,
            detectedAtUtc.toIso8601String(),
            _text(duplicate.single, 'id'),
          ],
        );
      }
      return;
    }
    final id = _uuid(_identifiers.nextIdentifier());
    _database.execute(
      '''INSERT INTO sync_conflicts
        (id, student_id, revision, created_at_utc, updated_at_utc,
         deleted_at_utc, entity_type, entity_id, local_revision,
         remote_revision, local_snapshot_json, remote_snapshot_json,
         detected_at_utc, resolved_at_utc, resolution_json,
         rejection_code, rejection_json)
        VALUES (?, ?, 1, ?, ?, NULL, ?, ?, ?, ?, ?, ?, ?, NULL, NULL, ?, ?)''',
      [
        id,
        _studentId,
        detectedAtUtc.toIso8601String(),
        detectedAtUtc.toIso8601String(),
        entityType,
        entityId,
        localRevision,
        remoteRevision,
        localSnapshotJson,
        remoteSnapshotJson,
        detectedAtUtc.toIso8601String(),
        rejectionCode,
        rejectionJson,
      ],
    );
  }

  void _owner(String studentId) {
    if (_uuid(studentId) != _studentId) {
      throw const RepositoryException(
        RepositoryFailureKind.ownershipMismatch,
        'Synchronization data belongs to another Student.',
      );
    }
  }
}

const _commitmentColumns = <String>[
  'commitment_type',
  'lifecycle_state',
  'placement_id',
  'preceptor_id',
  'planned_start_date',
  'planned_end_date',
  'planned_start_minutes',
  'planned_end_minutes',
  'time_zone',
  'planned_start_offset_minutes',
  'planned_end_offset_minutes',
  'planned_start_utc',
  'planned_end_utc',
  'actual_start_date',
  'actual_end_date',
  'actual_start_minutes',
  'actual_end_minutes',
  'actual_start_offset_minutes',
  'actual_end_offset_minutes',
  'actual_start_utc',
  'actual_end_utc',
];

const _templateColumns = <String>[
  'name',
  'commitment_type',
  'start_minutes',
  'end_minutes',
  'placement_id',
  'preceptor_id',
];
const _historyColumns = <String>[
  'placement_id',
  'preceptor_id',
  'completed_minutes',
  'effective_date',
  'note',
];
const _settingsColumns = <String>[
  'week_start',
  'time_display',
  'theme',
  'enhanced_accessibility',
  'synchronization_mode',
  'notification_preferences_json',
  'active_placement_id',
];
const _reminderColumns = <String>[
  'reminder_type',
  'subject_entity_id',
  'scheduled_for_utc',
  'snoozed_until_utc',
  'resolved_at_utc',
  'resolution_source',
  'occurrence_key',
];
const _academicAssignmentColumns = <String>[
  'title',
  'course',
  'course_id',
  'due_date',
  'status',
];
const _classCatalogEntryColumns = <String>['name', 'archived'];

String _tableFor(String entityType) => switch (entityType) {
  'student_profile' => 'student_profiles',
  'preceptor' => 'preceptors',
  'clinical_placement' => 'clinical_placements',
  'work_shift' || 'clinical_session' => 'commitments',
  'protected_day' => 'protected_days',
  'historical_hours_entry' => 'historical_hours_entries',
  'evaluation_plan' => 'evaluation_plans',
  'schedule_template' => 'schedule_templates',
  'settings' => 'settings',
  'reminder_state' => 'reminder_state',
  'academic_assignment' => 'academic_assignments',
  'class_catalog_entry' => 'class_catalog_entries',
  _ => throw const RepositoryException(
    RepositoryFailureKind.corruptData,
    'The remote entity type is unsupported.',
  ),
};

String _requirementBoundary(String kind) => switch (kind) {
  'initial_self_assessment' => 'beginning',
  'student_reviews_preceptor' || 'preceptor_reviews_student' => 'interim',
  'final_self_assessment' || 'final_placement_review' => 'end',
  _ => throw const FormatException('Unknown Evaluation Requirement kind.'),
};

SynchronizationHealthDisposition _healthDisposition(String value) =>
    switch (value) {
      'synced' => SynchronizationHealthDisposition.synced,
      'offline' => SynchronizationHealthDisposition.offline,
      'syncing' => SynchronizationHealthDisposition.syncing,
      'conflict' => SynchronizationHealthDisposition.conflictNeedsAttention,
      'failed' => SynchronizationHealthDisposition.failed,
      _ => throw const FormatException('Unknown synchronization health.'),
    };

String _healthValue(SynchronizationHealthDisposition value) => switch (value) {
  SynchronizationHealthDisposition.synced => 'synced',
  SynchronizationHealthDisposition.offline => 'offline',
  SynchronizationHealthDisposition.syncing => 'syncing',
  SynchronizationHealthDisposition.conflictNeedsAttention => 'conflict',
  SynchronizationHealthDisposition.failed => 'failed',
};

String _canonicalJson(Object? value) => jsonEncode(_canonical(value));

Map<String, dynamic> _snapshot(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw const RepositoryException(
      RepositoryFailureKind.corruptData,
      'A synchronization conflict snapshot is invalid.',
    );
  }
  return decoded;
}

bool _isEnvelope(Map<String, dynamic> value) =>
    value['schema_version'] == 1 && value['value'] is Map<String, dynamic>;

Map<String, dynamic> _snapshotValue(Map<String, dynamic> snapshot) {
  final value = snapshot['value'];
  if (value is! Map<String, dynamic>) {
    throw const RepositoryException(
      RepositoryFailureKind.corruptData,
      'A synchronization conflict version is incomplete.',
    );
  }
  return Map<String, dynamic>.from(value);
}

Map<String, dynamic> _correctedValue(String? source) {
  if (source == null) {
    throw const RepositoryException(
      RepositoryFailureKind.corruptData,
      'A corrected conflict version is required.',
    );
  }
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw const RepositoryException(
      RepositoryFailureKind.corruptData,
      'The corrected conflict version must be a JSON object.',
    );
  }
  return decoded;
}

LocalDate _localDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) throw const FormatException('Invalid local date.');
  return LocalDate(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

Object? _canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return {for (final key in keys) key: _canonical(value[key])};
  }
  if (value is List) return value.map(_canonical).toList(growable: false);
  return value;
}

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

String _uuid(String value) {
  final normalized = value.trim().toLowerCase();
  if (!_uuidPattern.hasMatch(normalized)) {
    throw ArgumentError.value(value, 'value', 'must be a UUID');
  }
  return normalized;
}

String _text(Map<Object?, Object?> row, String key) {
  final value = row[key];
  if (value is! String || value.isEmpty) throw const FormatException();
  return value;
}

String? _nullableText(Map<Object?, Object?> row, String key) {
  final value = row[key];
  if (value == null) return null;
  if (value is! String || value.isEmpty) throw const FormatException();
  return value;
}

int _integer(Map<Object?, Object?> row, String key) {
  final value = row[key];
  if (value is! int) throw const FormatException();
  return value;
}

DateTime? _nullableDate(Map<Object?, Object?> row, String key) {
  final value = _nullableText(row, key);
  return value == null ? null : DateTime.parse(value).toUtc();
}

void _requireUtc(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'must be UTC');
  }
}
