[CmdletBinding()]
param(
  [string]$Version,
  [string]$Publisher,
  [string]$PublisherDisplayName = 'Clinical Calendar',
  [string]$SigningThumbprint,
  [string]$ExpectedSignerSha256,
  [string]$TimestampUrl = 'http://timestamp.digicert.com',
  [string]$WindowsSdkVersion,
  [string]$FlutterExecutable = 'flutter',
  [switch]$SkipFlutterBuild,
  [switch]$AllowUnsigned
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$appRoot = Join-Path $repoRoot 'apps\clinical_calendar'
$pubspecPath = Join-Path $appRoot 'pubspec.yaml'
$releaseBundle = Join-Path $appRoot 'build\windows\x64\runner\Release'
$packagingRoot = Join-Path $appRoot 'build\windows\msix'
$stagingRoot = Join-Path $packagingRoot 'staging'
$templatePath = Join-Path $PSScriptRoot 'AppxManifest.template.xml'
$icon44Path = Join-Path $appRoot 'windows\runner\resources\app_icon_44.png'
$icon150Path = Join-Path $appRoot 'windows\runner\resources\app_icon_150.png'

function Resolve-SdkTool {
  param([Parameter(Mandatory)][string]$Name)

  $sdkBin = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
  if (-not (Test-Path -LiteralPath $sdkBin)) {
    throw "Windows SDK tools directory not found: $sdkBin"
  }

  if ($WindowsSdkVersion) {
    $requested = Join-Path $sdkBin "$WindowsSdkVersion\x64\$Name"
    if (-not (Test-Path -LiteralPath $requested)) {
      throw "Required Windows SDK tool not found: $requested"
    }
    return $requested
  }

  $candidate = Get-ChildItem -LiteralPath $sdkBin -Directory |
    Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' } |
    Sort-Object { [version]$_.Name } -Descending |
    ForEach-Object { Join-Path $_.FullName "x64\$Name" } |
    Where-Object { Test-Path -LiteralPath $_ } |
    Select-Object -First 1
  if (-not $candidate) {
    throw "$Name was not found in a versioned Windows SDK x64 directory."
  }
  return $candidate
}

function Get-PackageVersion {
  if ($Version) {
    return $Version
  }
  $versionLine = Get-Content -LiteralPath $pubspecPath |
    Where-Object { $_ -match '^version:\s*' } |
    Select-Object -First 1
  if (-not $versionLine -or $versionLine -notmatch '^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$') {
    throw 'pubspec.yaml must use version: major.minor.patch+build for MSIX packaging.'
  }
  return "$($Matches[1]).$($Matches[2]).$($Matches[3]).$($Matches[4])"
}

function Assert-PackageVersion {
  param([Parameter(Mandatory)][string]$Value)
  if ($Value -notmatch '^\d+\.\d+\.\d+\.\d+$') {
    throw "MSIX version must contain four numeric components: $Value"
  }
  foreach ($component in $Value.Split('.')) {
    if ([int64]$component -gt 65535) {
      throw "Every MSIX version component must be between 0 and 65535: $Value"
    }
  }
}

$packageVersion = Get-PackageVersion
Assert-PackageVersion -Value $packageVersion

$certificate = $null
if ($SigningThumbprint) {
  $normalizedThumbprint = $SigningThumbprint.Replace(' ', '').ToUpperInvariant()
  $certificatePath = "Cert:\CurrentUser\My\$normalizedThumbprint"
  if (-not (Test-Path -LiteralPath $certificatePath)) {
    throw "Signing certificate is not installed at $certificatePath"
  }
  $certificate = Get-Item -LiteralPath $certificatePath
  if (-not $certificate.HasPrivateKey) {
    throw 'The selected signing certificate has no private key.'
  }
  if ([string]::IsNullOrWhiteSpace($ExpectedSignerSha256)) {
    throw 'ExpectedSignerSha256 is required for signed packaging.'
  }
  $normalizedExpectedSignerSha256 = $ExpectedSignerSha256.Replace(':', '').Replace(' ', '').ToUpperInvariant()
  if ($normalizedExpectedSignerSha256 -notmatch '^[A-F0-9]{64}$') {
    throw 'ExpectedSignerSha256 must be a complete SHA-256 certificate fingerprint.'
  }
  $actualSignerSha256 = $certificate.GetCertHashString(
    [Security.Cryptography.HashAlgorithmName]::SHA256
  ).ToUpperInvariant()
  if ($actualSignerSha256 -ne $normalizedExpectedSignerSha256) {
    throw 'Signing certificate does not match the approved SHA-256 identity.'
  }
  $now = [DateTime]::UtcNow
  if ($now -lt $certificate.NotBefore.ToUniversalTime() -or
      $now -gt $certificate.NotAfter.ToUniversalTime()) {
    throw 'Signing certificate is not currently valid.'
  }
  if ($Publisher -and $Publisher -ne $certificate.Subject) {
    throw 'Publisher must exactly match the signing certificate subject.'
  }
  $Publisher = $certificate.Subject
} elseif (-not $AllowUnsigned) {
  throw 'A CurrentUser signing certificate thumbprint is required. Use -AllowUnsigned only for local package-structure validation.'
}

if (-not $Publisher) {
  $Publisher = 'CN=Clinical Calendar Unsigned Development'
}

if (-not $SkipFlutterBuild) {
  . (Join-Path $repoRoot 'tool\release\resolve_flutter_release_defines.ps1')
  $releaseArguments = if ($certificate) {
    Get-ClinicalCalendarReleaseFlutterArguments
  } else {
    @()
  }
  Push-Location $appRoot
  try {
    & $FlutterExecutable build windows --release @releaseArguments
    if ($LASTEXITCODE -ne 0) {
      throw "Flutter Windows release build failed with exit code $LASTEXITCODE."
    }
  } finally {
    Pop-Location
  }
}

if (-not (Test-Path -LiteralPath (Join-Path $releaseBundle 'clinical_calendar.exe'))) {
  throw "Windows release bundle not found: $releaseBundle"
}
foreach ($iconPath in @($icon44Path, $icon150Path)) {
  if (-not (Test-Path -LiteralPath $iconPath)) {
    throw "Package icon not found: $iconPath"
  }
}

$resolvedPackagingRoot = [IO.Path]::GetFullPath($packagingRoot)
$resolvedExpectedRoot = [IO.Path]::GetFullPath((Join-Path $appRoot 'build\windows\msix'))
if ($resolvedPackagingRoot -ne $resolvedExpectedRoot) {
  throw 'Refusing to clean an unexpected packaging directory.'
}
if (Test-Path -LiteralPath $packagingRoot) {
  Remove-Item -LiteralPath $packagingRoot -Recurse -Force
}
New-Item -ItemType Directory -Path (Join-Path $stagingRoot 'Assets') -Force | Out-Null
Copy-Item -Path (Join-Path $releaseBundle '*') -Destination $stagingRoot -Recurse -Force
Copy-Item -LiteralPath $icon44Path -Destination (Join-Path $stagingRoot 'Assets\AppIcon44.png')
Copy-Item -LiteralPath $icon150Path -Destination (Join-Path $stagingRoot 'Assets\AppIcon150.png')

$xmlEscape = [System.Security.SecurityElement]::Escape
$manifest = Get-Content -Raw -LiteralPath $templatePath
$manifest = $manifest.Replace('__VERSION__', $packageVersion)
$manifest = $manifest.Replace('__PUBLISHER__', $xmlEscape.Invoke($Publisher))
$manifest = $manifest.Replace('__PUBLISHER_DISPLAY_NAME__', $xmlEscape.Invoke($PublisherDisplayName))
$manifestPath = Join-Path $stagingRoot 'AppxManifest.xml'
[IO.File]::WriteAllText($manifestPath, $manifest, [Text.UTF8Encoding]::new($false))

$makeAppx = Resolve-SdkTool -Name 'makeappx.exe'
$signTool = Resolve-SdkTool -Name 'signtool.exe'
$suffix = if ($certificate) { '' } else { '.unsigned' }
$packagePath = Join-Path $packagingRoot "ClinicalCalendar-$packageVersion-x64$suffix.msix"
& $makeAppx pack /d $stagingRoot /p $packagePath /o
if ($LASTEXITCODE -ne 0) {
  throw "MakeAppx failed with exit code $LASTEXITCODE."
}

if ($certificate) {
  & $signTool sign /fd SHA256 /sha1 $certificate.Thumbprint /tr $TimestampUrl /td SHA256 $packagePath
  if ($LASTEXITCODE -ne 0) {
    throw "SignTool signing failed with exit code $LASTEXITCODE."
  }
  $signatureEvidencePath = "$packagePath.signature.txt"
  & $signTool verify /pa /all /v /tw $packagePath 2>&1 |
    Tee-Object -FilePath $signatureEvidencePath
  $verificationExitCode = $LASTEXITCODE
  if ($verificationExitCode -ne 0) {
    throw "SignTool verification failed with exit code $verificationExitCode."
  }
}

$hash = Get-FileHash -LiteralPath $packagePath -Algorithm SHA256
$hashPath = "$packagePath.sha256"
[IO.File]::WriteAllText(
  $hashPath,
  "$($hash.Hash.ToLowerInvariant())  $([IO.Path]::GetFileName($packagePath))`n",
  [Text.UTF8Encoding]::new($false)
)

Write-Output "MSIX_PACKAGE=$packagePath"
Write-Output "MSIX_SHA256=$hashPath"
Write-Output "MSIX_VERSION=$packageVersion"
Write-Output "MSIX_PUBLISHER=$Publisher"
if ($certificate) {
  Write-Output "MSIX_SIGNER_SHA256=$actualSignerSha256"
  Write-Output "MSIX_SIGNATURE_EVIDENCE=$signatureEvidencePath"
}
