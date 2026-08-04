$ErrorActionPreference = 'Stop'

$migration = Get-Content -Raw (
  Join-Path $PSScriptRoot '..\migrations\202608030001_sync_backend.sql'
)
$identityMigration = Get-Content -Raw (
  Join-Path $PSScriptRoot '..\migrations\202608030002_passwordless_identity_devices.sql'
)
$erasureMigration = Get-Content -Raw (
  Join-Path $PSScriptRoot '..\migrations\202608040003_account_erasure.sql'
)

$requiredPatterns = @(
  'alter table clinical_calendar_sync.records force row level security',
  "student_id = (select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid)",
  'security definer',
  'security invoker',
  'pg_catalog.pg_advisory_xact_lock',
  'on conflict (student_id, idempotency_key) do nothing',
  "'stale_revision'",
  "'schedule_conflict'",
  "'protected_day_violation'",
  "where f.student_id = (select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid)",
  'and f.cursor > greatest(p_after_cursor, 0)',
  'order by f.cursor',
  'revoke all on all tables in schema clinical_calendar_sync from public, anon, authenticated'
)

foreach ($pattern in $requiredPatterns) {
  if (-not $migration.Contains($pattern)) {
    throw "Missing synchronization contract pattern: $pattern"
  }
}

$identityPatterns = @(
  'create table clinical_calendar_sync.connected_devices',
  "current_setting('request.jwt.claim.session_id', true)",
  'clinical_calendar_sync.current_device_is_active()',
  'pg_catalog.pg_advisory_xact_lock(',
  "jsonb_build_object('code', 'revoked_device')",
  "raise sqlstate 'PT403' using message = 'revoked_device'",
  'public.register_current_device(uuid, text, text)',
  'public.revoke_connected_device(uuid)',
  'public.deactivate_current_device()',
  'revoke all on clinical_calendar_sync.connected_devices from public, anon, authenticated',
  'revoke select on clinical_calendar_sync.records'
)

foreach ($pattern in $identityPatterns) {
  if (-not $identityMigration.Contains($pattern)) {
    throw "Missing identity/device contract pattern: $pattern"
  }
}

$erasurePatterns = @(
  'create table clinical_calendar_sync.account_erasure_jobs',
  'create table clinical_calendar_sync.account_recovery_snapshots',
  "status in ('pending', 'cancelled', 'complete')",
  "purge_after_utc = requested_at_utc + interval '30 days'",
  "encryption_algorithm = 'aes-256-gcm'",
  'alter table clinical_calendar_sync.account_erasure_jobs force row level security',
  'alter table clinical_calendar_sync.account_recovery_snapshots force row level security',
  'clinical_calendar_sync.has_fresh_reauthentication(v_now)',
  "p_backup_choice = 'cancelled'",
  'public.cancel_account_erasure()',
  'rename to register_current_device_without_erasure_recovery',
  'clinical_calendar_sync.purge_due_account_erasure(',
  'delete from auth.users where id = p_student_id',
  "p_now_utc + interval '30 days'",
  'clinical_calendar_sync.delete_expired_recovery_snapshots(',
  'from public, anon, authenticated, clinical_calendar_sync_executor'
)

foreach ($pattern in $erasurePatterns) {
  if (-not $erasureMigration.Contains($pattern)) {
    throw "Missing account-erasure contract pattern: $pattern"
  }
}

$permanentPurgePatterns = @(
  'create table clinical_calendar_sync.purge_markers',
  "operation_type in ('upsert', 'delete', 'resolve_conflict', 'purge')",
  'alter table clinical_calendar_sync.purge_markers force row level security',
  'clinical_calendar_sync.purge_marker_owner(',
  'clinical_calendar_sync.apply_permanent_purge(',
  "p_operation_type = 'purge'",
  "'code', 'permanently_purged'",
  "'value', '{}'::jsonb",
  "'purge', v_feed_payload",
  'delete from clinical_calendar_sync.records',
  'delete from clinical_calendar_sync.purge_markers where student_id = p_student_id'
)
foreach ($pattern in $permanentPurgePatterns) {
  if (-not $erasureMigration.Contains($pattern)) {
    throw "Missing permanent-purge contract pattern: $pattern"
  }
}

$assertionCount = (
  Select-String -Path (Join-Path $PSScriptRoot 'sync_backend_test.sql') `
    -Pattern '^select (ok|is|results_eq|throws_ok)\(' -CaseSensitive
).Count
if ($assertionCount -ne 28) {
  throw "pgTAP plan is 28 but found $assertionCount assertions."
}

$identityAssertionCount = (
  Select-String -Path (Join-Path $PSScriptRoot 'identity_devices_test.sql') `
    -Pattern '^select (ok|is|results_eq|throws_ok)\(' -CaseSensitive
).Count
if ($identityAssertionCount -ne 25) {
  throw "Identity/device pgTAP plan is 25 but found $identityAssertionCount assertions."
}

$erasureAssertionCount = (
  Select-String -Path (Join-Path $PSScriptRoot 'account_erasure_test.sql') `
    -Pattern '^select (ok|is|results_eq|throws_ok)\(' -CaseSensitive
).Count
if ($erasureAssertionCount -ne 36) {
  throw "Account-erasure pgTAP plan is 36 but found $erasureAssertionCount assertions."
}

$permanentPurgeAssertionCount = (
  Select-String -Path (Join-Path $PSScriptRoot 'permanent_purge_test.sql') `
    -Pattern '^select (ok|is|results_eq|throws_ok)\(' -CaseSensitive
).Count
if ($permanentPurgeAssertionCount -ne 24) {
  throw "Permanent-purge pgTAP plan is 24 but found $permanentPurgeAssertionCount assertions."
}

$erasureConcurrencyFiles = @(
  'account_erasure_concurrency_setup.sql',
  'account_erasure_concurrency_session_a.sql',
  'account_erasure_concurrency_session_b.sql',
  'account_erasure_concurrency_verify.sql',
  'account_erasure_concurrency_cleanup.sql'
)
foreach ($file in $erasureConcurrencyFiles) {
  if (-not (Test-Path (Join-Path $PSScriptRoot $file))) {
    throw "Missing account-erasure concurrency contract file: $file"
  }
}


$permanentPurgeConcurrencyFiles = @(
  'permanent_purge_concurrency_setup.sql',
  'permanent_purge_concurrency_session_a.sql',
  'permanent_purge_concurrency_session_b.sql',
  'permanent_purge_concurrency_verify.sql',
  'permanent_purge_concurrency_cleanup.sql'
)
foreach ($file in $permanentPurgeConcurrencyFiles) {
  if (-not (Test-Path (Join-Path $PSScriptRoot $file))) {
    throw "Missing permanent-purge concurrency contract file: $file"
  }
}

Write-Output 'Static synchronization contract checks passed.'
