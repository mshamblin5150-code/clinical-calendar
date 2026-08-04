# Clinical Calendar synchronization backend

This directory is the complete Supabase/Postgres boundary for the MVP. It has
no service-role credential, production identity, or Student-owned seed data.

Passwordless sign-in uses the public Auth API and the committed local email
template renders `{{ .Token }}` as a code rather than a magic link. Hosted
projects must copy the same template through the Supabase Email Templates
settings. Auth access and refresh tokens belong only in the platform credential
store; they must never be written to SQLite, logs, configuration, or source.

## Contract

`public.apply_sync_operation` accepts the SQLite outbox envelope unchanged:

- `p_idempotency_key`, `p_entity_type`, `p_entity_id`, `p_operation_type`,
  `p_base_revision`, and the versioned JSON payload;
- the authenticated Student is always the JWT `sub` claim and must match the payload;
- accepted results contain `accepted`, `cursor`, `entity_type`, `entity_id`,
  and `revision`;
- rejected results contain `accepted: false` and a stable `rejection.code`.

Stable rejection codes are `unauthenticated`, `invalid_request`,
`invalid_payload`, `idempotency_conflict`, `ownership_violation`,
`stale_revision`, `not_found`, `relationship_violation`, `schedule_conflict`,
and `protected_day_violation`. Relationship rejections add a `relationship`;
Protected Day rejections may add a `reason`.

An identical idempotency key and request returns the stored original result.
The RPC serializes operations per Student using one transaction-scoped advisory
lock, then locks receipt, record, and feed head in that order. The feed cursor
is incremented transactionally per Student, so a returned cursor cannot commit
before a lower cursor. Rejected operations retain an idempotency receipt but do
not mutate a record or consume a cursor.

`public.pull_changes_after(after_cursor, limit)` returns all accepted changes,
including tombstones, ordered by cursor. It uses `cursor > after_cursor` keyset
pagination and caps a page at 500 rows. Realtime may wake a client, but this
durable feed remains the correctness mechanism.

The write RPC is necessarily `SECURITY DEFINER`: granting its table writes to
`authenticated` would allow clients to bypass revision and invariant checks.
Its owner is a non-login, non-bypass-RLS executor with only the four required
tables. All tables force RLS and cache the JWT `sub` request setting through a
scalar subquery. The read-only pull RPC is `SECURITY INVOKER`.

Connected Devices binds each installation identifier to the authenticated
JWT's `session_id`. The public sync RPC wrappers require an active binding, so
revocation blocks subsequent app-data access even while an already-issued JWT
has time remaining. It cannot erase a device's offline encrypted database.

## Local verification

With Docker running, use the Supabase CLI from the repository root:

```powershell
supabase db start --yes
supabase db reset --local --yes
supabase test db .\supabase\tests\sync_backend_test.sql --local
supabase db lint --local --schema public,clinical_calendar_sync --level error --fail-on error
```

The pgTAP suite covers atomic rejection, idempotency, stale revisions,
relationship parity, Schedule Conflicts, Protected Day violations, RLS
isolation and privileges, tombstones, and pull cursor retry. The concurrency
SQL files are a two-session test: run `concurrency_setup.sql`,
launch sessions A and B concurrently with `psql`, run the verifier, then run
the cleanup. Exactly one update is accepted and the other receives
`stale_revision`.

`identity_devices_test.sql` covers Connected Device registration and
same-Student reauthentication, cross-Student isolation, least privilege,
idempotent revocation, and the rule that a revoked JWT cannot push, pull, or
reactivate itself. The `identity_revoke_concurrency_*.sql` scripts are a second
two-session test: run setup, start session A, start session B shortly afterward,
then run verify and cleanup. Session A deliberately holds the shared
per-Student transaction lock while revoking; verification asserts that the
waiting synchronization write is rejected and the original revision remains.

Expired-code and refresh-token response mapping is covered by the Flutter
platform contract tests. The local Supabase stack provides Inbucket and the
same committed OTP template for manual end-to-end GoTrue verification; hosted
email delivery and provider configuration remain deployment checks rather than
database tests.

These checks run locally through Docker Desktop and the Supabase containers;
no live project or production credentials are required.

## Deployment notes

- Run migrations through the normal Supabase migration pipeline; never expose
  a service-role key to the Flutter application.
- Keep operation transactions free of network calls. The RPC statement and
  lock timeouts intentionally fail fast.
- If an entity payload schema changes, add a new forward migration and payload
  `schema_version`; do not reinterpret existing change-feed snapshots.
- Retain feed rows and tombstones until every supported device/recovery policy
  can safely advance beyond them. Purging is a later retention workflow, not a
  synchronization side effect.
