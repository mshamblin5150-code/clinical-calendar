$ErrorActionPreference = 'Stop'

$migration = Get-Content -Raw (
  Join-Path $PSScriptRoot '..\migrations\202609270001_work_schedule_feed_relay.sql'
)

$requiredPatterns = @(
  'create table clinical_calendar_sync.work_schedule_feeds',
  "url ~* '^(https|webcal)://'",
  'create table clinical_calendar_sync.work_schedule_feed_cache',
  "interval '15 minutes'",
  'public.claim_work_schedule_feed_relay',
  'public.finish_work_schedule_feed_relay',
  "message = 'invalid_relay_lease'",
  'octet_length(ics_text) <= 3145728',
  'from public, anon',
  'to authenticated'
)

foreach ($pattern in $requiredPatterns) {
  if (-not $migration.Contains($pattern)) {
    throw "Missing Work Schedule Feed relay contract pattern: $pattern"
  }
}

$assertionCount = (
  Select-String -Path (Join-Path $PSScriptRoot 'work_schedule_feed_relay_test.sql') `
    -Pattern '^select (ok|is|results_eq|throws_ok)\(' -CaseSensitive
).Count
if ($assertionCount -ne 7) {
  throw "Work Schedule Feed relay pgTAP plan is 7 but found $assertionCount assertions."
}

Write-Output 'Work Schedule Feed relay static contract checks passed.'
