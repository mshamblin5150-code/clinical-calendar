# Implement the Synchronization Client and Health State

Type: task
Status: open
Blocked by: 66, 77

## Objective

Implement durable push/pull synchronization over the local outbox and server cursor without blocking local use.

## Acceptance criteria

- Synchronization runs after local saves, reconnection, app launch/resume, and explicit Sync Now.
- Pending operations push in a retry-safe order and accepted changes pull and apply idempotently after the stored cursor.
- Realtime notifications, if enabled, only request a pull and are not required for correctness.
- Process termination at every push/pull boundary neither loses a local save nor applies a remote change twice.
- Health state reports Synced, Offline with locally saved changes, Syncing, Conflict Needs Attention, and Sync Failed with pending count and last success.
- Brief failures retry without false data-loss claims; one-hour and 24-hour failure states feed the reminder policy.
- Integration tests cover two devices, intermittent connectivity, retry, reordering, duplicate delivery, and cursor recovery.

