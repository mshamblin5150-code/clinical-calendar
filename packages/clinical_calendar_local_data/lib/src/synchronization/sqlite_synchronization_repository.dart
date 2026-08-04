import 'dart:convert';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';

import '../database/clinical_calendar_database.dart';

final class SqliteSynchronizationRepository
    implements SynchronizationLocalRepository {
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
    if ((change.operationType == OutboxOperationType.delete) !=
        (deletedAt != null)) {
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
          for (final key in _settingsColumns) key: value[key],
        });
      default:
        throw const RepositoryException(
          RepositoryFailureKind.corruptData,
          'The remote entity type is unsupported.',
        );
    }
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

  void _insertConflict({
    required String entityType,
    required String entityId,
    required int localRevision,
    required int remoteRevision,
    required String localSnapshotJson,
    required String remoteSnapshotJson,
    required DateTime detectedAtUtc,
  }) {
    final duplicate = _database.select(
      '''SELECT 1 FROM sync_conflicts WHERE student_id = ?
        AND entity_type = ? AND entity_id = ? AND local_revision = ?
        AND remote_revision = ? AND resolved_at_utc IS NULL LIMIT 1''',
      [_studentId, entityType, entityId, localRevision, remoteRevision],
    );
    if (duplicate.isNotEmpty) return;
    final id = _uuid(_identifiers.nextIdentifier());
    _database.execute(
      '''INSERT INTO sync_conflicts
        (id, student_id, revision, created_at_utc, updated_at_utc,
         deleted_at_utc, entity_type, entity_id, local_revision,
         remote_revision, local_snapshot_json, remote_snapshot_json,
         detected_at_utc, resolved_at_utc, resolution_json)
        VALUES (?, ?, 1, ?, ?, NULL, ?, ?, ?, ?, ?, ?, ?, NULL, NULL)''',
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
  'synchronization_mode',
  'notification_preferences_json',
  'active_placement_id',
];

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
