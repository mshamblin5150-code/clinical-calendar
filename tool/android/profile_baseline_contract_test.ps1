[CmdletBinding()]
param(
    [string]$DartPath = (Join-Path $PSScriptRoot '..\..\.tooling\flutter\bin\cache\dart-sdk\bin\dart.exe')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$capture = Join-Path $PSScriptRoot 'capture_profile_baseline.ps1'
if (-not (Test-Path -LiteralPath $capture -PathType Leaf)) {
    throw 'Profile baseline capture command is missing.'
}

$source = Get-Content -Raw -LiteralPath $capture
$timelineParser = Join-Path $PSScriptRoot 'parse_flutter_timeline.dart'
if (-not (Test-Path -LiteralPath $timelineParser -PathType Leaf)) {
    throw 'Flutter timeline parser is missing.'
}
$source += Get-Content -Raw -LiteralPath $timelineParser
foreach ($required in @(
    'containment-drone-fictional-v1',
    'BuildConfiguration = ''profile''',
    'uiThreadFrameTimeMsP95',
    'rasterThreadFrameTimeMsP95',
    'retainedMemoryKb',
    'refreshRateHz',
    'sha256',
    'DEBUGGABLE',
    'libapp\.so',
    'kernel_blob.bin',
    'Get-FileHash',
    '$ErrorActionPreference = ''Continue''',
    'topResumedActivity',
    'force-stop',
    'SkipRestart',
    'AutomateFocusedFlow',
    'pidof',
    'RedirectStandardInput',
    'StandardInput.WriteLine',
    '$totalFrames -le 0',
    'Dart VM service is listening on',
    "logcat '-d' '-v' brief",
    'clearVMTimeline',
    'getVMTimelineMicros',
    'timeOriginMicros',
    'getVMTimeline',
    'GPURasterizer::Draw',
    'ConvertTo-Json'
)) {
    if (-not $source.Contains($required)) {
        throw "Profile baseline command is missing required contract: $required"
    }
}

if ($source -match '(?i)(access.?token|refresh.?token|password|secret|signing.?key)') {
    throw 'Profile baseline command must not collect credentials or signing material.'
}

if (-not (Test-Path -LiteralPath $DartPath -PathType Leaf)) {
    throw "Dart was not found at $DartPath"
}
& $DartPath $timelineParser --self-test
if ($LASTEXITCODE -ne 0) {
    throw 'Flutter timeline parser behavioral self-test failed.'
}

Write-Host 'Profile baseline contract passed.'
