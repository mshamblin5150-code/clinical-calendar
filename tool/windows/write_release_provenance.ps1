[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$PackagePath,
  [Parameter(Mandatory)][string]$ChecksumPath,
  [Parameter(Mandatory)][string]$SignatureEvidencePath,
  [Parameter(Mandatory)][string]$OutputPath,
  [Parameter(Mandatory)][string]$Repository,
  [Parameter(Mandatory)][string]$CommitSha,
  [Parameter(Mandatory)][string]$WorkflowRef,
  [Parameter(Mandatory)][string]$RunId,
  [Parameter(Mandatory)][string]$RunAttempt,
  [Parameter(Mandatory)][string]$Publisher,
  [Parameter(Mandatory)][string]$SignerSha256,
  [Parameter(Mandatory)][string]$Version
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$resolvedPackage = (Resolve-Path -LiteralPath $PackagePath).Path
$resolvedChecksum = (Resolve-Path -LiteralPath $ChecksumPath).Path
$resolvedEvidence = (Resolve-Path -LiteralPath $SignatureEvidencePath).Path
$normalizedCommit = $CommitSha.Trim().ToLowerInvariant()
$normalizedSigner = $SignerSha256.Replace(':', '').Replace(' ', '').ToLowerInvariant()

if ($normalizedCommit -notmatch '^[a-f0-9]{40}$') {
  throw 'CommitSha must be a complete Git commit SHA.'
}
if ($normalizedSigner -notmatch '^[a-f0-9]{64}$') {
  throw 'SignerSha256 must be a complete SHA-256 certificate fingerprint.'
}
if ($Version -notmatch '^\d+\.\d+\.\d+\.\d+$') {
  throw 'Version must be a four-component MSIX version.'
}
if ([string]::IsNullOrWhiteSpace($Publisher) -or
    [string]::IsNullOrWhiteSpace($Repository) -or
    [string]::IsNullOrWhiteSpace($WorkflowRef)) {
  throw 'Publisher, Repository, and WorkflowRef are required.'
}

$packageHash = (Get-FileHash -LiteralPath $resolvedPackage -Algorithm SHA256).Hash.ToLowerInvariant()
$checksumLine = (Get-Content -Raw -LiteralPath $resolvedChecksum).Trim()
$escapedFileName = [Regex]::Escape([IO.Path]::GetFileName($resolvedPackage))
if ($checksumLine -notmatch "^([a-fA-F0-9]{64})  $escapedFileName$") {
  throw 'Checksum file must contain the package SHA-256 and exact file name.'
}
if ($Matches[1].ToLowerInvariant() -ne $packageHash) {
  throw 'Checksum does not match the release package.'
}
if ((Get-Item -LiteralPath $resolvedEvidence).Length -eq 0) {
  throw 'Signature verification evidence is empty.'
}

$provenance = [ordered]@{
  schemaVersion = 1
  artifact = [ordered]@{
    fileName = [IO.Path]::GetFileName($resolvedPackage)
    sha256 = $packageHash
  }
  applicationIdentity = [ordered]@{
    name = 'ClinicalCalendar'
    publisher = $Publisher
    version = $Version
    processorArchitecture = 'x64'
  }
  signer = [ordered]@{
    certificateSha256 = $normalizedSigner
  }
  signatureVerification = [ordered]@{
    tool = 'signtool.exe'
    policy = '/pa /all /v /tw'
    result = 'passed'
    evidenceFile = [IO.Path]::GetFileName($resolvedEvidence)
  }
  source = [ordered]@{
    repository = $Repository
    commitSha = $normalizedCommit
  }
  workflow = [ordered]@{
    workflowRef = $WorkflowRef
    runId = $RunId
    runAttempt = $RunAttempt
  }
  toolchain = [ordered]@{
    runner = 'windows-2025'
    flutter = '3.44.8'
    windowsSdk = '10.0.26100.0'
  }
  generatedAtUtc = [DateTime]::UtcNow.ToString('o')
}

$parent = Split-Path -Parent $OutputPath
if ($parent) {
  New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
[IO.File]::WriteAllText(
  $OutputPath,
  ($provenance | ConvertTo-Json -Depth 6) + "`n",
  [Text.UTF8Encoding]::new($false)
)

Write-Output "WINDOWS_RELEASE_PROVENANCE=$OutputPath"
