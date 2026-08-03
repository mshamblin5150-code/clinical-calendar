# Build Encrypted Portable Backup and Restore

Type: task
Status: open
Blocked by: 65, 66, 69

## Objective

Implement service-independent encrypted backup and safe all-or-nothing restore through platform file pickers.

## Acceptance criteria

- A versioned backup includes Clinical Placements, Preceptors, commitments, Protected Days, Historical Hours Entries, Evaluation Plans, templates, settings, profile, reminder state, and history.
- A Student-chosen passphrase protects the backup with documented modern authenticated encryption and no recoverable plaintext temporary file.
- Restore validates passphrase, encryption, checksum, schema version, and every record before writing anything.
- Supported older backups migrate forward; damaged, wrong-passphrase, and newer unsupported backups leave current data untouched.
- Restore into populated data previews a permanent-identity merge, keeps newer nonconflicting data, and asks about genuine conflicts.
- There is no unguarded Replace Everything action, and restore works without the synchronization service.
- Round-trip fixtures pass across Windows, iOS, and Android file pickers and supported schema versions.

