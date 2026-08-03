# Prove the Flutter and SQLite Vertical Slice

Type: task
Status: claimed
Blocked by: 57

## Objective

Prove the production stack on physical Windows, iPhone, and Android tablet targets before feature-scale implementation, as required by [`spec.md`](../spec.md#10-packaging-and-installation-gate).

## Acceptance criteria

- One Flutter workspace renders a responsive week view on all three target platforms.
- A Clinical Session entered in military time persists in encrypted SQLite after an offline process and device restart.
- Shared domain code rejects one Schedule Conflict and one commitment touching a Protected Day.
- Installable Windows, signed Android APK, and provisioned iPhone artifacts run on physical target devices.
- Build steps, toolchain versions, signing/provisioning prerequisites, and observed platform blockers are documented reproducibly.
- A written gate decision either approves Flutter for the MVP or records a framework-specific failure and triggers the specified .NET MAUI reassessment.

## Comments

- Implementation started on 2026-08-03 from the sole unblocked frontier.
- Created one Flutter workspace with Windows, Android, and iOS runners; shared
  domain validation rejects exact-minute overlaps and commitments touching a
  Protected Day.
- Added SQLCipher-backed SQLite storage with a random 256-bit key held through
  platform secure storage. Automated tests prove encrypted offline reopen and
  wrong-key rejection.
- `flutter analyze` and all seven domain, encryption, and responsive widget
  tests pass on Flutter 3.44.8 / Dart 3.12.2.
- Windows release build passed with Visual Studio 2022 17.12 and Windows SDK
  10.0.22621. Android debug APK build passed with Android SDK 36, Build Tools
  36.0.0, Platform Tools 37.0.1, NDK 28.2.13676358, CMake 3.22.1, and JDK 17.
- Android OS backup is disabled for the application so the encrypted database
  is not copied independently of its platform-protected key.
- Reproducible commands and the Mac/iPhone signing and device handoff are in
  `vertical-slice/README.md`.
- Gate remains open: install/run/force-quit/offline-reopen evidence is still
  required on physical Windows, Android tablet, and iPhone targets. iPhone
  compilation and provisioning require macOS/Xcode and cannot be performed on
  this Windows host.
- Physical Windows host pass completed on 2026-08-03 using the release build:
  the Variant F week rendered without clipping, saving Tuesday 07:00–19:00
  produced one 12-hour Clinical Session, the same-time attempt was rejected as
  a Schedule Conflict, and Thursday was rejected as a Protected Day. After the
  native process was closed and relaunched offline, the app restored exactly
  one session from encrypted SQLite. Remaining physical targets are the Android
  tablet and iPhone.
- Physical Android tablet pass completed on 2026-08-03 on a Samsung SM-X920
  running Android 16 (API 36), arm64-v8a, at 1848x2960 / 280 dpi. The 20.7 MB
  split ARM64 release APK installed over authorized USB ADB and cold-launched in
  659 ms. Portrait and landscape rendered the complete two-column Variant F
  week and evidence panel without clipping. Saving Tuesday 07:00–19:00 created
  exactly one 12-hour session; duplicate and Protected Day attempts were
  rejected without changing the persisted count. With Wi-Fi temporarily
  disabled, a force-stop and cold launch restored exactly one session from
  encrypted SQLite in 211 ms; the Android crash buffer was empty. Wi-Fi and
  automatic rotation were restored after testing.
- The iPhone portion is explicitly deferred at the owner's request until the
  required Mac and physical iPhone hardware are available. The iOS runner,
  shared code, SQLCipher hook, Keychain-backed secure-storage dependency, and
  reproducible Mac/Xcode handoff remain in place; no iPhone result is inferred
  from the Windows or Android passes.
