$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$workflow = Get-Content -Raw (Join-Path $repositoryRoot '.github/workflows/android-release.yml')
$gradle = Get-Content -Raw (Join-Path $repositoryRoot 'apps/clinical_calendar/android/app/build.gradle.kts')
$manifest = Get-Content -Raw (Join-Path $repositoryRoot 'apps/clinical_calendar/android/app/src/main/AndroidManifest.xml')
$mainActivity = Get-Content -Raw (Join-Path $repositoryRoot 'apps/clinical_calendar/android/app/src/main/kotlin/com/clinicalcalendar/clinical_calendar/MainActivity.kt')

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
    'CLINICAL_CALENDAR_ENVIRONMENT: private-release',
    'vars.CLINICAL_CALENDAR_SUPABASE_URL',
    'secrets.CLINICAL_CALENDAR_SUPABASE_PUBLISHABLE_KEY',
    'package_signed_profile_apk.ps1',
    'capture_release_size_ledger.ps1',
    'release-size-ledger.json',
    'app-release.apk.sha256',
    'app-profile.apk.sha256'
)
foreach ($fragment in $requiredWorkflowFragments) {
    if (-not $workflow.Contains($fragment)) {
        throw "Android release workflow is missing required fragment: $fragment"
    }
}
if ($workflow.Contains('AllowUnconfiguredAcceptanceBuild')) {
    throw 'Protected Android release workflow must never allow unconfigured acceptance builds.'
}

if (-not $manifest.Contains('android.permission.INTERNET')) {
    throw 'Android release manifest must grant network access for authentication and synchronization.'
}
if ($manifest.Contains('android:process=":restart"') -or
    $mainActivity.Contains('exitProcess') -or
    $mainActivity.Contains('restartProcess')) {
    throw 'Android release must preserve the live application host and unsaved planning state.'
}
if (-not $mainActivity.Contains('notifyLowMemoryWarning') -or
    -not $mainActivity.Contains('sendMemoryPressureWarning') -or
    -not $mainActivity.Contains('runFinalization') -or
    -not $mainActivity.Contains('postDelayed') -or
    -not $mainActivity.Contains('trimGallery')) {
    throw 'Gallery cleanup must notify the live Android host of releasable memory.'
}
if ($mainActivity.Contains('detachFromRenderer') -or
    $mainActivity.Contains('attachToRenderer')) {
    throw 'Gallery cleanup must keep the live rendering surface attached.'
}
$packager = Get-Content -Raw (Join-Path $repositoryRoot 'tool/android/package_signed_apk.ps1')
if (-not $packager.Contains('Get-ClinicalCalendarReleaseFlutterArguments')) {
    throw 'Android release packaging must resolve protected Supabase compile-time configuration.'
}
$ledgerCapture = Get-Content -Raw (Join-Path $repositoryRoot 'tool/android/capture_release_size_ledger.ps1')
foreach ($fragment in @(
    'package_signed_apk.ps1',
    'ExpectedSignerSha256',
    'unattributedGrowthBytes = 0'
)) {
    if (-not $ledgerCapture.Contains($fragment)) {
        throw "Release-size ledger capture is missing required fragment: $fragment"
    }
}

$profilePackagerPath = Join-Path $repositoryRoot 'tool/android/package_signed_profile_apk.ps1'
if (-not (Test-Path -LiteralPath $profilePackagerPath -PathType Leaf)) {
    throw 'Protected Android profile packaging script is missing.'
}
$profilePackager = Get-Content -Raw $profilePackagerPath
foreach ($fragment in @(
    'build apk --profile',
    'Get-ClinicalCalendarReleaseFlutterArguments',
    'verify_signed_apk.ps1',
    'app-profile.apk.sha256'
)) {
    if (-not $profilePackager.Contains($fragment)) {
        throw "Android profile packaging is missing required fragment: $fragment"
    }
}

if ($gradle.Contains('signingConfigs.getByName("debug")')) {
    throw 'Android release build must not use the debug signing configuration.'
}
if (-not $gradle.Contains('getByName("profile")') -or
    -not $gradle.Contains('signingConfigs.getByName("release")')) {
    throw 'Protected Android profile builds must use the approved release signer when configured.'
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
