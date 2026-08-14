import 'dart:async';
import 'dart:convert';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
// ignore: implementation_imports
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:sqlite3/sqlite3.dart';

import '../backup/portable_backup_crypto.dart';
import '../backup/portable_backup_models.dart';
import '../backup/portable_backup_service.dart';
import '../database/clinical_calendar_database.dart';
import '../synchronization/sqlite_synchronization_repository.dart';

typedef _Encoder<T> = Map<String, Object?> Function(T value);
typedef _Decoder<T> = T Function(Map<String, Object?> row);
typedef _AfterWrite<T> = void Function(T value, DateTime occurredAtUtc);

final RegExp _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// SQLCipher-backed repositories scoped to exactly one Student.
///
/// Public operations share a FIFO gate. Mutation callbacks are synchronous and
/// execute inside one `BEGIN IMMEDIATE` transaction.
final class SqliteRepositoryRegistry
    implements
        RepositoryRegistry,
        RecoveryStore,
        ClinicalPlacementAggregateDeletionStore {
  SqliteRepositoryRegistry({
    required String studentId,
    required this._database,
    required this._identifierGenerator,
  }) : studentId = _identifier(studentId);

  final String studentId;
  final ClinicalCalendarDatabase _database;
  final IdentifierGenerator _identifierGenerator;
  Future<void> _tail = Future<void>.value();
  bool _initialized = false;
  bool _closed = false;

  @override
  Future<void> initialize() => _enqueue(() {
    if (_closed) {
      throw const RepositoryException(
        RepositoryFailureKind.closed,
        'The local repository database is closed.',
      );
    }
    if (_initialized) return;
    final now = _utc(DateTime.now().toUtc());
    _database.execute(
      '''INSERT OR IGNORE INTO student_profiles
        (id, student_id, revision, created_at_utc, updated_at_utc,
         deleted_at_utc, display_name)
        VALUES (?, ?, 0, ?, ?, NULL, 'Student')''',
      [studentId, studentId, now, now],
    );
    _initialized = true;
  });

  @override
  Future<R> read<R>(R Function(LocalReadRepositories repositories) callback) =>
      _enqueue(() {
        _requireInitialized();
        final repositories = _Repositories(this, writable: false);
        try {
          return callback(repositories);
        } finally {
          repositories.close();
        }
      });

  @override
  Future<R> mutate<R>(
    R Function(LocalWriteRepositories repositories) callback,
  ) => _enqueue(() {
    _requireInitialized();
    final repositories = _Repositories(this, writable: true);
    try {
      try {
        return _database.transaction(() => callback(repositories));
      } on SqliteException catch (error) {
        throw RepositoryException(
          RepositoryFailureKind.persistenceFailure,
          'The local database write failed.',
          cause: error,
        );
      }
    } finally {
      repositories.close();
    }
  });

  @override
  Future<ClinicalPlacementDeletionPreview> previewClinicalPlacementDeletion({
    required String clinicalPlacementId,
    required int unsavedSchedulingDraftCount,
  }) => _enqueue(() {
    _requireInitialized();
    return _placementDeletionPreview(
      _identifier(clinicalPlacementId),
      unsavedSchedulingDraftCount,
    );
  });

  @override
  Future<void> moveClinicalPlacementAggregateToTrash({
    required ClinicalPlacementDeletionPreview preview,
    required String aggregateMutationId,
    required DateTime deletedAtUtc,
  }) => _enqueue(() {
    _requireInitialized();
    _requireUtcRecovery(deletedAtUtc);
    final normalizedAggregateId = _identifier(aggregateMutationId);
    return _database.transaction(() {
      final current = _placementDeletionPreview(
        _identifier(preview.clinicalPlacementId),
        preview.unsavedSchedulingDraftCount,
      );
      if (!_samePlacementDeletionPreview(preview, current)) {
        throw const RepositoryException(
          RepositoryFailureKind.concurrentModification,
          'The Clinical Placement changed after its deletion preview.',
        );
      }
      if (current.hasUnresolvedSynchronizationConflicts) {
        throw const RepositoryException(
          RepositoryFailureKind.concurrentModification,
          'Resolve synchronization conflicts before moving this Clinical Placement to Trash.',
        );
      }

      final repositories = _Repositories(this, writable: true);
      try {
        final placement = repositories.clinicalPlacements.find(
          studentId: studentId,
          id: current.clinicalPlacementId,
        )!;
        final sessions = repositories.clinicalSessions
            .list(studentId: studentId)
            .where(
              (record) =>
                  record.value.clinicalPlacementId ==
                  current.clinicalPlacementId,
            )
            .toList(growable: false);
        final history = repositories.historicalHoursEntries
            .list(studentId: studentId)
            .where(
              (record) =>
                  record.value.clinicalPlacementId ==
                  current.clinicalPlacementId,
            )
            .toList(growable: false);
        final templates = repositories.scheduleTemplates
            .list(studentId: studentId)
            .where(
              (record) =>
                  record.value.clinicalPlacementId ==
                  current.clinicalPlacementId,
            )
            .toList(growable: false);
        final plan = repositories.evaluationPlans.find(
          studentId: studentId,
          id: placement.value.evaluationPlanId,
        )!;
        final subjectIds = <String>{
          current.clinicalPlacementId,
          for (final record in sessions) record.value.id,
          for (final requirement in plan.value.requirements)
            requirement.identity.stableValue,
        };
        final reminders = repositories.reminderStates
            .list(studentId: studentId)
            .where(
              (record) => subjectIds.contains(record.value.subjectEntityId),
            )
            .toList(growable: false);

        final aggregateOperationIds = <String>[];
        MutationToken mutation() {
          final value = MutationToken(
            operationId: _identifierGenerator.nextIdentifier(),
            idempotencyKey: _identifierGenerator.nextIdentifier(),
            occurredAtUtc: deletedAtUtc,
          );
          aggregateOperationIds.add(value.operationId);
          return value;
        }

        // Dependents are tombstoned before their owners. The SQL transaction
        // and deferred relationship checks expose none of the partial graph.
        for (final record in reminders) {
          repositories.reminderStates.tombstone(
            studentId: studentId,
            id: record.value.id,
            expectedRevision: record.revision,
            mutation: mutation(),
          );
        }
        for (final record in sessions) {
          repositories.clinicalSessions.tombstone(
            studentId: studentId,
            id: record.value.id,
            expectedRevision: record.revision,
            mutation: mutation(),
          );
        }
        for (final record in history) {
          repositories.historicalHoursEntries.tombstone(
            studentId: studentId,
            id: record.value.id,
            expectedRevision: record.revision,
            mutation: mutation(),
          );
        }
        for (final record in templates) {
          repositories.scheduleTemplates.tombstone(
            studentId: studentId,
            id: record.value.id,
            expectedRevision: record.revision,
            mutation: mutation(),
          );
        }
        repositories.evaluationPlans.tombstone(
          studentId: studentId,
          id: plan.value.id,
          expectedRevision: plan.revision,
          mutation: mutation(),
        );
        repositories.clinicalPlacements.tombstone(
          studentId: studentId,
          id: placement.value.id,
          expectedRevision: placement.revision,
          mutation: mutation(),
        );
        if (current.clearsActivePlacementSelection) {
          final selection = repositories.activePlacementSelection.find(
            studentId: studentId,
          )!;
          repositories.activePlacementSelection.put(
            studentId: studentId,
            clinicalPlacementId: null,
            expectedRevision: selection.revision,
            mutation: mutation(),
          );
        }

        final manifest = _canonicalJson(current.memberRevisions);
        final recovery = _canonicalJson({
          'name': placement.value.name,
          'was_active': current.clearsActivePlacementSelection,
          'attached_preceptor_ids': placement.value.attachedPreceptorIds
              .toList(),
          'primary_preceptor_id': placement.value.primaryPreceptorId,
          'dependent_record_count': current.persistedDependentRecordCount,
        });
        for (final member in current.memberRevisions.keys) {
          final separator = member.indexOf(':');
          final entityType = member.substring(0, separator);
          if (entityType == 'settings') continue;
          final entityId = member.substring(separator + 1);
          _database.execute(
            '''UPDATE trash SET aggregate_mutation_id = ?,
               aggregate_root_id = ?, aggregate_manifest_json = ?,
               aggregate_recovery_json = ?
               WHERE student_id = ? AND entity_type = ? AND entity_id = ?
                 AND permanently_deleted_at_utc IS NULL''',
            [
              normalizedAggregateId,
              current.clinicalPlacementId,
              manifest,
              recovery,
              studentId,
              entityType,
              entityId,
            ],
          );
        }
        final operationPlaceholders = List.filled(
          aggregateOperationIds.length,
          '?',
        ).join(', ');
        _database.execute(
          '''UPDATE outbox_operations SET payload_json = json_set(
               payload_json,
               '\$.aggregate_mutation_id', ?,
               '\$.aggregate_root_id', ?,
               '\$.expected_member_manifest', json(?),
               '\$.aggregate_recovery', json(?)
             )
             WHERE student_id = ? AND id IN ($operationPlaceholders)''',
          [
            normalizedAggregateId,
            current.clinicalPlacementId,
            manifest,
            recovery,
            studentId,
            ...aggregateOperationIds,
          ],
        );
      } finally {
        repositories.close();
      }
    });
  });

  ClinicalPlacementDeletionPreview _placementDeletionPreview(
    String placementId,
    int unsavedSchedulingDraftCount,
  ) {
    final repositories = _Repositories(this, writable: false);
    try {
      final placement = repositories.clinicalPlacements.find(
        studentId: studentId,
        id: placementId,
      );
      if (placement == null) {
        throw const RepositoryException(
          RepositoryFailureKind.notFound,
          'Clinical Placement was not found.',
        );
      }
      final sessions = repositories.clinicalSessions
          .list(studentId: studentId)
          .where((record) => record.value.clinicalPlacementId == placementId)
          .toList(growable: false);
      final history = repositories.historicalHoursEntries
          .list(studentId: studentId)
          .where((record) => record.value.clinicalPlacementId == placementId)
          .toList(growable: false);
      final templates = repositories.scheduleTemplates
          .list(studentId: studentId)
          .where((record) => record.value.clinicalPlacementId == placementId)
          .toList(growable: false);
      final plan = repositories.evaluationPlans.find(
        studentId: studentId,
        id: placement.value.evaluationPlanId,
      );
      if (plan == null) {
        throw const RepositoryException(
          RepositoryFailureKind.corruptData,
          'The Clinical Placement Evaluation Plan is missing.',
        );
      }
      final reminderSubjectIds = <String>{
        placementId,
        for (final record in sessions) record.value.id,
        for (final requirement in plan.value.requirements)
          requirement.identity.stableValue,
      };
      final reminders = repositories.reminderStates
          .list(studentId: studentId)
          .where(
            (record) =>
                reminderSubjectIds.contains(record.value.subjectEntityId),
          )
          .toList(growable: false);
      final selection = repositories.activePlacementSelection.find(
        studentId: studentId,
      );
      final revisions = <String, int>{
        'clinical_placement:${placement.value.id}': placement.revision,
        'evaluation_plan:${plan.value.id}': plan.revision,
        for (final record in sessions)
          'clinical_session:${record.value.id}': record.revision,
        for (final record in history)
          'historical_hours_entry:${record.value.id}': record.revision,
        for (final record in templates)
          'schedule_template:${record.value.id}': record.revision,
        for (final record in reminders)
          'reminder_state:${record.value.id}': record.revision,
        if (selection?.value == placementId)
          'settings:$studentId': selection!.revision,
      };
      final conflicts = _database.select(
        '''SELECT entity_type, entity_id FROM sync_conflicts
           WHERE student_id = ? AND resolved_at_utc IS NULL''',
        [studentId],
      );
      final hasConflict = conflicts.any((row) {
        final direct =
            '${_text(row, 'entity_type')}:${_text(row, 'entity_id')}';
        return revisions.containsKey(direct);
      });

      int count(ClinicalSessionState state) =>
          sessions.where((record) => record.value.state == state).length;
      return ClinicalPlacementDeletionPreview(
        clinicalPlacementId: placement.value.id,
        clinicalPlacementName: placement.value.name,
        clinicalPlacementState: placement.value.state,
        memberRevisions: Map.unmodifiable(revisions),
        scheduledClinicalSessionCount: count(ClinicalSessionState.scheduled),
        awaitingConfirmationClinicalSessionCount: count(
          ClinicalSessionState.awaitingConfirmation,
        ),
        completedClinicalSessionCount: count(ClinicalSessionState.completed),
        cancelledClinicalSessionCount: count(ClinicalSessionState.cancelled),
        missedClinicalSessionCount: count(ClinicalSessionState.missed),
        clinicalSessionCompletedMinutes: sessions.fold(
          0,
          (total, record) => total + record.value.completedMinutes,
        ),
        historicalHoursEntryCount: history.length,
        historicalCompletedMinutes: history.fold(
          0,
          (total, record) => total + record.value.completedMinutes,
        ),
        evaluationRequirementCount: plan.value.requirements.length,
        documentedEvaluationRequirementCount: plan.value.requirements
            .where((requirement) => requirement.documentation != null)
            .length,
        scheduleTemplateCount: templates.length,
        reminderStateCount: reminders.length,
        attachedPreceptorRelationshipCount:
            placement.value.attachedPreceptorIds.length,
        unsavedSchedulingDraftCount: unsavedSchedulingDraftCount,
        clearsActivePlacementSelection: selection?.value == placementId,
        hasUnresolvedSynchronizationConflicts: hasConflict,
      );
    } finally {
      repositories.close();
    }
  }

  bool _samePlacementDeletionPreview(
    ClinicalPlacementDeletionPreview expected,
    ClinicalPlacementDeletionPreview current,
  ) {
    if (expected.clinicalPlacementId != current.clinicalPlacementId ||
        expected.unsavedSchedulingDraftCount !=
            current.unsavedSchedulingDraftCount ||
        expected.memberRevisions.length != current.memberRevisions.length) {
      return false;
    }
    for (final entry in expected.memberRevisions.entries) {
      if (current.memberRevisions[entry.key] != entry.value) return false;
    }
    return true;
  }

  /// Runs one complete portable-backup operation behind the repository FIFO.
  ///
  /// The callback may be asynchronous; the gate remains held until its Future
  /// completes, so database reads and restore writes cannot interleave with
  /// repository work on this connection.
  Future<R> runPortableBackupExclusive<R>(
    FutureOr<R> Function(PortableBackupService service) callback, {
    PortableBackupCrypto? crypto,
    PortableBackupMigrator migrator = const DefaultPortableBackupMigrator(),
  }) => _enqueue(() {
    _requireInitialized();
    return callback(
      PortableBackupService(
        database: _database,
        studentId: studentId,
        synchronizationIntentSink: _RestoreOutboxIntentSink(this),
        crypto: crypto,
        migrator: migrator,
      ),
    );
  });

  @override
  Future<List<TrashEntry>> listTrash({required DateTime nowUtc}) =>
      _enqueue(() {
        _requireInitialized();
        _database.transaction(() => _purgeExpiredTrash(nowUtc));
        final rows = _database.select(
          '''SELECT * FROM trash WHERE student_id = ?
         AND permanently_deleted_at_utc IS NULL
         ORDER BY updated_at_utc DESC, id''',
          [studentId],
        );
        final result = <TrashEntry>[];
        final emittedAggregates = <String>{};
        for (final row in rows) {
          final aggregateId = row['aggregate_mutation_id'];
          if (aggregateId is String && aggregateId.isNotEmpty) {
            if (!emittedAggregates.add(aggregateId)) continue;
            final group = rows
                .where(
                  (candidate) =>
                      candidate['aggregate_mutation_id'] == aggregateId,
                )
                .toList(growable: false);
            final rootId = _identifier(_text(row, 'aggregate_root_id'));
            final root = group.singleWhere(
              (candidate) =>
                  _text(candidate, 'entity_type') == 'clinical_placement' &&
                  _identifier(_text(candidate, 'entity_id')) == rootId,
            );
            final recovery =
                jsonDecode(_text(root, 'aggregate_recovery_json'))
                    as Map<String, Object?>;
            result.add(
              TrashEntry(
                id: _identifier(_text(root, 'id')),
                entityType: 'clinical_placement_aggregate',
                entityId: rootId,
                deletedAtUtc: _dateTime(root, 'updated_at_utc'),
                purgeAfterUtc: _dateTime(root, 'purge_after_utc'),
                displayName: recovery['name']! as String,
                dependentRecordCount: group.length - 1,
              ),
            );
            continue;
          }
          result.add(
            TrashEntry(
              id: _identifier(_text(row, 'id')),
              entityType: _text(row, 'entity_type'),
              entityId: _identifier(_text(row, 'entity_id')),
              deletedAtUtc: _dateTime(row, 'updated_at_utc'),
              purgeAfterUtc: _dateTime(row, 'purge_after_utc'),
            ),
          );
        }
        return result;
      });

  @override
  Future<void> restoreTrash({
    required String trashId,
    required DateTime restoredAtUtc,
    required MutationToken mutation,
  }) => _enqueue(() {
    _requireInitialized();
    _requireUtcRecovery(restoredAtUtc);
    return _database.transaction(() {
      final rows = _database.select(
        '''SELECT * FROM trash WHERE student_id = ? AND id = ?
           AND permanently_deleted_at_utc IS NULL''',
        [studentId, _identifier(trashId)],
      );
      if (rows.isEmpty) {
        throw const RecoveryException(
          RecoveryFailureKind.notFound,
          'The Trash entry no longer exists.',
        );
      }
      final row = rows.single;
      if (!_dateTime(row, 'purge_after_utc').isAfter(restoredAtUtc)) {
        throw const RecoveryException(
          RecoveryFailureKind.expired,
          'The Trash entry has expired.',
        );
      }
      final repositories = _Repositories(this, writable: true);
      try {
        final aggregateId = row['aggregate_mutation_id'];
        if (aggregateId is String && aggregateId.isNotEmpty) {
          final group = _database.select(
            '''SELECT * FROM trash WHERE student_id = ?
               AND aggregate_mutation_id = ?
               AND permanently_deleted_at_utc IS NULL''',
            [studentId, aggregateId],
          );
          _restorePlacementAggregate(
            repositories,
            group: group,
            rootRow: row,
            restoredAtUtc: restoredAtUtc,
            rootMutation: mutation,
          );
        } else {
          _restoreTombstone(
            repositories,
            entityType: _text(row, 'entity_type'),
            entityId: _identifier(_text(row, 'entity_id')),
            mutation: mutation,
          );
        }
        _backupService().validateCurrentState();
      } on RecoveryException {
        rethrow;
      } on Object catch (error) {
        throw RecoveryException(
          RecoveryFailureKind.invariantViolation,
          'Restoring this record would violate the current calendar rules.',
          cause: error,
        );
      } finally {
        repositories.close();
      }
    });
  });

  void _restorePlacementAggregate(
    _Repositories repositories, {
    required List<Map<String, Object?>> group,
    required Map<String, Object?> rootRow,
    required DateTime restoredAtUtc,
    required MutationToken rootMutation,
  }) {
    if (group.isEmpty) {
      throw const RecoveryException(
        RecoveryFailureKind.invariantViolation,
        'The Clinical Placement recovery group is incomplete.',
      );
    }
    final manifest =
        jsonDecode(_text(rootRow, 'aggregate_manifest_json'))
            as Map<String, Object?>;
    final expectedTrashMembers = manifest.keys
        .where((key) => !key.startsWith('settings:'))
        .toSet();
    final actualTrashMembers = {
      for (final member in group)
        '${_text(member, 'entity_type')}:${_text(member, 'entity_id')}',
    };
    if (expectedTrashMembers.length != group.length ||
        !actualTrashMembers.containsAll(expectedTrashMembers)) {
      throw const RecoveryException(
        RecoveryFailureKind.invariantViolation,
        'The Clinical Placement recovery group is incomplete.',
      );
    }
    for (final member in group) {
      final entityType = _text(member, 'entity_type');
      final entityId = _text(member, 'entity_id');
      final key = '$entityType:$entityId';
      final expectedBaseRevision = manifest[key];
      final snapshot = jsonDecode(_text(member, 'deleted_snapshot_json'));
      final expectedTombstoneRevision = expectedBaseRevision is int
          ? expectedBaseRevision + 1
          : null;
      final entityRows = _database.select(
        'SELECT revision, deleted_at_utc FROM ${_recoveryTable(entityType)} '
        'WHERE student_id = ? AND id = ?',
        [studentId, entityId],
      );
      if (expectedTombstoneRevision == null ||
          snapshot is! Map<String, dynamic> ||
          snapshot['revision'] != expectedTombstoneRevision ||
          entityRows.length != 1 ||
          _int(entityRows.single, 'revision') != expectedTombstoneRevision ||
          entityRows.single['deleted_at_utc'] == null) {
        throw const RecoveryException(
          RecoveryFailureKind.concurrentModification,
          'The Clinical Placement recovery group changed after deletion.',
        );
      }
    }
    final expiry = _dateTime(rootRow, 'purge_after_utc');
    if (group.any((member) => _dateTime(member, 'purge_after_utc') != expiry)) {
      throw const RecoveryException(
        RecoveryFailureKind.invariantViolation,
        'The Clinical Placement recovery group has inconsistent expiry data.',
      );
    }
    final recovery =
        jsonDecode(_text(rootRow, 'aggregate_recovery_json'))
            as Map<String, Object?>;
    final preceptorIds = (recovery['attached_preceptor_ids']! as List<Object?>)
        .cast<String>();
    for (final preceptorId in preceptorIds) {
      if (repositories.preceptors.find(
            studentId: studentId,
            id: _identifier(preceptorId),
          ) ==
          null) {
        throw const RecoveryException(
          RecoveryFailureKind.invariantViolation,
          'Restore the independently deleted Preceptor before restoring this Clinical Placement.',
        );
      }
    }

    const dependencyOrder = <String, int>{
      'clinical_placement': 0,
      'evaluation_plan': 1,
      'historical_hours_entry': 2,
      'clinical_session': 3,
      'schedule_template': 4,
      'reminder_state': 5,
    };
    final orderedGroup = List<Map<String, Object?>>.of(group)
      ..sort(
        (left, right) => dependencyOrder[_text(left, 'entity_type')]!.compareTo(
          dependencyOrder[_text(right, 'entity_type')]!,
        ),
      );
    var usedRootMutation = false;
    final aggregateOperationIds = <String>[];
    for (final member in orderedGroup) {
      final memberMutation = !usedRootMutation
          ? rootMutation
          : _newRecoveryMutation(restoredAtUtc);
      usedRootMutation = true;
      aggregateOperationIds.add(memberMutation.operationId);
      _restoreTombstone(
        repositories,
        entityType: _text(member, 'entity_type'),
        entityId: _identifier(_text(member, 'entity_id')),
        mutation: memberMutation,
      );
    }
    var restoredActiveSelection = false;
    if (recovery['was_active'] == true) {
      final selection = repositories.activePlacementSelection.find(
        studentId: studentId,
      );
      if (selection?.value == null) {
        final selectionMutation = _newRecoveryMutation(restoredAtUtc);
        repositories.activePlacementSelection.put(
          studentId: studentId,
          clinicalPlacementId: _identifier(_text(rootRow, 'aggregate_root_id')),
          expectedRevision: selection?.revision ?? 0,
          mutation: selectionMutation,
        );
        aggregateOperationIds.add(selectionMutation.operationId);
        restoredActiveSelection = true;
      }
    }
    final restoreManifest = Map<String, Object?>.of(manifest);
    if (!restoredActiveSelection) restoreManifest.remove('settings:$studentId');
    final restoreAggregateId = _identifierGenerator.nextIdentifier();
    final operationPlaceholders = List.filled(
      aggregateOperationIds.length,
      '?',
    ).join(', ');
    _database.execute(
      '''UPDATE outbox_operations SET payload_json = json_set(
           payload_json,
           '\$.aggregate_mutation_id', ?,
           '\$.aggregate_root_id', ?,
           '\$.expected_member_manifest', json(?)
         )
         WHERE student_id = ? AND id IN ($operationPlaceholders)''',
      [
        restoreAggregateId,
        _identifier(_text(rootRow, 'aggregate_root_id')),
        _canonicalJson(restoreManifest),
        studentId,
        ...aggregateOperationIds,
      ],
    );
  }

  @override
  Future<void> permanentlyDelete({
    required String trashId,
    required DateTime deletedAtUtc,
    required MutationToken mutation,
  }) => _enqueue(() {
    _requireInitialized();
    _requireUtcRecovery(deletedAtUtc);
    _database.transaction(() {
      final rows = _database.select(
        'SELECT * FROM trash WHERE student_id = ? AND id = ? '
        'AND permanently_deleted_at_utc IS NULL',
        [studentId, _identifier(trashId)],
      );
      if (rows.isEmpty) {
        throw const RecoveryException(
          RecoveryFailureKind.notFound,
          'The Trash entry no longer exists.',
        );
      }
      final selected = rows.single;
      final aggregateId = selected['aggregate_mutation_id'];
      final members = aggregateId is String && aggregateId.isNotEmpty
          ? _database.select(
              '''SELECT * FROM trash WHERE student_id = ?
                 AND aggregate_mutation_id = ?
                 AND permanently_deleted_at_utc IS NULL ORDER BY id''',
              [studentId, aggregateId],
            )
          : [selected];
      _purgeTrashGroup(members, deletedAtUtc, mutation);
    });
  });

  @override
  Future<int> clearTrash({
    required DateTime deletedAtUtc,
    required List<MutationToken> mutations,
  }) => _enqueue(() {
    _requireInitialized();
    _requireUtcRecovery(deletedAtUtc);
    return _database.transaction(() {
      final rows = _database.select(
        'SELECT * FROM trash WHERE student_id = ? '
        'AND permanently_deleted_at_utc IS NULL ORDER BY id',
        [studentId],
      );
      final groups = <List<Map<String, Object?>>>[];
      final seenAggregates = <String>{};
      for (final row in rows) {
        final aggregateId = row['aggregate_mutation_id'];
        if (aggregateId is String && aggregateId.isNotEmpty) {
          if (!seenAggregates.add(aggregateId)) continue;
          groups.add(
            rows
                .where(
                  (candidate) =>
                      candidate['aggregate_mutation_id'] == aggregateId,
                )
                .toList(growable: false),
          );
        } else {
          groups.add([row]);
        }
      }
      if (groups.length != mutations.length) {
        throw const RecoveryException(
          RecoveryFailureKind.concurrentModification,
          'Trash changed before it could be cleared.',
        );
      }
      for (var groupIndex = 0; groupIndex < groups.length; groupIndex++) {
        final group = groups[groupIndex];
        _purgeTrashGroup(group, deletedAtUtc, mutations[groupIndex]);
      }
      return groups.length;
    });
  });

  @override
  Future<int> purgeExpired({required DateTime nowUtc}) => _enqueue(() {
    _requireInitialized();
    _requireUtcRecovery(nowUtc);
    return _database.transaction(() => _purgeExpiredTrash(nowUtc));
  });

  @override
  Future<OperationalSnapshotSummary> createDailySnapshot({
    required DateTime nowUtc,
  }) => _enqueue(() {
    _requireInitialized();
    _requireUtcRecovery(nowUtc);
    final date = nowUtc.toIso8601String().substring(0, 10);
    final expires = nowUtc.add(const Duration(days: 30));
    final existing = _database.select(
      'SELECT id FROM operational_recovery_snapshots '
      'WHERE student_id = ? AND snapshot_date = ?',
      [studentId, date],
    );
    final id = existing.isEmpty
        ? _identifier(_identifierGenerator.nextIdentifier())
        : _identifier(_text(existing.single, 'id'));
    final payload = _backupService().createOperationalSnapshotPayload(
      createdAtUtc: nowUtc,
    );
    _database.transaction(() {
      _database.execute(
        'DELETE FROM operational_recovery_snapshots '
        'WHERE student_id = ? AND expires_at_utc <= ?',
        [studentId, _utc(nowUtc)],
      );
      _database.execute(
        '''INSERT INTO operational_recovery_snapshots
          (id, student_id, snapshot_date, created_at_utc, expires_at_utc,
           payload_json) VALUES (?, ?, ?, ?, ?, ?)
          ON CONFLICT(student_id, snapshot_date) DO UPDATE SET
            created_at_utc = excluded.created_at_utc,
            expires_at_utc = excluded.expires_at_utc,
            payload_json = excluded.payload_json''',
        [id, studentId, date, _utc(nowUtc), _utc(expires), payload],
      );
    });
    return OperationalSnapshotSummary(
      id: id,
      snapshotDate: date,
      createdAtUtc: nowUtc,
      expiresAtUtc: expires,
    );
  });

  @override
  Future<List<OperationalSnapshotSummary>> listSnapshots({
    required DateTime nowUtc,
  }) => _enqueue(() {
    _requireInitialized();
    _requireUtcRecovery(nowUtc);
    _database.execute(
      'DELETE FROM operational_recovery_snapshots '
      'WHERE student_id = ? AND expires_at_utc <= ?',
      [studentId, _utc(nowUtc)],
    );
    return _database
        .select(
          '''SELECT * FROM operational_recovery_snapshots
             WHERE student_id = ? ORDER BY created_at_utc DESC''',
          [studentId],
        )
        .map(_snapshotSummary)
        .toList(growable: false);
  });

  @override
  Future<OperationalRecoveryPreview> previewSnapshot({
    required String snapshotId,
    required DateTime nowUtc,
  }) => _enqueue(() async {
    _requireInitialized();
    final row = _snapshotRow(snapshotId, nowUtc);
    final preview = await _backupService().previewOperationalRestore(
      payloadJson: _text(row, 'payload_json'),
    );
    return _recoveryPreview(_snapshotSummary(row), preview);
  });

  @override
  Future<RecoveryApplyResult> restoreSnapshot({
    required String snapshotId,
    required Map<String, RecoveryConflictChoice> choices,
    required DateTime nowUtc,
  }) => _enqueue(() async {
    _requireInitialized();
    final row = _snapshotRow(snapshotId, nowUtc);
    final service = _backupService();
    final preview = await service.previewOperationalRestore(
      payloadJson: _text(row, 'payload_json'),
    );
    final byStableIdentity = {
      for (final item in preview.items)
        item.identity.stableValue: item.identity,
    };
    final converted = <BackupRecordIdentity, RestoreConflictChoice>{};
    for (final choice in choices.entries) {
      final identity = byStableIdentity[choice.key];
      if (identity == null) continue;
      converted[identity] = choice.value == RecoveryConflictChoice.keepCurrent
          ? RestoreConflictChoice.keepLocal
          : RestoreConflictChoice.useBackup;
    }
    final result = await service.applyRestore(
      preview: preview,
      conflictChoices: converted,
    );
    return RecoveryApplyResult(
      applied: result.applied,
      unchanged: result.unchanged,
    );
  });

  PortableBackupService _backupService() => PortableBackupService(
    database: _database,
    studentId: studentId,
    synchronizationIntentSink: _RestoreOutboxIntentSink(this),
  );

  int _purgeExpiredTrash(DateTime nowUtc) {
    final rows = _database.select(
      '''SELECT * FROM trash WHERE student_id = ?
         AND permanently_deleted_at_utc IS NULL AND purge_after_utc <= ?
         ORDER BY purge_after_utc, id''',
      [studentId, _utc(nowUtc)],
    );
    final grouped = <String, List<Map<String, Object?>>>{};
    for (final row in rows) {
      final aggregateId = row['aggregate_mutation_id'];
      final key = aggregateId is String && aggregateId.isNotEmpty
          ? aggregateId
          : 'trash:${_text(row, 'id')}';
      grouped.putIfAbsent(key, () => []).add(row);
    }
    for (final group in grouped.values) {
      _purgeTrashGroup(group, nowUtc, _newRecoveryMutation(nowUtc));
    }
    return rows.length;
  }

  void _purgeTrashGroup(
    List<Map<String, Object?>> rows,
    DateTime deletedAtUtc,
    MutationToken firstMutation,
  ) {
    const purgeOrder = <String, int>{
      'reminder_state': 0,
      'clinical_session': 1,
      'historical_hours_entry': 1,
      'schedule_template': 1,
      'evaluation_plan': 2,
      'clinical_placement': 3,
    };
    final orderedRows = List<Map<String, Object?>>.of(rows)
      ..sort(
        (left, right) => (purgeOrder[_text(left, 'entity_type')] ?? 0)
            .compareTo(purgeOrder[_text(right, 'entity_type')] ?? 0),
      );
    final operationIds = <String>[];
    final manifest = <String, Object?>{};
    for (var index = 0; index < orderedRows.length; index++) {
      final row = orderedRows[index];
      final mutation = index == 0
          ? firstMutation
          : _newRecoveryMutation(deletedAtUtc);
      final snapshot = jsonDecode(_text(row, 'deleted_snapshot_json'));
      if (snapshot is! Map<String, dynamic> || snapshot['revision'] is! int) {
        throw const RecoveryException(
          RecoveryFailureKind.invariantViolation,
          'The Trash recovery snapshot is invalid.',
        );
      }
      manifest['${_text(row, 'entity_type')}:${_text(row, 'entity_id')}'] =
          (snapshot['revision'] as int) + 1;
      operationIds.add(mutation.operationId);
      _purgeTrashRow(row, deletedAtUtc, mutation);
    }
    final aggregateId = orderedRows.first['aggregate_mutation_id'];
    if (aggregateId is! String || aggregateId.isEmpty) {
      return;
    }
    final placeholders = List.filled(operationIds.length, '?').join(', ');
    _database.execute(
      '''UPDATE outbox_operations SET payload_json = json_set(
           payload_json,
           '\$.aggregate_mutation_id', ?,
           '\$.aggregate_root_id', ?,
           '\$.expected_member_manifest', json(?)
         )
         WHERE student_id = ? AND id IN ($placeholders)''',
      [
        _identifierGenerator.nextIdentifier(),
        _text(orderedRows.first, 'aggregate_root_id'),
        _canonicalJson(manifest),
        studentId,
        ...operationIds,
      ],
    );
  }

  void _purgeTrashRow(
    Map<String, Object?> row,
    DateTime deletedAtUtc,
    MutationToken mutation,
  ) {
    final entityType = _text(row, 'entity_type');
    final table = _recoveryTable(entityType);
    final entityId = _identifier(_text(row, 'entity_id'));
    try {
      final entityRows = _database.select(
        'SELECT revision, created_at_utc, deleted_at_utc FROM $table '
        'WHERE student_id = ? AND id = ? AND deleted_at_utc IS NOT NULL',
        [studentId, entityId],
      );
      if (entityRows.isEmpty) {
        throw const RecoveryException(
          RecoveryFailureKind.concurrentModification,
          'The tombstone changed before permanent deletion.',
        );
      }
      final entity = entityRows.single;
      final baseRevision = _int(entity, 'revision');
      final revision = baseRevision + 1;
      final payload = _canonicalJson({
        'schema_version': 1,
        'entity_type': entityType,
        'entity_id': entityId,
        'student_id': studentId,
        'revision': revision,
        'created_at_utc': _text(entity, 'created_at_utc'),
        'updated_at_utc': _utc(deletedAtUtc),
        'deleted_at_utc': _text(entity, 'deleted_at_utc'),
        'purged_at_utc': _utc(deletedAtUtc),
        'value': <String, Object?>{},
      });
      if (entityType == 'evaluation_plan') {
        _database.execute(
          'DELETE FROM evaluation_requirements WHERE student_id = ? '
          'AND evaluation_plan_id = ?',
          [studentId, entityId],
        );
      }
      if (entityType == 'clinical_placement') {
        _database.execute(
          'DELETE FROM placement_preceptors WHERE student_id = ? '
          'AND placement_id = ?',
          [studentId, entityId],
        );
      }
      _database.execute(
        'DELETE FROM $table WHERE student_id = ? AND id = ? '
        'AND deleted_at_utc IS NOT NULL',
        [studentId, entityId],
      );
      _database.execute('DELETE FROM trash WHERE student_id = ? AND id = ?', [
        studentId,
        _identifier(_text(row, 'id')),
      ]);
      _database.execute(
        '''INSERT INTO permanent_purge_markers
          (student_id, entity_type, entity_id, revision, purged_at_utc)
          VALUES (?, ?, ?, ?, ?)
          ON CONFLICT(student_id, entity_type, entity_id) DO UPDATE SET
            revision = max(revision, excluded.revision),
            purged_at_utc = max(purged_at_utc, excluded.purged_at_utc)''',
        [studentId, entityType, entityId, revision, _utc(deletedAtUtc)],
      );
      _database.execute(
        '''INSERT INTO outbox_operations
          (id, student_id, idempotency_key, entity_type, entity_id,
           operation_type, base_revision, payload_json, created_at_utc)
          VALUES (?, ?, ?, ?, ?, 'purge', ?, ?, ?)''',
        [
          mutation.operationId,
          studentId,
          mutation.idempotencyKey,
          entityType,
          entityId,
          baseRevision,
          payload,
          _utc(mutation.occurredAtUtc),
        ],
      );
    } on Object catch (error) {
      throw RecoveryException(
        RecoveryFailureKind.invariantViolation,
        'Related records prevent permanent deletion.',
        cause: error,
      );
    }
  }

  MutationToken _newRecoveryMutation(DateTime occurredAtUtc) => MutationToken(
    operationId: _identifierGenerator.nextIdentifier(),
    idempotencyKey: _identifierGenerator.nextIdentifier(),
    occurredAtUtc: occurredAtUtc,
  );

  String _recoveryTable(String entityType) => switch (entityType) {
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
    _ => throw const RecoveryException(
      RecoveryFailureKind.invariantViolation,
      'This type of Trash entry cannot be recovered.',
    ),
  };

  Map<String, Object?> _snapshotRow(String snapshotId, DateTime nowUtc) {
    _requireUtcRecovery(nowUtc);
    final rows = _database.select(
      'SELECT * FROM operational_recovery_snapshots '
      'WHERE student_id = ? AND id = ?',
      [studentId, _identifier(snapshotId)],
    );
    if (rows.isEmpty) {
      throw const RecoveryException(
        RecoveryFailureKind.notFound,
        'The recovery snapshot no longer exists.',
      );
    }
    final row = Map<String, Object?>.from(rows.single);
    if (!_dateTime(row, 'expires_at_utc').isAfter(nowUtc)) {
      _database.execute(
        'DELETE FROM operational_recovery_snapshots '
        'WHERE student_id = ? AND id = ?',
        [studentId, _identifier(snapshotId)],
      );
      throw const RecoveryException(
        RecoveryFailureKind.expired,
        'The recovery snapshot has expired.',
      );
    }
    return row;
  }

  /// Counts local mutations whose value is not safely represented by an
  /// acknowledged server operation. Delayed retries and unrecovered terminal
  /// rejections remain visible, while rejected audit rows with an identical
  /// replacement or a later acknowledged full snapshot do not falsely block
  /// device-copy removal.
  Future<({int count, DateTime? oldestAtUtc})> localRemovalPreview() =>
      _enqueue(() {
        _requireInitialized();
        final row = _database
            .select(
              '''SELECT count(*) AS pending_count,
                    min(pending.created_at_utc) AS oldest_at_utc
             FROM outbox_operations AS pending
             WHERE pending.student_id = ?
               AND pending.acknowledged_at_utc IS NULL
               AND (
                 pending.terminal_rejected_at_utc IS NULL
                 OR NOT EXISTS (
                   SELECT 1 FROM outbox_operations AS replacement
                   WHERE replacement.student_id = pending.student_id
                     AND replacement.id <> pending.id
                     AND replacement.entity_type = pending.entity_type
                     AND replacement.entity_id = pending.entity_id
                     AND replacement.acknowledged_at_utc IS NOT NULL
                     AND (
                       (
                         replacement.operation_type = pending.operation_type
                         AND replacement.base_revision = pending.base_revision
                         AND replacement.payload_json = pending.payload_json
                       )
                       OR (
                         replacement.created_at_utc >= pending.created_at_utc
                         AND CAST(json_extract(
                           replacement.payload_json, '\$.revision'
                         ) AS INTEGER) >= CAST(json_extract(
                           pending.payload_json, '\$.revision'
                         ) AS INTEGER)
                       )
                     )
                 )
               )''',
              [studentId],
            )
            .single;
        final oldest = row['oldest_at_utc'] as String?;
        return (
          count: row['pending_count'] as int,
          oldestAtUtc: oldest == null ? null : DateTime.parse(oldest).toUtc(),
        );
      });

  String get databasePath => _database.path;

  /// Waits behind all repository work, then closes the SQLCipher connection.
  /// The registry cannot be reused after this succeeds.
  Future<void> close() => _enqueue(() async {
    if (_closed) return;
    _initialized = false;
    await _database.close();
    _closed = true;
  });

  Future<R> _enqueue<R>(FutureOr<R> Function() action) {
    final completer = Completer<R>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await action());
      } on Object catch (error, stackTrace) {
        if (error is StateError &&
            error.toString().contains('local database is closed')) {
          completer.completeError(
            const RepositoryException(
              RepositoryFailureKind.closed,
              'The local repository database is closed.',
            ),
            stackTrace,
          );
        } else {
          completer.completeError(error, stackTrace);
        }
      }
    });
    return completer.future;
  }

  void _requireInitialized() {
    if (_closed) {
      throw const RepositoryException(
        RepositoryFailureKind.closed,
        'The local repository database is closed.',
      );
    }
    if (!_initialized) {
      throw const RepositoryException(
        RepositoryFailureKind.uninitialized,
        'Repository registry is not initialized.',
      );
    }
  }
}

void _requireUtcRecovery(DateTime value) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, 'time', 'must be UTC');
  }
}

OperationalSnapshotSummary _snapshotSummary(Map<String, Object?> row) =>
    OperationalSnapshotSummary(
      id: _identifier(_text(row, 'id')),
      snapshotDate: _text(row, 'snapshot_date'),
      createdAtUtc: _dateTime(row, 'created_at_utc'),
      expiresAtUtc: _dateTime(row, 'expires_at_utc'),
    );

OperationalRecoveryPreview _recoveryPreview(
  OperationalSnapshotSummary snapshot,
  PortableRestorePreview preview,
) => OperationalRecoveryPreview(
  snapshot: snapshot,
  items: preview.items
      .map(
        (item) => RecoveryMergeItem(
          identity: item.identity.stableValue,
          disposition: switch (item.disposition) {
            RestoreMergeDisposition.add => RecoveryMergeDisposition.add,
            RestoreMergeDisposition.keepLocal =>
              RecoveryMergeDisposition.keepCurrent,
            RestoreMergeDisposition.useBackup =>
              RecoveryMergeDisposition.useSnapshot,
            RestoreMergeDisposition.conflict =>
              RecoveryMergeDisposition.conflict,
          },
        ),
      )
      .toList(growable: false),
);

void _restoreTombstone(
  _Repositories repositories, {
  required String entityType,
  required String entityId,
  required MutationToken mutation,
}) {
  switch (entityType) {
    case 'work_shift':
      _restoreRecord(
        repositories.workShifts,
        repositories.registry.studentId,
        entityId,
        mutation,
      );
    case 'clinical_session':
      _restoreRecord(
        repositories.clinicalSessions,
        repositories.registry.studentId,
        entityId,
        mutation,
      );
    case 'protected_day':
      _restoreRecord(
        repositories.protectedDays,
        repositories.registry.studentId,
        entityId,
        mutation,
      );
    case 'schedule_template':
      _restoreRecord(
        repositories.scheduleTemplates,
        repositories.registry.studentId,
        entityId,
        mutation,
      );
    case 'preceptor':
      _restoreRecord(
        repositories.preceptors,
        repositories.registry.studentId,
        entityId,
        mutation,
      );
    case 'clinical_placement':
      _restoreRecord(
        repositories.clinicalPlacements,
        repositories.registry.studentId,
        entityId,
        mutation,
      );
    case 'historical_hours_entry':
      _restoreRecord(
        repositories.historicalHoursEntries,
        repositories.registry.studentId,
        entityId,
        mutation,
      );
    case 'evaluation_plan':
      _restoreRecord(
        repositories.evaluationPlans,
        repositories.registry.studentId,
        entityId,
        mutation,
      );
    case 'reminder_state':
      _restoreRecord(
        repositories.reminderStates,
        repositories.registry.studentId,
        entityId,
        mutation,
      );
    case 'academic_assignment':
      _restoreRecord(
        repositories.academicAssignments,
        repositories.registry.studentId,
        entityId,
        mutation,
      );
    case 'class_catalog_entry':
      _restoreRecord(
        repositories.classCatalogEntries,
        repositories.registry.studentId,
        entityId,
        mutation,
      );
    default:
      throw const RecoveryException(
        RecoveryFailureKind.invariantViolation,
        'This type of record cannot be restored.',
      );
  }
}

void _restoreRecord<T>(
  MutableRepository<T> repository,
  String studentId,
  String entityId,
  MutationToken mutation,
) {
  final record = repository.find(
    studentId: studentId,
    id: entityId,
    includeDeleted: true,
  );
  if (record == null || !record.isDeleted) {
    throw const RecoveryException(
      RecoveryFailureKind.concurrentModification,
      'The deleted record changed before it could be restored.',
    );
  }
  repository.put(
    studentId: studentId,
    value: record.value,
    expectedRevision: record.revision,
    mutation: mutation,
  );
}

const _restoreLocalOnlyTables = {'trash'};

final class _RestoreOutboxIntentSink
    implements RestoreSynchronizationIntentSink {
  _RestoreOutboxIntentSink(this.registry);

  final SqliteRepositoryRegistry registry;

  @override
  void recordFreshIntents(List<RestoreSynchronizationIntent> intents) {
    final targets = <String, _RestoreOutboxTarget>{};
    for (final intent in intents) {
      final target = _targetFor(intent);
      if (target != null) targets[target.stableValue] = target;
    }
    if (targets.isEmpty) return;

    final repositories = _Repositories(registry, writable: false);
    try {
      final ordered = targets.values.toList()
        ..sort((left, right) {
          final dependency = left.dependencyRank.compareTo(
            right.dependencyRank,
          );
          return dependency == 0
              ? left.stableValue.compareTo(right.stableValue)
              : dependency;
        });
      final batchStartedAtUtc = DateTime.now().toUtc();
      final operationIds = <String, String>{};
      for (var index = 0; index < ordered.length; index++) {
        operationIds[ordered[index].manifestKey] = _insertFreshIntent(
          ordered[index],
          repositories,
          batchStartedAtUtc.add(Duration(microseconds: index)),
        );
      }
      _annotateAggregateIntents(operationIds);
    } finally {
      repositories.close();
    }
  }

  _RestoreOutboxTarget? _targetFor(RestoreSynchronizationIntent intent) {
    final table = intent.identity.table;
    if (_restoreLocalOnlyTables.contains(table)) return null;
    if (table == 'reminder_state' &&
        !_belongsToPlacementAggregate(
          'reminder_state:${_text(intent.row, 'id')}',
        )) {
      return null;
    }
    if (table == 'placement_preceptors') {
      return _RestoreOutboxTarget(
        table: 'clinical_placements',
        entityType: 'clinical_placement',
        entityId: _identifier(_text(intent.row, 'placement_id')),
      );
    }
    if (table == 'evaluation_requirements') {
      return _RestoreOutboxTarget(
        table: 'evaluation_plans',
        entityType: 'evaluation_plan',
        entityId: _identifier(_text(intent.row, 'evaluation_plan_id')),
      );
    }
    final entityType = switch (table) {
      'student_profiles' => 'student_profile',
      'preceptors' => 'preceptor',
      'clinical_placements' => 'clinical_placement',
      'commitments' => switch (_text(intent.row, 'commitment_type')) {
        'work_shift' => 'work_shift',
        'clinical_session' => 'clinical_session',
        _ => throw const FormatException('Unknown commitment type.'),
      },
      'protected_days' => 'protected_day',
      'historical_hours_entries' => 'historical_hours_entry',
      'evaluation_plans' => 'evaluation_plan',
      'schedule_templates' => 'schedule_template',
      'academic_assignments' => 'academic_assignment',
      'class_catalog_entries' => 'class_catalog_entry',
      'settings' => 'settings',
      'reminder_state' => 'reminder_state',
      _ => throw StateError('Unmapped portable restore table: $table'),
    };
    return _RestoreOutboxTarget(
      table: table,
      entityType: entityType,
      entityId: _identifier(_text(intent.row, 'id')),
    );
  }

  bool _belongsToPlacementAggregate(String manifestKey) {
    final rows = registry._database.select(
      '''SELECT aggregate_manifest_json FROM trash WHERE student_id = ?
         AND aggregate_manifest_json IS NOT NULL''',
      [registry.studentId],
    );
    return rows.any((row) {
      final manifest = jsonDecode(_text(row, 'aggregate_manifest_json'));
      return manifest is Map<String, dynamic> &&
          manifest.containsKey(manifestKey);
    });
  }

  String _insertFreshIntent(
    _RestoreOutboxTarget target,
    _Repositories repositories,
    DateTime createdAtUtc,
  ) {
    final rows = registry._database.select(
      'SELECT * FROM ${target.table} WHERE student_id = ? AND id = ?',
      [registry.studentId, target.entityId],
    );
    if (rows.length != 1) {
      throw const RepositoryException(
        RepositoryFailureKind.corruptData,
        'A restored synchronization aggregate is incomplete.',
      );
    }
    final row = Map<String, Object?>.from(rows.single);
    final revision = _int(row, 'revision');
    final deletedAt = _nullableText(row, 'deleted_at_utc');
    final payload = _canonicalJson(<String, Object?>{
      'schema_version': 1,
      'entity_type': target.entityType,
      'entity_id': target.entityId,
      'student_id': registry.studentId,
      'revision': revision,
      'created_at_utc': _text(row, 'created_at_utc'),
      'updated_at_utc': _text(row, 'updated_at_utc'),
      'deleted_at_utc': deletedAt,
      'value': _restorePayloadValue(target, row, repositories),
    });
    final operationId = _identifier(
      registry._identifierGenerator.nextIdentifier(),
    );
    final idempotencyKey = _identifier(
      registry._identifierGenerator.nextIdentifier(),
    );
    registry._database.execute(
      '''INSERT INTO outbox_operations
        (id, student_id, idempotency_key, entity_type, entity_id,
         operation_type, base_revision, payload_json, created_at_utc)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        operationId,
        registry.studentId,
        idempotencyKey,
        target.entityType,
        target.entityId,
        deletedAt == null ? 'upsert' : 'delete',
        revision == 0 ? 0 : revision - 1,
        payload,
        _utc(createdAtUtc),
      ],
    );
    return operationId;
  }

  void _annotateAggregateIntents(Map<String, String> operationIds) {
    final roots = registry._database.select(
      '''SELECT * FROM trash WHERE student_id = ?
         AND aggregate_mutation_id IS NOT NULL
         AND aggregate_root_id = entity_id''',
      [registry.studentId],
    );
    for (final root in roots) {
      final manifest = jsonDecode(_text(root, 'aggregate_manifest_json'));
      if (manifest is! Map<String, dynamic>) continue;
      final matchingOperationIds = manifest.keys
          .whereType<String>()
          .map((key) => operationIds[key])
          .whereType<String>()
          .toList(growable: false);
      if (matchingOperationIds.isEmpty) continue;
      final placeholders = List.filled(
        matchingOperationIds.length,
        '?',
      ).join(', ');
      registry._database.execute(
        '''UPDATE outbox_operations SET payload_json = json_set(
             payload_json,
             '\$.aggregate_mutation_id', ?,
             '\$.aggregate_root_id', ?,
             '\$.expected_member_manifest', json(?),
             '\$.aggregate_recovery', json(?)
           )
           WHERE student_id = ? AND id IN ($placeholders)''',
        [
          _text(root, 'aggregate_mutation_id'),
          _text(root, 'aggregate_root_id'),
          _text(root, 'aggregate_manifest_json'),
          _text(root, 'aggregate_recovery_json'),
          registry.studentId,
          ...matchingOperationIds,
        ],
      );
    }
  }
}

final class _RestoreOutboxTarget {
  const _RestoreOutboxTarget({
    required this.table,
    required this.entityType,
    required this.entityId,
  });

  final String table;
  final String entityType;
  final String entityId;

  String get stableValue => '$entityType/$entityId';
  String get manifestKey => '$entityType:$entityId';

  int get dependencyRank => switch (entityType) {
    'student_profile' => 0,
    'preceptor' ||
    'protected_day' ||
    'work_shift' ||
    'class_catalog_entry' => 1,
    'academic_assignment' => 2,
    'clinical_placement' => 2,
    'evaluation_plan' ||
    'clinical_session' ||
    'historical_hours_entry' ||
    'schedule_template' => 3,
    'reminder_state' => 4,
    'settings' => 4,
    _ => throw StateError('Unmapped restore entity type: $entityType'),
  };
}

Map<String, Object?> _restorePayloadValue(
  _RestoreOutboxTarget target,
  Map<String, Object?> row,
  _Repositories repositories,
) => switch (target.table) {
  'student_profiles' => {
    'display_name': _text(row, 'display_name'),
    'program': _nullableText(row, 'program'),
    'account_identity': _nullableText(row, 'account_identity'),
    'avatar_base64': row['avatar_bytes'] == null
        ? null
        : base64Encode(row['avatar_bytes']! as List<int>),
  },
  'preceptors' => _encodePreceptor(_decodePreceptor(row)),
  'clinical_placements' => _encodeClinicalPlacementPayload(
    _decodeClinicalPlacement(repositories, row),
  ),
  'commitments' => switch (target.entityType) {
    'work_shift' => _encodeWorkShift(_decodeWorkShift(row)),
    'clinical_session' => _encodeClinicalSession(_decodeClinicalSession(row)),
    _ => throw const FormatException('Unknown commitment type.'),
  },
  'protected_days' => _encodeProtectedDay(
    repositories,
    _decodeProtectedDay(row),
  ),
  'historical_hours_entries' => _encodeHistoricalHours(
    _decodeHistoricalHours(row),
  ),
  'evaluation_plans' => _encodeEvaluationPlanPayload(
    repositories,
    _decodeEvaluationPlan(repositories, row),
  ),
  'schedule_templates' => _encodeScheduleTemplate(_decodeScheduleTemplate(row)),
  'academic_assignments' => _encodeAcademicAssignment(
    _decodeAcademicAssignment(row),
  ),
  'class_catalog_entries' => _encodeClassCatalogEntry(
    _decodeClassCatalogEntry(row),
  ),
  'settings' => {
    'week_start': _int(row, 'week_start'),
    'time_display': _text(row, 'time_display'),
    'theme': _text(row, 'theme'),
    'enhanced_accessibility': _int(row, 'enhanced_accessibility') == 1,
    'synchronization_mode': _text(row, 'synchronization_mode'),
    'notification_preferences_json': _text(
      row,
      'notification_preferences_json',
    ),
    'active_placement_id': _nullableText(row, 'active_placement_id'),
  },
  'reminder_state' => _encodeReminderState(_decodeReminderState(row)),
  _ => throw StateError('Unmapped restore payload table: ${target.table}'),
};

final class _Repositories
    implements
        SupportLocalWriteRepositories,
        ReminderLocalWriteRepositories,
        SynchronizationLocalWriteRepositories,
        AcademicAssignmentLocalWriteRepositories,
        ClassCatalogLocalWriteRepositories {
  _Repositories(this.registry, {required this.writable});

  final SqliteRepositoryRegistry registry;
  final bool writable;
  bool _active = true;

  @override
  late final workShifts = _EntityRepository<WorkShift>(
    this,
    table: 'commitments',
    entityType: 'work_shift',
    idOf: (value) => value.id,
    encode: _encodeWorkShift,
    decode: _decodeWorkShift,
    discriminatorSql: "commitment_type = 'work_shift'",
  );
  @override
  late final clinicalSessions = _EntityRepository<ClinicalSession>(
    this,
    table: 'commitments',
    entityType: 'clinical_session',
    idOf: (value) => value.id,
    encode: _encodeClinicalSession,
    decode: _decodeClinicalSession,
    discriminatorSql: "commitment_type = 'clinical_session'",
  );
  @override
  late final protectedDays = _EntityRepository<ProtectedDay>(
    this,
    table: 'protected_days',
    entityType: 'protected_day',
    idOf: (value) => value.id,
    encode: (value) => _encodeProtectedDay(this, value),
    decode: _decodeProtectedDay,
  );
  @override
  late final scheduleTemplates = _EntityRepository<ScheduleTemplate>(
    this,
    table: 'schedule_templates',
    entityType: 'schedule_template',
    idOf: (value) => value.id,
    encode: _encodeScheduleTemplate,
    decode: _decodeScheduleTemplate,
  );
  @override
  late final preceptors = _EntityRepository<Preceptor>(
    this,
    table: 'preceptors',
    entityType: 'preceptor',
    idOf: (value) => value.id,
    encode: _encodePreceptor,
    decode: _decodePreceptor,
  );
  @override
  late final clinicalPlacements = _ClinicalPlacementRepository(this);
  @override
  late final historicalHoursEntries = _EntityRepository<HistoricalHoursEntry>(
    this,
    table: 'historical_hours_entries',
    entityType: 'historical_hours_entry',
    idOf: (value) => value.id,
    encode: _encodeHistoricalHours,
    decode: _decodeHistoricalHours,
  );
  @override
  late final evaluationPlans = _EvaluationPlanRepository(this);
  @override
  late final outbox = _OutboxRepository(this);
  @override
  late final syncCursors = _SyncCursorRepository(this);
  @override
  late final synchronization = SqliteSynchronizationRepository(
    database: registry._database,
    identifiers: registry._identifierGenerator,
    studentId: registry.studentId,
  );
  @override
  late final activePlacementSelection = _ActivePlacementSelectionRepository(
    this,
  );
  @override
  late final studentProfile = _StudentProfileRepository(this);
  @override
  late final studentSettings = _StudentSettingsRepository(this);
  @override
  late final reminderStates = _EntityRepository<ReminderState>(
    this,
    table: 'reminder_state',
    entityType: 'reminder_state',
    idOf: (value) => value.id,
    encode: _encodeReminderState,
    decode: _decodeReminderState,
  );
  @override
  late final academicAssignments = _EntityRepository<AcademicAssignment>(
    this,
    table: 'academic_assignments',
    entityType: 'academic_assignment',
    idOf: (value) => value.id,
    encode: _encodeAcademicAssignment,
    decode: _decodeAcademicAssignment,
  );
  @override
  late final classCatalogEntries = _EntityRepository<ClassCatalogEntry>(
    this,
    table: 'class_catalog_entries',
    entityType: 'class_catalog_entry',
    idOf: (value) => value.id,
    encode: _encodeClassCatalogEntry,
    decode: _decodeClassCatalogEntry,
    payloadEncode: _encodeClassCatalogEntryPayload,
  );

  void requireWritable() {
    requireActive();
    if (!writable) {
      throw const RepositoryException(
        RepositoryFailureKind.uninitialized,
        'Writes require a mutation callback.',
      );
    }
  }

  void requireActive() {
    if (!_active) {
      throw const RepositoryException(
        RepositoryFailureKind.closed,
        'The repository callback has ended.',
      );
    }
  }

  void close() => _active = false;
}

final class _EntityRepository<T> implements MutableRepository<T> {
  _EntityRepository(
    this.repositories, {
    required this.table,
    required this.entityType,
    required this.idOf,
    required this.encode,
    required this.decode,
    this.discriminatorSql,
    this.afterWrite,
    _Encoder<T>? payloadEncode,
  }) : payloadEncode = payloadEncode ?? encode;

  final _Repositories repositories;
  final String table;
  final String entityType;
  final String Function(T) idOf;
  final _Encoder<T> encode;
  final _Decoder<T> decode;
  final String? discriminatorSql;
  final _AfterWrite<T>? afterWrite;
  final _Encoder<T> payloadEncode;

  ClinicalCalendarDatabase get db {
    repositories.requireActive();
    return repositories.registry._database;
  }

  String get owner {
    repositories.requireActive();
    return repositories.registry.studentId;
  }

  @override
  StoredDomainRecord<T>? find({
    required String studentId,
    required String id,
    bool includeDeleted = false,
  }) {
    _owner(studentId, owner);
    final normalizedId = _identifier(id);
    final rows = db.select(
      'SELECT * FROM $table WHERE student_id = ? AND id = ? '
      '${discriminatorSql == null ? '' : 'AND $discriminatorSql '}'
      '${includeDeleted ? '' : 'AND deleted_at_utc IS NULL'}',
      [owner, normalizedId],
    );
    if (rows.isEmpty) return null;
    return _record(rows.single);
  }

  @override
  List<StoredDomainRecord<T>> list({
    required String studentId,
    bool includeDeleted = false,
  }) {
    _owner(studentId, owner);
    final rows = db.select(
      'SELECT * FROM $table WHERE student_id = ? '
      '${discriminatorSql == null ? '' : 'AND $discriminatorSql '}'
      '${includeDeleted ? '' : 'AND deleted_at_utc IS NULL '}'
      'ORDER BY id',
      [owner],
    );
    return rows.map(_record).toList(growable: false);
  }

  @override
  MutationReceipt<T> put({
    required String studentId,
    required T value,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    repositories.requireWritable();
    _owner(studentId, owner);
    final id = _identifier(idOf(value));
    final purgeMarker = db.select(
      'SELECT 1 FROM permanent_purge_markers WHERE student_id = ? '
      'AND entity_type = ? AND entity_id = ?',
      [owner, entityType, id],
    );
    if (purgeMarker.isNotEmpty) {
      throw const RepositoryException(
        RepositoryFailureKind.notFound,
        'A permanently deleted identity cannot be reused.',
      );
    }
    final content = encode(value);
    final payloadContent = payloadEncode(value);
    if (_tryReplay(
      mutation,
      id: id,
      type: OutboxOperationType.upsert,
      baseRevision: expectedRevision,
      desiredContent: payloadContent,
    )) {
      return MutationReceipt(
        record: find(studentId: owner, id: id, includeDeleted: true)!,
        replayed: true,
      );
    }
    final existing = _row(id);
    final base = existing == null ? 0 : _int(existing, 'revision');
    final createdAt = existing == null
        ? mutation.occurredAtUtc
        : _dateTime(existing, 'created_at_utc');
    final revision = base + 1;
    final payload = _canonicalJson(<String, Object?>{
      'schema_version': 1,
      'entity_type': entityType,
      'entity_id': id,
      'student_id': owner,
      'revision': revision,
      'created_at_utc': _utc(createdAt),
      'updated_at_utc': _utc(mutation.occurredAtUtc),
      'deleted_at_utc': null,
      'value': payloadContent,
    });
    _revision(expectedRevision, base);
    final common = <String, Object?>{
      'id': id,
      'student_id': owner,
      'revision': revision,
      'created_at_utc': _utc(createdAt),
      'updated_at_utc': _utc(mutation.occurredAtUtc),
      'deleted_at_utc': null,
    }..addAll(content);
    _upsert(common);
    afterWrite?.call(value, mutation.occurredAtUtc);
    _resolveTrash(id, mutation.occurredAtUtc);
    _insertOutbox(mutation, id, OutboxOperationType.upsert, base, payload);
    return MutationReceipt(
      record: StoredDomainRecord<T>(
        value: value,
        studentId: owner,
        revision: revision,
        createdAtUtc: createdAt,
        updatedAtUtc: mutation.occurredAtUtc,
      ),
      replayed: false,
    );
  }

  @override
  MutationReceipt<T> tombstone({
    required String studentId,
    required String id,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    repositories.requireWritable();
    _owner(studentId, owner);
    final normalizedId = _identifier(id);
    final existing = _row(normalizedId);
    if (_tryReplay(
      mutation,
      id: normalizedId,
      type: OutboxOperationType.delete,
      baseRevision: expectedRevision,
    )) {
      return MutationReceipt(
        record: find(studentId: owner, id: normalizedId, includeDeleted: true)!,
        replayed: true,
      );
    }
    if (existing == null) {
      throw const RepositoryException(
        RepositoryFailureKind.notFound,
        'The record does not exist.',
      );
    }
    final base = _int(existing, 'revision');
    final value = decode(existing);
    final payload = _canonicalJson(<String, Object?>{
      'schema_version': 1,
      'entity_type': entityType,
      'entity_id': normalizedId,
      'student_id': owner,
      'revision': base + 1,
      'created_at_utc': _text(existing, 'created_at_utc'),
      'updated_at_utc': _utc(mutation.occurredAtUtc),
      'deleted_at_utc': _utc(mutation.occurredAtUtc),
      'value': payloadEncode(value),
    });
    _revision(expectedRevision, base);
    db.execute(
      'UPDATE $table SET revision = ?, updated_at_utc = ?, deleted_at_utc = ? '
      'WHERE student_id = ? AND id = ?',
      [
        base + 1,
        _utc(mutation.occurredAtUtc),
        _utc(mutation.occurredAtUtc),
        owner,
        normalizedId,
      ],
    );
    _putTrash(normalizedId, payload, mutation.occurredAtUtc);
    _insertOutbox(
      mutation,
      normalizedId,
      OutboxOperationType.delete,
      base,
      payload,
    );
    return MutationReceipt(
      record: find(studentId: owner, id: normalizedId, includeDeleted: true)!,
      replayed: false,
    );
  }

  Map<String, Object?>? _row(String id) {
    final collision = db.select('SELECT student_id FROM $table WHERE id = ?', [
      id,
    ]);
    if (collision.isNotEmpty &&
        _text(collision.single, 'student_id') != owner) {
      throw const RepositoryException(
        RepositoryFailureKind.ownershipMismatch,
        'The identifier belongs to a different Student.',
      );
    }
    if (collision.isNotEmpty && discriminatorSql != null) {
      final matching = db.select(
        'SELECT 1 FROM $table WHERE id = ? AND $discriminatorSql',
        [id],
      );
      if (matching.isEmpty) {
        throw const RepositoryException(
          RepositoryFailureKind.ownershipMismatch,
          'The identifier belongs to a different entity type.',
        );
      }
    }
    final rows = db.select(
      'SELECT * FROM $table WHERE student_id = ? AND id = ? '
      '${discriminatorSql == null ? '' : 'AND $discriminatorSql'}',
      [owner, id],
    );
    return rows.isEmpty ? null : Map<String, Object?>.from(rows.single);
  }

  StoredDomainRecord<T> _record(Map<String, Object?> row) {
    try {
      return StoredDomainRecord<T>(
        value: decode(row),
        studentId: _identifier(_text(row, 'student_id')),
        revision: _int(row, 'revision'),
        createdAtUtc: _dateTime(row, 'created_at_utc'),
        updatedAtUtc: _dateTime(row, 'updated_at_utc'),
        deletedAtUtc: _nullableDateTime(row, 'deleted_at_utc'),
      );
    } on RepositoryException {
      rethrow;
    } on Object {
      throw const RepositoryException(
        RepositoryFailureKind.corruptData,
        'A stored record is invalid or uses an unknown value.',
      );
    }
  }

  void _upsert(Map<String, Object?> values) {
    final columns = values.keys.toList(growable: false);
    final updates = columns
        .where((column) => column != 'id')
        .map((column) => '$column = excluded.$column')
        .join(', ');
    db.execute(
      'INSERT INTO $table (${columns.join(', ')}) '
      'VALUES (${List.filled(columns.length, '?').join(', ')}) '
      'ON CONFLICT(id) DO UPDATE SET $updates',
      columns.map((column) => values[column]).toList(growable: false),
    );
  }

  bool _tryReplay(
    MutationToken mutation, {
    required String id,
    required OutboxOperationType type,
    required int baseRevision,
    Map<String, Object?>? desiredContent,
  }) {
    final rows = db.select(
      'SELECT * FROM outbox_operations WHERE idempotency_key = ?',
      [mutation.idempotencyKey],
    );
    if (rows.isEmpty) {
      final operationCollision = db.select(
        'SELECT 1 FROM outbox_operations WHERE id = ?',
        [mutation.operationId],
      );
      if (operationCollision.isNotEmpty) {
        throw const RepositoryException(
          RepositoryFailureKind.idempotencyConflict,
          'The operation identifier was already used for another mutation.',
        );
      }
      return false;
    }
    final row = rows.single;
    Object? priorContent;
    try {
      final decoded = jsonDecode(_text(row, 'payload_json'));
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      priorContent = decoded['value'];
    } on Object {
      throw const RepositoryException(
        RepositoryFailureKind.corruptData,
        'A stored outbox payload is invalid.',
      );
    }
    final identical =
        _text(row, 'id') == mutation.operationId &&
        _text(row, 'student_id') == owner &&
        _text(row, 'entity_type') == entityType &&
        _text(row, 'entity_id') == id &&
        _text(row, 'operation_type') == _operation(type) &&
        _int(row, 'base_revision') == baseRevision &&
        _dateTime(row, 'created_at_utc') == mutation.occurredAtUtc &&
        (desiredContent == null ||
            _canonicalJson(priorContent) == _canonicalJson(desiredContent));
    if (!identical) {
      throw const RepositoryException(
        RepositoryFailureKind.idempotencyConflict,
        'The idempotency key was already used for a different mutation.',
      );
    }
    return true;
  }

  void _insertOutbox(
    MutationToken mutation,
    String id,
    OutboxOperationType type,
    int baseRevision,
    String payload,
  ) {
    _identifier(mutation.operationId);
    _identifier(mutation.idempotencyKey);
    db.execute(
      '''INSERT INTO outbox_operations
        (id, student_id, idempotency_key, entity_type, entity_id,
         operation_type, base_revision, payload_json, created_at_utc)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        mutation.operationId,
        owner,
        mutation.idempotencyKey,
        entityType,
        id,
        _operation(type),
        baseRevision,
        payload,
        _utc(mutation.occurredAtUtc),
      ],
    );
  }

  void _putTrash(String entityId, String snapshot, DateTime deletedAt) {
    final existing = db.select(
      'SELECT id, created_at_utc, revision FROM trash '
      'WHERE student_id = ? AND entity_type = ? AND entity_id = ?',
      [owner, entityType, entityId],
    );
    final id = existing.isEmpty
        ? _identifier(
            repositories.registry._identifierGenerator.nextIdentifier(),
          )
        : _identifier(_text(existing.single, 'id'));
    final created = existing.isEmpty
        ? deletedAt
        : _dateTime(existing.single, 'created_at_utc');
    final revision = existing.isEmpty
        ? 1
        : _int(existing.single, 'revision') + 1;
    db.execute(
      '''INSERT INTO trash
        (id, student_id, revision, created_at_utc, updated_at_utc, deleted_at_utc,
         entity_type, entity_id, deleted_snapshot_json, purge_after_utc,
         permanently_deleted_at_utc)
        VALUES (?, ?, ?, ?, ?, NULL, ?, ?, ?, ?, NULL)
        ON CONFLICT(student_id, entity_type, entity_id) DO UPDATE SET
          revision = excluded.revision, updated_at_utc = excluded.updated_at_utc,
          deleted_snapshot_json = excluded.deleted_snapshot_json,
          purge_after_utc = excluded.purge_after_utc,
          permanently_deleted_at_utc = NULL''',
      [
        id,
        owner,
        revision,
        _utc(created),
        _utc(deletedAt),
        entityType,
        entityId,
        snapshot,
        _utc(deletedAt.add(const Duration(days: 30))),
      ],
    );
  }

  void _resolveTrash(String entityId, DateTime restoredAt) {
    db.execute(
      'UPDATE trash SET revision = revision + 1, updated_at_utc = ?, '
      'deleted_at_utc = ?, permanently_deleted_at_utc = ? '
      'WHERE student_id = ? AND entity_type = ? AND entity_id = ? '
      'AND permanently_deleted_at_utc IS NULL',
      [
        _utc(restoredAt),
        _utc(restoredAt),
        _utc(restoredAt),
        owner,
        entityType,
        entityId,
      ],
    );
  }
}

String _identifier(String value) {
  final normalized = value.trim().toLowerCase();
  if (!_uuid.hasMatch(normalized)) {
    throw const RepositoryException(
      RepositoryFailureKind.corruptData,
      'A persistence identifier is not a UUID.',
    );
  }
  return normalized;
}

void _owner(String supplied, String expected) {
  if (_identifier(supplied) != expected) {
    throw const RepositoryException(
      RepositoryFailureKind.ownershipMismatch,
      'The repository is bound to a different Student.',
    );
  }
}

void _revision(int expected, int actual) {
  if (expected != actual) {
    throw const RepositoryException(
      RepositoryFailureKind.concurrentModification,
      'The expected revision does not match the stored record.',
    );
  }
}

String _utc(DateTime value) => value.toUtc().toIso8601String();
String _canonicalJson(Object? value) => jsonEncode(value);
String _operation(OutboxOperationType type) => switch (type) {
  OutboxOperationType.upsert => 'upsert',
  OutboxOperationType.delete => 'delete',
  OutboxOperationType.resolveConflict => 'resolve_conflict',
  OutboxOperationType.purge => 'purge',
};

String _text(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is! String) throw const FormatException();
  return value;
}

String? _nullableText(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value == null) return null;
  if (value is! String) throw const FormatException();
  return value;
}

int _int(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is! int) throw const FormatException();
  return value;
}

int? _nullableInt(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value == null) return null;
  if (value is! int) throw const FormatException();
  return value;
}

DateTime _dateTime(Map<String, Object?> row, String key) {
  final result = DateTime.parse(_text(row, key));
  if (!result.isUtc) throw const FormatException();
  return result;
}

DateTime? _nullableDateTime(Map<String, Object?> row, String key) =>
    row[key] == null ? null : _dateTime(row, key);

LocalDate _localDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) throw const FormatException();
  return LocalDate(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

LocalTime _localTime(int minutes) => LocalTime(minutes ~/ 60, minutes % 60);

Map<String, Object?> _intervalColumns(ZonedInterval value, String prefix) => {
  '${prefix}start_date': value.startDate.toString(),
  '${prefix}end_date': value.endDate.toString(),
  '${prefix}start_minutes': value.startTime.minutesSinceMidnight,
  '${prefix}end_minutes': value.endTime.minutesSinceMidnight,
  if (prefix == 'planned_') 'time_zone': value.timeZone.value,
  '${prefix}start_offset_minutes': value.startOffset.minutes,
  '${prefix}end_offset_minutes': value.endOffset.minutes,
  '${prefix}start_utc': _utc(value.startInstantUtc),
  '${prefix}end_utc': _utc(value.endInstantUtc),
};

ZonedInterval _interval(Map<String, Object?> row, String prefix) {
  final interval = ZonedInterval(
    startDate: _localDate(_text(row, '${prefix}start_date')),
    startTime: _localTime(_int(row, '${prefix}start_minutes')),
    endTime: _localTime(_int(row, '${prefix}end_minutes')),
    timeZone: TimeZoneId(_text(row, 'time_zone')),
    startOffset: UtcOffset.inMinutes(
      _int(row, '${prefix}start_offset_minutes'),
    ),
    endOffset: UtcOffset.inMinutes(_int(row, '${prefix}end_offset_minutes')),
  );
  if (_text(row, '${prefix}end_date') != interval.endDate.toString() ||
      _dateTime(row, '${prefix}start_utc') != interval.startInstantUtc ||
      _dateTime(row, '${prefix}end_utc') != interval.endInstantUtc) {
    throw const FormatException();
  }
  return interval;
}

Map<String, Object?> _encodeWorkShift(WorkShift value) => {
  'commitment_type': 'work_shift',
  'lifecycle_state': 'scheduled',
  'placement_id': null,
  'preceptor_id': null,
  ..._intervalColumns(value.plannedInterval, 'planned_'),
  'actual_start_date': null,
  'actual_end_date': null,
  'actual_start_minutes': null,
  'actual_end_minutes': null,
  'actual_start_offset_minutes': null,
  'actual_end_offset_minutes': null,
  'actual_start_utc': null,
  'actual_end_utc': null,
};

WorkShift _decodeWorkShift(Map<String, Object?> row) {
  if (_text(row, 'commitment_type') != 'work_shift') {
    throw const FormatException();
  }
  return WorkShift(
    id: _identifier(_text(row, 'id')),
    plannedInterval: _interval(row, 'planned_'),
  );
}

Map<String, Object?> _encodeClinicalSession(ClinicalSession value) {
  final actual = value.actualInterval;
  return {
    'commitment_type': 'clinical_session',
    'lifecycle_state': switch (value.state) {
      ClinicalSessionState.scheduled => 'scheduled',
      ClinicalSessionState.awaitingConfirmation => 'awaiting_confirmation',
      ClinicalSessionState.completed => 'completed',
      ClinicalSessionState.cancelled => 'cancelled',
      ClinicalSessionState.missed => 'missed',
    },
    'placement_id': _identifier(value.clinicalPlacementId),
    'preceptor_id': _identifier(value.preceptorId),
    ..._intervalColumns(value.plannedInterval, 'planned_'),
    if (actual != null)
      ..._intervalColumns(actual, 'actual_')
    else ...{
      'actual_start_date': null,
      'actual_end_date': null,
      'actual_start_minutes': null,
      'actual_end_minutes': null,
      'actual_start_offset_minutes': null,
      'actual_end_offset_minutes': null,
      'actual_start_utc': null,
      'actual_end_utc': null,
    },
  };
}

ClinicalSession _decodeClinicalSession(Map<String, Object?> row) {
  if (_text(row, 'commitment_type') != 'clinical_session') {
    throw const FormatException();
  }
  final state = switch (_text(row, 'lifecycle_state')) {
    'scheduled' => ClinicalSessionState.scheduled,
    'awaiting_confirmation' => ClinicalSessionState.awaitingConfirmation,
    'completed' => ClinicalSessionState.completed,
    'cancelled' => ClinicalSessionState.cancelled,
    'missed' => ClinicalSessionState.missed,
    _ => throw const FormatException(),
  };
  return ClinicalSession.restore(
    id: _identifier(_text(row, 'id')),
    clinicalPlacementId: _identifier(_text(row, 'placement_id')),
    preceptorId: _identifier(_text(row, 'preceptor_id')),
    plannedInterval: _interval(row, 'planned_'),
    state: state,
    actualInterval: row['actual_start_date'] == null
        ? null
        : _interval(row, 'actual_'),
  );
}

Map<String, Object?> _encodeProtectedDay(
  _Repositories repositories,
  ProtectedDay value,
) {
  final rows = repositories.registry._database.select(
    'SELECT week_start FROM settings WHERE student_id = ?',
    [repositories.registry.studentId],
  );
  final weekStart = rows.isEmpty
      ? DateTime.sunday
      : _int(rows.single, 'week_start');
  final weekday = value.date.asUtcCalendarDate.weekday;
  final daysSinceStart = (weekday - weekStart + 7) % 7;
  return {
    'local_date': value.date.toString(),
    'week_start_date': value.date.addDays(-daysSinceStart).toString(),
  };
}

ProtectedDay _decodeProtectedDay(Map<String, Object?> row) => ProtectedDay(
  id: _identifier(_text(row, 'id')),
  date: _localDate(_text(row, 'local_date')),
);

Map<String, Object?> _encodeScheduleTemplate(ScheduleTemplate value) => {
  'name': value.name,
  'commitment_type': switch (value.type) {
    ScheduleTemplateType.workShift => 'work_shift',
    ScheduleTemplateType.clinicalSession => 'clinical_session',
  },
  'start_minutes': value.startTime.minutesSinceMidnight,
  'end_minutes': value.endTime.minutesSinceMidnight,
  'placement_id': value.clinicalPlacementId == null
      ? null
      : _identifier(value.clinicalPlacementId!),
  'preceptor_id': value.preceptorId == null
      ? null
      : _identifier(value.preceptorId!),
};

ScheduleTemplate _decodeScheduleTemplate(Map<String, Object?> row) =>
    ScheduleTemplate(
      id: _identifier(_text(row, 'id')),
      name: _text(row, 'name'),
      type: switch (_text(row, 'commitment_type')) {
        'work_shift' => ScheduleTemplateType.workShift,
        'clinical_session' => ScheduleTemplateType.clinicalSession,
        _ => throw const FormatException(),
      },
      startTime: _localTime(_int(row, 'start_minutes')),
      endTime: _localTime(_int(row, 'end_minutes')),
      clinicalPlacementId: _nullableText(row, 'placement_id'),
      preceptorId: _nullableText(row, 'preceptor_id'),
    );

Map<String, Object?> _encodePreceptor(Preceptor value) => {
  'name': value.name,
  'organization_or_site': value.organizationOrSite,
  'phone': value.phone,
  'email': value.email,
  'scheduling_notes': value.schedulingNotes,
};

Preceptor _decodePreceptor(Map<String, Object?> row) => Preceptor(
  id: _identifier(_text(row, 'id')),
  name: _text(row, 'name'),
  organizationOrSite: _nullableText(row, 'organization_or_site'),
  phone: _nullableText(row, 'phone'),
  email: _nullableText(row, 'email'),
  schedulingNotes: _nullableText(row, 'scheduling_notes'),
);

Map<String, Object?> _encodeAcademicAssignment(AcademicAssignment value) => {
  'title': value.title,
  'course': value.course,
  'course_id': value.courseId,
  'due_date': value.dueDate.toString(),
  'status': value.status.name,
};

AcademicAssignment _decodeAcademicAssignment(Map<String, Object?> row) =>
    AcademicAssignment(
      id: _identifier(_text(row, 'id')),
      title: _text(row, 'title'),
      course: _text(row, 'course'),
      courseId: _nullableText(row, 'course_id'),
      dueDate: _localDate(_text(row, 'due_date')),
      status: AcademicAssignmentStatus.values.byName(_text(row, 'status')),
    );

Map<String, Object?> _encodeClassCatalogEntry(ClassCatalogEntry value) => {
  'name': value.name,
  'archived': value.isArchived ? 1 : 0,
};

Map<String, Object?> _encodeClassCatalogEntryPayload(ClassCatalogEntry value) =>
    {'name': value.name, 'archived': value.isArchived};

ClassCatalogEntry _decodeClassCatalogEntry(Map<String, Object?> row) =>
    ClassCatalogEntry(
      id: _identifier(_text(row, 'id')),
      name: _text(row, 'name'),
      isArchived: _int(row, 'archived') == 1,
    );

Map<String, Object?> _encodeReminderState(ReminderState value) => {
  'reminder_type': value.kind.name,
  'subject_entity_id': value.subjectEntityId,
  'scheduled_for_utc': _utc(value.scheduledForUtc),
  'snoozed_until_utc': value.snoozedUntilUtc == null
      ? null
      : _utc(value.snoozedUntilUtc!),
  'resolved_at_utc': value.resolvedAtUtc == null
      ? null
      : _utc(value.resolvedAtUtc!),
  'resolution_source': value.resolutionSource,
  'occurrence_key': value.occurrenceKey,
};

ReminderState _decodeReminderState(Map<String, Object?> row) => ReminderState(
  id: _identifier(_text(row, 'id')),
  occurrenceKey: _text(row, 'occurrence_key'),
  kind: ReminderKind.values.byName(_text(row, 'reminder_type')),
  subjectEntityId: _text(row, 'subject_entity_id'),
  scheduledForUtc: _dateTime(row, 'scheduled_for_utc'),
  snoozedUntilUtc: _nullableDateTime(row, 'snoozed_until_utc'),
  resolvedAtUtc: _nullableDateTime(row, 'resolved_at_utc'),
  resolutionSource: _nullableText(row, 'resolution_source'),
);

Map<String, Object?> _encodeHistoricalHours(HistoricalHoursEntry value) => {
  'placement_id': _identifier(value.clinicalPlacementId),
  'preceptor_id': value.preceptorId == null
      ? null
      : _identifier(value.preceptorId!),
  'completed_minutes': value.completedMinutes,
  'effective_date': value.effectiveDate.toString(),
  'note': value.note,
};

HistoricalHoursEntry _decodeHistoricalHours(Map<String, Object?> row) =>
    HistoricalHoursEntry(
      id: _identifier(_text(row, 'id')),
      clinicalPlacementId: _identifier(_text(row, 'placement_id')),
      completedMinutes: _int(row, 'completed_minutes'),
      effectiveDate: _localDate(_text(row, 'effective_date')),
      preceptorId: _nullableText(row, 'preceptor_id'),
      note: _nullableText(row, 'note'),
    );

final class _ClinicalPlacementRepository
    extends _EntityRepository<ClinicalPlacement> {
  _ClinicalPlacementRepository(super.repositories)
    : super(
        table: 'clinical_placements',
        entityType: 'clinical_placement',
        idOf: (value) => value.id,
        encode: _encodeClinicalPlacement,
        payloadEncode: _encodeClinicalPlacementPayload,
        decode: (row) => _decodeClinicalPlacement(repositories, row),
        afterWrite: (value, occurredAtUtc) =>
            _writePlacementAttachments(repositories, value, occurredAtUtc),
      );
}

Map<String, Object?> _encodeClinicalPlacement(ClinicalPlacement value) => {
  'name': value.name,
  'target_minutes': value.targetHours.minutes,
  'start_date': value.startDate.toString(),
  'completion_deadline': value.completionDeadline.toString(),
  'lifecycle_state': switch (value.state) {
    ClinicalPlacementState.active => 'active',
    ClinicalPlacementState.readyToComplete => 'ready_to_complete',
    ClinicalPlacementState.completed => 'completed',
  },
  'primary_preceptor_id': _identifier(value.primaryPreceptorId),
};

Map<String, Object?> _encodeClinicalPlacementPayload(ClinicalPlacement value) =>
    {
      'name': value.name,
      'target_minutes': value.targetHours.minutes,
      'start_date': value.startDate.toString(),
      'completion_deadline': value.completionDeadline.toString(),
      'lifecycle_state': switch (value.state) {
        ClinicalPlacementState.active => 'active',
        ClinicalPlacementState.readyToComplete => 'ready_to_complete',
        ClinicalPlacementState.completed => 'completed',
      },
      'primary_preceptor_id': _identifier(value.primaryPreceptorId),
      'attached_preceptor_ids':
          (value.attachedPreceptorIds.map(_identifier).toList()..sort()),
      'evaluation_plan_id': _identifier(value.evaluationPlanId),
    };

ClinicalPlacement _decodeClinicalPlacement(
  _Repositories repositories,
  Map<String, Object?> row,
) {
  final id = _identifier(_text(row, 'id'));
  final owner = repositories.registry.studentId;
  final attachmentRows = repositories.registry._database.select(
    'SELECT preceptor_id FROM placement_preceptors '
    'WHERE student_id = ? AND placement_id = ? ORDER BY preceptor_id',
    [owner, id],
  );
  final planRows = repositories.registry._database.select(
    'SELECT id FROM evaluation_plans '
    'WHERE student_id = ? AND placement_id = ? ORDER BY id',
    [owner, id],
  );
  if (attachmentRows.isEmpty || planRows.length != 1) {
    throw const RepositoryException(
      RepositoryFailureKind.corruptData,
      'A Clinical Placement aggregate is incomplete.',
    );
  }
  return ClinicalPlacement.restore(
    id: id,
    name: _text(row, 'name'),
    targetHours: TargetHours.fromMinutes(_int(row, 'target_minutes')),
    startDate: _localDate(_text(row, 'start_date')),
    completionDeadline: _localDate(_text(row, 'completion_deadline')),
    attachedPreceptorIds: attachmentRows.map(
      (attachment) => _identifier(_text(attachment, 'preceptor_id')),
    ),
    primaryPreceptorId: _identifier(_text(row, 'primary_preceptor_id')),
    evaluationPlanId: _identifier(_text(planRows.single, 'id')),
    state: switch (_text(row, 'lifecycle_state')) {
      'active' => ClinicalPlacementState.active,
      'ready_to_complete' => ClinicalPlacementState.readyToComplete,
      'completed' => ClinicalPlacementState.completed,
      _ => throw const FormatException(),
    },
  );
}

void _writePlacementAttachments(
  _Repositories repositories,
  ClinicalPlacement value,
  DateTime occurredAtUtc,
) {
  final db = repositories.registry._database;
  final owner = repositories.registry.studentId;
  final placementId = _identifier(value.id);
  final normalized = value.attachedPreceptorIds.map(_identifier).toSet();
  if (!normalized.contains(_identifier(value.primaryPreceptorId))) {
    throw const RepositoryException(
      RepositoryFailureKind.corruptData,
      'The Primary Preceptor attachment is missing.',
    );
  }
  final existing = db
      .select(
        'SELECT preceptor_id FROM placement_preceptors '
        'WHERE student_id = ? AND placement_id = ?',
        [owner, placementId],
      )
      .map((row) => _identifier(_text(row, 'preceptor_id')))
      .toSet();
  for (final preceptorId in normalized.toList()..sort()) {
    if (!existing.contains(preceptorId)) {
      db.execute(
        '''INSERT INTO placement_preceptors
        (placement_id, preceptor_id, student_id, attached_at_utc)
        VALUES (?, ?, ?, ?)''',
        [placementId, preceptorId, owner, _utc(occurredAtUtc)],
      );
    }
  }
  for (final removed in existing.difference(normalized)) {
    db.execute(
      'DELETE FROM placement_preceptors WHERE student_id = ? '
      'AND placement_id = ? AND preceptor_id = ?',
      [owner, placementId, removed],
    );
  }
}

final class _EvaluationPlanRepository
    extends _EntityRepository<EvaluationPlan> {
  _EvaluationPlanRepository(super.repositories)
    : super(
        table: 'evaluation_plans',
        entityType: 'evaluation_plan',
        idOf: (value) => value.id,
        encode: (value) => _encodeEvaluationPlan(repositories, value),
        payloadEncode: (value) =>
            _encodeEvaluationPlanPayload(repositories, value),
        decode: (row) => _decodeEvaluationPlan(repositories, row),
        afterWrite: (value, occurredAtUtc) =>
            _writeEvaluationRequirements(repositories, value, occurredAtUtc),
      );
}

Map<String, Object?> _encodeEvaluationPlanPayload(
  _Repositories repositories,
  EvaluationPlan value,
) => {
  'placement_id': _encodeEvaluationPlan(repositories, value)['placement_id'],
  'configuration': {
    'initial_self_assessment_required':
        value.configuration.initialSelfAssessmentRequired,
    'interim_review_cadence_minutes':
        value.configuration.interimReviewCadenceMinutes,
    'final_self_assessment_required':
        value.configuration.finalSelfAssessmentRequired,
    'final_placement_review_required':
        value.configuration.finalPlacementReviewRequired,
  },
  'requirements':
      (value.requirements.toList()..sort(
            (left, right) =>
                left.identity.stableValue.compareTo(right.identity.stableValue),
          ))
          .map(
            (requirement) => {
              'identity': requirement.identity.stableValue,
              'kind': _requirementType(requirement.identity.kind),
              'threshold_minutes': requirement.thresholdMinutes,
              'is_currently_required': requirement.isCurrentlyRequired,
              'primary_preceptor_id': requirement.primaryPreceptorId,
              'documentation': requirement.documentation == null
                  ? null
                  : {
                      'date_documented': requirement
                          .documentation!
                          .dateDocumented
                          .toString(),
                      'location': requirement.documentation!.location,
                      'reference_or_note':
                          requirement.documentation!.referenceOrNote,
                    },
            },
          )
          .toList(growable: false),
};

Map<String, Object?> _encodeEvaluationPlan(
  _Repositories repositories,
  EvaluationPlan value,
) {
  final placementRows = repositories.registry._database.select(
    'SELECT id FROM clinical_placements WHERE student_id = ? '
    'AND deleted_at_utc IS NULL ORDER BY id',
    [repositories.registry.studentId],
  );
  final matches = placementRows.where((row) {
    final id = _identifier(_text(row, 'id'));
    final plans = repositories.registry._database.select(
      'SELECT id FROM evaluation_plans WHERE student_id = ? AND placement_id = ?',
      [repositories.registry.studentId, id],
    );
    return plans.any((plan) => _text(plan, 'id') == value.id);
  }).toList();
  String placementId;
  if (matches.length == 1) {
    placementId = _identifier(_text(matches.single, 'id'));
  } else {
    // A new plan's inverse association is supplied by the Clinical Placement
    // payload already queued in this same transaction.
    final placementOutbox = repositories.registry._database.select(
      "SELECT entity_id, payload_json FROM outbox_operations "
      "WHERE student_id = ? AND entity_type = 'clinical_placement' "
      "AND operation_type = 'upsert' ORDER BY created_at_utc DESC",
      [repositories.registry.studentId],
    );
    final candidates = placementOutbox.where((row) {
      final payload = jsonDecode(_text(row, 'payload_json'));
      return payload is Map &&
          payload['value'] is Map &&
          (payload['value'] as Map)['evaluation_plan_id'] == value.id;
    }).toList();
    if (candidates.length != 1) {
      throw const RepositoryException(
        RepositoryFailureKind.notFound,
        'The Evaluation Plan Clinical Placement association was not found.',
      );
    }
    placementId = _identifier(_text(candidates.single, 'entity_id'));
  }
  final configuration = value.configuration;
  return {
    'placement_id': placementId,
    'interim_cadence_minutes': configuration.interimReviewCadenceMinutes,
    'initial_self_assessment_required':
        configuration.initialSelfAssessmentRequired ? 1 : 0,
    'final_self_assessment_required': configuration.finalSelfAssessmentRequired
        ? 1
        : 0,
    'final_placement_review_required':
        configuration.finalPlacementReviewRequired ? 1 : 0,
  };
}

EvaluationPlan _decodeEvaluationPlan(
  _Repositories repositories,
  Map<String, Object?> row,
) {
  final id = _identifier(_text(row, 'id'));
  final requirementRows = repositories.registry._database.select(
    'SELECT * FROM evaluation_requirements '
    'WHERE student_id = ? AND evaluation_plan_id = ? '
    'AND deleted_at_utc IS NULL ORDER BY requirement_key',
    [repositories.registry.studentId, id],
  );
  return EvaluationPlan.restore(
    id: id,
    configuration: EvaluationPlanConfiguration(
      initialSelfAssessmentRequired:
          _int(row, 'initial_self_assessment_required') == 1,
      interimReviewCadenceMinutes: _int(row, 'interim_cadence_minutes'),
      finalSelfAssessmentRequired:
          _int(row, 'final_self_assessment_required') == 1,
      finalPlacementReviewRequired:
          _int(row, 'final_placement_review_required') == 1,
    ),
    requirements: requirementRows.map((requirement) {
      final kind = _requirementKind(_text(requirement, 'requirement_type'));
      final documentationDate = _nullableText(requirement, 'documented_at_utc');
      final reference =
          _nullableText(requirement, 'documentation_reference') ??
          _nullableText(requirement, 'documentation_note');
      return EvaluationRequirement.restore(
        identity: EvaluationRequirementIdentity(
          evaluationPlanId: id,
          kind: kind,
          thresholdMinutes: _nullableInt(requirement, 'threshold_minutes'),
        ),
        isCurrentlyRequired: _int(requirement, 'is_currently_required') == 1,
        primaryPreceptorId: _nullableText(
          requirement,
          'documented_preceptor_id',
        ),
        documentation: documentationDate == null
            ? null
            : EvaluationDocumentation(
                dateDocumented: _localDate(documentationDate.substring(0, 10)),
                location: _text(requirement, 'documentation_location'),
                referenceOrNote: reference,
              ),
      );
    }),
  );
}

void _writeEvaluationRequirements(
  _Repositories repositories,
  EvaluationPlan value,
  DateTime occurredAtUtc,
) {
  final db = repositories.registry._database;
  final owner = repositories.registry.studentId;
  final planId = _identifier(value.id);
  final existing = db.select(
    'SELECT id, requirement_key, created_at_utc, revision '
    'FROM evaluation_requirements WHERE student_id = ? '
    'AND evaluation_plan_id = ?',
    [owner, planId],
  );
  final byKey = {
    for (final row in existing) _text(row, 'requirement_key'): row,
  };
  final retainedKeys = <String>{};
  for (final requirement in value.requirements) {
    final key = requirement.identity.stableValue;
    retainedKeys.add(key);
    final prior = byKey[key];
    final requirementId = prior == null
        ? _identifier(
            repositories.registry._identifierGenerator.nextIdentifier(),
          )
        : _identifier(_text(prior, 'id'));
    final createdAt = prior == null
        ? occurredAtUtc
        : _dateTime(prior, 'created_at_utc');
    final revision = prior == null ? 1 : _int(prior, 'revision') + 1;
    final documentation = requirement.documentation;
    final documentedAt = documentation == null
        ? null
        : _utc(documentation.dateDocumented.asUtcCalendarDate);
    db.execute(
      '''INSERT INTO evaluation_requirements
        (id, student_id, revision, created_at_utc, updated_at_utc,
         deleted_at_utc, evaluation_plan_id, requirement_key,
         requirement_type, threshold_minutes, boundary, status,
         documented_at_utc, documentation_location,
         documentation_reference, documentation_note,
         documented_preceptor_id, is_currently_required)
        VALUES (?, ?, ?, ?, ?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          revision = excluded.revision, updated_at_utc = excluded.updated_at_utc,
          deleted_at_utc = NULL, requirement_key = excluded.requirement_key,
          requirement_type = excluded.requirement_type,
          threshold_minutes = excluded.threshold_minutes,
          boundary = excluded.boundary, status = excluded.status,
          documented_at_utc = excluded.documented_at_utc,
          documentation_location = excluded.documentation_location,
          documentation_reference = excluded.documentation_reference,
          documentation_note = NULL,
          documented_preceptor_id = excluded.documented_preceptor_id,
          is_currently_required = excluded.is_currently_required''',
      [
        requirementId,
        owner,
        revision,
        _utc(createdAt),
        _utc(occurredAtUtc),
        planId,
        key,
        _requirementType(requirement.identity.kind),
        requirement.thresholdMinutes,
        _requirementBoundary(requirement.identity.kind),
        documentation == null ? 'not_due' : 'documented',
        documentedAt,
        documentation?.location,
        documentation?.referenceOrNote,
        requirement.primaryPreceptorId == null
            ? null
            : _identifier(requirement.primaryPreceptorId!),
        requirement.isCurrentlyRequired ? 1 : 0,
      ],
    );
  }
  for (final row in existing) {
    if (!retainedKeys.contains(_text(row, 'requirement_key'))) {
      db.execute(
        'UPDATE evaluation_requirements SET revision = revision + 1, '
        'updated_at_utc = ?, deleted_at_utc = ? WHERE id = ? '
        'AND deleted_at_utc IS NULL',
        [_utc(occurredAtUtc), _utc(occurredAtUtc), _text(row, 'id')],
      );
    }
  }
}

String _requirementType(EvaluationRequirementKind kind) => switch (kind) {
  EvaluationRequirementKind.initialSelfAssessment => 'initial_self_assessment',
  EvaluationRequirementKind.interimStudentReviewsPrimaryPreceptor =>
    'student_reviews_preceptor',
  EvaluationRequirementKind.interimPrimaryPreceptorReviewsStudent =>
    'preceptor_reviews_student',
  EvaluationRequirementKind.finalSelfAssessment => 'final_self_assessment',
  EvaluationRequirementKind.finalPlacementReview => 'final_placement_review',
};

EvaluationRequirementKind _requirementKind(String value) => switch (value) {
  'initial_self_assessment' => EvaluationRequirementKind.initialSelfAssessment,
  'student_reviews_preceptor' =>
    EvaluationRequirementKind.interimStudentReviewsPrimaryPreceptor,
  'preceptor_reviews_student' =>
    EvaluationRequirementKind.interimPrimaryPreceptorReviewsStudent,
  'final_self_assessment' => EvaluationRequirementKind.finalSelfAssessment,
  'final_placement_review' => EvaluationRequirementKind.finalPlacementReview,
  _ => throw const FormatException(),
};

String _requirementBoundary(EvaluationRequirementKind kind) => switch (kind) {
  EvaluationRequirementKind.initialSelfAssessment => 'beginning',
  EvaluationRequirementKind.interimStudentReviewsPrimaryPreceptor ||
  EvaluationRequirementKind.interimPrimaryPreceptorReviewsStudent => 'interim',
  EvaluationRequirementKind.finalSelfAssessment ||
  EvaluationRequirementKind.finalPlacementReview => 'end',
};

final class _OutboxRepository implements OutboxMaintenanceRepository {
  _OutboxRepository(this.repositories);
  final _Repositories repositories;

  @override
  List<OutboxOperation> pending({
    required String studentId,
    required DateTime asOfUtc,
    int limit = 100,
  }) {
    repositories.requireActive();
    _owner(studentId, repositories.registry.studentId);
    if (limit <= 0) return const [];
    final rows = repositories.registry._database.select(
      '''WITH eligible AS (
          SELECT *, first_value(operation_type) OVER (
            PARTITION BY student_id, entity_type, entity_id
            ORDER BY created_at_utc DESC, id DESC
          ) AS final_operation_type
          FROM outbox_operations
          WHERE student_id = ? AND acknowledged_at_utc IS NULL
          AND terminal_rejected_at_utc IS NULL
          AND (next_attempt_at_utc IS NULL OR next_attempt_at_utc <= ?)
        )
        SELECT * FROM eligible
        ORDER BY
          CASE
            WHEN final_operation_type = 'delete' THEN CASE entity_type
              WHEN 'evaluation_plan' THEN 0
              WHEN 'clinical_session' THEN 0
              WHEN 'historical_hours_entry' THEN 0
              WHEN 'settings' THEN 0
              WHEN 'reminder_state' THEN 0
              WHEN 'schedule_template' THEN 0
              WHEN 'clinical_placement' THEN 1
              WHEN 'preceptor' THEN 2
              WHEN 'protected_day' THEN 2
              WHEN 'work_shift' THEN 2
              WHEN 'student_profile' THEN 3
              ELSE 3
            END
            ELSE CASE entity_type
              WHEN 'student_profile' THEN 0
              WHEN 'preceptor' THEN 1
              WHEN 'protected_day' THEN 1
              WHEN 'work_shift' THEN 1
              WHEN 'clinical_placement' THEN 2
              WHEN 'evaluation_plan' THEN 3
              WHEN 'clinical_session' THEN 3
              WHEN 'historical_hours_entry' THEN 3
              WHEN 'schedule_template' THEN 3
              WHEN 'settings' THEN 4
              WHEN 'reminder_state' THEN 5
              ELSE 5
            END
          END,
          entity_type, entity_id,
          created_at_utc, id LIMIT ?''',
      [repositories.registry.studentId, _utc(asOfUtc), limit],
    );
    try {
      return rows.map(_decodeOutbox).toList(growable: false);
    } on Object catch (error) {
      throw RepositoryException(
        RepositoryFailureKind.corruptData,
        'A stored outbox operation is invalid.',
        cause: error,
      );
    }
  }

  @override
  void acknowledge({
    required String studentId,
    required String operationId,
    required int serverCursor,
    required DateTime acknowledgedAtUtc,
  }) {
    repositories.requireWritable();
    _owner(studentId, repositories.registry.studentId);
    final prior = _findOperation(operationId);
    final priorCursor = _nullableInt(prior, 'acknowledged_cursor');
    final priorAt = _nullableDateTime(prior, 'acknowledged_at_utc');
    if (priorCursor != null) {
      if (priorCursor == serverCursor && priorAt == acknowledgedAtUtc) return;
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'The outbox operation was already acknowledged differently.',
      );
    }
    repositories.registry._database.execute(
      'UPDATE outbox_operations SET acknowledged_cursor = ?, '
      'acknowledged_at_utc = ?, last_failure_code = NULL '
      'WHERE student_id = ? AND id = ?',
      [
        serverCursor,
        _utc(acknowledgedAtUtc),
        repositories.registry.studentId,
        _identifier(operationId),
      ],
    );
  }

  @override
  void recordFailedAttempt({
    required String studentId,
    required String operationId,
    required DateTime attemptedAtUtc,
    required DateTime nextAttemptAtUtc,
    required String failureCode,
  }) {
    repositories.requireWritable();
    _owner(studentId, repositories.registry.studentId);
    final prior = _findOperation(operationId);
    if (_nullableDateTime(prior, 'acknowledged_at_utc') != null) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'An acknowledged outbox operation cannot record a failure.',
      );
    }
    if (nextAttemptAtUtc.isBefore(attemptedAtUtc)) {
      throw ArgumentError.value(nextAttemptAtUtc, 'nextAttemptAtUtc');
    }
    repositories.registry._database.execute(
      'UPDATE outbox_operations SET attempt_count = attempt_count + 1, '
      'next_attempt_at_utc = ?, last_failure_code = ? '
      'WHERE student_id = ? AND id = ? AND acknowledged_at_utc IS NULL',
      [
        _utc(nextAttemptAtUtc),
        failureCode,
        repositories.registry.studentId,
        _identifier(operationId),
      ],
    );
  }

  Map<String, Object?> _findOperation(String operationId) {
    final rows = repositories.registry._database.select(
      'SELECT * FROM outbox_operations WHERE student_id = ? AND id = ?',
      [repositories.registry.studentId, _identifier(operationId)],
    );
    if (rows.isEmpty) {
      throw const RepositoryException(
        RepositoryFailureKind.notFound,
        'The outbox operation does not exist.',
      );
    }
    return Map<String, Object?>.from(rows.single);
  }
}

OutboxOperation _decodeOutbox(Map<String, Object?> row) => OutboxOperation(
  mutation: MutationToken(
    operationId: _identifier(_text(row, 'id')),
    idempotencyKey: _identifier(_text(row, 'idempotency_key')),
    occurredAtUtc: _dateTime(row, 'created_at_utc'),
  ),
  studentId: _identifier(_text(row, 'student_id')),
  entityType: _text(row, 'entity_type'),
  entityId: _identifier(_text(row, 'entity_id')),
  type: switch (_text(row, 'operation_type')) {
    'upsert' => OutboxOperationType.upsert,
    'delete' => OutboxOperationType.delete,
    'resolve_conflict' => OutboxOperationType.resolveConflict,
    'purge' => OutboxOperationType.purge,
    _ => throw const FormatException(),
  },
  baseRevision: _int(row, 'base_revision'),
  payloadJson: _text(row, 'payload_json'),
  attemptCount: _int(row, 'attempt_count'),
  nextAttemptAtUtc: _nullableDateTime(row, 'next_attempt_at_utc'),
  acknowledgedCursor: _nullableInt(row, 'acknowledged_cursor'),
  acknowledgedAtUtc: _nullableDateTime(row, 'acknowledged_at_utc'),
  lastFailureCode: _nullableText(row, 'last_failure_code'),
  terminalRejectionCode: _nullableText(row, 'terminal_rejection_code'),
  terminalRejectedAtUtc: _nullableDateTime(row, 'terminal_rejected_at_utc'),
);

final class _SyncCursorRepository implements SyncCursorRepository {
  _SyncCursorRepository(this.repositories);
  final _Repositories repositories;

  @override
  SyncCursor? find({required String studentId, required String remoteScope}) {
    repositories.requireActive();
    _owner(studentId, repositories.registry.studentId);
    final rows = repositories.registry._database.select(
      'SELECT * FROM sync_cursors WHERE student_id = ? AND remote_scope = ?',
      [repositories.registry.studentId, remoteScope],
    );
    if (rows.isEmpty) return null;
    try {
      final row = rows.single;
      return SyncCursor(
        studentId: _identifier(_text(row, 'student_id')),
        remoteScope: _text(row, 'remote_scope'),
        serverCursor: _int(row, 'server_cursor'),
        updatedAtUtc: _dateTime(row, 'updated_at_utc'),
      );
    } on Object catch (error) {
      throw RepositoryException(
        RepositoryFailureKind.corruptData,
        'A stored synchronization cursor is invalid.',
        cause: error,
      );
    }
  }

  @override
  void put(SyncCursor cursor) {
    repositories.requireWritable();
    _owner(cursor.studentId, repositories.registry.studentId);
    final prior = find(
      studentId: cursor.studentId,
      remoteScope: cursor.remoteScope,
    );
    if (prior != null && cursor.serverCursor < prior.serverCursor) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'A synchronization cursor cannot move backwards.',
      );
    }
    if (prior != null &&
        cursor.serverCursor == prior.serverCursor &&
        cursor.updatedAtUtc == prior.updatedAtUtc) {
      return;
    }
    repositories.registry._database.execute(
      '''INSERT INTO sync_cursors
        (student_id, remote_scope, server_cursor, updated_at_utc)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(student_id, remote_scope) DO UPDATE SET
          server_cursor = excluded.server_cursor,
          updated_at_utc = excluded.updated_at_utc''',
      [
        repositories.registry.studentId,
        cursor.remoteScope,
        cursor.serverCursor,
        _utc(cursor.updatedAtUtc),
      ],
    );
  }
}

final class _ActivePlacementSelectionRepository
    implements ActivePlacementSelectionRepository {
  _ActivePlacementSelectionRepository(this.repositories);

  final _Repositories repositories;

  ClinicalCalendarDatabase get _database => repositories.registry._database;
  String get _studentId => repositories.registry.studentId;

  @override
  StoredDomainRecord<String?>? find({required String studentId}) {
    repositories.requireActive();
    _ownerCheck(studentId);
    final rows = _database.select(
      'SELECT id, student_id, revision, created_at_utc, updated_at_utc, '
      'deleted_at_utc, active_placement_id FROM settings '
      'WHERE student_id = ?',
      [_studentId],
    );
    if (rows.isEmpty) return null;
    try {
      final row = rows.single;
      final activeId = _nullableText(row, 'active_placement_id');
      return StoredDomainRecord<String?>(
        value: activeId == null ? null : _identifier(activeId),
        studentId: _identifier(_text(row, 'student_id')),
        revision: _int(row, 'revision'),
        createdAtUtc: _dateTime(row, 'created_at_utc'),
        updatedAtUtc: _dateTime(row, 'updated_at_utc'),
        deletedAtUtc: _nullableDateTime(row, 'deleted_at_utc'),
      );
    } on RepositoryException {
      rethrow;
    } on Object {
      throw const RepositoryException(
        RepositoryFailureKind.corruptData,
        'The stored active Clinical Placement selection is invalid.',
      );
    }
  }

  @override
  MutationReceipt<String?> put({
    required String studentId,
    required String? clinicalPlacementId,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    repositories.requireWritable();
    _ownerCheck(studentId);
    final activeId = clinicalPlacementId == null
        ? null
        : _identifier(clinicalPlacementId);
    if (activeId != null) {
      final placement = _database.select(
        'SELECT 1 FROM clinical_placements WHERE student_id = ? AND id = ? '
        'AND deleted_at_utc IS NULL',
        [_studentId, activeId],
      );
      if (placement.isEmpty) {
        throw const RepositoryException(
          RepositoryFailureKind.notFound,
          'The selected Clinical Placement does not exist.',
        );
      }
    }

    final existingRows = _database.select(
      'SELECT * FROM settings WHERE student_id = ?',
      [_studentId],
    );
    final existing = existingRows.isEmpty ? null : existingRows.single;
    final settingsId = existing == null
        ? _identifier(_studentId)
        : _identifier(_text(existing, 'id'));
    if (_isReplay(
      mutation: mutation,
      settingsId: settingsId,
      activeId: activeId,
      expectedRevision: expectedRevision,
    )) {
      return MutationReceipt<String?>(
        record: find(studentId: _studentId)!,
        replayed: true,
      );
    }

    final baseRevision = existing == null ? 0 : _int(existing, 'revision');
    _revision(expectedRevision, baseRevision);
    final createdAt = existing == null
        ? mutation.occurredAtUtc
        : _dateTime(existing, 'created_at_utc');
    final revision = expectedRevision + 1;
    final weekStart = existing == null
        ? DateTime.sunday
        : _int(existing, 'week_start');
    final timeDisplay = existing == null
        ? 'military'
        : _text(existing, 'time_display');
    final theme = existing == null
        ? StudentSettings.graphiteThemeId
        : _normalizeThemeId(_text(existing, 'theme'));
    final enhancedAccessibility = existing == null
        ? 0
        : _int(existing, 'enhanced_accessibility');
    final synchronizationMode = existing == null
        ? 'enabled'
        : _text(existing, 'synchronization_mode');
    final notificationPreferences = existing == null
        ? '{}'
        : _text(existing, 'notification_preferences_json');
    final valuePayload = <String, Object?>{
      'week_start': weekStart,
      'time_display': timeDisplay,
      'theme': theme,
      'enhanced_accessibility': enhancedAccessibility == 1,
      'synchronization_mode': synchronizationMode,
      'notification_preferences_json': notificationPreferences,
      'active_placement_id': activeId,
    };
    final payload = _canonicalJson(<String, Object?>{
      'schema_version': 1,
      'entity_type': 'settings',
      'entity_id': settingsId,
      'student_id': _studentId,
      'revision': revision,
      'created_at_utc': _utc(createdAt),
      'updated_at_utc': _utc(mutation.occurredAtUtc),
      'deleted_at_utc': null,
      'value': valuePayload,
    });
    _database.execute(
      '''INSERT INTO settings
        (id, student_id, revision, created_at_utc, updated_at_utc,
         deleted_at_utc, week_start, time_display, theme,
         enhanced_accessibility,
         synchronization_mode, notification_preferences_json,
         active_placement_id)
        VALUES (?, ?, ?, ?, ?, NULL, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(student_id) DO UPDATE SET
          revision = excluded.revision,
          updated_at_utc = excluded.updated_at_utc,
          deleted_at_utc = NULL,
          week_start = excluded.week_start,
          time_display = excluded.time_display,
          theme = excluded.theme,
          enhanced_accessibility = excluded.enhanced_accessibility,
          synchronization_mode = excluded.synchronization_mode,
          notification_preferences_json = excluded.notification_preferences_json,
          active_placement_id = excluded.active_placement_id''',
      [
        settingsId,
        _studentId,
        revision,
        _utc(createdAt),
        _utc(mutation.occurredAtUtc),
        weekStart,
        timeDisplay,
        theme,
        enhancedAccessibility,
        synchronizationMode,
        notificationPreferences,
        activeId,
      ],
    );
    _database.execute(
      '''INSERT INTO outbox_operations
        (id, student_id, idempotency_key, entity_type, entity_id,
         operation_type, base_revision, payload_json, created_at_utc)
        VALUES (?, ?, ?, 'settings', ?, 'upsert', ?, ?, ?)''',
      [
        mutation.operationId,
        _studentId,
        mutation.idempotencyKey,
        settingsId,
        baseRevision,
        payload,
        _utc(mutation.occurredAtUtc),
      ],
    );
    return MutationReceipt<String?>(
      record: StoredDomainRecord<String?>(
        value: activeId,
        studentId: _studentId,
        revision: revision,
        createdAtUtc: createdAt,
        updatedAtUtc: mutation.occurredAtUtc,
      ),
      replayed: false,
    );
  }

  bool _isReplay({
    required MutationToken mutation,
    required String settingsId,
    required String? activeId,
    required int expectedRevision,
  }) {
    final rows = _database.select(
      'SELECT * FROM outbox_operations WHERE idempotency_key = ?',
      [mutation.idempotencyKey],
    );
    if (rows.isEmpty) return false;
    final row = rows.single;
    Object? storedActiveId;
    try {
      final payload = jsonDecode(_text(row, 'payload_json'));
      if (payload is! Map<String, dynamic> ||
          payload['value'] is! Map<String, dynamic>) {
        throw const FormatException();
      }
      storedActiveId =
          (payload['value'] as Map<String, dynamic>)['active_placement_id'];
    } on Object {
      throw const RepositoryException(
        RepositoryFailureKind.corruptData,
        'The stored settings outbox payload is invalid.',
      );
    }
    final identical =
        _text(row, 'id') == mutation.operationId &&
        _text(row, 'student_id') == _studentId &&
        _text(row, 'entity_type') == 'settings' &&
        _text(row, 'entity_id') == settingsId &&
        _text(row, 'operation_type') == 'upsert' &&
        _int(row, 'base_revision') == expectedRevision &&
        _dateTime(row, 'created_at_utc') == mutation.occurredAtUtc &&
        storedActiveId == activeId;
    if (!identical) {
      throw const RepositoryException(
        RepositoryFailureKind.idempotencyConflict,
        'The idempotency key was already used for a different mutation.',
      );
    }
    return true;
  }

  void _ownerCheck(String studentId) => _owner(studentId, _studentId);
}

final class _StudentProfileRepository implements StudentProfileRepository {
  _StudentProfileRepository(this.repositories);

  final _Repositories repositories;

  ClinicalCalendarDatabase get _database => repositories.registry._database;
  String get _studentId => repositories.registry.studentId;

  @override
  StoredDomainRecord<StudentProfile>? find({required String studentId}) {
    repositories.requireActive();
    _owner(studentId, _studentId);
    final rows = _database.select(
      'SELECT * FROM student_profiles WHERE student_id = ?',
      [_studentId],
    );
    if (rows.isEmpty) return null;
    try {
      final row = rows.single;
      final avatar = row['avatar_bytes'];
      return StoredDomainRecord<StudentProfile>(
        value: StudentProfile(
          id: _identifier(_text(row, 'id')),
          displayName: _text(row, 'display_name'),
          program: _nullableText(row, 'program'),
          accountIdentity: _nullableText(row, 'account_identity'),
          avatarBytes: avatar == null ? null : List<int>.from(avatar as List),
        ),
        studentId: _identifier(_text(row, 'student_id')),
        revision: _int(row, 'revision'),
        createdAtUtc: _dateTime(row, 'created_at_utc'),
        updatedAtUtc: _dateTime(row, 'updated_at_utc'),
        deletedAtUtc: _nullableDateTime(row, 'deleted_at_utc'),
      );
    } on RepositoryException {
      rethrow;
    } on Object catch (error) {
      throw RepositoryException(
        RepositoryFailureKind.corruptData,
        'The stored Student Profile is invalid.',
        cause: error,
      );
    }
  }

  @override
  MutationReceipt<StudentProfile> put({
    required String studentId,
    required StudentProfile profile,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    repositories.requireWritable();
    _owner(studentId, _studentId);
    final existing = _database.select(
      'SELECT * FROM student_profiles WHERE student_id = ?',
      [_studentId],
    );
    if (existing.isEmpty) {
      throw const RepositoryException(
        RepositoryFailureKind.notFound,
        'The Student Profile does not exist.',
      );
    }
    final row = existing.single;
    final profileId = _identifier(_text(row, 'id'));
    if (_identifier(profile.id) != profileId) {
      throw const RepositoryException(
        RepositoryFailureKind.ownershipMismatch,
        'The Student Profile identifier does not match this Student.',
      );
    }
    final baseRevision = _int(row, 'revision');
    final revision = expectedRevision + 1;
    final createdAt = _dateTime(row, 'created_at_utc');
    final valuePayload = <String, Object?>{
      'display_name': profile.displayName,
      'program': profile.program,
      'account_identity': profile.accountIdentity,
      'avatar_base64': profile.avatarBytes == null
          ? null
          : base64Encode(profile.avatarBytes!),
    };
    final payload = _canonicalJson(<String, Object?>{
      'schema_version': 1,
      'entity_type': 'student_profile',
      'entity_id': profileId,
      'student_id': _studentId,
      'revision': revision,
      'created_at_utc': _utc(createdAt),
      'updated_at_utc': _utc(mutation.occurredAtUtc),
      'deleted_at_utc': null,
      'value': valuePayload,
    });
    if (_supportReplay(
      database: _database,
      mutation: mutation,
      studentId: _studentId,
      entityType: 'student_profile',
      entityId: profileId,
      expectedRevision: expectedRevision,
      payload: payload,
    )) {
      return MutationReceipt(
        record: find(studentId: _studentId)!,
        replayed: true,
      );
    }
    _revision(expectedRevision, baseRevision);
    _database.execute(
      '''UPDATE student_profiles SET revision = ?, updated_at_utc = ?,
        deleted_at_utc = NULL, display_name = ?, avatar_bytes = ?, program = ?,
        account_identity = ? WHERE student_id = ?''',
      [
        revision,
        _utc(mutation.occurredAtUtc),
        profile.displayName,
        profile.avatarBytes,
        profile.program,
        profile.accountIdentity,
        _studentId,
      ],
    );
    _insertSupportOutbox(
      database: _database,
      mutation: mutation,
      studentId: _studentId,
      entityType: 'student_profile',
      entityId: profileId,
      baseRevision: baseRevision,
      payload: payload,
    );
    return MutationReceipt(
      record: StoredDomainRecord(
        value: profile,
        studentId: _studentId,
        revision: revision,
        createdAtUtc: createdAt,
        updatedAtUtc: mutation.occurredAtUtc,
      ),
      replayed: false,
    );
  }
}

final class _StudentSettingsRepository implements StudentSettingsRepository {
  _StudentSettingsRepository(this.repositories);

  final _Repositories repositories;

  ClinicalCalendarDatabase get _database => repositories.registry._database;
  String get _studentId => repositories.registry.studentId;

  @override
  StoredDomainRecord<StudentSettings>? find({required String studentId}) {
    repositories.requireActive();
    _owner(studentId, _studentId);
    final rows = _database.select(
      'SELECT * FROM settings WHERE student_id = ?',
      [_studentId],
    );
    if (rows.isEmpty) return null;
    try {
      final row = rows.single;
      final notificationJson = jsonDecode(
        _text(row, 'notification_preferences_json'),
      );
      if (notificationJson is! Map<String, dynamic>) {
        throw const FormatException();
      }
      return StoredDomainRecord<StudentSettings>(
        value: StudentSettings(
          weekStart: _int(row, 'week_start'),
          timeDisplay: switch (_text(row, 'time_display')) {
            'military' => TimeDisplayPreference.military,
            'twelve_hour' => TimeDisplayPreference.twelveHour,
            _ => throw const FormatException(),
          },
          themeId: _normalizeThemeId(_text(row, 'theme')),
          enhancedAccessibility: _int(row, 'enhanced_accessibility') == 1,
          synchronization: switch (_text(row, 'synchronization_mode')) {
            'enabled' => SynchronizationPreference.enabled,
            'paused' => SynchronizationPreference.paused,
            _ => throw const FormatException(),
          },
          notifications: NotificationPreferences.fromJson(notificationJson),
        ),
        studentId: _identifier(_text(row, 'student_id')),
        revision: _int(row, 'revision'),
        createdAtUtc: _dateTime(row, 'created_at_utc'),
        updatedAtUtc: _dateTime(row, 'updated_at_utc'),
        deletedAtUtc: _nullableDateTime(row, 'deleted_at_utc'),
      );
    } on RepositoryException {
      rethrow;
    } on Object catch (error) {
      throw RepositoryException(
        RepositoryFailureKind.corruptData,
        'The stored Student Settings are invalid.',
        cause: error,
      );
    }
  }

  @override
  MutationReceipt<StudentSettings> put({
    required String studentId,
    required StudentSettings settings,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    repositories.requireWritable();
    _owner(studentId, _studentId);
    final rows = _database.select(
      'SELECT * FROM settings WHERE student_id = ?',
      [_studentId],
    );
    final existing = rows.isEmpty ? null : rows.single;
    final settingsId = existing == null
        ? _identifier(_studentId)
        : _identifier(_text(existing, 'id'));
    final baseRevision = existing == null ? 0 : _int(existing, 'revision');
    final revision = expectedRevision + 1;
    final createdAt = existing == null
        ? mutation.occurredAtUtc
        : _dateTime(existing, 'created_at_utc');
    final activePlacementId = existing == null
        ? null
        : _nullableText(existing, 'active_placement_id');
    final notificationJson = _canonicalJson(settings.notifications.toJson());
    final valuePayload = <String, Object?>{
      'week_start': settings.weekStart,
      'time_display': _timeDisplay(settings.timeDisplay),
      'theme': settings.themeId,
      'enhanced_accessibility': settings.enhancedAccessibility,
      'synchronization_mode': _synchronization(settings.synchronization),
      'notification_preferences_json': notificationJson,
      'active_placement_id': activePlacementId,
    };
    final payload = _canonicalJson(<String, Object?>{
      'schema_version': 1,
      'entity_type': 'settings',
      'entity_id': settingsId,
      'student_id': _studentId,
      'revision': revision,
      'created_at_utc': _utc(createdAt),
      'updated_at_utc': _utc(mutation.occurredAtUtc),
      'deleted_at_utc': null,
      'value': valuePayload,
    });
    if (_supportReplay(
      database: _database,
      mutation: mutation,
      studentId: _studentId,
      entityType: 'settings',
      entityId: settingsId,
      expectedRevision: expectedRevision,
      payload: payload,
    )) {
      return MutationReceipt(
        record: find(studentId: _studentId)!,
        replayed: true,
      );
    }
    _revision(expectedRevision, baseRevision);
    _database.execute(
      '''INSERT INTO settings
        (id, student_id, revision, created_at_utc, updated_at_utc,
         deleted_at_utc, week_start, time_display, theme,
         enhanced_accessibility,
         synchronization_mode, notification_preferences_json,
         active_placement_id)
        VALUES (?, ?, ?, ?, ?, NULL, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(student_id) DO UPDATE SET
          revision = excluded.revision,
          updated_at_utc = excluded.updated_at_utc,
          deleted_at_utc = NULL,
          week_start = excluded.week_start,
          time_display = excluded.time_display,
          theme = excluded.theme,
          enhanced_accessibility = excluded.enhanced_accessibility,
          synchronization_mode = excluded.synchronization_mode,
          notification_preferences_json = excluded.notification_preferences_json,
          active_placement_id = excluded.active_placement_id''',
      [
        settingsId,
        _studentId,
        revision,
        _utc(createdAt),
        _utc(mutation.occurredAtUtc),
        settings.weekStart,
        _timeDisplay(settings.timeDisplay),
        settings.themeId,
        settings.enhancedAccessibility ? 1 : 0,
        _synchronization(settings.synchronization),
        notificationJson,
        activePlacementId,
      ],
    );
    _insertSupportOutbox(
      database: _database,
      mutation: mutation,
      studentId: _studentId,
      entityType: 'settings',
      entityId: settingsId,
      baseRevision: baseRevision,
      payload: payload,
    );
    return MutationReceipt(
      record: StoredDomainRecord(
        value: settings,
        studentId: _studentId,
        revision: revision,
        createdAtUtc: createdAt,
        updatedAtUtc: mutation.occurredAtUtc,
      ),
      replayed: false,
    );
  }
}

bool _supportReplay({
  required ClinicalCalendarDatabase database,
  required MutationToken mutation,
  required String studentId,
  required String entityType,
  required String entityId,
  required int expectedRevision,
  required String payload,
}) {
  final rows = database.select(
    'SELECT * FROM outbox_operations WHERE idempotency_key = ?',
    [mutation.idempotencyKey],
  );
  if (rows.isEmpty) return false;
  final row = rows.single;
  final identical =
      _text(row, 'id') == mutation.operationId &&
      _text(row, 'student_id') == studentId &&
      _text(row, 'entity_type') == entityType &&
      _text(row, 'entity_id') == entityId &&
      _text(row, 'operation_type') == 'upsert' &&
      _int(row, 'base_revision') == expectedRevision &&
      _text(row, 'payload_json') == payload &&
      _dateTime(row, 'created_at_utc') == mutation.occurredAtUtc;
  if (!identical) {
    throw const RepositoryException(
      RepositoryFailureKind.idempotencyConflict,
      'The idempotency key was already used for a different mutation.',
    );
  }
  return true;
}

void _insertSupportOutbox({
  required ClinicalCalendarDatabase database,
  required MutationToken mutation,
  required String studentId,
  required String entityType,
  required String entityId,
  required int baseRevision,
  required String payload,
}) {
  database.execute(
    '''INSERT INTO outbox_operations
      (id, student_id, idempotency_key, entity_type, entity_id,
       operation_type, base_revision, payload_json, created_at_utc)
      VALUES (?, ?, ?, ?, ?, 'upsert', ?, ?, ?)''',
    [
      mutation.operationId,
      studentId,
      mutation.idempotencyKey,
      entityType,
      entityId,
      baseRevision,
      payload,
      _utc(mutation.occurredAtUtc),
    ],
  );
}

String _timeDisplay(TimeDisplayPreference value) => switch (value) {
  TimeDisplayPreference.military => 'military',
  TimeDisplayPreference.twelveHour => 'twelve_hour',
};

String _synchronization(SynchronizationPreference value) => switch (value) {
  SynchronizationPreference.enabled => 'enabled',
  SynchronizationPreference.paused => 'paused',
};

String _normalizeThemeId(String value) =>
    value == 'borg_tactical' ? StudentSettings.variantFThemeId : value;
