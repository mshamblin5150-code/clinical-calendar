$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$provenanceWriter = Join-Path $repositoryRoot 'tool/windows/write_release_provenance.ps1'
$verifier = Join-Path $repositoryRoot 'tool/windows/verify_release_bundle.ps1'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) "clinical-calendar-release-test-$([Guid]::NewGuid().ToString('N'))"

function Assert-FailsWith {
  param(
    [Parameter(Mandatory)][scriptblock]$Operation,
    [Parameter(Mandatory)][string]$ExpectedMessage
  )
  try {
    & $Operation
  } catch {
    if (-not $_.Exception.Message.Contains($ExpectedMessage)) {
      throw "Expected failure containing '$ExpectedMessage' but received: $($_.Exception.Message)"
    }
    return
  }
  throw "Expected operation to fail with: $ExpectedMessage"
}

try {
  New-Item -ItemType Directory -Path $testRoot | Out-Null
  $packagePath = Join-Path $testRoot 'ClinicalCalendar-1.2.3.4-x64.msix'
  $checksumPath = "$packagePath.sha256"
  $evidencePath = "$packagePath.signature.txt"
  $provenancePath = Join-Path $testRoot 'windows_release_provenance.json'
  $expectedPublisher = 'CN=Clinical Calendar Release'
  $expectedSigner = 'a' * 64
  $expectedCommit = 'b' * 40

  [IO.File]::WriteAllBytes($packagePath, [Text.Encoding]::UTF8.GetBytes('synthetic unsigned package'))
  [IO.File]::WriteAllText($evidencePath, 'synthetic evidence for pre-signature validation')
  [IO.File]::WriteAllText($checksumPath, "$('0' * 64)  $([IO.Path]::GetFileName($packagePath))`n")

  Assert-FailsWith -ExpectedMessage 'Checksum does not match' -Operation {
    & $provenanceWriter `
      -PackagePath $packagePath `
      -ChecksumPath $checksumPath `
      -SignatureEvidencePath $evidencePath `
      -OutputPath $provenancePath `
      -Repository 'mshamblin5150-code/clinical-calendar' `
      -CommitSha $expectedCommit `
      -WorkflowRef 'mshamblin5150-code/clinical-calendar/.github/workflows/windows-release.yml@refs/heads/main' `
      -RunId '123' `
      -RunAttempt '1' `
      -Publisher $expectedPublisher `
      -SignerSha256 $expectedSigner `
      -Version '1.2.3.4' `
      -RunnerImage 'windows-2025' `
      -FlutterVersion '3.44.8' `
      -WindowsSdkVersion '10.0.26100.0'
  }

  $hash = (Get-FileHash -LiteralPath $packagePath -Algorithm SHA256).Hash.ToLowerInvariant()
  [IO.File]::WriteAllText($checksumPath, "$hash  $([IO.Path]::GetFileName($packagePath))`n")
  & $provenanceWriter `
    -PackagePath $packagePath `
    -ChecksumPath $checksumPath `
    -SignatureEvidencePath $evidencePath `
    -OutputPath $provenancePath `
    -Repository 'mshamblin5150-code/clinical-calendar' `
    -CommitSha $expectedCommit `
    -WorkflowRef 'mshamblin5150-code/clinical-calendar/.github/workflows/windows-release.yml@refs/heads/main' `
    -RunId '123' `
    -RunAttempt '1' `
    -Publisher $expectedPublisher `
    -SignerSha256 ('c' * 64) `
    -Version '1.2.3.4' `
    -RunnerImage 'windows-2025' `
    -FlutterVersion '3.44.8' `
    -WindowsSdkVersion '10.0.26100.0'

  Assert-FailsWith -ExpectedMessage 'does not match the independently approved artifact identity' -Operation {
    & $verifier `
      -BundlePath $testRoot `
      -ExpectedPublisher $expectedPublisher `
      -ExpectedSignerSha256 $expectedSigner `
      -ExpectedRepository 'mshamblin5150-code/clinical-calendar' `
      -ExpectedCommitSha $expectedCommit
  }
} finally {
  $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
  $resolvedTempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
  if ($resolvedTestRoot.StartsWith($resolvedTempRoot, [StringComparison]::OrdinalIgnoreCase) -and
      (Split-Path -Leaf $resolvedTestRoot).StartsWith('clinical-calendar-release-test-')) {
    Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

Write-Host 'Windows release verifier behavior passed.'
