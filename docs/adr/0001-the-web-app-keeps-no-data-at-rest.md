---
status: accepted
---

# The web app keeps no data at rest

The web app hosted on GitHub Pages is a full client, and it is the Student's iPhone client until a native iPhone app ships. `docs/architecture.md` still requires encryption at rest, and a browser cannot give the guarantee SQLCipher and an OS keystore give: sqlite3 runs as WASM without SQLCipher, and `flutter_secure_storage` on web is obfuscation, not a keystore. Safari may also evict site storage. So **the web app downloads the Student's data from Supabase into memory after sign-in, pushes every change immediately, and writes no calendar data to browser storage.** Closing or reloading the tab discards the copy, and the next open downloads it again. Grilled in #230.

## Considered options

- **An IndexedDB/OPFS copy with a documented at-rest exception.** Rejected. It would weaken the architecture's one security promise for the least trustworthy device, and eviction could silently lose unsynced Clinical Sessions and Completed Hours.
- **Encrypting a browser copy with a key derived from the session.** Rejected. The key would sit in the same browser storage as the data, so this adds complexity without protection.
- **A separate online-only code path that talks to Supabase directly.** Rejected. Supabase holds opaque sync records, not queryable domain tables, and every calendar rule lives in the Dart domain and application layers. The memory-only store is one more `RepositoryRegistry` adapter, so none of those rules fork.

## Consequences

- Web requires sign-in. On native, a device can still be a standalone local copy with no account.
- Offline edits live only in the in-memory outbox. The web app shows a "Not yet synced" banner, retries in the background, and asks before the tab closes while changes are unsent. If the tab closes offline, those changes are lost.
- Web keeps exactly two identity values at rest: the refresh token, so the Student is not asked for a code on every open, and the opaque device ID that binds that browser to its Connected Device record. Access tokens and every calendar, outbox, and synchronization value remain memory-only. This exception is bounded by revocation: every browser is its own Connected Device, and a web Connected Device is revoked automatically after 90 days without a sync.
- Backups are not created or restored from web. Exports are browser downloads behind the same gates as native.
