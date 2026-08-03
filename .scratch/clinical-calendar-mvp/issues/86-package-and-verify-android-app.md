# Package and Verify the Android Tablet Application

Type: task
Status: open
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

