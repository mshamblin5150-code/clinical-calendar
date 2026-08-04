# Implement Trash, Recovery, and Account Erasure

Type: task
Status: claimed
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
