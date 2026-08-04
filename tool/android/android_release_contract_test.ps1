$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$workflow = Get-Content -Raw (Join-Path $repositoryRoot '.github/workflows/android-release.yml')
$gradle = Get-Content -Raw (Join-Path $repositoryRoot 'apps/clinical_calendar/android/app/build.gradle.kts')

$requiredWorkflowFragments = @(
    'actions/checkout@11d5960a326750d5838078e36cf38b85af677262',
    'actions/setup-java@d7793b545071e98d581d3bf084a51c3213318a07',
    'android-actions/setup-android@9fc6c4e9069bf8d3d10b2204b1fb8f6ef7065407',
    'subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2',
    'actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02',
    'java-version: 17.0.20+8',
    'platforms;android-36',
    'build-tools;36.0.0',
    'flutter-version: 3.44.8',
    'environment: android-private-release',
    'secrets.ANDROID_KEYSTORE_BASE64',
    'secrets.ANDROID_KEYSTORE_PASSWORD',
    'secrets.ANDROID_KEY_ALIAS',
    'secrets.ANDROID_KEY_PASSWORD',
    'vars.ANDROID_SIGNING_CERT_SHA256',
    'package_signed_apk.ps1',
    'app-release.apk.sha256'
)
foreach ($fragment in $requiredWorkflowFragments) {
    if (-not $workflow.Contains($fragment)) {
        throw "Android release workflow is missing required fragment: $fragment"
    }
}

if ($gradle.Contains('signingConfigs.getByName("debug")')) {
    throw 'Android release build must not use the debug signing configuration.'
}
foreach ($name in @(
    'CLINICAL_CALENDAR_ANDROID_KEYSTORE_PATH',
    'CLINICAL_CALENDAR_ANDROID_KEYSTORE_PASSWORD',
    'CLINICAL_CALENDAR_ANDROID_KEY_ALIAS',
    'CLINICAL_CALENDAR_ANDROID_KEY_PASSWORD'
)) {
    if (-not $gradle.Contains($name)) {
        throw "Android Gradle configuration is missing $name."
    }
}

Write-Host 'Android release contract passed.'
