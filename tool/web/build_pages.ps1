param(
  [string]$FlutterExecutable = 'flutter'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$applicationRoot = Join-Path $repositoryRoot 'apps\clinical_calendar'
. (Join-Path $repositoryRoot 'tool\release\resolve_flutter_release_defines.ps1')

$versionLine = Get-Content -LiteralPath (Join-Path $applicationRoot 'pubspec.yaml') |
  Where-Object { $_ -match '^version:\s*' } |
  Select-Object -First 1
if (-not $versionLine -or $versionLine -notmatch '^version:\s*\d+\.\d+\.\d+\+(\d+)\s*$') {
  throw 'The web release requires a positive numeric build in pubspec.yaml.'
}
$buildNumber = [int]$Matches[1]
if ($buildNumber -lt 1) {
  throw 'The web release build number must be positive.'
}

$buildIdPath = Join-Path $applicationRoot 'web\build-id.json'
$buildId = Get-Content -LiteralPath $buildIdPath -Raw | ConvertFrom-Json
if ($buildId.build_number -ne $buildNumber) {
  throw 'web/build-id.json must match the pubspec build number.'
}

$releaseArguments = @(Get-ClinicalCalendarReleaseFlutterArguments)
$releaseArguments += "--dart-define=CLINICAL_CALENDAR_BUILD_NUMBER=$buildNumber"

Push-Location $applicationRoot
try {
  $LASTEXITCODE = 0
  & $FlutterExecutable `
    build web --release `
    --base-href '/clinical-calendar/' `
    @releaseArguments
  if (-not $? -or $LASTEXITCODE -ne 0) {
    throw "Flutter web release build failed with exit code $LASTEXITCODE."
  }
} finally {
  Pop-Location
}
