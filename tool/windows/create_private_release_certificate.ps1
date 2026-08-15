[CmdletBinding()]
param(
  [string]$Subject = 'CN=Clinical Calendar Private Release',
  [ValidateRange(1, 10)][int]$ValidYears = 10,
  [string]$BackupDirectory
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($env:OS -ne 'Windows_NT') {
  throw 'Private Windows release certificates can only be created on Windows.'
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if ([string]::IsNullOrWhiteSpace($BackupDirectory)) {
  $BackupDirectory = Join-Path $repoRoot '.secrets\windows-signing'
}
$resolvedBackup = [IO.Path]::GetFullPath($BackupDirectory)
$expectedSecretsRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot '.secrets'))
if (-not $resolvedBackup.StartsWith(
    "$expectedSecretsRoot$([IO.Path]::DirectorySeparatorChar)",
    [StringComparison]::OrdinalIgnoreCase
  )) {
  throw 'Certificate backups must remain under the ignored .secrets directory.'
}
if (Test-Path -LiteralPath $resolvedBackup) {
  $existingFiles = @(Get-ChildItem -LiteralPath $resolvedBackup -Force)
  if ($existingFiles.Count -ne 0) {
    throw "Refusing to overwrite an existing certificate backup: $resolvedBackup"
  }
} else {
  New-Item -ItemType Directory -Path $resolvedBackup | Out-Null
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
& icacls.exe $resolvedBackup /inheritance:r /grant:r "${identity}:(OI)(CI)F" | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Unable to restrict certificate backup permissions (icacls exit $LASTEXITCODE)."
}

$existingCertificate = @(Get-ChildItem Cert:\CurrentUser\My | Where-Object {
  $_.Subject -eq $Subject -and $_.HasPrivateKey
})
if ($existingCertificate.Count -ne 0) {
  throw 'A private release certificate with this Subject already exists; rotate explicitly instead of replacing it.'
}

$passwordBytes = [byte[]]::new(48)
$randomNumberGenerator = [Security.Cryptography.RandomNumberGenerator]::Create()
try {
  $randomNumberGenerator.GetBytes($passwordBytes)
} finally {
  $randomNumberGenerator.Dispose()
}
$passwordText = [Convert]::ToBase64String($passwordBytes).
  TrimEnd('=').
  Replace('+', '-').
  Replace('/', '_')
$securePassword = ConvertTo-SecureString $passwordText -AsPlainText -Force
$certificate = $null
try {
  $certificate = New-SelfSignedCertificate `
    -Type Custom `
    -Subject $Subject `
    -FriendlyName 'Clinical Calendar durable private release signing' `
    -CertStoreLocation Cert:\CurrentUser\My `
    -KeyAlgorithm RSA `
    -KeyLength 4096 `
    -KeyExportPolicy Exportable `
    -HashAlgorithm SHA256 `
    -KeyUsage DigitalSignature `
    -NotAfter (Get-Date).AddYears($ValidYears) `
    -TextExtension @(
      '2.5.29.37={text}1.3.6.1.5.5.7.3.3',
      '2.5.29.19={text}ca=0'
    )

  $pfxPath = Join-Path $resolvedBackup 'ClinicalCalendarPrivateRelease.pfx'
  $cerPath = Join-Path $resolvedBackup 'ClinicalCalendarPrivateRelease.cer'
  $passwordPath = Join-Path $resolvedBackup 'ClinicalCalendarPrivateRelease.password.txt'
  Export-PfxCertificate `
    -Cert $certificate `
    -FilePath $pfxPath `
    -Password $securePassword `
    -CryptoAlgorithmOption AES256_SHA256 | Out-Null
  Export-Certificate -Cert $certificate -FilePath $cerPath | Out-Null
  [IO.File]::WriteAllText(
    $passwordPath,
    "$passwordText`n",
    [Text.UTF8Encoding]::new($false)
  )
} catch {
  if ($certificate) {
    Remove-Item -LiteralPath "Cert:\CurrentUser\My\$($certificate.Thumbprint)" -Force -ErrorAction SilentlyContinue
  }
  throw
}

$certificateSha256 = $certificate.GetCertHashString(
  [Security.Cryptography.HashAlgorithmName]::SHA256
).ToUpperInvariant()
Write-Host "Created durable private release certificate: $($certificate.Subject)"
Write-Host "Certificate SHA-256: $certificateSha256"
Write-Host "Encrypted backup directory: $resolvedBackup"
Write-Host 'The PFX password was stored only in the access-restricted backup directory.'
