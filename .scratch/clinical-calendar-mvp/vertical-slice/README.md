# Clinical Calendar vertical slice

Ticket 58's production-stack gate. This is one Flutter codebase for Windows,
Android, and iPhone. It proves a responsive Variant F week view, shared
scheduling invariants, encrypted SQLCipher persistence, and OS-backed key
storage before feature-scale implementation begins.

## Proven environment

- Flutter 3.44.8 / Dart 3.12.2
- Windows 11 with Visual Studio 2022 17.12 and Windows SDK 10.0.22621
- Android SDK 36, Build Tools 36.0.0, Platform Tools 37.0.1, JDK 17
- `sqlite3` configured to bundle SQLCipher on supported native targets
- `flutter_secure_storage` for Windows Credential Manager, Android encrypted
  storage, and iOS Keychain integration

## Validate

From this directory:

```text
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build windows --release
flutter build apk --debug
```

On 2026-08-03, analysis and all seven tests passed. Windows produced
`build/windows/x64/runner/Release/clinical_calendar_vertical_slice.exe`, and
Android produced `build/app/outputs/flutter-apk/app-debug.apk`. Build output is
intentionally excluded from version control.

The tests prove exact-minute overlap handling, adjacency, Protected Day rules,
encrypted close/reopen persistence, rejection of a wrong database key, and
responsive 390x844 and 1200x800 compositions. A deliberate wrong-key test emits
SQLCipher HMAC errors to the test log; that is expected evidence of rejection.

## Mac and iPhone handoff

1. Install current Xcode and its iOS Simulator runtime, Flutter stable, and
   CocoaPods on Apple silicon macOS.
2. Run `flutter doctor -v` and resolve only reported iOS toolchain problems.
3. From this directory, run `flutter pub get` and `flutter test`.
4. Open `ios/Runner.xcworkspace` in Xcode. Select the Runner target, choose the
   owner's Apple development team, and set a unique bundle identifier if Xcode
   reports a collision.
5. Run `flutter build ios --simulator`, then launch on at least one compact
   iPhone Simulator.
6. Connect the physical iPhone, trust the Mac, enable Developer Mode if asked,
   select the device, and run the app from Xcode or `flutter run`.
7. Verify create, conflict rejection, Protected Day rejection, force-quit,
   offline relaunch, encrypted-data persistence, safe areas, and rotation.

Do not commit signing certificates, provisioning profiles, Keychain material,
local databases, SDKs, or generated build folders. Simulator success does not
complete ticket 58; the physical iPhone, Android tablet, and Windows checks are
explicit acceptance requirements.
