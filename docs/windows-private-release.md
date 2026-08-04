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
- Keep the certificate subject stable. It becomes the MSIX Publisher identity;
  changing it creates a different application instead of an upgrade.
- Never commit or attach the PFX, its password, a private key, database key,
  backup passphrase, Supabase privileged key, or test account credential.

The workflow imports the PFX into the ephemeral runner's Current User store,
derives the manifest Publisher from the certificate subject, requires it to
match the pinned `WINDOWS_SIGNING_PUBLISHER`, signs with SHA-256
and an RFC 3161 timestamp, verifies the completed signature, uploads only the
MSIX and SHA-256 file, and removes the certificate in an `always()` cleanup
step. Missing signing secrets fail before the release build.

## Produce a release

1. Increment `apps/clinical_calendar/pubspec.yaml` using
   `major.minor.patch+build`. MSIX receives `major.minor.patch.build`; every
   component must be between 0 and 65535, and an upgrade must be greater than
   the installed package version.
2. Complete `docs/release-security-checklist.md` against the candidate commit.
3. Run the `Windows private release` workflow manually from that commit.
4. Download the workflow artifact and retain the workflow URL, commit SHA,
   package version, signer certificate subject/thumbprint, timestamp result,
   SHA-256 value, and verification-machine identity in the private release log.

For local structure validation only, after a Windows release build run:

```powershell
./tool/windows/package_msix.ps1 -SkipFlutterBuild -AllowUnsigned -WindowsSdkVersion 10.0.22621.0
```

This intentionally produces `*.unsigned.msix`. It cannot be installed as a
release and must never be privately delivered.

## Verify before installation

On the target Windows machine, compare the package with the separately shared
expected hash and require a valid trusted signature:

```powershell
$package = Resolve-Path .\ClinicalCalendar-<version>-x64.msix
Get-FileHash -Algorithm SHA256 $package
$signature = Get-AuthenticodeSignature $package
$signature | Format-List Status,StatusMessage,SignerCertificate,TimeStamperCertificate
if ($signature.Status -ne 'Valid') { throw 'Clinical Calendar signature is not valid.' }
```

The signer subject must match the recorded publisher. For a self-signed private
test certificate, distribute only its public `.cer` through a separate trusted
channel and install it in Local Computer `Trusted People` before verifying the
MSIX. Never distribute the PFX. A publicly trusted code-signing certificate or
Azure Artifact Signing avoids that manual trust bootstrap for production use.

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
these instructions over authenticated channels. Keep the hash on a channel
separate from the package where practical. Retain the preceding supported
artifact for rollback construction, but never publish mutable “latest” files
without the exact version, commit, signer, and checksum record.
