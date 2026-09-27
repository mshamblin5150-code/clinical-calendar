$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$wrapperPath = Join-Path $PSScriptRoot 'build_pages.ps1'
if (-not (Test-Path -LiteralPath $wrapperPath)) {
  throw 'The validated web release wrapper is missing.'
}

$saved = @{}
foreach ($name in @(
    'CLINICAL_CALENDAR_ENVIRONMENT',
    'CLINICAL_CALENDAR_SUPABASE_URL',
    'CLINICAL_CALENDAR_SUPABASE_PUBLISHABLE_KEY'
  )) {
  $saved[$name] = [Environment]::GetEnvironmentVariable($name)
}

$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) `
  "clinical-calendar-pages-$([Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
$capturePath = Join-Path $temporaryDirectory 'arguments.json'
$fakeFlutterPath = Join-Path $temporaryDirectory 'flutter.ps1'
@'
param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments)
$Arguments | ConvertTo-Json | Set-Content -LiteralPath $env:CAPTURE_PATH
'@ | Set-Content -LiteralPath $fakeFlutterPath

try {
  $env:CLINICAL_CALENDAR_ENVIRONMENT = 'private-release'
  $env:CLINICAL_CALENDAR_SUPABASE_URL = 'https://project.example.test'
  $env:CLINICAL_CALENDAR_SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_test-only'
  $env:CAPTURE_PATH = $capturePath

  & $wrapperPath -FlutterExecutable $fakeFlutterPath
  $arguments = @(Get-Content -LiteralPath $capturePath -Raw | ConvertFrom-Json)
  $versionLine = Get-Content -LiteralPath `
    (Join-Path $repositoryRoot 'apps\clinical_calendar\pubspec.yaml') |
    Where-Object { $_ -match '^version:\s*' } |
    Select-Object -First 1
  if ($versionLine -notmatch '^version:\s*\d+\.\d+\.\d+\+(\d+)\s*$') {
    throw 'The application pubspec has no numeric build number.'
  }
  $buildNumber = [int]$Matches[1]
  $expected = @(
    'build',
    'web',
    '--release',
    '--base-href',
    '/clinical-calendar/',
    '--dart-define=CLINICAL_CALENDAR_ENVIRONMENT=private-release',
    '--dart-define=CLINICAL_CALENDAR_SUPABASE_URL=https://project.example.test',
    '--dart-define=CLINICAL_CALENDAR_SUPABASE_PUBLISHABLE_KEY=sb_publishable_test-only',
    "--dart-define=CLINICAL_CALENDAR_BUILD_NUMBER=$buildNumber"
  )
  foreach ($argument in $expected) {
    if (-not $arguments.Contains($argument)) {
      throw "Web release build omitted argument: $argument"
    }
  }
} finally {
  foreach ($entry in $saved.GetEnumerator()) {
    [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value)
  }
  Remove-Item Env:CAPTURE_PATH -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $capturePath, $fakeFlutterPath -Force `
    -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $temporaryDirectory -Force
}

Write-Host 'Pages build contract passed.'
