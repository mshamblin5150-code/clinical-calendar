[CmdletBinding()]
param(
    [string]$AdbPath = (Join-Path $PSScriptRoot '..\..\.tooling\android-sdk\platform-tools\adb.exe'),
    [string]$DartPath = (Join-Path $PSScriptRoot '..\..\.tooling\flutter\bin\cache\dart-sdk\bin\dart.exe'),
    [string]$Serial,
    [string]$PackageId = 'com.clinicalcalendar.clinical_calendar',
    [string]$FixtureId = 'containment-drone-fictional-v1',
    [switch]$SkipRestart,
    [switch]$AutomateFocusedFlow,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-fA-F]{64}$')]
    [string]$BuildArtifactSha256,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-fA-F]{40}$')]
    [string]$BuildCommit,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    [ValidateRange(5, 120)]
    [int]$SampleSeconds = 30
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not $FixtureId.Contains('fictional')) {
    throw 'FixtureId must explicitly identify a fictional fixture.'
}
if (-not (Test-Path -LiteralPath $AdbPath -PathType Leaf)) {
    throw "adb was not found at $AdbPath"
}
if (-not (Test-Path -LiteralPath $DartPath -PathType Leaf)) {
    throw "Dart was not found at $DartPath"
}
$timelineParser = Join-Path $PSScriptRoot 'parse_flutter_timeline.dart'
if (-not (Test-Path -LiteralPath $timelineParser -PathType Leaf)) {
    throw 'The Flutter timeline parser is missing.'
}

function Invoke-Adb {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        # Windows PowerShell surfaces native stderr as ErrorRecord objects. adb
        # writes successful transfer progress there, so rely on its exit code.
        $ErrorActionPreference = 'Continue'
        $result = & $AdbPath -s $script:DeviceSerial @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($exitCode -ne 0) {
        throw "adb command failed: $($Arguments -join ' ')"
    }
    return ($result -join "`n")
}

function Assert-PackageForeground {
    $activities = Invoke-Adb shell dumpsys activity activities
    $packagePattern = [regex]::Escape($PackageId)
    if ($activities -notmatch "topResumedActivity=.*\s$packagePattern/") {
        throw 'The application did not remain in the foreground for the profile sample.'
    }
}

if ([string]::IsNullOrWhiteSpace($Serial)) {
    $deviceLines = & $AdbPath devices | Select-Object -Skip 1 | Where-Object {
        $_ -match "^([^\s]+)\s+device$"
    }
    if (@($deviceLines).Count -ne 1) {
        throw 'Connect exactly one authorized Android device or pass -Serial.'
    }
    $Serial = ([regex]::Match($deviceLines[0], '^([^\s]+)')).Groups[1].Value
}
$script:DeviceSerial = $Serial

$packageInfo = Invoke-Adb shell dumpsys package $PackageId
if (-not $packageInfo.Contains('DEBUGGABLE')) {
    throw 'The installed application is not a profile-capable build (DEBUGGABLE flag absent).'
}
$versionCode = [regex]::Match($packageInfo, 'versionCode=(\d+)').Groups[1].Value
$versionName = [regex]::Match($packageInfo, 'versionName=([^\s]+)').Groups[1].Value
if ([string]::IsNullOrWhiteSpace($versionCode) -or [string]::IsNullOrWhiteSpace($versionName)) {
    throw 'Unable to resolve the installed application version.'
}

$packagePathOutput = Invoke-Adb shell pm path $PackageId
$installedApkPath = [regex]::Match($packagePathOutput, '(?m)^package:(.+base\.apk)$').Groups[1].Value.Trim()
if ([string]::IsNullOrWhiteSpace($installedApkPath)) {
    throw 'Unable to resolve the installed base APK.'
}
$temporaryApk = [IO.Path]::GetTempFileName()
try {
    $null = Invoke-Adb pull $installedApkPath $temporaryApk
    $installedSha256 = (Get-FileHash -LiteralPath $temporaryApk -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($installedSha256 -ne $BuildArtifactSha256.ToLowerInvariant()) {
        throw 'The installed APK does not match -BuildArtifactSha256.'
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($temporaryApk)
    try {
        $entryNames = @($archive.Entries | ForEach-Object FullName)
        $hasAotLibrary = @($entryNames | Where-Object { $_ -match '^lib/[^/]+/libapp\.so$' }).Count -gt 0
        $hasDebugKernel = @($entryNames | Where-Object { $_ -eq 'assets/flutter_assets/kernel_blob.bin' }).Count -gt 0
        if (-not $hasAotLibrary -or $hasDebugKernel) {
            throw 'The installed APK is debug-shaped rather than an AOT profile build.'
        }
    }
    finally {
        $archive.Dispose()
    }
}
finally {
    Remove-Item -LiteralPath $temporaryApk -Force -ErrorAction SilentlyContinue
}

if (-not $SkipRestart) {
    $null = Invoke-Adb shell am force-stop $PackageId
    $null = Invoke-Adb shell monkey -p $PackageId 1
}
Start-Sleep -Seconds 2
Assert-PackageForeground
$targetPid = (Invoke-Adb shell pidof $PackageId).Trim()
if ($targetPid -notmatch '^\d+$') {
    throw 'Unable to resolve the application process id.'
}
$logcat = Invoke-Adb logcat '-d' '-v' brief
$escapedPid = [regex]::Escape($targetPid)
$serviceMatches = [regex]::Matches(
    $logcat,
    "I/flutter\s*\(\s*$escapedPid\s*\).*Dart VM service is listening on http://127\.0\.0\.1:(\d+)/([^\s/]+)/"
)
if ($serviceMatches.Count -eq 0) {
    throw 'Unable to locate the profile build Dart VM service.'
}
$serviceMatch = $serviceMatches[$serviceMatches.Count - 1]
$deviceServicePort = $serviceMatch.Groups[1].Value
$serviceToken = $serviceMatch.Groups[2].Value
$hostServicePort = (Invoke-Adb forward 'tcp:0' "tcp:$deviceServicePort").Trim()
if ($hostServicePort -notmatch '^\d+$') {
    throw 'Unable to forward the Dart VM service port.'
}
$serviceBaseUri = "http://127.0.0.1:$hostServicePort/$serviceToken/"

$displayInfo = Invoke-Adb shell dumpsys display
$memoryBefore = Invoke-Adb shell dumpsys meminfo $PackageId
try {
    $null = Invoke-RestMethod -Uri "${serviceBaseUri}clearVMTimeline" -TimeoutSec 10
    $timelineOriginMicros = [long](
        Invoke-RestMethod -Uri "${serviceBaseUri}getVMTimelineMicros" -TimeoutSec 10
    ).result.timestamp
    Write-Host "Sampling the focused flow for $SampleSeconds seconds."
    $sampleClock = [Diagnostics.Stopwatch]::StartNew()
    if ($AutomateFocusedFlow) {
        $nativeGeometry = [regex]::Match(
            $displayInfo,
            'mBaseDisplayInfo=DisplayInfo\{.*?real (\d+) x (\d+)',
            [Text.RegularExpressions.RegexOptions]::Singleline
        )
        $nativeWidth = if ($nativeGeometry.Success) { [int]$nativeGeometry.Groups[1].Value } else { 0 }
        $nativeHeight = if ($nativeGeometry.Success) { [int]$nativeGeometry.Groups[2].Value } else { 0 }
        $nativeDimensions = @($nativeWidth, $nativeHeight) | Sort-Object
        $overrideGeometry = [regex]::Match(
            $displayInfo,
            'mOverrideDisplayInfo=DisplayInfo\{.*?rotation (\d+)',
            [Text.RegularExpressions.RegexOptions]::Singleline
        )
        $currentRotation = if ($overrideGeometry.Success) { [int]$overrideGeometry.Groups[1].Value } else { -1 }
        if (-not $displayInfo.Contains('mOverrideDisplayInfo=DisplayInfo') -or
            $nativeDimensions -join 'x' -ne '1848x2960' -or
            $currentRotation % 2 -ne 1) {
            throw 'The automated focused flow requires the 2960x1848 landscape tablet profile rig.'
        }
        Start-Sleep -Seconds 1
        $null = Invoke-Adb shell input tap 2255 275
        Start-Sleep -Milliseconds 600
        $null = Invoke-Adb shell input tap 2388 275
        Start-Sleep -Milliseconds 600
        $null = Invoke-Adb shell input swipe 1500 1300 1500 600 350
        Start-Sleep -Milliseconds 600
        $null = Invoke-Adb shell input tap 2122 275
    }
    $remainingSampleMs = [Math]::Max(
        0,
        ($SampleSeconds * 1000) - [int]$sampleClock.ElapsedMilliseconds
    )
    Start-Sleep -Milliseconds $remainingSampleMs
    Assert-PackageForeground
    $timelineEndMicros = [long](
        Invoke-RestMethod -Uri "${serviceBaseUri}getVMTimelineMicros" -TimeoutSec 10
    ).result.timestamp
    $timelineExtentMicros = $timelineEndMicros - $timelineOriginMicros
    $timelineUri = "${serviceBaseUri}getVMTimeline?timeOriginMicros=$timelineOriginMicros&timeExtentMicros=$timelineExtentMicros"
    Write-Host 'Reading the bounded Flutter timeline.'
    $parserStartInfo = [Diagnostics.ProcessStartInfo]::new()
    $parserStartInfo.FileName = $DartPath
    $parserStartInfo.Arguments = "`"$timelineParser`""
    $parserStartInfo.UseShellExecute = $false
    $parserStartInfo.CreateNoWindow = $true
    $parserStartInfo.RedirectStandardInput = $true
    $parserStartInfo.RedirectStandardOutput = $true
    $parserStartInfo.RedirectStandardError = $true
    $parserProcess = [Diagnostics.Process]::new()
    $parserProcess.StartInfo = $parserStartInfo
    try {
        $null = $parserProcess.Start()
        $parserProcess.StandardInput.WriteLine($timelineUri)
        $parserProcess.StandardInput.Close()
        $metricsJson = $parserProcess.StandardOutput.ReadToEnd()
        $parserError = $parserProcess.StandardError.ReadToEnd()
        $parserProcess.WaitForExit()
        $parserExitCode = $parserProcess.ExitCode
    }
    finally {
        $parserProcess.Dispose()
    }
    if ($parserExitCode -ne 0) {
        Write-Error $parserError
        throw 'The Flutter timeline parser failed.'
    }
    $timelineMetrics = $metricsJson | ConvertFrom-Json
    Write-Host 'Flutter timeline received.'
}
finally {
    $null = Invoke-Adb forward --remove "tcp:$hostServicePort"
}
$memoryAfter = Invoke-Adb shell dumpsys meminfo $PackageId

function Read-MatchNumber {
    param([string]$Text, [string]$Pattern, [string]$Label)
    $match = [regex]::Match($Text, $Pattern, [Text.RegularExpressions.RegexOptions]::Multiline)
    if (-not $match.Success) { throw "Unable to read $Label from device output." }
    return [double]::Parse($match.Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture)
}

$refreshRate = Read-MatchNumber $displayInfo 'mActiveSfDisplayMode=.*?peakRefreshRate=([0-9.]+)' 'active refresh rate'
$memoryBeforeKb = Read-MatchNumber $memoryBefore '^\s*TOTAL\s+(\d+)' 'post-launch retained memory'
$memoryAfterKb = Read-MatchNumber $memoryAfter '^\s*TOTAL\s+(\d+)' 'post-sample retained memory'

Write-Host 'Flutter timeline parsed.'

$totalFrames = [int]$timelineMetrics.renderedFrames
if ($totalFrames -le 0) {
    throw 'The profile sample rendered no frames; exercise a focused application flow during capture.'
}
$uiP95 = [double]$timelineMetrics.uiThreadFrameTimeMsP95
$rasterP95 = [double]$timelineMetrics.rasterThreadFrameTimeMsP95

$report = [ordered]@{
    schemaVersion = 1
    capturedAtUtc = [DateTime]::UtcNow.ToString('o')
    fixture = $FixtureId
    application = [ordered]@{
        packageId = $PackageId
        versionName = $versionName
        versionCode = [int]$versionCode
        BuildConfiguration = 'profile'
        commit = $BuildCommit.ToLowerInvariant()
        artifact = [ordered]@{ sha256 = $BuildArtifactSha256.ToLowerInvariant() }
    }
    device = [ordered]@{
        manufacturer = (Invoke-Adb shell getprop ro.product.manufacturer).Trim()
        model = (Invoke-Adb shell getprop ro.product.model).Trim()
        androidVersion = (Invoke-Adb shell getprop ro.build.version.release).Trim()
        refreshRateHz = $refreshRate
        frameIntervalMs = [Math]::Round(1000 / $refreshRate, 3)
    }
    measurement = [ordered]@{
        sampleSeconds = $SampleSeconds
        renderedFrames = [int]$totalFrames
        uiThreadFrameTimeMsP95 = $uiP95
        rasterThreadFrameTimeMsP95 = $rasterP95
        retainedMemoryKb = [ordered]@{
            postLaunch = [int]$memoryBeforeKb
            afterSample = [int]$memoryAfterKb
            delta = [int]($memoryAfterKb - $memoryBeforeKb)
        }
    }
}

$resolvedOutput = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
$outputDirectory = Split-Path -Parent $resolvedOutput
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $resolvedOutput -Encoding utf8
Write-Host "Profile baseline written to $resolvedOutput"
