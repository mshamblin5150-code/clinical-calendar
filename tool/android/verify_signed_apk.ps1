[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $ApkPath,

    [Parameter(Mandatory = $true)]
    [string] $ExpectedSignerSha256,

    [string] $ApkSignerExecutable
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Normalize-Fingerprint([string] $Fingerprint) {
    return ($Fingerprint -replace '[^0-9A-Fa-f]', '').ToUpperInvariant()
}

if (-not (Test-Path -LiteralPath $ApkPath -PathType Leaf)) {
    throw "APK does not exist: $ApkPath"
}

$expectedFingerprint = Normalize-Fingerprint $ExpectedSignerSha256
if ($expectedFingerprint.Length -ne 64) {
    throw 'Expected signer fingerprint must contain exactly 64 hexadecimal characters.'
}

if ([string]::IsNullOrWhiteSpace($ApkSignerExecutable)) {
    $androidSdkRoot = if (-not [string]::IsNullOrWhiteSpace($env:ANDROID_HOME)) {
        $env:ANDROID_HOME
    } elseif (-not [string]::IsNullOrWhiteSpace($env:ANDROID_SDK_ROOT)) {
        $env:ANDROID_SDK_ROOT
    } else {
        throw 'ANDROID_HOME or ANDROID_SDK_ROOT is required to locate apksigner.'
    }

    $executableName = if ($env:OS -eq 'Windows_NT') { 'apksigner.bat' } else { 'apksigner' }
    $candidate = Get-ChildItem -LiteralPath (Join-Path $androidSdkRoot 'build-tools') -Directory |
        Sort-Object { [version]($_.Name -replace '-.*$', '') } -Descending |
        ForEach-Object { Join-Path $_.FullName $executableName } |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
        Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($candidate)) {
        throw 'No Android SDK apksigner executable was found.'
    }
    $ApkSignerExecutable = $candidate
}

$verificationOutput = & $ApkSignerExecutable verify --verbose --print-certs $ApkPath 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "apksigner rejected the APK.`n$($verificationOutput -join [Environment]::NewLine)"
}

$digestMatches = @(
    $verificationOutput |
        Select-String -Pattern 'certificate SHA-256 digest:\s*([0-9A-Fa-f:]+)' |
        ForEach-Object { Normalize-Fingerprint $_.Matches[0].Groups[1].Value } |
        Select-Object -Unique
)
if ($digestMatches.Count -ne 1) {
    throw "Expected exactly one APK signer, found $($digestMatches.Count)."
}
if ($digestMatches[0] -ne $expectedFingerprint) {
    throw "APK signer fingerprint does not match the approved release certificate. Actual: $($digestMatches[0])"
}

$certificateLines = $verificationOutput | Select-String -Pattern 'certificate DN:'
if ($certificateLines -match 'CN=Android Debug(?:,|$)') {
    throw 'APK is signed with an Android debug certificate.'
}

$apkHash = (Get-FileHash -LiteralPath $ApkPath -Algorithm SHA256).Hash.ToLowerInvariant()
$hashPath = "$ApkPath.sha256"
Set-Content -LiteralPath $hashPath -Value "$apkHash  $([IO.Path]::GetFileName($ApkPath))" -Encoding ascii

Write-Host "Verified APK signer SHA-256: $expectedFingerprint"
Write-Host "APK SHA-256: $apkHash"
Write-Host "Checksum file: $hashPath"
