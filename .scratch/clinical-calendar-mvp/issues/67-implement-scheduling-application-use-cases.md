# Implement Scheduling Application Use Cases

Type: task
Status: resolved
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

## Answer

Implemented a transactional `SchedulingApplicationService` for all-or-nothing nonconsecutive Work Shift, Clinical Session, and Protected Day batches; structured multi-conflict reporting; copied Schedule Template application; guarded commitment moves; corrected Clinical Session confirmation with exact elapsed Completed Hours; cancellation, Missed, erroneous-delete, and Protected Day lifecycle operations; missing-week queries; and placement progress reads.

Every mutation runs through the repository unit of work with optimistic revisions, UUID mutation tokens, and one shared clock instant. Twelve application-level scenario tests cover batch rollback, overnight coverage, collisions, template independence, date-driven state changes, correction rollback, lifecycle eligibility, and Protected Day rules without Flutter widgets. The full workspace quality gate and Windows and Android release builds pass.
