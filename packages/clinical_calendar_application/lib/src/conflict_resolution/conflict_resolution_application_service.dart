import 'dart:convert';

import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import '../ports.dart';
import '../repositories.dart';
import 'conflict_resolution_models.dart';

final class ConflictResolutionApplicationService {
  ConflictResolutionApplicationService({
    required RepositoryRegistry repositories,
    required Clock clock,
    required IdentifierGenerator identifiers,
    required String studentId,
    SynchronizationService? synchronization,
  }) : this._(repositories, clock, identifiers, studentId, synchronization);

  ConflictResolutionApplicationService._(
    this._repositories,
    this._clock,
    this._identifiers,
    this._studentId,
    this._synchronization,
  );

  final RepositoryRegistry _repositories;
  final Clock _clock;
  final IdentifierGenerator _identifiers;
  final String _studentId;
  final SynchronizationService? _synchronization;

  Future<ConflictResolutionSnapshot> load() => _repositories.read(
    (repositories) => ConflictResolutionSnapshot(
      _synchronizationRepository(
        repositories,
      ).listConflicts(studentId: _studentId),
    ),
  );

  Future<SynchronizationConflictResolutionReceipt> resolve({
    required String conflictId,
    required SynchronizationConflictResolutionChoice choice,
    Map<String, Object?>? correctedValues,
  }) async {
    if ((choice == SynchronizationConflictResolutionChoice.correctedVersion) !=
        (correctedValues != null)) {
      throw ArgumentError(
        'Corrected values are required only for a corrected version.',
      );
    }
    final receipt = await _repositories.mutate((repositories) {
      final synchronization = _synchronizationRepository(repositories);
      if (correctedValues != null) {
        final conflict = synchronization.findConflict(
          studentId: _studentId,
          conflictId: conflictId,
        );
        if (conflict == null) {
          throw const RepositoryException(
            RepositoryFailureKind.notFound,
            'The synchronization conflict does not exist.',
          );
        }
        _validateCorrectedVersion(
          repositories: repositories,
          studentId: _studentId,
          conflict: ConflictResolutionItem(conflict),
          corrected: correctedValues,
          nowUtc: _clock.nowUtc(),
        );
      }
      return synchronization.resolveConflict(
        studentId: _studentId,
        conflictId: conflictId,
        choice: choice,
        correctedValueJson: correctedValues == null
            ? null
            : jsonEncode(correctedValues),
        mutation: _mutation(),
      );
    });
    await _synchronization?.synchronize();
    return receipt;
  }

  Future<SynchronizationConflictResolutionReceipt> resolveCrossRecord({
    required ConflictResolutionItem conflict,
    required CrossRecordResolutionAction action,
    Map<String, Object?>? movedValues,
  }) async {
    if (conflict.workflow == SynchronizationConflictWorkflow.sameRecord) {
      throw ArgumentError('The conflict is not a cross-record conflict.');
    }
    final corrected = Map<String, Object?>.from(conflict.local.values);
    switch (action) {
      case CrossRecordResolutionAction.move:
        if (movedValues == null) {
          throw ArgumentError('Moving requires corrected scheduling values.');
        }
        corrected.addAll(movedValues);
        _normalizeMovedCommitment(
          corrected,
          conflict.record.entityType,
          _clock.nowUtc(),
        );
      case CrossRecordResolutionAction.cancel:
        _requireClinicalSession(conflict);
        _requireLifecycleState(conflict, const {
          'scheduled',
          'awaiting_confirmation',
        }, 'Cancelled');
        corrected['lifecycle_state'] = 'cancelled';
        _clearActualInterval(corrected);
      case CrossRecordResolutionAction.missed:
        _requireClinicalSession(conflict);
        _requireLifecycleState(conflict, const {
          'awaiting_confirmation',
        }, 'marked Missed');
        corrected['lifecycle_state'] = 'missed';
        _clearActualInterval(corrected);
      case CrossRecordResolutionAction.deleteIfEligible:
        _requireEligibleDeletion(conflict);
        return resolve(
          conflictId: conflict.record.id,
          choice: SynchronizationConflictResolutionChoice.deleteVersion,
        );
    }
    final receipt = await _repositories.mutate((repositories) {
      _validateCrossRecordCorrection(
        repositories: repositories,
        studentId: _studentId,
        conflict: conflict,
        corrected: corrected,
      );
      return _synchronizationRepository(repositories).resolveConflict(
        studentId: _studentId,
        conflictId: conflict.record.id,
        choice: SynchronizationConflictResolutionChoice.correctedVersion,
        correctedValueJson: jsonEncode(corrected),
        mutation: _mutation(),
      );
    });
    await _synchronization?.synchronize();
    return receipt;
  }

  MutationToken _mutation() {
    final occurredAt = _clock.nowUtc();
    if (!occurredAt.isUtc) throw StateError('Clock must return UTC.');
    return MutationToken(
      operationId: _identifiers.nextIdentifier(),
      idempotencyKey: _identifiers.nextIdentifier(),
      occurredAtUtc: occurredAt,
    );
  }
}

void _validateCorrectedVersion({
  required LocalReadRepositories repositories,
  required String studentId,
  required ConflictResolutionItem conflict,
  required Map<String, Object?> corrected,
  required DateTime nowUtc,
}) {
  try {
    switch (conflict.record.entityType) {
      case 'work_shift' || 'clinical_session' || 'protected_day':
        _normalizeMovedCommitment(
          corrected,
          conflict.record.entityType,
          nowUtc,
        );
        _validateCrossRecordCorrection(
          repositories: repositories,
          studentId: studentId,
          conflict: conflict,
          corrected: corrected,
        );
      case 'preceptor':
        Preceptor(
          id: conflict.record.entityId,
          name: _text(corrected, 'name'),
          organizationOrSite: _nullableText(corrected, 'organization_or_site'),
          phone: _nullableText(corrected, 'phone'),
          email: _nullableText(corrected, 'email'),
          schedulingNotes: _nullableText(corrected, 'scheduling_notes'),
        );
      case 'schedule_template':
        ScheduleTemplate(
          id: conflict.record.entityId,
          name: _text(corrected, 'name'),
          type: switch (_text(corrected, 'commitment_type')) {
            'work_shift' => ScheduleTemplateType.workShift,
            'clinical_session' => ScheduleTemplateType.clinicalSession,
            _ => throw const FormatException('Unknown template type.'),
          },
          startTime: _localTime(_integer(corrected, 'start_minutes')),
          endTime: _localTime(_integer(corrected, 'end_minutes')),
          clinicalPlacementId: _nullableText(corrected, 'placement_id'),
          preceptorId: _nullableText(corrected, 'preceptor_id'),
        );
      case 'historical_hours_entry':
        HistoricalHoursEntry(
          id: conflict.record.entityId,
          clinicalPlacementId: _text(corrected, 'placement_id'),
          completedMinutes: _integer(corrected, 'completed_minutes'),
          effectiveDate: _localDate(_text(corrected, 'effective_date')),
          preceptorId: _nullableText(corrected, 'preceptor_id'),
          note: _nullableText(corrected, 'note'),
        );
      case 'academic_assignment':
        AcademicAssignment(
          id: conflict.record.entityId,
          title: _text(corrected, 'title'),
          course: _text(corrected, 'course'),
          courseId: _nullableText(corrected, 'course_id'),
          dueDate: _localDate(_text(corrected, 'due_date')),
          status: AcademicAssignmentStatus.values.byName(
            _text(corrected, 'status'),
          ),
        );
      case 'class_catalog_entry':
        ClassCatalogEntry(
          id: conflict.record.entityId,
          name: _text(corrected, 'name'),
          isArchived:
              corrected['archived'] == true || corrected['archived'] == 1,
        );
      case 'student_profile':
        StudentProfile(
          id: conflict.record.entityId,
          displayName: _text(corrected, 'display_name'),
          program: _nullableText(corrected, 'program'),
          accountIdentity: _nullableText(corrected, 'account_identity'),
          avatarBytes: _nullableText(corrected, 'avatar_base64') == null
              ? null
              : base64Decode(_text(corrected, 'avatar_base64')),
        );
      default:
        if (corrected.isEmpty) throw const FormatException('Empty version.');
    }
  } on ConflictResolutionException {
    rethrow;
  } on Object catch (_) {
    throw const ConflictResolutionException(
      'The corrected version is incomplete or invalid.',
    );
  }
}

void _validateCrossRecordCorrection({
  required LocalReadRepositories repositories,
  required String studentId,
  required ConflictResolutionItem conflict,
  required Map<String, Object?> corrected,
}) {
  try {
    final weekStartsOn = repositories is SupportLocalReadRepositories
        ? repositories.studentSettings
                  .find(studentId: studentId)
                  ?.value
                  .weekStart ??
              DateTime.sunday
        : DateTime.sunday;
    final invariants = SchedulingInvariantEngine(
      weekConfiguration: CalendarWeekConfiguration(weekStartsOn: weekStartsOn),
    );
    final existing = SchedulingState(
      workShifts: repositories.workShifts
          .list(studentId: studentId)
          .map((record) => record.value)
          .where((value) => value.id != conflict.record.entityId),
      clinicalSessions: repositories.clinicalSessions
          .list(studentId: studentId)
          .map((record) => record.value)
          .where((value) => value.id != conflict.record.entityId),
      protectedDays: repositories.protectedDays
          .list(studentId: studentId)
          .map((record) => record.value)
          .where((value) => value.id != conflict.record.entityId),
    );
    final batch = switch (conflict.record.entityType) {
      'work_shift' => SchedulingBatch(
        workShifts: [
          WorkShift(
            id: conflict.record.entityId,
            plannedInterval: _interval(corrected, 'planned_'),
          ),
        ],
      ),
      'clinical_session' => SchedulingBatch(
        clinicalSessions: [
          _clinicalSession(conflict.record.entityId, corrected),
        ],
      ),
      'protected_day' => SchedulingBatch(
        protectedDays: [
          ProtectedDay(
            id: conflict.record.entityId,
            date: _localDate(_text(corrected, 'local_date')),
          ),
        ],
      ),
      _ => throw const ConflictResolutionException(
        'This record must be corrected through its authoritative workflow.',
      ),
    };
    if (conflict.record.entityType == 'protected_day') {
      corrected['week_start_date'] = invariants
          .weekContaining(_localDate(_text(corrected, 'local_date')))
          .start
          .toString();
    }
    final validation = invariants.validateBatch(
      existing: existing,
      batch: batch,
    );
    if (!validation.canCommit) {
      throw ConflictResolutionException(
        'The corrected version still has ${validation.errors.length} '
        'scheduling conflict${validation.errors.length == 1 ? '' : 's'}.',
      );
    }
  } on ConflictResolutionException {
    rethrow;
  } on Object catch (_) {
    throw const ConflictResolutionException(
      'The corrected scheduling version is incomplete or invalid.',
    );
  }
}

void _normalizeMovedCommitment(
  Map<String, Object?> values,
  String entityType,
  DateTime nowUtc,
) {
  try {
    if (entityType == 'protected_day') return;
    if (entityType != 'work_shift' && entityType != 'clinical_session') {
      throw const ConflictResolutionException(
        'Only scheduling records can be moved from this conflict.',
      );
    }
    final interval = _interval(values, 'planned_');
    values.addAll(_encodedInterval(interval, 'planned_'));
    if (entityType == 'work_shift') {
      values['lifecycle_state'] = 'scheduled';
      return;
    }
    final state = values['lifecycle_state'];
    if (state == 'cancelled' || state == 'missed') {
      throw const ConflictResolutionException(
        'A Cancelled or Missed Clinical Session cannot be moved.',
      );
    }
    final localNow = nowUtc.toUtc().add(interval.startOffset.duration);
    final today = LocalDate(localNow.year, localNow.month, localNow.day);
    values['lifecycle_state'] = interval.startDate.isBefore(today)
        ? 'awaiting_confirmation'
        : 'scheduled';
    _clearActualInterval(values);
  } on ConflictResolutionException {
    rethrow;
  } on Object catch (_) {
    throw const ConflictResolutionException(
      'The moved scheduling version is incomplete or invalid.',
    );
  }
}

Map<String, Object?> _encodedInterval(ZonedInterval value, String prefix) => {
  '${prefix}start_date': value.startDate.toString(),
  '${prefix}end_date': value.endDate.toString(),
  '${prefix}start_minutes': value.startTime.minutesSinceMidnight,
  '${prefix}end_minutes': value.endTime.minutesSinceMidnight,
  'time_zone': value.timeZone.value,
  '${prefix}start_offset_minutes': value.startOffset.minutes,
  '${prefix}end_offset_minutes': value.endOffset.minutes,
  '${prefix}start_utc': value.startInstantUtc.toIso8601String(),
  '${prefix}end_utc': value.endInstantUtc.toIso8601String(),
};

ClinicalSession _clinicalSession(String id, Map<String, Object?> values) {
  final state = switch (_text(values, 'lifecycle_state')) {
    'scheduled' => ClinicalSessionState.scheduled,
    'awaiting_confirmation' => ClinicalSessionState.awaitingConfirmation,
    'completed' => ClinicalSessionState.completed,
    'cancelled' => ClinicalSessionState.cancelled,
    'missed' => ClinicalSessionState.missed,
    _ => throw const FormatException('Unknown Clinical Session state.'),
  };
  return ClinicalSession.restore(
    id: id,
    clinicalPlacementId: _text(values, 'placement_id'),
    preceptorId: _text(values, 'preceptor_id'),
    plannedInterval: _interval(values, 'planned_'),
    state: state,
    actualInterval: state == ClinicalSessionState.completed
        ? _interval(values, 'actual_')
        : null,
  );
}

ZonedInterval _interval(Map<String, Object?> values, String prefix) =>
    ZonedInterval(
      startDate: _localDate(_text(values, '${prefix}start_date')),
      startTime: _localTime(_integer(values, '${prefix}start_minutes')),
      endTime: _localTime(_integer(values, '${prefix}end_minutes')),
      timeZone: TimeZoneId(_text(values, 'time_zone')),
      startOffset: UtcOffset.inMinutes(
        _integer(values, '${prefix}start_offset_minutes'),
      ),
      endOffset: UtcOffset.inMinutes(
        _integer(values, '${prefix}end_offset_minutes'),
      ),
    );

LocalDate _localDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) throw const FormatException('Invalid local date.');
  return LocalDate(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

LocalTime _localTime(int minutes) => LocalTime(minutes ~/ 60, minutes % 60);

String _text(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is! String || value.isEmpty) throw const FormatException();
  return value;
}

String? _nullableText(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value == null) return null;
  if (value is! String) throw const FormatException();
  return value;
}

int _integer(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is! int) throw const FormatException();
  return value;
}

void _requireLifecycleState(
  ConflictResolutionItem conflict,
  Set<String> eligibleStates,
  String action,
) {
  final state = conflict.local.values['lifecycle_state'];
  if (state is! String || !eligibleStates.contains(state)) {
    throw ConflictResolutionException(
      'This Clinical Session cannot be $action from its current state.',
    );
  }
}

final class ConflictResolutionException implements Exception {
  const ConflictResolutionException(this.message);
  final String message;

  @override
  String toString() => 'ConflictResolutionException: $message';
}

SynchronizationLocalRepository _synchronizationRepository(
  LocalReadRepositories repositories,
) {
  if (repositories case final SynchronizationLocalReadRepositories sync) {
    return sync.synchronization;
  }
  throw const RepositoryException(
    RepositoryFailureKind.uninitialized,
    'Synchronization conflict repositories are unavailable.',
  );
}

void _requireClinicalSession(ConflictResolutionItem conflict) {
  if (conflict.record.entityType != 'clinical_session') {
    throw const ConflictResolutionException(
      'Only a Clinical Session may be Cancelled or marked Missed.',
    );
  }
}

void _requireEligibleDeletion(ConflictResolutionItem conflict) {
  if (!const {
    'work_shift',
    'clinical_session',
    'protected_day',
  }.contains(conflict.record.entityType)) {
    throw const ConflictResolutionException(
      'This record is not eligible for deletion from conflict resolution.',
    );
  }
}

void _clearActualInterval(Map<String, Object?> values) {
  for (final key in const [
    'actual_start_date',
    'actual_end_date',
    'actual_start_minutes',
    'actual_end_minutes',
    'actual_start_offset_minutes',
    'actual_end_offset_minutes',
    'actual_start_utc',
    'actual_end_utc',
  ]) {
    values[key] = null;
  }
}
