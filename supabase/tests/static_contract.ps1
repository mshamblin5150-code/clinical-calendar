$ErrorActionPreference = 'Stop'

$migration = Get-Content -Raw (
  Join-Path $PSScriptRoot '..\migrations\202608030001_sync_backend.sql'
)
$identityMigration = Get-Content -Raw (
  Join-Path $PSScriptRoot '..\migrations\202608030002_passwordless_identity_devices.sql'
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

Write-Output 'Static synchronization contract checks passed.'
