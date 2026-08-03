# Synchronization and Storage Model Research

Researched: 2026-08-02

## Decision

Use a **small managed relational sync backend**, with Supabase/Postgres as the reference MVP service, and keep a full local SQLite database on every device. Synchronization should exchange record-level operations through an outbox/inbox protocol; it should not upload and replace one shared database file.

Google Drive may later be offered as an explicit encrypted export/backup destination, but it should not be the authoritative synchronization transport.

This decision applies to the single-Student MVP while preserving a later path to independently private accounts for other Students.

## Why this is the safer fit

The calendar contains rules that must remain true across devices: commitments cannot overlap, no commitment may occur on a Protected Day, Completed Hours must not be counted twice, and each Clinical Placement has exactly one Primary Preceptor. Those are record and transaction invariants, not file-storage concerns.

A Drive file can hold the records, but Drive does not merge application records or enforce these rules. Its change log reports the current state of a changed item rather than a delta, and its push messages do not contain the change details. Consequently, safe multi-device use would require the application to build a database-like merge protocol on top of Drive anyway ([Drive change log](https://developers.google.com/workspace/drive/api/guides/about-changes), [retrieving changes](https://developers.google.com/workspace/drive/api/guides/manage-changes), [push notifications](https://developers.google.com/workspace/drive/api/guides/push)).

Postgres, by contrast, can validate a synchronization operation in one transaction. Serializable transactions reject concurrent executions that cannot be explained as a safe serial order, and range exclusion constraints can reject overlapping time ranges ([PostgreSQL transaction isolation](https://www.postgresql.org/docs/current/transaction-iso.html), [PostgreSQL range constraints](https://www.postgresql.org/docs/current/rangetypes.html)). Supabase exposes a full Postgres database and callable database functions, so the server can accept or reject an operation atomically ([Supabase database overview](https://supabase.com/docs/guides/database/overview), [database functions](https://supabase.com/docs/guides/database/functions)).

## Comparison

| Concern | Google Drive app-managed data | Managed Supabase/Postgres backend |
| --- | --- | --- |
| Student setup | Normal Google consent; no Student-supplied API key. The developer registers the OAuth clients and the Student signs in. | Normal account sign-in; no Student-supplied API key. A public project key is bundled with the app and the Student authenticates for a personal session. Google sign-in can be offered without requesting Drive access. |
| Offline use | Must be built in the app with a local database and upload/merge code. Drive itself is remote file storage. | Must still keep a local database and durable outbox. The backend supplies authoritative record storage and transactions, but Supabase is not by itself an offline database. |
| Concurrent offline edits | Whole-file replacement risks one device overwriting another. File-per-record reduces the collision surface but still needs tombstones, revisions, referential checks, and a merge algorithm. | Record-level optimistic concurrency can reject stale writes. A server transaction can enforce cross-record rules and return a specific conflict for user resolution. |
| Change detection | Drive exposes file versions and a change log, but change entries represent current file state, not field deltas. Push delivery requires an HTTPS webhook, carries no file body, and channels expire, so desktop/mobile clients still need polling or a server. | Pull changes by server revision/cursor; optionally use Realtime only as a wake-up hint. Every accepted mutation receives an ordered server revision. |
| Backup and restore | `appDataFolder` is hidden and app-only, but users can delete it and it is deleted when the user disconnects/uninstalls the app from Drive. Blob revisions are not a durable backup policy: unpinned revisions are normally purgeable after 30 days or earlier after 100 revisions; at most 200 can be kept forever. A visible folder is user-accessible but is also easier to rename, edit, duplicate, or delete. | Pro projects receive daily database backups with seven-day retention. Free projects do not receive automatic backups and can pause after one inactive week, so a dependable release needs either Pro or scheduled off-site logical dumps. A user-facing export remains necessary for ownership and account-loss recovery. |
| Privacy | Data stays in the Student's Google account and the hidden app-data folder is inaccessible to other Drive apps. OAuth refresh tokens must be protected on each device. A visible folder exposes filenames/content to the Student and any party to whom they share it. | The service operator stores the data. Every row must carry `student_id`; Row Level Security must restrict every exposed table to `auth.uid() = student_id`. No patient information is permitted. Local databases and tokens still require platform secure storage/device encryption. |
| Cost | Standard Drive API use currently has no additional charge within quota; Google states charging above a daily threshold is planned later in 2026. The larger cost is custom sync engineering and support. | Free is suitable for development, but it pauses after inactivity and lacks automatic backups. Supabase Pro currently starts at US$25/month and includes daily backups. Usage-based charges must be monitored before broader distribution. |
| Later distribution | Requires production OAuth branding/configuration and separate platform OAuth clients. `drive.appdata` is non-sensitive and narrower than general Drive access, but every Student must have a Google account and consent to Drive access. | Supports provider-neutral accounts and later Google sign-in. Flutter support covers Windows, iOS, and Android. Central schema migrations, support diagnostics, deletion/export, and account isolation are easier to operate consistently. |

## Google Drive details

### Authorization and onboarding

Installed applications are public clients and cannot keep a client secret. The application developer creates the OAuth client credentials; the Student uses the system browser to grant access, with PKCE recommended. Access and refresh tokens—not an API key copied by the Student—authorize the app ([Google OAuth for installed apps](https://developers.google.com/identity/protocols/oauth2/native-app)).

The narrow `drive.appdata` scope is classified as non-sensitive. It grants access only to a hidden, application-specific folder. A visible-folder design should use the narrow `drive.file` scope, which permits the app to create files and modify files opened or shared with it, rather than requesting broad Drive access ([Drive scopes](https://developers.google.com/workspace/drive/api/guides/api-specific-auth)). Production still requires correctly configured OAuth branding, owned domains where applicable, and adherence to Google's user-data policies; sensitive or restricted scopes would add verification obligations ([OAuth production readiness](https://developers.google.com/identity/protocols/oauth2/production-readiness/policy-compliance)).

The hidden folder is convenient but unsuitable as the only recovery mechanism: users cannot access it in the Drive UI, cannot share its contents, and deleting the application's connection/data removes it ([Drive application data folder](https://developers.google.com/workspace/drive/api/guides/appdata)). A visible folder improves transparency and manual portability, but user interference becomes part of the synchronization threat model.

### Conflict and recovery consequences

Drive exposes a monotonically increasing `version` for a file, which can reveal that the server copy changed ([Drive file resource](https://developers.google.com/workspace/drive/api/reference/rest/v3/files)). That is useful for conflict detection, but it does not define how two devices' Clinical Session edits should merge. A single serialized database file is especially unsafe: upload order can determine which snapshot survives. Splitting data into one file per entity reduces, but does not remove, conflicts involving deletions, relationships, Schedule Conflicts, and Protected Days.

Drive revision history is a recovery aid, not a backup guarantee. Unpinned blob revisions are normally retained for 30 days but can be purged earlier after 100 revisions; only 200 revisions per file can be marked `keepForever` ([Drive revision management](https://developers.google.com/workspace/drive/api/guides/manage-revisions)).

Drive API calls are currently free within published quotas, although Google says over-threshold charges are planned later in 2026 ([Drive API limits and pricing](https://developers.google.com/workspace/drive/api/guides/limits)).

## Managed-backend details

Supabase is the concrete reference because its Flutter client supports Windows, iOS, and Android, while the database remains accessible through standard APIs if the application stack changes ([Supabase Flutter quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)). Its publishable key is intentionally safe to include in mobile and desktop packages; authentication plus database authorization protects private records. Secret/service-role keys must never ship in the application ([Supabase API keys](https://supabase.com/docs/guides/getting-started/api-keys)).

For later distribution, Supabase Auth can provide Sign in with Google using only identity scopes (`openid`, email, and profile); the app does not need permission to read or write the Student's Drive ([Supabase Google login](https://supabase.com/docs/guides/auth/social-login/auth-google)). Email-based sign-in can also avoid making Google accounts mandatory.

Row Level Security must be enabled on every exposed table, with authenticated policies keyed to the owning Student. Supabase explicitly requires RLS for exposed schemas and documents `auth.uid()` ownership policies ([Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)).

At current published pricing, Free includes 500 MB database storage and 50,000 monthly active users but pauses after one inactive week and omits automatic backups. Pro starts at US$25/month, does not pause, and includes daily backups retained for seven days ([Supabase pricing](https://supabase.com/pricing), [Supabase backups](https://supabase.com/docs/guides/platform/backups)). Prices and quotas are operational assumptions to re-check before release, not permanent product guarantees.

## Required synchronization contract

The implementation ticket should preserve these requirements regardless of the eventual UI stack:

1. Each device owns a complete SQLite working database and remains fully usable without a network connection.
2. Every mutable entity has a UUID, `student_id`, integer `revision`, `updated_at`, and deletion tombstone. Deletes are synchronized, not immediately erased.
3. Every local mutation also writes a durable outbox operation in the same local transaction. Each operation has a unique idempotency key and the entity's base revision.
4. A server database function applies one operation atomically. It rejects a stale base revision rather than silently applying last-write-wins.
5. Server-side validation is authoritative for Schedule Conflicts, Protected Days, ownership, and relationship invariants. Local validation provides immediate feedback but is not the final guard against concurrent devices.
6. An accepted operation receives a monotonically ordered server cursor/revision. Devices pull all changes after their last cursor and apply them idempotently.
7. A rejected stale operation remains visible as a sync conflict. The Student chooses which version to keep or edits a new valid value; the app never silently discards a commitment.
8. Sync status must distinguish `up to date`, `offline with pending changes`, `syncing`, and `needs attention`.
9. Realtime notifications, if used, are only a prompt to pull; correctness depends on the durable change cursor, not notification delivery.
10. Provide a versioned, human-portable export and restore path independent of the managed service. Google Drive can be one destination for that export after explicit authorization.

## Recommendation boundary

Choose the managed backend now because correctness under concurrent offline edits is a core MVP property. Do not make public distribution part of the MVP, but avoid personal hard-coding: use one Student identity, ownership columns, RLS, migration-versioned schemas, and export/delete primitives from the start.

The next data-ownership/recovery decision should define export format, retention, restore validation, account-loss behavior, and whether automatic encrypted Google Drive exports are worth adding.
