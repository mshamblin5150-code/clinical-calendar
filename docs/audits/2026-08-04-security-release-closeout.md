# Security and Private-Release Closeout — 2026-08-04

This record preserves the resumable engineering, security, and physical-device
evidence for Clinical Calendar Tickets #84–#87. It contains no signing
passwords, database keys, OTPs, backup passphrases, or privileged Supabase
credentials.

## Scope and final disposition

- [Ticket #84](https://github.com/mshamblin5150-code/clinical-calendar/issues/84),
  privacy and security boundaries: resolved and closed.
- [Ticket #85](https://github.com/mshamblin5150-code/clinical-calendar/issues/85),
  Windows packaging: remains open/in progress. The packaging implementation is
  complete, but a durable release certificate and clean-machine lifecycle
  acceptance are still required.
- [Ticket #86](https://github.com/mshamblin5150-code/clinical-calendar/issues/86),
  Android tablet packaging: remains open/in progress. A production-signed
  artifact and substantial physical-device coverage exist, but configured
  authentication/synchronization, notification delivery/action coverage, and
  removal/recovery acceptance remain open.
- [Ticket #87](https://github.com/mshamblin5150-code/clinical-calendar/issues/87),
  iPhone packaging: deliberately deferred at the maintainer's direction until
  Mac/Xcode and physical iPhone equipment are available. Prepared icon assets
  do not constitute iPhone release verification.

The completed changes were reviewed through stacked pull requests
[#89](https://github.com/mshamblin5150-code/clinical-calendar/pull/89) and
[#90](https://github.com/mshamblin5150-code/clinical-calendar/pull/90), with
passing GitHub Quality checks. The authorized closeout merged both stacks to
`main` in dependency order: #89 as `aa573454a23abe708c312a8e81903eea01ba4ab3`,
then #90 as `d0baeed30a28e0da125cd195d66cd57c21c13741`. No force push or
protection bypass was used.

## Codex Security scan

- The first scan, `9501dd17-aff0-46d1-840c-ca11262338dd`, is orphaned failed
  progress only. It stopped during discovery after a Windows repository-path
  inventory rejection: 534 files were detected, but it produced zero worklist
  rows, zero reviews, no findings, and no report. Its zero findings must never
  be interpreted as a clean result.
- The replacement standard repository-wide scan is
  `a216b205-c273-4ac9-9013-ec2084e69f2d`. It completed threat modeling,
  exhaustive inventory of all 534 files, discovery, validation, attack-path
  analysis, canonical artifacts, report generation, and completion. Its
  workbench `artifacts/fix_report.md` contains the required fix evidence.
- Seven evidence-backed findings were validated and remediated: four medium
  and three low severity. The fixes cover permanent-purge convergence,
  fail-closed Android release signing, HTTPS-only release Supabase transport,
  constrained non-clinical evaluation references, CSV formula neutralization,
  and bounded portable-backup parsing/KDF work.
- `docs/release-security-checklist.md` is the tracked release boundary checklist
  for patient-information prohibition, credentials, telemetry, SQLCipher and
  secure storage, lock-screen privacy, authorization/RLS, exports/backups,
  session revocation, Trash/permanent purge/account erasure, artifacts, and
  support/diagnostic paths.

Security verification completed successfully:

- full repository analyze/test quality gate;
- 117 Supabase pgTAP assertions;
- static synchronization contract and concurrent permanent-purge race;
- focused evaluation privacy, CSV encoding, backup limit, and KDF tests;
- Android debug build plus required fail-closed unsigned-release test;
- source and debug-APK scans for credential/signing-secret signatures; and
- `git diff --check`.

The SQLCipher `hmac check failed` messages emitted by the quality gate are from
intentional wrong-key and corruption negative tests; those tests pass and the
messages are not production failures.

## Implemented security and release behavior

Commit history, in dependency order:

- `56db4c3` — Ticket #84 security remediations.
- `4f71175` — pinned private Windows/Android packaging, shared Axion calendar
  app identity, notification permission correction, and release documentation.
- `b605894` — production backup/restore and export composition, including
  Android content-URI-safe `.ccbackup` selection.
- `23ac377` — Windows build 4 package validation evidence.
- `c495156` — deferred native export platform detection until save time so
  production composition remains testable on Linux CI while unsupported saves
  still fail closed.

Notable implementation decisions:

- Production signing secrets remain outside the repository and CI removes
  temporary imported credentials after packaging.
- Android and Windows release paths use pinned Flutter 3.44.8 workflows,
  versioned identities, signer/checksum verification, and fail-closed checks.
- Backup creation is encrypted; restore presents a content-free preview and
  applies only after confirmation. Cancelled selection clears stale preview,
  and failed/cancelled creation is not reported as success.
- Complete JSON export requires privacy acknowledgement and fresh OTP
  reauthentication. Placement PDF/CSV exports require an active Clinical
  Placement. CSV cells that could be interpreted as formulas are neutralized.
- Notification permission is requested before candidate discovery so an empty
  or failed candidate query cannot suppress Android's permission prompt.
- The approved Axion mark with a correctly scaled delta is the shared Android,
  Windows, and prepared iOS app icon. Clinical Calendar test data need not be
  preserved as brand data.

## Android signing and physical-device evidence

The durable Android signer is stored outside the repository under the
maintainer's `Documents/Clinical Calendar Release Signing` directory, protected
by Windows user/SYSTEM ACLs and DPAPI-backed credential handling. The public
signer SHA-256 certificate fingerprint is:

`9903ACA5242DAA0F926270940B4174687F65144B698D28A7C4DBD00BEDB817F0`

Do not replace this signer for future upgrades. Never copy its password or
private key into the repository, issue tracker, logs, or CI configuration.

Physical target: Samsung SM-X920, serial `R52Y208MECT`, Android 16/API 36.
Only app-scoped install/uninstall/restart operations were performed. Firmware,
bootloader, recovery, factory reset, system configuration, and other apps were
not modified.

Evidence sequence:

1. The original 0.1.0+1 install used the Android debug certificate and could
   not be upgraded into the permanent production signing lineage. The owner
   declared its data disposable and authorized app-only uninstall/install.
2. Production build 1 installed and launched. A content-free secure-storage
   migration handled the obsolete debug-install algorithm marker.
3. Build 2 upgraded in place and preserved a fictional Work Shift for
   2026-08-05, 08:00–16:00. No patient or real clinical data was used.
4. Build 3 corrected notification permission ordering. It displayed Android's
   permission prompt and retained the approved signer. Detailed lock-screen
   previews remained off and quiet hours remained 21:00–07:00.
5. With Wi-Fi disabled and no default network, cold launch completed in 250 ms
   and preserved the Work Shift. A normal restart produced a 696 ms offline
   cold launch with data and notification permission preserved.
6. An accidental full power-off/restart while still offline was treated as an
   additional power-loss test. After boot completion, cold launch took 261 ms;
   data and permission survived with no fatal, SQLCipher, or secure-storage log
   evidence.
7. After Wi-Fi restoration, Android reported a default network and the app
   cold-launched in 255 ms with the Work Shift intact. This proves local
   offline-to-online lifecycle recovery, not server synchronization: the build
   remains visibly `LOCAL` because protected Supabase configuration/session
   material is absent.
8. Production build 4 APK SHA-256 is
   `45A73A86A0B735B17FE81B4734405FFA84ECC4A6D6AA54095FB8F7F70EBBCF43`.
   It upgraded in place, retained the signer, Work Shift, and notification
   grant, and cold-launched in 270 ms.
9. Android DocumentsUI created a 3,838-byte encrypted `.ccbackup` in the
   tablet's Downloads directory. A wrong passphrase failed generically without
   changing data. The correct passphrase produced the content-free preview
   `0 additions · 0 newer backup updates · 3 local records kept`; safe merge
   succeeded and preserved the Work Shift.
10. Export navigation is reachable. Placement PDF/CSV correctly disable with
    no active Clinical Placement. Complete JSON shows its privacy warning and
    then refuses export because a `LOCAL` build cannot complete fresh OTP
    reauthentication; no destination picker opens.

The physical test backup contains only fictional local data. It was not deleted
during this work.

## Windows evidence

- A pinned Windows 2025 / Flutter 3.44.8 workflow builds a versioned x64 MSIX,
  imports an ephemeral PFX, derives the manifest Publisher from the certificate
  subject, signs with timestamping, verifies the signature/checksum, and removes
  temporary credentials.
- A one-day smoke-test certificate produced a timestamped MSIX that SignTool
  verified with zero warnings/errors; the temporary certificate and trust entry
  were removed afterward. It is not the durable production identity.
- The 0.1.0.4 unsigned structural package is
  `ClinicalCalendar-0.1.0.4-x64.unsigned.msix`, SHA-256
  `CA87D7B565625D8B6398F5C121CB762BE2C443DF44CDC84C1BE73667A6E9872A`.
  MakeAppx structure validation passed. This artifact is explicitly
  non-distributable because it is unsigned.
- Shared 44px and 150px Axion calendar assets are referenced by the manifest.

## Commands and reproducible checks

The principal commands used during implementation and closeout were:

```powershell
# Complete repository verification
& .tooling\flutter\bin\dart.bat run tool/quality.dart

# Android signer and package verification
pwsh -File tool/android/android_release_contract_test.ps1
pwsh -File tool/android/verify_signed_apk.ps1 <apk> <expected-fingerprint>

# Safe in-place Android upgrade (after signer verification)
.tooling\android-sdk\platform-tools\adb.exe install -r <signed-apk>

# GitHub check verification
gh pr checks 89
gh pr checks 90
```

The final local full quality gate passed. PR #89's Quality run
`30932301186` passed. PR #90's final Quality run `30940457073` passed on
commit `c495156` after correcting Linux-only eager platform resolution. The
documentation closeout run `30941062406` also passed before PR #90 merged. The
local `main` checkout was then fast-forwarded to `origin/main` and verified
clean at `d0baeed`.

## Remaining work and safe resume point

Ticket #85 must remain open until a durable real Windows private-release
certificate exists and a clean machine proves install, launch, authentication,
local creation, offline use, signed upgrade preservation, uninstall semantics,
and synchronized or encrypted-backup recovery.

Ticket #86 must remain open until a protected Supabase release build proves
passwordless authentication, RLS-isolated synchronization/outbox convergence,
and session revocation. Add only fictional Clinical Placement, Preceptor, and
Clinical Session data for placement PDF/CSV and reminder tests. Verify actual
scheduled notification delivery/actions and background restrictions: after
build 4, inspection found no application alarms and no `reminders` notification
channel, so delivery must not be claimed. Remove This Device's Copy and
uninstall/recovery are intentionally deferred until authenticated sync or a
verified recovery source makes those destructive app-data operations safe.

Ticket #87 remains deferred. Do not infer acceptance from generated iOS icon
assets; resume only when the maintainer has suitable Apple hardware/tooling.

At authorized closeout, `main` contains both PR #89 and PR #90. Ticket #84 is
closed. GitHub automatically closed #85 when PR #90 merged even though its
acceptance criteria remain incomplete; #85 was immediately reopened with an
explanatory comment and remains in progress. Ticket #86 remains open and in
progress. Ticket #87 remains open and explicitly equipment-deferred.
