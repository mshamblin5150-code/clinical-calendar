# Android Private Release

Ticket 86 is the release evidence record. A successful build alone does not
replace the physical-tablet install, upgrade, notification, offline, file, and
recovery checks in that ticket.

## One-time GitHub environment setup

Create a protected GitHub environment named `android-private-release`. Limit
deployment access to the maintainer, and configure these environment secrets:

- `ANDROID_KEYSTORE_BASE64`: the release keystore encoded as Base64.
- `ANDROID_KEYSTORE_PASSWORD`: the keystore password.
- `ANDROID_KEY_ALIAS`: the release key alias.
- `ANDROID_KEY_PASSWORD`: the release key password.

Configure `ANDROID_SIGNING_CERT_SHA256` as an environment **variable**. Obtain
it directly from the offline release keystore without printing any password:

```text
keytool -list -v -keystore clinical-calendar-release.keystore -alias <alias>
```

Copy the certificate's complete SHA-256 fingerprint. Keep the keystore and
passwords outside the repository, shell history, issue comments, and build
artifacts. Preserve an offline backup: losing the signing key prevents trusted
upgrades over the installed application.

## Build and retrieve the APK

Run the `Android private release` workflow manually for the reviewed commit.
It uses Flutter 3.44.8, Temurin JDK 17.0.20+8, and Android SDK 36 build
tools 36.0.0 on Ubuntu 24.04, runs the repository quality gate,
materializes the keystore only in the temporary runner directory, builds the
release APK, verifies its signature against the approved certificate, writes a
SHA-256 checksum, and removes the temporary keystore even after failure.

Download the `clinical-calendar-android-<commit>` artifact. Retain the workflow
run URL, commit, APK checksum, and verified signer fingerprint with the release
record. The artifact expires after 14 days and is not a public distribution
channel.

Reverify on a trusted workstation with the Android SDK installed:

```text
powershell -File ./tool/android/verify_signed_apk.ps1 \
  -ApkPath ./app-release.apk \
  -ExpectedSignerSha256 <approved-sha256-fingerprint>
```

Compare the generated `app-release.apk.sha256` with the workflow artifact.
Never install an APK whose digest or signer differs.

## Private installation and upgrade

Enable developer options and USB debugging only for the installation window.
Connect the supported tablet, approve its host prompt, then confirm exactly one
intended device is listed before installing:

```text
adb devices
adb install ./app-release.apk
```

For an upgrade from the previous supported release, preserve application data:

```text
adb install -r ./app-release.apk
```

Android rejects an upgrade signed by another certificate. Do not uninstall to
work around that rejection, because uninstalling removes the local encrypted
database, secure-storage key, session, and pending offline work.

After installation, turn USB debugging back off. Do not distribute the APK by
public link or attach it to a public issue.

## Required tablet evidence

Use a supported physical tablet and record Android version, manufacturer/model,
old and new app versions, artifact digest, and signer fingerprint. Use invented
non-patient data throughout.

1. Install on a clean tablet, launch, authenticate, and create a Clinical
   Placement, Preceptor, Work Shift, Clinical Session, reminder, and encrypted
   backup.
2. Disconnect all networking, restart the application and tablet, and verify
   the encrypted local data, credentials, outbox, reminders, and generic
   lock-screen notifications remain usable without exposing private details.
3. Reconnect and verify queued changes synchronize once, without duplicate or
   missing records.
4. Install the next version with `adb install -r`. Verify the encrypted
   database, secure credentials, migrations, outbox, quiet hours, reminders,
   and notification channels survive.
5. Exercise notification actions and Android background restrictions on every
   supported Android version, including delayed delivery after restrictions
   are relaxed.
6. Export through the system file picker. Create and restore an encrypted
   backup through that picker, including an incorrect-passphrase failure that
   leaves existing data unchanged.
7. Exercise Remove This Device's Copy and its confirmation. Verify it removes
   only this tablet's database, key, session, and scheduled notifications; it
   must not claim synchronized server data was erased.
8. Reconnect after removal and recover synchronized state, then separately
   verify recovery from an encrypted backup. Record conflicts without copying
   private content into logs or the ticket.

## Uninstall and recovery boundary

Android uninstall removes the application's local data. It does not erase
synchronized server data and does not substitute for account erasure. Pending
offline changes that were never synchronized are lost unless captured in an
encrypted backup. Reinstall the same trusted signer, authenticate, synchronize,
or restore a known encrypted backup through the documented in-app flow.

If any lifecycle check fails, stop distribution, retain the failing artifact
digest and content-free reproduction steps, and keep Ticket 86 open.
