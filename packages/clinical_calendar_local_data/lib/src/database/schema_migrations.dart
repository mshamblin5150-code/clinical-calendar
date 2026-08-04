import 'package:sqlite3/sqlite3.dart';

import 'database_failure.dart';

typedef MigrationTestHook = void Function(int targetVersion, Database database);

/// Runs the forward-only local schema migrations.
///
/// [forTesting] is the sole fault-injection seam. Its callback runs inside the
/// migration transaction immediately before the version and history record are
/// written, allowing tests to prove that all DDL and data changes roll back.
final class DatabaseMigrationRunner {
  const DatabaseMigrationRunner() : _testHook = null;

  const DatabaseMigrationRunner.forTesting(MigrationTestHook hook)
    : _testHook = hook;

  static const latestVersion = 5;

  final MigrationTestHook? _testHook;

  void migrate(Database database, int currentVersion) {
    for (
      var targetVersion = currentVersion + 1;
      targetVersion <= latestVersion;
      targetVersion++
    ) {
      _runOne(database, targetVersion);
    }
  }

  void _runOne(Database database, int targetVersion) {
    database.execute('BEGIN IMMEDIATE');
    try {
      for (final statement in _statements[targetVersion]!) {
        database.execute(statement);
      }
      _testHook?.call(targetVersion, database);
      database.execute(
        'INSERT INTO schema_migrations (version, applied_at_utc) '
        "VALUES (?, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))",
        [targetVersion],
      );
      database.execute('PRAGMA user_version = $targetVersion');
      database.execute('COMMIT');
    } catch (_) {
      try {
        database.execute('ROLLBACK');
      } on Object {
        // Preserve the sanitized migration diagnostic below.
      }
      throw ClinicalCalendarDatabaseException.migrationFailed();
    }
  }
}

const _syncColumns = '''
  id TEXT NOT NULL CHECK (length(id) = 36),
  student_id TEXT NOT NULL CHECK (length(student_id) = 36),
  revision INTEGER NOT NULL DEFAULT 0 CHECK (revision >= 0),
  created_at_utc TEXT NOT NULL,
  updated_at_utc TEXT NOT NULL CHECK (updated_at_utc >= created_at_utc),
  deleted_at_utc TEXT
''';

final Map<int, List<String>> _statements = {
  1: [
    '''CREATE TABLE schema_migrations (
      version INTEGER PRIMARY KEY CHECK (version > 0),
      applied_at_utc TEXT NOT NULL
    ) STRICT''',
    '''CREATE TABLE student_profiles (
      $_syncColumns,
      display_name TEXT NOT NULL CHECK (length(trim(display_name)) BETWEEN 1 AND 160),
      avatar_bytes BLOB,
      program TEXT,
      account_identity TEXT,
      PRIMARY KEY (id),
      UNIQUE (student_id),
      UNIQUE (id, student_id)
    ) STRICT''',
    '''CREATE TABLE preceptors (
      $_syncColumns,
      name TEXT NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 120),
      organization_or_site TEXT,
      phone TEXT,
      email TEXT,
      scheduling_notes TEXT,
      PRIMARY KEY (id),
      UNIQUE (id, student_id),
      FOREIGN KEY (student_id) REFERENCES student_profiles(student_id)
    ) STRICT''',
    '''CREATE TABLE clinical_placements (
      $_syncColumns,
      name TEXT NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 160),
      target_minutes INTEGER NOT NULL CHECK (target_minutes > 0),
      start_date TEXT NOT NULL,
      completion_deadline TEXT NOT NULL,
      lifecycle_state TEXT NOT NULL CHECK (lifecycle_state IN ('active', 'ready_to_complete', 'completed')),
      primary_preceptor_id TEXT NOT NULL,
      PRIMARY KEY (id),
      UNIQUE (id, student_id),
      CHECK (completion_deadline >= start_date),
      FOREIGN KEY (student_id) REFERENCES student_profiles(student_id),
      FOREIGN KEY (id, primary_preceptor_id, student_id)
        REFERENCES placement_preceptors(placement_id, preceptor_id, student_id)
        DEFERRABLE INITIALLY DEFERRED
    ) STRICT''',
    '''CREATE TABLE placement_preceptors (
      placement_id TEXT NOT NULL,
      preceptor_id TEXT NOT NULL,
      student_id TEXT NOT NULL,
      attached_at_utc TEXT NOT NULL,
      PRIMARY KEY (placement_id, preceptor_id),
      UNIQUE (placement_id, preceptor_id, student_id),
      FOREIGN KEY (placement_id, student_id)
        REFERENCES clinical_placements(id, student_id),
      FOREIGN KEY (preceptor_id, student_id)
        REFERENCES preceptors(id, student_id)
    ) STRICT''',
    '''CREATE TABLE commitments (
      $_syncColumns,
      commitment_type TEXT NOT NULL CHECK (commitment_type IN ('work_shift', 'clinical_session')),
      lifecycle_state TEXT NOT NULL CHECK (lifecycle_state IN ('scheduled', 'awaiting_confirmation', 'completed', 'cancelled', 'missed')),
      placement_id TEXT,
      preceptor_id TEXT,
      planned_start_date TEXT NOT NULL,
      planned_end_date TEXT NOT NULL,
      planned_start_minutes INTEGER NOT NULL CHECK (planned_start_minutes BETWEEN 0 AND 1439),
      planned_end_minutes INTEGER NOT NULL CHECK (planned_end_minutes BETWEEN 0 AND 1439),
      time_zone TEXT NOT NULL CHECK (length(trim(time_zone)) BETWEEN 1 AND 255),
      planned_start_offset_minutes INTEGER NOT NULL CHECK (planned_start_offset_minutes BETWEEN -840 AND 840),
      planned_end_offset_minutes INTEGER NOT NULL CHECK (planned_end_offset_minutes BETWEEN -840 AND 840),
      planned_start_utc TEXT NOT NULL,
      planned_end_utc TEXT NOT NULL,
      actual_start_date TEXT,
      actual_end_date TEXT,
      actual_start_minutes INTEGER CHECK (actual_start_minutes BETWEEN 0 AND 1439),
      actual_end_minutes INTEGER CHECK (actual_end_minutes BETWEEN 0 AND 1439),
      actual_start_offset_minutes INTEGER CHECK (actual_start_offset_minutes BETWEEN -840 AND 840),
      actual_end_offset_minutes INTEGER CHECK (actual_end_offset_minutes BETWEEN -840 AND 840),
      actual_start_utc TEXT,
      actual_end_utc TEXT,
      PRIMARY KEY (id),
      UNIQUE (id, student_id),
      CHECK (planned_end_utc > planned_start_utc),
      CHECK ((commitment_type = 'work_shift' AND placement_id IS NULL AND preceptor_id IS NULL) OR
             (commitment_type = 'clinical_session' AND placement_id IS NOT NULL AND preceptor_id IS NOT NULL)),
      CHECK ((actual_start_date IS NULL AND actual_end_date IS NULL AND actual_start_minutes IS NULL AND actual_end_minutes IS NULL AND actual_start_offset_minutes IS NULL AND actual_end_offset_minutes IS NULL AND actual_start_utc IS NULL AND actual_end_utc IS NULL) OR
             (actual_start_date IS NOT NULL AND actual_end_date IS NOT NULL AND actual_start_minutes IS NOT NULL AND actual_end_minutes IS NOT NULL AND actual_start_offset_minutes IS NOT NULL AND actual_end_offset_minutes IS NOT NULL AND actual_start_utc IS NOT NULL AND actual_end_utc IS NOT NULL AND actual_end_utc > actual_start_utc)),
      CHECK (lifecycle_state != 'completed' OR actual_start_utc IS NOT NULL),
      FOREIGN KEY (student_id) REFERENCES student_profiles(student_id),
      FOREIGN KEY (placement_id, preceptor_id, student_id)
        REFERENCES placement_preceptors(placement_id, preceptor_id, student_id)
    ) STRICT''',
    '''CREATE TABLE protected_days (
      $_syncColumns,
      local_date TEXT NOT NULL,
      week_start_date TEXT NOT NULL,
      PRIMARY KEY (id),
      UNIQUE (id, student_id),
      UNIQUE (student_id, week_start_date),
      FOREIGN KEY (student_id) REFERENCES student_profiles(student_id)
    ) STRICT''',
    '''CREATE TABLE historical_hours_entries (
      $_syncColumns,
      placement_id TEXT NOT NULL,
      preceptor_id TEXT,
      completed_minutes INTEGER NOT NULL CHECK (completed_minutes > 0),
      effective_date TEXT NOT NULL,
      note TEXT,
      PRIMARY KEY (id),
      UNIQUE (id, student_id),
      FOREIGN KEY (placement_id, student_id)
        REFERENCES clinical_placements(id, student_id),
      FOREIGN KEY (placement_id, preceptor_id, student_id)
        REFERENCES placement_preceptors(placement_id, preceptor_id, student_id)
    ) STRICT''',
    '''CREATE TABLE evaluation_plans (
      $_syncColumns,
      placement_id TEXT NOT NULL,
      interim_cadence_minutes INTEGER CHECK (interim_cadence_minutes > 0),
      initial_self_assessment_required INTEGER NOT NULL CHECK (initial_self_assessment_required IN (0, 1)),
      final_self_assessment_required INTEGER NOT NULL CHECK (final_self_assessment_required IN (0, 1)),
      final_placement_review_required INTEGER NOT NULL CHECK (final_placement_review_required IN (0, 1)),
      PRIMARY KEY (id),
      UNIQUE (id, student_id),
      UNIQUE (placement_id, student_id),
      FOREIGN KEY (placement_id, student_id)
        REFERENCES clinical_placements(id, student_id)
    ) STRICT''',
    '''CREATE TABLE evaluation_requirements (
      $_syncColumns,
      evaluation_plan_id TEXT NOT NULL,
      requirement_key TEXT NOT NULL,
      requirement_type TEXT NOT NULL CHECK (requirement_type IN ('initial_self_assessment', 'student_reviews_preceptor', 'preceptor_reviews_student', 'final_self_assessment', 'final_placement_review')),
      threshold_minutes INTEGER CHECK (threshold_minutes > 0),
      boundary TEXT CHECK (boundary IN ('beginning', 'interim', 'end')),
      status TEXT NOT NULL CHECK (status IN ('not_due', 'approaching', 'due', 'documented')),
      documented_at_utc TEXT,
      documentation_location TEXT,
      documentation_reference TEXT,
      documentation_note TEXT,
      documented_preceptor_id TEXT,
      PRIMARY KEY (id),
      UNIQUE (id, student_id),
      UNIQUE (evaluation_plan_id, requirement_key),
      CHECK (status != 'documented' OR documented_at_utc IS NOT NULL),
      FOREIGN KEY (evaluation_plan_id, student_id)
        REFERENCES evaluation_plans(id, student_id),
      FOREIGN KEY (documented_preceptor_id, student_id)
        REFERENCES preceptors(id, student_id)
    ) STRICT''',
    '''CREATE TABLE schedule_templates (
      $_syncColumns,
      name TEXT NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 160),
      commitment_type TEXT NOT NULL CHECK (commitment_type IN ('work_shift', 'clinical_session')),
      start_minutes INTEGER NOT NULL CHECK (start_minutes BETWEEN 0 AND 1439),
      end_minutes INTEGER NOT NULL CHECK (end_minutes BETWEEN 0 AND 1439),
      placement_id TEXT,
      preceptor_id TEXT,
      PRIMARY KEY (id),
      UNIQUE (id, student_id),
      CHECK ((commitment_type = 'work_shift' AND placement_id IS NULL AND preceptor_id IS NULL) OR
             (commitment_type = 'clinical_session' AND placement_id IS NOT NULL AND preceptor_id IS NOT NULL)),
      FOREIGN KEY (placement_id, preceptor_id, student_id)
        REFERENCES placement_preceptors(placement_id, preceptor_id, student_id)
    ) STRICT''',
  ],
  2: [
    '''CREATE TABLE IF NOT EXISTS schema_migrations (
      version INTEGER PRIMARY KEY CHECK (version > 0),
      applied_at_utc TEXT NOT NULL
    ) STRICT''',
    '''CREATE TABLE settings (
      $_syncColumns,
      week_start INTEGER NOT NULL DEFAULT 7 CHECK (week_start BETWEEN 1 AND 7),
      time_display TEXT NOT NULL DEFAULT 'military' CHECK (time_display IN ('military', 'twelve_hour')),
      theme TEXT NOT NULL DEFAULT 'borg_tactical',
      synchronization_mode TEXT NOT NULL DEFAULT 'enabled' CHECK (synchronization_mode IN ('enabled', 'paused')),
      notification_preferences_json TEXT NOT NULL DEFAULT '{}',
      active_placement_id TEXT,
      PRIMARY KEY (id),
      UNIQUE (student_id),
      FOREIGN KEY (student_id) REFERENCES student_profiles(student_id),
      FOREIGN KEY (active_placement_id, student_id)
        REFERENCES clinical_placements(id, student_id)
    ) STRICT''',
    '''CREATE TABLE reminder_state (
      $_syncColumns,
      reminder_type TEXT NOT NULL,
      subject_entity_id TEXT,
      scheduled_for_utc TEXT,
      snoozed_until_utc TEXT,
      resolved_at_utc TEXT,
      resolution_source TEXT,
      PRIMARY KEY (id),
      UNIQUE (id, student_id),
      FOREIGN KEY (student_id) REFERENCES student_profiles(student_id)
    ) STRICT''',
    '''CREATE TABLE device_metadata (
      $_syncColumns,
      device_name TEXT NOT NULL,
      platform TEXT NOT NULL CHECK (platform IN ('windows', 'ios', 'android')),
      notification_enabled INTEGER NOT NULL DEFAULT 0 CHECK (notification_enabled IN (0, 1)),
      detailed_preview_enabled INTEGER NOT NULL DEFAULT 0 CHECK (detailed_preview_enabled IN (0, 1)),
      last_synchronized_at_utc TEXT,
      revoked_at_utc TEXT,
      PRIMARY KEY (id),
      UNIQUE (id, student_id),
      FOREIGN KEY (student_id) REFERENCES student_profiles(student_id)
    ) STRICT''',
    '''CREATE TABLE reminder_delivery_state (
      reminder_id TEXT NOT NULL,
      device_id TEXT NOT NULL,
      student_id TEXT NOT NULL,
      scheduled_notification_id TEXT,
      delivered_at_utc TEXT,
      dismissed_at_utc TEXT,
      PRIMARY KEY (reminder_id, device_id),
      FOREIGN KEY (reminder_id, student_id) REFERENCES reminder_state(id, student_id),
      FOREIGN KEY (device_id, student_id) REFERENCES device_metadata(id, student_id)
    ) STRICT''',
    '''CREATE TABLE trash (
      $_syncColumns,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      deleted_snapshot_json TEXT NOT NULL,
      purge_after_utc TEXT NOT NULL,
      permanently_deleted_at_utc TEXT,
      PRIMARY KEY (id),
      UNIQUE (id, student_id),
      UNIQUE (student_id, entity_type, entity_id),
      FOREIGN KEY (student_id) REFERENCES student_profiles(student_id)
    ) STRICT''',
    '''CREATE TABLE sync_cursors (
      student_id TEXT NOT NULL,
      remote_scope TEXT NOT NULL,
      server_cursor INTEGER NOT NULL DEFAULT 0 CHECK (server_cursor >= 0),
      updated_at_utc TEXT NOT NULL,
      PRIMARY KEY (student_id, remote_scope),
      FOREIGN KEY (student_id) REFERENCES student_profiles(student_id)
    ) STRICT''',
    '''CREATE TABLE sync_state (
      student_id TEXT PRIMARY KEY NOT NULL,
      disposition TEXT NOT NULL CHECK (disposition IN ('synced', 'offline', 'syncing', 'conflict', 'failed')),
      last_success_at_utc TEXT,
      last_attempt_at_utc TEXT,
      failure_code TEXT,
      FOREIGN KEY (student_id) REFERENCES student_profiles(student_id)
    ) STRICT''',
    '''CREATE TABLE sync_conflicts (
      $_syncColumns,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      local_revision INTEGER NOT NULL CHECK (local_revision >= 0),
      remote_revision INTEGER NOT NULL CHECK (remote_revision >= 0),
      local_snapshot_json TEXT NOT NULL,
      remote_snapshot_json TEXT NOT NULL,
      detected_at_utc TEXT NOT NULL,
      resolved_at_utc TEXT,
      resolution_json TEXT,
      PRIMARY KEY (id),
      UNIQUE (id, student_id),
      FOREIGN KEY (student_id) REFERENCES student_profiles(student_id)
    ) STRICT''',
    '''CREATE TABLE outbox_operations (
      id TEXT PRIMARY KEY NOT NULL CHECK (length(id) = 36),
      student_id TEXT NOT NULL CHECK (length(student_id) = 36),
      idempotency_key TEXT NOT NULL CHECK (length(idempotency_key) = 36),
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL CHECK (length(entity_id) = 36),
      operation_type TEXT NOT NULL CHECK (operation_type IN ('upsert', 'delete', 'resolve_conflict')),
      base_revision INTEGER NOT NULL CHECK (base_revision >= 0),
      payload_json TEXT NOT NULL,
      created_at_utc TEXT NOT NULL,
      attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
      next_attempt_at_utc TEXT,
      acknowledged_cursor INTEGER CHECK (acknowledged_cursor >= 0),
      acknowledged_at_utc TEXT,
      last_failure_code TEXT,
      UNIQUE (idempotency_key),
      FOREIGN KEY (student_id) REFERENCES student_profiles(student_id)
    ) STRICT''',
  ],
  3: [
    '''CREATE TABLE IF NOT EXISTS schema_migrations (
      version INTEGER PRIMARY KEY CHECK (version > 0),
      applied_at_utc TEXT NOT NULL
    ) STRICT''',
    'CREATE INDEX commitments_calendar_index ON commitments(student_id, planned_start_utc, planned_end_utc) WHERE deleted_at_utc IS NULL',
    'CREATE INDEX commitments_placement_index ON commitments(placement_id, lifecycle_state) WHERE deleted_at_utc IS NULL',
    'CREATE INDEX protected_days_date_index ON protected_days(student_id, local_date) WHERE deleted_at_utc IS NULL',
    'CREATE INDEX historical_hours_placement_index ON historical_hours_entries(placement_id) WHERE deleted_at_utc IS NULL',
    'CREATE INDEX evaluation_requirements_due_index ON evaluation_requirements(student_id, status) WHERE deleted_at_utc IS NULL',
    'CREATE INDEX reminder_due_index ON reminder_state(student_id, scheduled_for_utc) WHERE resolved_at_utc IS NULL AND deleted_at_utc IS NULL',
    'CREATE INDEX trash_purge_index ON trash(student_id, purge_after_utc) WHERE permanently_deleted_at_utc IS NULL',
    'CREATE INDEX outbox_pending_index ON outbox_operations(student_id, created_at_utc) WHERE acknowledged_at_utc IS NULL',
    'CREATE INDEX sync_conflicts_open_index ON sync_conflicts(student_id, detected_at_utc) WHERE resolved_at_utc IS NULL',
  ],
  4: [
    '''ALTER TABLE evaluation_requirements
      ADD COLUMN is_currently_required INTEGER NOT NULL DEFAULT 1
      CHECK (is_currently_required IN (0, 1))''',
  ],
  5: [
    '''ALTER TABLE outbox_operations
      ADD COLUMN terminal_rejection_code TEXT''',
    '''ALTER TABLE outbox_operations
      ADD COLUMN terminal_rejected_at_utc TEXT''',
    '''ALTER TABLE sync_state
      ADD COLUMN failure_started_at_utc TEXT''',
    // Pre-release random Settings identities are safe to rewrite only before
    // the idempotency key could have reached the server. Otherwise opening
    // fails atomically and the pre-release database must be reset.
    '''CREATE TEMP TABLE settings_identity_migration_guard (
      invalid INTEGER NOT NULL CHECK (invalid = 0)
    ) STRICT''',
    '''INSERT INTO settings_identity_migration_guard (invalid)
      SELECT 1 FROM outbox_operations
      WHERE entity_type = 'settings'
        AND entity_id <> student_id
        AND (attempt_count > 0 OR acknowledged_at_utc IS NOT NULL)
      LIMIT 1''',
    r'''UPDATE outbox_operations
      SET entity_id = student_id,
          payload_json = json_set(payload_json, '$.entity_id', student_id)
      WHERE entity_type = 'settings' AND entity_id <> student_id''',
    r'''UPDATE sync_conflicts
      SET entity_id = student_id,
          local_snapshot_json = json_set(
            local_snapshot_json, '$.entity_id', student_id
          ),
          remote_snapshot_json = json_set(
            remote_snapshot_json, '$.entity_id', student_id
          )
      WHERE entity_type = 'settings' AND entity_id <> student_id''',
    'UPDATE settings SET id = student_id WHERE id <> student_id',
    'DROP TABLE settings_identity_migration_guard',
    'DROP INDEX outbox_pending_index',
    '''CREATE INDEX outbox_pending_index
      ON outbox_operations(student_id, created_at_utc)
      WHERE acknowledged_at_utc IS NULL
        AND terminal_rejected_at_utc IS NULL''',
  ],
};
