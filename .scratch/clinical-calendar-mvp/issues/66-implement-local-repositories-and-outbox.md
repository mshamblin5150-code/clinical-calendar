# Implement Local Repositories and the Transactional Outbox

Type: task
Status: resolved
Blocked by: 62, 63, 64, 65

## Objective

Expose domain-oriented repositories over SQLite and guarantee that every synchronizable local mutation produces one durable outbox operation.

## Acceptance criteria

- Repository interfaces return domain records rather than database rows and support transactional application use cases.
- Every successful synchronizable mutation and its unique idempotent outbox operation commit in the same SQLite transaction.
- A failed mutation writes neither domain state nor an outbox operation.
- Reads and writes complete offline and never wait for the synchronization adapter.
- Tombstoned records remain available to synchronization, Trash, history, and restore workflows according to retention rules.
- Restarting during queued operations neither loses nor duplicates outbox intent.
- Integration tests cover transaction rollback, concurrent local access, idempotency keys, cursor persistence, and migration compatibility.

## Answer

Implemented application-owned repository contracts and a SQLCipher-backed `SqliteRepositoryRegistry` for Work Shifts, Clinical Sessions, Protected Days, Schedule Templates, Preceptors, Clinical Placements, Historical Hours Entries, and Evaluation Plans. The registry serializes callers through an asynchronous FIFO gate while keeping transaction callbacks synchronous, expires repository handles after each callback, returns domain records with synchronization metadata, and enforces owner identity, UUIDs, optimistic revisions, and corruption checks.

Every successful domain mutation and its canonical aggregate outbox operation commit in one `BEGIN IMMEDIATE` transaction. Durable mutation tokens make exact retries no-ops across restarts and reject mismatched reuse. Tombstones remain explicitly readable, create a 30-day Trash snapshot, and can be restored without losing history. Outbox retry/acknowledgement state and monotonic synchronization cursors are persisted locally without network dependencies. Schema migration 4 stores whether each Evaluation Plan requirement is currently required so documented historical requirements round-trip without abusing deletion tombstones.

Eleven real-SQLCipher repository integration tests cover all eight domain types, atomic multi-write commits, foreign-key and revision rollback, restart-safe idempotency, concurrent FIFO calls, callback expiry, Trash restore, outbox maintenance, cursor persistence, and repository use after a real v2 migration. The full workspace quality gate and Windows and Android release builds pass. iPhone compilation remains deferred to ticket 87 and the approved Mac hardware gate.
