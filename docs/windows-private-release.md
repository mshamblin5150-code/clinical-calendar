# Windows Private Release

Clinical Calendar uses a signed x64 MSIX package for private Windows delivery.
MSIX supplies a stable package identity, signature and integrity enforcement,
versioned upgrades, and clean Windows-managed uninstall behavior.

## Maintainer prerequisites

- Build only from a reviewed commit with Flutter `3.44.8` and the Windows SDK
  `10.0.26100.0`, as pinned in `.github/workflows/windows-release.yml`.
- Configure the protected `windows-private-release` GitHub environment with:
  - `WINDOWS_SIGNING_PFX_BASE64`: base64 of the private code-signing PFX.
  - `WINDOWS_SIGNING_PFX_PASSWORD`: the PFX password.
- Configure `WINDOWS_SIGNING_PUBLISHER` as a protected environment variable
  containing the exact certificate subject distinguished name.
- Configure `WINDOWS_SIGNING_CERT_SHA256` as a protected environment variable
  containing the maintainer-approved, 64-hex SHA-256 fingerprint of the public
  signing certificate. Record it from a separately authenticated public
  certificate; do not derive approval from the uploaded PFX.
- Configure `CLINICAL_CALENDAR_SUPABASE_URL` as a protected environment
  variable containing the hosted HTTPS project URL and
  `CLINICAL_CALENDAR_SUPABASE_PUBLISHABLE_KEY` as a protected secret containing
  only a publishable key or legacy `anon` JWT. Release packaging rejects
  service-role/secret keys and missing or non-HTTPS configuration.
- Keep the certificate subject stable. It becomes the MSIX Publisher identity;
  changing it creates a different application instead of an upgrade.
- Never commit or attach the PFX, its password, a private key, database key,
  backup passphrase, Supabase privileged key, or test account credential.

For this private release, create the maintainer-approved durable self-signed
identity once on the maintainer's Windows machine:

```powershell
./tool/windows/create_private_release_certificate.ps1
```

The command creates a ten-year RSA-4096 code-signing certificate and stores its
encrypted PFX, public CER, and generated password under the ignored,
access-restricted `.secrets/windows-signing` directory. Keep an encrypted
offline copy of that directory. Losing the PFX or its password prevents future
packages from remaining in the same signing lineage. Only the public CER,
subject, and SHA-256 fingerprint may be shared.

The workflow imports the PFX into the ephemeral runner's Current User store
without making the key exportable, deletes the temporary PFX in the same step,
and removes the imported certificate in an `always()` cleanup step. After the
subject and SHA-256 fingerprint match the approved values, it temporarily adds
only that pinned public certificate to the runner's Current User Trusted People
store so the self-signed chain can be verified, then removes that trust entry in
the same cleanup. It requires
the certificate subject and SHA-256 fingerprint to match the independently
approved `WINDOWS_SIGNING_PUBLISHER` and `WINDOWS_SIGNING_CERT_SHA256` values.
It never prints or uploads PFX bytes, passwords, private keys, or protected app
configuration. Missing or mismatched signing inputs fail before upload.

The `windows-private-release` environment admits protected branches only. Keep
that policy enabled and require normal protected-branch review before dispatch.
Signing uses SHA-256 and the pinned RFC 3161 timestamp service. Verification
uses SignTool `/pa /all /v /tw`, so an invalid trust chain, signature, or
missing timestamp fails closed.

## Produce a release

1. Increment `apps/clinical_calendar/pubspec.yaml` using
   `major.minor.patch+build`. MSIX receives `major.minor.patch.build`; every
   component must be between 0 and 65535, and an upgrade must be greater than
   the installed package version.
2. Complete `docs/release-security-checklist.md` against the candidate commit.
3. Merge the reviewed candidate commit to the protected branch and run the
   `Windows private release` workflow from that exact commit.
4. Download the immutable, commit-named artifact. It contains one signed x64
   MSIX, its checksum, public signer CER, SignTool signature/timestamp evidence,
   `windows_release_provenance.json`, and the offline attestation bundle
   `windows_release_provenance.sigstore.json`.
5. Independently verify the bundle as described below. Record the workflow URL,
   artifact name and ID, commit SHA, package version and SHA-256, signer subject
   and certificate SHA-256, verifier machine, verifier result, and attestation
   result on the owning issue. That hash-identified issue record selects the
   exact downstream candidate; never replace it under the same label.

For local structure validation only, after a Windows release build run:

```powershell
./tool/windows/package_msix.ps1 -SkipFlutterBuild -AllowUnsigned -WindowsSdkVersion 10.0.22621.0
```

This intentionally produces `*.unsigned.msix`. It cannot be installed as a
release and must never be privately delivered.

## Verify before installation

On a supported Windows machine, use approved Publisher and certificate values
obtained separately from the downloaded artifact. Verify the bundled CER's
SHA-256 against that separate record, then trust only that public certificate
before package verification:

```powershell
$bundle = Resolve-Path .\clinical-calendar-windows-<commit-sha>
$publicCertificate = Resolve-Path "$bundle\ClinicalCalendar-<version>-x64.msix.cer"
$certificate = [Security.Cryptography.X509Certificates.X509Certificate2]::new($publicCertificate)
$approvedFingerprint = '<approved 64-hex certificate SHA-256>'.ToUpperInvariant()
$actualFingerprint = $certificate.GetCertHashString(
  [Security.Cryptography.HashAlgorithmName]::SHA256
).ToUpperInvariant()
if ($actualFingerprint -ne $approvedFingerprint) {
  throw 'Refusing to trust an unapproved Windows release certificate.'
}
Import-Certificate `
  -FilePath $publicCertificate `
  -CertStoreLocation Cert:\LocalMachine\TrustedPeople

./tool/windows/verify_release_bundle.ps1 `
  -BundlePath $bundle `
  -ExpectedPublisher '<approved certificate subject>' `
  -ExpectedSignerSha256 $approvedFingerprint `
  -ExpectedRepository 'mshamblin5150-code/clinical-calendar' `
  -ExpectedCommitSha '<40-hex candidate commit>' `
  -WindowsSdkVersion '10.0.26100.0'

$package = Resolve-Path "$bundle\ClinicalCalendar-<version>-x64.msix"
gh attestation verify $package `
  --repo mshamblin5150-code/clinical-calendar `
  --signer-workflow mshamblin5150-code/clinical-calendar/.github/workflows/windows-release.yml `
  --source-digest '<40-hex candidate commit>' `
  --bundle "$bundle\windows_release_provenance.sigstore.json"
```

The verifier recomputes the checksum, reconciles the provenance identity,
requires a trusted Authenticode signer and timestamp, compares the subject and
certificate SHA-256 with independently approved values, and reruns pinned-SDK
SignTool verification. The GitHub CLI command binds those bytes to the protected
workflow and source commit. Both commands must pass.

This certificate is approved only for authenticated private delivery. It does
not carry public-CA trust and must not be represented as suitable for public
distribution. Each target machine must verify its SHA-256 through a separate
channel and trust only the public `.cer` in Local Computer `Trusted People`.
Never distribute the PFX or its password.

## Clean install and offline verification

1. Verify the hash and signature, then install with Windows App Installer or
   `Add-AppxPackage .\ClinicalCalendar-<version>-x64.msix`.
2. Launch Clinical Calendar, complete passwordless sign-in, and create a unique
   non-patient test schedule sentinel.
3. Confirm the local database is SQLCipher encrypted and its key is held only
   by Windows secure credential storage.
4. Disconnect networking, restart the application, and verify the local
   schedule, navigation, notifications, exports, Trash, and encrypted-backup
   creation remain functional. Sync and sign-in must report offline state
   without losing local data.
5. Reconnect and verify the outbox synchronizes once without duplicates.

Record evidence on a clean supported Windows machine; a successful build on a
developer machine is not clean-install acceptance evidence.

## Upgrade and rollback

Install a higher-version package with the same `Identity Name` and certificate
subject over the previous supported build. Before upgrading, record database
and notification state and create an encrypted portable backup. After upgrade,
verify the encrypted database, secure credentials, schema migrations, pending
outbox, notification settings, offline restart, and sync convergence.

MSIX does not permit a version downgrade. Rollback therefore means rebuilding
the previously approved source with a new, higher package version and the same
identity/signing lineage, then installing it as an upgrade. Confirm schema
compatibility before authorizing rollback; otherwise restore the pre-upgrade
encrypted portable backup into a compatible release.

## Uninstall, device removal, and recovery

Windows uninstall removes the installed app package and its package-local data;
it does **not** delete synchronized server data or the account. If the intent is
to retire a device, first use **Remove This Device's Copy** in the application
and complete its guarded pending-change, sign-out, database-sidecar, and secure-
credential workflow. Do not describe ordinary uninstall as account erasure.

After reinstalling a valid newer or equal package version, the Student may sign
in and reconnect to synchronized data. If the account cannot be recovered, use
the in-app encrypted portable-backup restore flow with the Student-held
passphrase. Support cannot retrieve that passphrase, inspect the backup or
private server data, bypass ownership, or restore an erased account.

## Private delivery

Share the signed MSIX, expected SHA-256, public certificate when required, and
these instructions over authenticated channels. Keep the approved Publisher,
certificate SHA-256, and package checksum on a separate channel where
practical. These records contain no secret material.

Retain the downloaded workflow bundle and owning-issue selection record for
reproducible verification. GitHub retention is 90 days, so archival policy must
preserve the exact bytes before expiry. Immutability comes from the package
SHA-256, certificate identity, source commit, and signed GitHub provenance, not
from a mutable display name. Retain the preceding supported
artifact for rollback construction, but never publish mutable “latest” files
without the exact version, commit, signer, and checksum record.
