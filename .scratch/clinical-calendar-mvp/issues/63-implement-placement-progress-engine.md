# Implement the Clinical Placement Progress Engine

Type: task
Status: resolved
Blocked by: 60, 61

## Objective

Implement the single derived ledger and progress formulas from [`spec.md`](../spec.md#52-progress-calculations).

## Acceptance criteria

- Completed, Scheduled, Awaiting Confirmation, Remaining, Unscheduled, and Over-Target Hours match the specification formulas using exact minutes.
- Historical Hours Entries contribute to Completed Hours without entering the calendar ledger.
- Per-Preceptor totals reconcile with the Clinical Placement total plus a distinct Unattributed bucket.
- Projected Completion Date is produced when Completed plus Scheduled Hours reach target; otherwise required weekly pace is produced.
- Aggregate Total Progress uses all Clinical Placements and supplies the same eight-segment percentage model to every presentation.
- Over-target activity never makes Remaining or Unscheduled Hours negative.
- Table-driven tests cover zero target defenses, corrections, cancellations, missed sessions, historical hours, over-target hours, and multiple Preceptors.

## Answer

Implemented the single `ClinicalPlacementProgressEngine` in the dependency-free
domain package:

- Every ledger is recomputed from source Clinical Sessions and Historical Hours
  Entries using exact minutes. Confirmed actual minutes drive Completed Hours;
  planned minutes drive Scheduled and Awaiting Confirmation Hours; Cancelled and
  Missed Sessions contribute nothing.
- Remaining and Unscheduled Minutes floor at zero, while Over-Target Minutes
  remain explicit.
- Historical Hours contribute to Completed Hours without becoming calendar
  activity. Attached entries reconcile into their Preceptor bucket and entries
  without a Preceptor reconcile into a distinct Unattributed bucket.
- Projection sorts completed and scheduled contributions chronologically and
  returns the date on which the target is crossed. When Completed plus Scheduled
  Hours do not reach the target, the ledger returns the exact Unscheduled Minutes
  and inclusive remaining days needed for the additional average weekly pace.
- Aggregate Total Progress combines every Clinical Placement, caps the displayed
  Completed percentage at 100, and provides the same proportional eight-segment
  fill model used by accepted Variant F.
- Duplicate record identities are rejected rather than double-counted, and
  positive `TargetHours` remains the denominator authority.

Table-driven tests cover corrected actual times, Scheduled/Awaiting separation,
Cancelled and Missed Sessions, Historical Hours, multiple Preceptors,
Unattributed reconciliation, duplicates, target-crossing projections, weekly
pace, over-target floors, multiple Clinical Placements, and the eight-segment
model. The integrated repository gate passes with 57 domain tests.
