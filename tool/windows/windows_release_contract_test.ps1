$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$workflow = Get-Content -Raw (Join-Path $repositoryRoot '.github/workflows/windows-release.yml')
$packager = Get-Content -Raw (Join-Path $repositoryRoot 'tool/windows/package_msix.ps1')
$releaseGuide = Get-Content -Raw (Join-Path $repositoryRoot 'docs/windows-private-release.md')

$requiredWorkflowFragments = @(
    'actions/checkout@11d5960a326750d5838078e36cf38b85af677262',
    'subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2',
    'actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02',
    'actions/attest@1e69f48acb82d1966a394da916b4c1698aa569d6',
    'runner: windows-2025',
    'flutter: 3.44.8',
    'windows_sdk: 10.0.26100.0',
    'environment: windows-private-release',
    'WINDOWS_SIGNING_PFX_BASE64',
    'WINDOWS_SIGNING_PFX_PASSWORD',
    'vars.WINDOWS_SIGNING_PUBLISHER',
    'vars.WINDOWS_SIGNING_CERT_SHA256',
    'CLINICAL_CALENDAR_ENVIRONMENT: private-release',
    'vars.CLINICAL_CALENDAR_SUPABASE_URL',
    'secrets.CLINICAL_CALENDAR_SUPABASE_PUBLISHABLE_KEY',
    'attestations: write',
    'artifact-metadata: write',
    'id-token: write',
    'windows_release_provenance.json',
    'verify_release_bundle_test.ps1',
    '*.signature.txt',
    '*.cer',
    'Cert:\CurrentUser\TrustedPeople',
    'imported_thumbprints',
    'trust_thumbprint',
    'retention-days: 90'
)
foreach ($fragment in $requiredWorkflowFragments) {
    if (-not $workflow.Contains($fragment)) {
        throw "Windows release workflow is missing required fragment: $fragment"
    }
}
if ($workflow.Contains('-AllowUnsigned')) {
    throw 'Protected Windows release workflow must never allow unsigned packaging.'
}

foreach ($fragment in @(
    'ExpectedSignerSha256',
    'GetCertHashString',
    'verify /pa /all /v /tw',
    'MSIX_SIGNATURE_EVIDENCE',
    'MSIX_SIGNER_CERTIFICATE'
)) {
    if (-not $packager.Contains($fragment)) {
        throw "Windows MSIX packager is missing required fragment: $fragment"
    }
}

foreach ($relativePath in @(
    'tool/windows/write_release_provenance.ps1',
    'tool/windows/verify_release_bundle.ps1',
    'tool/windows/create_private_release_certificate.ps1'
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot $relativePath) -PathType Leaf)) {
        throw "Windows release contract file is missing: $relativePath"
    }
}

$verifier = Get-Content -Raw (Join-Path $repositoryRoot 'tool/windows/verify_release_bundle.ps1')
foreach ($fragment in @(
    'makeappx.exe',
    'AppxManifest.xml',
    "GetAttribute('Name')",
    "GetAttribute('Publisher')",
    "GetAttribute('Version')",
    "GetAttribute('ProcessorArchitecture')"
)) {
    if (-not $verifier.Contains($fragment)) {
        throw "Windows release verifier is missing manifest identity check: $fragment"
    }
}

foreach ($fragment in @(
    '*.msix.cer',
    'certificateSha256',
    'SignerCertificate.Subject'
)) {
    if (-not $verifier.Contains($fragment)) {
        throw "Windows release verifier is missing public signer-certificate check: $fragment"
    }
}

foreach ($fragment in @(
    'WINDOWS_SIGNING_CERT_SHA256',
    'verify_release_bundle.ps1',
    'gh attestation verify',
    'windows_release_provenance.json',
    'immutable',
    '$actualFingerprint -ne $approvedFingerprint',
    'Refusing to trust an unapproved Windows release certificate.'
)) {
    if (-not $releaseGuide.Contains($fragment)) {
        throw "Windows private-release guidance is missing required fragment: $fragment"
    }
}

Write-Host 'Windows release contract passed.'
