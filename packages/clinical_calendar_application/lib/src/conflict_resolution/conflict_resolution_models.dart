import 'dart:convert';

import '../repositories.dart';

enum SynchronizationConflictWorkflow {
  sameRecord,
  schedule,
  protectedDay,
  relationship,
}

enum CrossRecordResolutionAction { move, cancel, missed, deleteIfEligible }

final class ConflictVersionSnapshot {
  ConflictVersionSnapshot._({
    required this.isComplete,
    required this.revision,
    required this.values,
  });

  factory ConflictVersionSnapshot._incomplete() => ConflictVersionSnapshot._(
    isComplete: false,
    revision: null,
    values: const <String, Object?>{},
  );

  factory ConflictVersionSnapshot.fromJson(
    String source, {
    String? expectedEntityType,
    String? expectedEntityId,
    String? expectedStudentId,
    int? expectedRevision,
  }) {
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      return ConflictVersionSnapshot._incomplete();
    }
    if (decoded is! Map<String, dynamic>) {
      return ConflictVersionSnapshot._incomplete();
    }
    final revision = decoded['revision'];
    final isComplete = isCompleteConflictSnapshotEnvelope(
      decoded,
      expectedEntityType: expectedEntityType,
      expectedEntityId: expectedEntityId,
      expectedStudentId: expectedStudentId,
      expectedRevision: expectedRevision,
    );
    if (!isComplete) return ConflictVersionSnapshot._incomplete();
    return ConflictVersionSnapshot._(
      isComplete: true,
      revision: revision,
      values: Map.unmodifiable(decoded['value'] as Map<String, dynamic>),
    );
  }

  final bool isComplete;
  final int? revision;
  final Map<String, Object?> values;

  String valueJson() => jsonEncode(values);
}

final class ConflictResolutionItem {
  ConflictResolutionItem(this.record)
    : local = ConflictVersionSnapshot.fromJson(
        record.localSnapshotJson,
        expectedEntityType: record.entityType,
        expectedEntityId: record.entityId,
        expectedStudentId: record.studentId,
        expectedRevision: record.localRevision,
      ),
      remote = ConflictVersionSnapshot.fromJson(
        record.remoteSnapshotJson,
        expectedEntityType: record.entityType,
        expectedEntityId: record.entityId,
        expectedStudentId: record.studentId,
        expectedRevision: record.remoteRevision,
      );

  final SynchronizationConflictRecord record;
  final ConflictVersionSnapshot local;
  final ConflictVersionSnapshot remote;

  SynchronizationConflictWorkflow get workflow => switch (record
      .rejectionCode) {
    'schedule_conflict' => SynchronizationConflictWorkflow.schedule,
    'protected_day_violation' => SynchronizationConflictWorkflow.protectedDay,
    'relationship_violation' => SynchronizationConflictWorkflow.relationship,
    _ => SynchronizationConflictWorkflow.sameRecord,
  };

  bool get supportsSideBySideResolution => remote.isComplete;
  bool get planningIncomplete => record.keepsPlanningIncomplete;

  List<String> get comparableFields {
    final fields = {...local.values.keys, ...remote.values.keys}.toList()
      ..sort();
    return fields;
  }
}

bool isCompleteConflictSnapshotEnvelope(
  Map<String, dynamic> value, {
  required String? expectedEntityType,
  required String? expectedEntityId,
  required String? expectedStudentId,
  required int? expectedRevision,
}) {
  final revision = value['revision'];
  final deletedAtUtc = value['deleted_at_utc'];
  return value['schema_version'] == 1 &&
      value['value'] is Map<String, dynamic> &&
      revision is int &&
      revision >= 0 &&
      revision == expectedRevision &&
      value['entity_type'] is String &&
      value['entity_type'] == expectedEntityType &&
      value['entity_id'] is String &&
      value['entity_id'] == expectedEntityId &&
      value['student_id'] is String &&
      value['student_id'] == expectedStudentId &&
      _isUtcTimestamp(value['created_at_utc']) &&
      _isUtcTimestamp(value['updated_at_utc']) &&
      (deletedAtUtc == null || _isUtcTimestamp(deletedAtUtc));
}

bool _isUtcTimestamp(Object? value) {
  if (value is! String) return false;
  final parsed = DateTime.tryParse(value);
  return parsed != null && parsed.isUtc;
}

final class ConflictResolutionSnapshot {
  ConflictResolutionSnapshot(List<SynchronizationConflictRecord> conflicts)
    : items = List.unmodifiable(conflicts.map(ConflictResolutionItem.new));

  final List<ConflictResolutionItem> items;

  bool get hasConflicts => items.isNotEmpty;
  int get planningIncompleteCount =>
      items.where((item) => item.planningIncomplete).length;
}
