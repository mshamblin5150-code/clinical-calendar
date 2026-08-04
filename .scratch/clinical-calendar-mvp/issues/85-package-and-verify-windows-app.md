# Package and Verify the Windows Application

Type: task
Status: claimed
Blocked by: 71, 72, 73, 74, 75, 76, 78, 79, 80, 81, 82, 83, 84

## Objective

Produce a repeatable privately installable Windows release and verify install, upgrade, offline, and recovery behavior.

## Acceptance criteria

- CI produces the chosen signed Windows release artifact from a pinned toolchain and versioned application identity.
- A clean machine can install, launch, sign in, create local data, work offline, and uninstall through documented steps.
- Upgrading from the previous supported build preserves the encrypted database, credentials, migrations, outbox, and notification settings.
- Removing only the application does not claim server data is deleted; Remove This Device's Copy follows its guarded workflow.
- Reinstallation can reconnect to synchronized data or restore an encrypted backup.
- Artifact signing, verification, rollback, and private-delivery instructions contain no secret material and are reproducible by the maintainer.

## Comments

- 2026-08-04: Claimed after Ticket 84 resolved. The repository-pinned Flutter 3.44.8 toolchain successfully produced the baseline Windows release executable at `apps/clinical_calendar/build/windows/x64/runner/Release/clinical_calendar.exe`. Next work is the versioned signed installer/CI path and install-upgrade-recovery verification; the unsigned runner bundle is not being treated as the deliverable.
