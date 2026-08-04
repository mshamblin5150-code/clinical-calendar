# Build the Supabase Synchronization Backend

Type: task
Status: resolved
Blocked by: 62, 65, 66

## Objective

Implement the Postgres schema, ownership policies, ordered change feed, and atomic operation endpoint required by [`spec.md`](../spec.md#83-synchronization-contract).

## Acceptance criteria

- Server records use UUID, `student_id`, revision, timestamps, and tombstones compatible with the local schema.
- Row Level Security prevents every authenticated Student from reading or mutating another Student's records.
- One database function accepts an idempotency key and base revision, applies a valid operation atomically, and returns an ordered server cursor.
- Duplicate idempotency keys return the original result without applying the mutation twice.
- Stale revisions, Schedule Conflicts, Protected Day violations, ownership violations, and relationship violations return structured rejections.
- Pull-after-cursor returns a complete ordered sequence including tombstones and supports safe retry.
- Database tests cover concurrent operations, RLS isolation, rollback, idempotency, and invariant parity with the Dart domain suite.

## Answer

Implemented the private Supabase/Postgres synchronization schema, forced RLS, least-privilege RPC executor, atomic idempotent mutation endpoint, structured invariant rejections, ordered cursor feed, and tombstone pulls. Docker-backed verification passes a clean migration/reset, 27 pgTAP assertions, schema lint, static contract checks, and a real two-session race with exactly one accepted update and one stale-revision rejection.
