# Package and Verify the iPhone Application

Type: task
Status: open
Blocked by: 71, 72, 73, 74, 75, 76, 78, 79, 80, 81, 82, 83, 84

## Objective

Produce a provisioned iPhone release and verify the preferred repeatable private beta path.

## Acceptance criteria

- A pinned macOS/Xcode build environment produces an archive signed with the documented Apple team, bundle identity, and entitlements.
- The application installs and runs on a supported physical iPhone through the approved development/ad hoc gate and the repeatable TestFlight beta path.
- Upgrade preserves the encrypted database, Keychain credentials, migrations, outbox, reminders, and notification permissions.
- Background/resume sync, quiet hours, notification actions, file-provider backup/restore, export, and offline restart pass on the supported iOS version matrix.
- Provisioning expiry, device replacement, uninstall/reinstall, and backup recovery behavior are documented accurately.
- No public App Store launch work is introduced into the MVP ticket.

## Comments

- 2026-08-04: Prerequisite tickets are complete, but this ticket remains deliberately deferred at the maintainer's direction until Mac/Xcode and physical iPhone equipment are available. It is not claimed and no iPhone packaging work is running.
