$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'resolve_flutter_release_defines.ps1')

$names = @(
  'CLINICAL_CALENDAR_ENVIRONMENT',
  'CLINICAL_CALENDAR_SUPABASE_URL',
  'CLINICAL_CALENDAR_SUPABASE_PUBLISHABLE_KEY'
)
$saved = @{}
foreach ($name in $names) {
  $saved[$name] = [Environment]::GetEnvironmentVariable($name)
}

function Assert-Fails {
  param([Parameter(Mandatory)][scriptblock]$Action)
  try {
    & $Action
  } catch {
    return
  }
  throw 'Expected release configuration validation to fail.'
}

try {
  foreach ($name in $names) {
    [Environment]::SetEnvironmentVariable($name, $null)
  }
  Assert-Fails { Get-ClinicalCalendarReleaseFlutterArguments }

  $env:CLINICAL_CALENDAR_ENVIRONMENT = 'private-release'
  $env:CLINICAL_CALENDAR_SUPABASE_URL = 'http://project.example.test'
  $env:CLINICAL_CALENDAR_SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_test-only'
  Assert-Fails { Get-ClinicalCalendarReleaseFlutterArguments }

  $env:CLINICAL_CALENDAR_SUPABASE_URL = 'https://project.example.test'
  $env:CLINICAL_CALENDAR_SUPABASE_PUBLISHABLE_KEY = 'sb_secret_forbidden-test'
  Assert-Fails { Get-ClinicalCalendarReleaseFlutterArguments }

  $env:CLINICAL_CALENDAR_SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_test-only'
  $arguments = @(Get-ClinicalCalendarReleaseFlutterArguments)
  if ($arguments.Count -ne 3 -or
      -not $arguments.Contains(
        '--dart-define=CLINICAL_CALENDAR_ENVIRONMENT=private-release'
      )) {
    throw 'Release configuration did not produce the required Flutter defines.'
  }
} finally {
  foreach ($name in $names) {
    [Environment]::SetEnvironmentVariable($name, $saved[$name])
  }
}

Write-Host 'Release configuration contract passed.'
