# Implement Scheduling Application Use Cases

Type: task
Status: open
Blocked by: 66

## Objective

Implement transactional application services for scheduling, editing, moving, confirming, cancelling, missing, deleting, and protecting days.

## Acceptance criteria

- Batch creation accepts nonconsecutive dates and commits all valid Work Shifts, Clinical Sessions, or Protected Days in one transaction.
- Invalid dates return structured conflict details and leave all persisted state unchanged.
- Applying a Schedule Template copies current values and does not link saved commitments to later template edits.
- Moving a commitment preserves attached data, rejects invalid destinations, and applies date-driven Clinical Session state changes.
- Confirmation accepts corrected actual times and Preceptor and records exact Completed Hours.
- Cancel, Missed, erroneous-delete, Protected Day move, and Protected Day removal follow the history and eligibility rules.
- Application tests exercise every scenario in [`spec.md`](../spec.md#121-scheduling) without Flutter widgets.

