# Define Data Ownership, Backup, and Recovery

Type: grilling
Status: resolved
Blocked by: 02

## Question

What should the Student be able to export, restore, reset, and recover; how should device replacement and account loss behave; and which guarantees must the chosen synchronization model provide?

## Comments

## Answer

### Ownership and identity

- The Student owns all entered data. The service may use it only to provide synchronization, backup, recovery, and requested exports; advertising, sale, model training, and behavioral profiling are prohibited.
- Diagnostic telemetry excludes schedule contents, Preceptor details, notes, and exported files.
- A passwordless email account is the synchronization identity. Initial setup and new-device sign-in use an emailed one-time code; no password or Google account is required. After initial authentication, the complete local calendar remains usable offline.
- A still-signed-in device may change the account email after verifying the new address. If no signed-in device remains and the email account is inaccessible, the old account is unrecoverable; the Student creates a new account and restores an encrypted backup. Support cannot bypass ownership or inspect private data.

### Device and local-data protection

- Every device keeps a complete encrypted local database. Its key resides in platform secure credential storage, while normal device PIN, biometric, or Windows authentication controls physical access.
- Connected Devices shows each device's name, platform, and last synchronization time. The Student may revoke a lost device to prevent future synchronization; revocation cannot remotely erase an offline copy.
- Sign Out and Remove This Device's Copy removes only that device's local data after clearly reporting whether all pending changes synchronized. It never deletes the account or other devices' copies.

### Synchronization guarantees

- Local saves never wait for the network. Synchronization runs after saved changes, reconnection, and app launch or resume, with a manual Sync Now action also available.
- Every main screen exposes synchronization health: Synced, Offline with locally saved changes, Syncing, Conflict Needs Attention, or Sync Failed, plus last successful synchronization time and pending-change count. The app never implies unsynchronized data is backed up.
- Conflicting offline records are preserved rather than resolved by timestamp or silent last-write-wins behavior. If merged records violate Schedule Conflict or Protected Day rules, both remain visible as a Sync Conflict until the Student moves, cancels, or deletes one; the affected week cannot be fully planned meanwhile.
- Two offline edits to the same record produce a side-by-side resolution screen. The Student may choose either version or compose a corrected final version, while both originals remain in recovery history.

### Trash and operational recovery

- Deleted eligible records enter synchronized Trash for 30 days and may be restored from any device. Permanent deletion requires confirmation; clearing all Trash requires reauthentication. Existing domain rules still prohibit deleting referenced or nonempty records merely to bypass history.
- The service retains daily recovery snapshots for 30 days to protect against corruption, synchronization defects, or bulk mistakes. Snapshot recovery first creates a preview copy and never overwrites live data without confirmation.

### Portable backup and restore

- The Student can create a complete encrypted portable backup containing placements, sessions, Preceptors, templates, settings, Evaluation Plans, and history. A Student-chosen backup passphrase protects it; the normal system file picker can save it to Google Drive, iCloud Drive, OneDrive, removable storage, or a local folder.
- A backup restores independently of the synchronization service. Restoring into populated data always previews and safely merges by permanent record identity; it keeps newer nonconflicting data and asks about genuine conflicts. The MVP offers no unguarded Replace Everything action.
- Restore is all-or-nothing: encryption, checksum, schema version, and every record are validated first. Older supported backups migrate forward; damaged or newer unsupported backups are rejected clearly, leaving current data untouched.

### Open exports

- A Clinical Placement report exports as printable PDF by default, with CSV as an advanced option. It includes placement dates and target, completed/scheduled/remaining/over-target totals, session ledger, per-Preceptor breakdown, and Evaluation Plan status.
- A complete machine-readable JSON export supports data portability. Because it is readable and exposes private schedule and contact data, it requires reauthentication and a privacy warning.

### Account deletion

- Delete Account and All Data is distinct from signing out. It requires reauthentication, offers a backup first, and begins a 30-day recovery period; signing back in during that period cancels deletion.
- When the grace period expires, active synchronized data, Trash, device registrations, and authentication records are permanently removed. Residual encrypted operational snapshots expire within at most 30 additional days, after which the account and its data are unrecoverable.
