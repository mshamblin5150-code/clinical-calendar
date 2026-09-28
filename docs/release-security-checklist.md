# Release Security Checklist

Use this checklist for every public web release and every private Windows,
Android, or iPhone build. Record the completed evidence with the owning release
or packaging issue; never paste a secret value into the checklist, issue
tracker, logs, or artifact metadata.

## Data and privacy

- Confirm production surfaces do not solicit patient identifiers, encounter
  details, diagnoses, clinical narratives, evaluation files, or credentials.
- Confirm evaluation documentation accepts only a short external record
  reference and displays the no-patient-information boundary.
- Exercise PDF, CSV, and JSON exports with sentinel private values. Verify the
  intended report fields only, spreadsheet-formula neutralization, the JSON
  reauthentication gate, and the privacy warning.
- Verify backup creation and restoration use memory-only plaintext handling,
  reject out-of-policy KDF parameters, and reject container/dataset limits
  before expensive processing.

## Credentials, artifacts, and transport

- Build from a clean checkout and a pinned toolchain. Supply signing material
  only through the platform or CI secret store.
- Verify the final artifact is not signed by an Android debug certificate and
  validate every platform signature before private delivery.
- Inspect the final artifact for private keys, privileged Supabase keys,
  backup passphrases, SQLCipher keys, access/refresh tokens, test accounts, and
  prototype fixture data. Public Supabase publishable keys are not authority.
- Verify every non-loopback identity and synchronization endpoint is HTTPS.

## Runtime controls

- Verify SQLCipher fails closed when encryption is unavailable and its random
  database key remains in the approved platform secure-storage adapter.
- Verify default lock-screen notifications contain no Preceptor, location,
  note, Clinical Placement, or schedule detail.
- Verify revoked Connected Devices cannot refresh, pull, or push, and removing
  a local copy deletes only the documented local database/key/session files.
- Seed a unique private sentinel, move its record through Trash and permanent
  purge, and verify it is absent from live records, synchronization history,
  idempotency receipts, exports, logs, and support diagnostics.
- Verify full account erasure removes Auth, synchronized data, devices, and
  sync state, while encrypted recovery snapshots expire on schedule.

## Web release

Exercise this section against the deployed HTTPS site with invented,
non-patient data. Record the deployed commit, Pages run, browser and version,
date, and results on the owning release issue.

- Confirm the production URL is HTTPS, HTTP redirects to HTTPS, and every
  non-loopback identity, synchronization, and work-schedule-feed request uses
  HTTPS.
- Sign in, create and synchronize a unique calendar sentinel, and inspect the
  site's Local Storage, IndexedDB, Origin Private File System (OPFS), and Cache
  Storage. Calendar records, synchronization records, the outbox, access
  tokens, and exported data must not be at rest in any of them. Close or reload
  the tab and confirm the calendar is downloaded again rather than restored
  from browser storage.
- Permit only the documented remembered-session exception: the refresh token
  and opaque Connected Device ID may remain in Local Storage. Confirm revoking
  that Connected Device blocks further refresh, pull, and push. Confirm the
  server auto-revokes a web Connected Device after 90 days without a sync.
- Confirm public hosting exposes only the application assets and Supabase
  publishable key. Verify no service-role or secret key, private key, database
  key, backup passphrase, access or refresh token, test credential, or calendar
  fixture is present in the deployed bundle. Confirm row-level security blocks
  cross-Student reads and writes.
- Exercise PDF and CSV exports and verify the privacy warning, intended fields,
  and spreadsheet-formula neutralization. Exercise complete JSON export and
  verify fresh one-time-code reauthentication is required before the browser
  download begins. Cancel or fail reauthentication and confirm no download is
  produced.
- Open **Backup & Restore** and confirm the web client says backups are made
  from installed apps. No create, restore, file-picker, or automatic-backup
  control may be available on web.
- Confirm the external-sharing gate in
  [the web release guide](web-release.md) is satisfied before sharing the URL
  outside the Supabase organization.

## Support boundary and residual risk

- Support may explain local recovery steps and collect only Student-approved,
  content-free health metadata. Support has no private-data viewer, ownership
  bypass, service-role client, database-key recovery path, or notification and
  export bypass.
- Record unavailable platform tests as unresolved release blockers rather than
  treating static inspection or another platform as equivalent evidence.
- Record the artifact digest, signer identity/fingerprint, toolchain versions,
  install/upgrade source version, verification commands, and remaining risks.
