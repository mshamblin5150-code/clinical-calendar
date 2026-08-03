# Implement the Clinical Placement Progress Engine

Type: task
Status: open
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

