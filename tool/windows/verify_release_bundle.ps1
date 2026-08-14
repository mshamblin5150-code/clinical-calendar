[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$BundlePath,
  [Parameter(Mandatory)][string]$ExpectedPublisher,
  [Parameter(Mandatory)][string]$ExpectedSignerSha256,
  [Parameter(Mandatory)][string]$ExpectedRepository,
  [string]$ExpectedCommitSha,
  [string]$ExpectedRunnerImage = 'windows-2025',
  [string]$ExpectedFlutterVersion = '3.44.8',
  [string]$WindowsSdkVersion = '10.0.26100.0'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-OneFile {
  param(
    [Parameter(Mandatory)][string]$Root,
    [Parameter(Mandatory)][string]$Filter,
    [Parameter(Mandatory)][string]$Description
  )
  $files = @(Get-ChildItem -LiteralPath $Root -File -Recurse -Filter $Filter)
  if ($files.Count -ne 1) {
    throw "Release bundle must contain exactly one $Description; found $($files.Count)."
  }
  return $files[0]
}

function Resolve-SdkTool {
  param([Parameter(Mandatory)][string]$Name)

  $sdkBin = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
  $path = Join-Path $sdkBin "$WindowsSdkVersion\x64\$Name"
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "Pinned Windows SDK tool was not found: $path"
  }
  return $path
}

$resolvedBundle = (Resolve-Path -LiteralPath $BundlePath).Path
$package = Get-OneFile -Root $resolvedBundle -Filter '*.msix' -Description 'signed MSIX'
if ($package.Name.EndsWith('.unsigned.msix', [StringComparison]::OrdinalIgnoreCase)) {
  throw 'Unsigned MSIX packages are never release candidates.'
}
if ($package.BaseName -notmatch '^ClinicalCalendar-(\d+\.\d+\.\d+\.\d+)-x64$') {
  throw 'Release package file name must contain its four-component version and x64 architecture.'
}
$fileVersion = $Matches[1]
$checksum = Get-OneFile -Root $resolvedBundle -Filter '*.msix.sha256' -Description 'MSIX checksum'
$evidence = Get-OneFile -Root $resolvedBundle -Filter '*.msix.signature.txt' -Description 'signature evidence file'
$publicCertificateFile = Get-OneFile -Root $resolvedBundle -Filter '*.msix.cer' -Description 'public signer certificate'
$provenanceFile = Get-OneFile -Root $resolvedBundle -Filter 'windows_release_provenance.json' -Description 'provenance record'

$checksumLine = (Get-Content -Raw -LiteralPath $checksum.FullName).Trim()
$escapedPackageName = [Regex]::Escape($package.Name)
if ($checksumLine -notmatch "^([a-fA-F0-9]{64})  $escapedPackageName$") {
  throw 'Checksum record does not name the exact release package.'
}
$actualPackageHash = (Get-FileHash -LiteralPath $package.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
if ($Matches[1].ToLowerInvariant() -ne $actualPackageHash) {
  throw 'Release package SHA-256 does not match its checksum record.'
}

$provenance = Get-Content -Raw -LiteralPath $provenanceFile.FullName | ConvertFrom-Json
$normalizedSigner = $ExpectedSignerSha256.Replace(':', '').Replace(' ', '').ToLowerInvariant()
if ($normalizedSigner -notmatch '^[a-f0-9]{64}$') {
  throw 'ExpectedSignerSha256 must be a complete SHA-256 certificate fingerprint.'
}
$normalizedCommit = if ($ExpectedCommitSha) {
  $ExpectedCommitSha.Trim().ToLowerInvariant()
} else {
  ''
}
if ($normalizedCommit -and $normalizedCommit -notmatch '^[a-f0-9]{40}$') {
  throw 'ExpectedCommitSha must be a complete Git commit SHA when supplied.'
}

if ($provenance.schemaVersion -ne 1 -or
    $provenance.artifact.fileName -ne $package.Name -or
    $provenance.artifact.sha256 -ne $actualPackageHash -or
    $provenance.applicationIdentity.name -ne 'ClinicalCalendar' -or
    $provenance.applicationIdentity.publisher -ne $ExpectedPublisher -or
    $provenance.applicationIdentity.version -ne $fileVersion -or
    $provenance.applicationIdentity.processorArchitecture -ne 'x64' -or
    $provenance.signer.certificateSha256 -ne $normalizedSigner -or
    $provenance.signer.publicCertificateFile -ne $publicCertificateFile.Name -or
    $provenance.source.repository -ne $ExpectedRepository -or
    ($normalizedCommit -and $provenance.source.commitSha -ne $normalizedCommit) -or
    $provenance.signatureVerification.policy -ne '/pa /all /v /tw' -or
    $provenance.signatureVerification.result -ne 'passed' -or
    $provenance.signatureVerification.evidenceFile -ne $evidence.Name -or
    $provenance.toolchain.runner -ne $ExpectedRunnerImage -or
    $provenance.toolchain.flutter -ne $ExpectedFlutterVersion -or
    $provenance.toolchain.windowsSdk -ne $WindowsSdkVersion) {
  throw 'Release provenance does not match the independently approved artifact identity.'
}

$publicCertificate = [Security.Cryptography.X509Certificates.X509Certificate2]::new(
  $publicCertificateFile.FullName
)
$publicCertificateSha256 = $publicCertificate.GetCertHashString(
  [Security.Cryptography.HashAlgorithmName]::SHA256
).ToLowerInvariant()
if ($publicCertificateSha256 -ne $normalizedSigner -or
    $publicCertificate.Subject -ne $ExpectedPublisher) {
  throw 'Bundled public certificate does not match the independently approved signer identity.'
}

$signature = Get-AuthenticodeSignature -LiteralPath $package.FullName
if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid -or
    -not $signature.SignerCertificate -or
    -not $signature.TimeStamperCertificate) {
  throw 'MSIX signature or RFC 3161 timestamp is not valid on this machine.'
}
$actualSigner = $signature.SignerCertificate.GetCertHashString(
  [Security.Cryptography.HashAlgorithmName]::SHA256
).ToLowerInvariant()
if ($signature.SignerCertificate.Subject -ne $ExpectedPublisher -or
    $actualSigner -ne $normalizedSigner -or
    $actualSigner -ne $publicCertificateSha256) {
  throw 'MSIX signer does not match the independently approved certificate identity.'
}

$signTool = Resolve-SdkTool -Name 'signtool.exe'
& $signTool verify /pa /all /v /tw $package.FullName
if ($LASTEXITCODE -ne 0) {
  throw "Independent SignTool verification failed with exit code $LASTEXITCODE."
}

$unpackRoot = Join-Path ([IO.Path]::GetTempPath()) "clinical-calendar-msix-verify-$([Guid]::NewGuid().ToString('N'))"
try {
  $makeAppx = Resolve-SdkTool -Name 'makeappx.exe'
  & $makeAppx unpack /p $package.FullName /d $unpackRoot /o
  if ($LASTEXITCODE -ne 0) {
    throw "MakeAppx inspection failed with exit code $LASTEXITCODE."
  }
  [xml]$manifest = Get-Content -Raw -LiteralPath (Join-Path $unpackRoot 'AppxManifest.xml')
  $identity = $manifest.SelectSingleNode("/*[local-name()='Package']/*[local-name()='Identity']")
  if (-not $identity -or
      $identity.GetAttribute('Name') -ne 'ClinicalCalendar' -or
      $identity.GetAttribute('Publisher') -ne $ExpectedPublisher -or
      $identity.GetAttribute('Version') -ne $fileVersion -or
      $identity.GetAttribute('ProcessorArchitecture') -ne 'x64') {
    throw 'Signed MSIX manifest does not match the approved versioned application identity.'
  }
} finally {
  $resolvedUnpackRoot = [IO.Path]::GetFullPath($unpackRoot)
  $resolvedTempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
  if ($resolvedUnpackRoot.StartsWith($resolvedTempRoot, [StringComparison]::OrdinalIgnoreCase) -and
      (Split-Path -Leaf $resolvedUnpackRoot).StartsWith('clinical-calendar-msix-verify-')) {
    Remove-Item -LiteralPath $resolvedUnpackRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

Write-Host "Verified immutable Windows release candidate: $($package.Name)"
Write-Host "SHA-256: $actualPackageHash"
Write-Host "Commit: $($provenance.source.commitSha)"
Write-Host "Version: $($provenance.applicationIdentity.version)"
