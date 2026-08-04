# Implement Trash, Recovery, and Account Erasure

Type: task
Status: resolved
Blocked by: 66, 78, 80

## Objective

Implement synchronized soft deletion, 30-day recovery, operational snapshot recovery, and guarded account deletion.

## Acceptance criteria

- Eligible deletions create synchronized tombstones and Trash entries with a 30-day expiry.
- Restore works from any connected device and revalidates all domain invariants before reinstating a record.
- Permanent deletion requires confirmation; clearing all Trash requires reauthentication.
- Daily snapshots retain 30 days and restore through a preview copy before confirmed merge into live data.
- Delete Account and All Data is distinct from sign-out, requires reauthentication, offers backup first, and supports cancellation during a 30-day grace period.
- Grace-period expiry removes active data, Trash, device registrations, and authentication records; residual encrypted snapshots expire within 30 additional days.
- Automated time-controlled tests cover restoration, expiry, cancellation, purge retries, and invariant-prohibited deletion.

## Answer

Implemented synchronized 30-day Trash, invariant-safe cross-device restore, confirmed content-free permanent purge, and daily 30-day operational recovery snapshots with preview-before-merge. Permanent purge is atomic with the local outbox, converges through an ordered server `purge` event, retains only a minimal anti-resurrection marker, and rejects stale, reordered, future-revision, and cross-owner attempts to recreate deleted content. Clear Trash requires a genuinely fresh emailed OTP and consumes a one-shot proof; cancellation or failed verification leaves Trash unchanged. Variant F exposes a responsive Trash & Recovery destination, and production creates idempotent daily snapshots on launch or resume.

Delete Account and All Data is distinct from device-local sign-out. The guarded flow offers a real encrypted portable backup through the native save surface, requires a newly issued passwordless session, revokes every Connected Device, and begins an exact 30-day grace period that can be cancelled only with fresh verification. The private scheduler purge removes synchronized records, Trash, devices, sync state, and Auth atomically and retry-safely; residual AES-256-GCM recovery snapshots are private, force-RLS protected, and expire within 30 additional days.

The shared Dart/Flutter quality gate passes, including 57 local-data, 89 presentation, and 9 app tests. Docker verification passes 28 synchronization, 25 identity, 36 account-erasure, and 24 permanent-purge pgTAP assertions, schema lint, static privacy contracts, purge-versus-stale-upsert concurrency, and idempotent account-purge concurrency. Windows and Android debug builds pass; iOS runtime verification remains deferred to tickets 87 and 88 and the approved Mac hardware gate.
