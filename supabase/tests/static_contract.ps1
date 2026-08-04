$ErrorActionPreference = 'Stop'

$migration = Get-Content -Raw (
  Join-Path $PSScriptRoot '..\migrations\202608030001_sync_backend.sql'
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

$assertionCount = (
  Select-String -Path (Join-Path $PSScriptRoot 'sync_backend_test.sql') `
    -Pattern '^select (ok|is|results_eq|throws_ok)\(' -CaseSensitive
).Count
if ($assertionCount -ne 27) {
  throw "pgTAP plan is 27 but found $assertionCount assertions."
}

Write-Output 'Static synchronization contract checks passed.'
