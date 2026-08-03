# Implement Local Repositories and the Transactional Outbox

Type: task
Status: open
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
