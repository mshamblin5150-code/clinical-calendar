import 'dart:convert';

import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import '../placements/placement_application_service.dart';
import '../ports.dart';
import '../repositories.dart';
import 'export_models.dart';

final class ExportDataService implements ExportSnapshotSource {
  const ExportDataService(
    this._repositories,
    this._placements,
    this._clock,
    this._studentId,
  );

  final RepositoryRegistry _repositories;
  final PlacementApplicationService _placements;
  final Clock _clock;
  final String _studentId;

  @override
  Future<PlacementExportSnapshot> placement(String placementId) async {
    final placement = await _placements.placement(placementId);
    final now = _now();
    return _repositories.read((repositories) {
      final sessions = repositories.clinicalSessions
          .list(studentId: _studentId)
          .where((record) => record.value.clinicalPlacementId == placementId)
          .toList(growable: false);
      final history = repositories.historicalHoursEntries
          .list(studentId: _studentId)
          .where((record) => record.value.clinicalPlacementId == placementId)
          .toList(growable: false);
      final plan = repositories.evaluationPlans.find(
        studentId: _studentId,
        id: placement.placement.evaluationPlanId,
      );
      if (plan == null) {
        throw const RepositoryException(
          RepositoryFailureKind.corruptData,
          'Clinical Placement Evaluation Plan is missing.',
        );
      }
      return PlacementExportSnapshot(
        generatedAtUtc: now,
        placement: placement,
        sessions: sessions,
        historicalHours: history,
        evaluationPlan: plan,
      );
    });
  }

  @override
  Future<PortableExportSnapshot> completePortableData() {
    final now = _now();
    return _repositories.read((repositories) {
      final support = repositories is SupportLocalReadRepositories
          ? repositories
          : null;
      final activeSelection = repositories.activePlacementSelection.find(
        studentId: _studentId,
      );
      final document = <String, Object?>{
        'schema_name': PortableExportSnapshot.currentSchemaName,
        'schema_version': PortableExportSnapshot.currentSchemaVersion,
        'exported_at_utc': now.toIso8601String(),
        'student_id': _studentId,
        'records': <String, Object?>{
          'student_profile': support == null
              ? null
              : _recordOrNull(
                  support.studentProfile.find(studentId: _studentId),
                  _profileJson,
                ),
          'student_settings': support == null
              ? null
              : _recordOrNull(
                  support.studentSettings.find(studentId: _studentId),
                  _settingsJson,
                ),
          'clinical_placements': _records(
            repositories.clinicalPlacements.list(studentId: _studentId),
            _placementJson,
          ),
          'preceptors': _records(
            repositories.preceptors.list(studentId: _studentId),
            _preceptorJson,
          ),
          'work_shifts': _records(
            repositories.workShifts.list(studentId: _studentId),
            _workShiftJson,
          ),
          'clinical_sessions': _records(
            repositories.clinicalSessions.list(studentId: _studentId),
            _clinicalSessionJson,
          ),
          'protected_days': _records(
            repositories.protectedDays.list(studentId: _studentId),
            (value) => {'id': value.id, 'date': value.date.toString()},
          ),
          'schedule_templates': _records(
            repositories.scheduleTemplates.list(studentId: _studentId),
            _templateJson,
          ),
          'historical_hours_entries': _records(
            repositories.historicalHoursEntries.list(studentId: _studentId),
            _historicalJson,
          ),
          'evaluation_plans': _records(
            repositories.evaluationPlans.list(studentId: _studentId),
            _evaluationPlanJson,
          ),
          'active_clinical_placement_selection': activeSelection == null
              ? null
              : _record(activeSelection, (value) => value),
        },
      };
      return PortableExportSnapshot(
        schemaName: PortableExportSnapshot.currentSchemaName,
        schemaVersion: PortableExportSnapshot.currentSchemaVersion,
        exportedAtUtc: now,
        studentId: _studentId,
        document: document,
      );
    });
  }

  DateTime _now() {
    final now = _clock.nowUtc();
    if (!now.isUtc) throw StateError('Clock.nowUtc() must return UTC.');
    return now;
  }
}

List<Object?> _records<T>(
  List<StoredDomainRecord<T>> records,
  Object? Function(T value) encode,
) => [for (final record in records) _record(record, encode)];

Object? _recordOrNull<T>(
  StoredDomainRecord<T>? record,
  Object? Function(T value) encode,
) => record == null ? null : _record(record, encode);

Map<String, Object?> _record<T>(
  StoredDomainRecord<T> record,
  Object? Function(T value) encode,
) => {
  'revision': record.revision,
  'created_at_utc': record.createdAtUtc.toIso8601String(),
  'updated_at_utc': record.updatedAtUtc.toIso8601String(),
  'value': encode(record.value),
};

Map<String, Object?> _profileJson(StudentProfile value) => {
  'id': value.id,
  'display_name': value.displayName,
  'program': value.program,
  'account_identity': value.accountIdentity,
  'avatar_base64': value.avatarBytes == null
      ? null
      : base64Encode(value.avatarBytes!),
};

Map<String, Object?> _settingsJson(StudentSettings value) => {
  'week_start': value.weekStart,
  'time_display': value.timeDisplay.name,
  'theme_id': value.themeId,
  'synchronization': value.synchronization.name,
  'notifications': value.notifications.toJson(),
};

Map<String, Object?> _placementJson(ClinicalPlacement value) => {
  'id': value.id,
  'name': value.name,
  'target_minutes': value.targetHours.minutes,
  'start_date': value.startDate.toString(),
  'completion_deadline': value.completionDeadline.toString(),
  'attached_preceptor_ids': value.attachedPreceptorIds.toList()..sort(),
  'primary_preceptor_id': value.primaryPreceptorId,
  'evaluation_plan_id': value.evaluationPlanId,
  'state': value.state.name,
};

Map<String, Object?> _preceptorJson(Preceptor value) => {
  'id': value.id,
  'name': value.name,
  'organization_or_site': value.organizationOrSite,
  'phone': value.phone,
  'email': value.email,
  'scheduling_notes': value.schedulingNotes,
};

Map<String, Object?> _workShiftJson(WorkShift value) => {
  'id': value.id,
  'planned_interval': _intervalJson(value.plannedInterval),
};

Map<String, Object?> _clinicalSessionJson(ClinicalSession value) => {
  'id': value.id,
  'clinical_placement_id': value.clinicalPlacementId,
  'preceptor_id': value.preceptorId,
  'planned_interval': _intervalJson(value.plannedInterval),
  'state': value.state.name,
  'actual_interval': value.actualInterval == null
      ? null
      : _intervalJson(value.actualInterval!),
};

Map<String, Object?> _intervalJson(ZonedInterval value) => {
  'start_date': value.startDate.toString(),
  'end_date': value.endDate.toString(),
  'start_time': value.startTime.military,
  'end_time': value.endTime.military,
  'time_zone': value.timeZone.value,
  'start_offset_minutes': value.startOffset.minutes,
  'end_offset_minutes': value.endOffset.minutes,
  'elapsed_minutes': value.elapsedMinutes,
};

Map<String, Object?> _templateJson(ScheduleTemplate value) => {
  'id': value.id,
  'name': value.name,
  'type': value.type.name,
  'start_time': value.startTime.military,
  'end_time': value.endTime.military,
  'clinical_placement_id': value.clinicalPlacementId,
  'preceptor_id': value.preceptorId,
};

Map<String, Object?> _historicalJson(HistoricalHoursEntry value) => {
  'id': value.id,
  'clinical_placement_id': value.clinicalPlacementId,
  'completed_minutes': value.completedMinutes,
  'effective_date': value.effectiveDate.toString(),
  'preceptor_id': value.preceptorId,
  'note': value.note,
};

Map<String, Object?> _evaluationPlanJson(EvaluationPlan value) => {
  'id': value.id,
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
  'requirements': [
    for (final requirement in value.requirements)
      {
        'identity': requirement.identity.stableValue,
        'kind': requirement.identity.kind.name,
        'threshold_minutes': requirement.thresholdMinutes,
        'currently_required': requirement.isCurrentlyRequired,
        'primary_preceptor_id': requirement.primaryPreceptorId,
        'documentation': requirement.documentation == null
            ? null
            : {
                'date_documented': requirement.documentation!.dateDocumented
                    .toString(),
                'location': requirement.documentation!.location,
                'reference_or_note': requirement.documentation!.referenceOrNote,
              },
      },
  ],
};
