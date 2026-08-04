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

  factory ConflictVersionSnapshot.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Conflict snapshot must be an object.');
    }
    final value = decoded['value'];
    return ConflictVersionSnapshot._(
      isComplete:
          decoded['schema_version'] == 1 && value is Map<String, dynamic>,
      revision: decoded['revision'] is int ? decoded['revision'] as int : null,
      values: value is Map<String, dynamic>
          ? Map.unmodifiable(value)
          : const <String, Object?>{},
    );
  }

  final bool isComplete;
  final int? revision;
  final Map<String, Object?> values;

  String valueJson() => jsonEncode(values);
}

final class ConflictResolutionItem {
  ConflictResolutionItem(this.record)
    : local = ConflictVersionSnapshot.fromJson(record.localSnapshotJson),
      remote = ConflictVersionSnapshot.fromJson(record.remoteSnapshotJson);

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

final class ConflictResolutionSnapshot {
  ConflictResolutionSnapshot(List<SynchronizationConflictRecord> conflicts)
    : items = List.unmodifiable(conflicts.map(ConflictResolutionItem.new));

  final List<ConflictResolutionItem> items;

  bool get hasConflicts => items.isNotEmpty;
  int get planningIncompleteCount =>
      items.where((item) => item.planningIncomplete).length;
}
