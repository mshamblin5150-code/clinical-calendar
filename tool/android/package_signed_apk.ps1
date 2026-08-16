[CmdletBinding()]
param(
    [string] $FlutterExecutable = 'flutter',
    [Parameter(Mandatory = $true)]
    [string] $ExpectedSignerSha256,
    [switch] $AllowUnconfiguredAcceptanceBuild
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$requiredEnvironment = @(
    'CLINICAL_CALENDAR_ANDROID_KEYSTORE_PATH',
    'CLINICAL_CALENDAR_ANDROID_KEYSTORE_PASSWORD',
    'CLINICAL_CALENDAR_ANDROID_KEY_ALIAS',
    'CLINICAL_CALENDAR_ANDROID_KEY_PASSWORD'
)
foreach ($name in $requiredEnvironment) {
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
        throw "Signed Android build requires $name."
    }
}
if (-not (Test-Path -LiteralPath $env:CLINICAL_CALENDAR_ANDROID_KEYSTORE_PATH -PathType Leaf)) {
    throw 'The configured Android release keystore does not exist.'
}

$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$applicationPath = Join-Path $repositoryRoot 'apps/clinical_calendar'
$apkPath = Join-Path $applicationPath 'build/app/outputs/flutter-apk/app-release.apk'
. (Join-Path $repositoryRoot 'tool/release/resolve_flutter_release_defines.ps1')
$releaseArguments = if ($AllowUnconfiguredAcceptanceBuild) {
    @()
} else {
    Get-ClinicalCalendarReleaseFlutterArguments
}

Push-Location $applicationPath
try {
    & $FlutterExecutable build apk --release @releaseArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter Android release build failed with exit code $LASTEXITCODE."
    }
} finally {
    Pop-Location
}

& (Join-Path $PSScriptRoot 'verify_signed_apk.ps1') `
    -ApkPath $apkPath `
    -ExpectedSignerSha256 $ExpectedSignerSha256
& (Join-Path $PSScriptRoot 'verify_presentation_assets_in_apk.ps1') `
    -ApkPath $apkPath
