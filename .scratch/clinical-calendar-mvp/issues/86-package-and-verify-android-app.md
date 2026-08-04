# Package and Verify the Android Tablet Application

Type: task
Status: claimed
Blocked by: 71, 72, 73, 74, 75, 76, 78, 79, 80, 81, 82, 83, 84

## Objective

Produce a signed privately installable Android tablet release and verify lifecycle, notification, file, and offline behavior.

## Acceptance criteria

- CI produces a signed APK for private installation from a pinned toolchain without exposing the signing secret.
- A supported physical tablet can install, launch, authenticate, create data, restart offline, and synchronize after reconnection.
- Upgrade preserves the encrypted database, secure credentials, migrations, outbox, reminders, and notification channels.
- Quiet hours, notification actions, background restrictions, file-picker backup/restore, and export work on the supported Android version matrix.
- Uninstall/reinstall behavior is accurately explained and recovery from synchronized state or encrypted backup succeeds.
- Artifact signing verification and private-install instructions are reproducible by the maintainer.

## Comments

- 2026-08-04: Claimed for parallel execution after Ticket 84 resolved and every prerequisite closed. Signed APK CI, maintainer verification, and tablet lifecycle evidence are in progress; physical-tablet acceptance remains evidence-based and will not be inferred from emulator or build-only results.
- 2026-08-04: Added the pinned, protected `Android private release` workflow plus fail-closed packaging and `apksigner` certificate verification scripts. Signing material remains external to the repository and is removed from the runner after every attempt. Added reproducible private-install, upgrade, checksum, signer, offline, notification, file-picker, device-copy removal, and recovery procedures in `docs/android-private-release.md`. Static and local build-path validation are in progress; all physical-tablet acceptance criteria remain open pending real supported hardware evidence.
- 2026-08-04: Local validation passed for the Android release contract, PowerShell parsing, workflow YAML parsing, missing-credential fail-closed behavior, and explicit rejection of an `apksigner`-valid APK carrying the Android debug certificate. A production-signed artifact and every supported physical-tablet lifecycle check still require the maintainer's protected signing environment and tablet hardware, so Ticket 86 remains claimed rather than resolved.
- 2026-08-04: Physical hardware is now available and authorized: Samsung SM-X920, Android 16/API 36, 1848x2960 at 280 dpi. The currently installed `com.clinicalcalendar.clinical_calendar` 0.1.0+1 APK has exactly one signer and it is the Android debug certificate (`0c3838cb...d555ee2`), so it cannot be upgraded in place by a production key. No production keystore credentials are present in this task environment. Establishing or supplying the durable production signing lineage, then backing up/removing the debug-signed install before the first production install, are required before destructive hardware lifecycle execution.
- 2026-08-04: Established the first permanent production signing lineage outside the repository with user/SYSTEM-only Windows ACLs, DPAPI-protected credentials, a public certificate/fingerprint, recovery instructions, and a Desktop shortcut. A 4,096-bit RSA production release APK built successfully and `apksigner` verified exactly the approved non-debug signer (`9903aca5...b817f0`); APK SHA-256 is `3518471b...007d83`. The tablet remains unchanged. Because Android cannot upgrade the existing debug-signed install to the production lineage, an in-app encrypted backup or explicit confirmation that existing local data is disposable is required before app-only uninstall/install testing.
- 2026-08-04: The owner confirmed the previous debug-install data was disposable. Performed an app-only uninstall/install on the Samsung SM-X920 without changing firmware, bootloader, system settings, or any other application. Production build 1 installed and cold-launched successfully. After a content-free secure-storage migration from the debug install's obsolete Android algorithm marker, a second cold launch completed without storage or fatal errors.
- 2026-08-04: Adopted the approved scaled-delta Axion calendar mark as the shared Android, iOS, and Windows app icon, with a deterministic generator and checked-in master. Created one fictional Work Shift (2026-08-05, 08:00-16:00), installed production build 2 with `adb install -r`, and verified version, cold launch (231 ms), signer continuity, and Work Shift persistence. No real clinical or patient data was used.
- 2026-08-04: Physical Android 16 QA found that enabling System notification delivery could leave `POST_NOTIFICATIONS` denied without displaying the OS prompt when candidate discovery failed first. Reordered permission handling ahead of candidate discovery and added a regression test. Production build 3 (`867f18fa...8ac4ec`) is signed by the approved signer (`9903aca5...b817f0`), upgraded in place, displayed the OS permission prompt, and received the grant. The device still reports detailed lock-screen previews off and quiet hours 21:00-07:00, and the fictional Work Shift remains present. The full repository quality gate passes. Offline/reconnection, authentication/synchronization, notification action/background delivery, file-picker backup/restore/export, and removal/recovery checks remain outstanding, so the ticket stays claimed.
