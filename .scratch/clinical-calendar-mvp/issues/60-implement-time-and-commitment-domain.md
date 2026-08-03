# Implement Time and Commitment Domain Types

Type: task
Status: open
Blocked by: 59

## Objective

Implement the platform-independent time and commitment model defined by [`spec.md`](../spec.md#3-canonical-model-and-invariants).

## Acceptance criteria

- Work Shift, Clinical Session, Protected Day, Schedule Template, local date, local time, time zone, and overnight interval types have explicit validated constructors.
- Military `HHMM` and `HH:MM` input normalizes to stored 24-hour values; 12-hour formatting changes display only.
- Exact elapsed minutes are derived without automatic rounding or break deduction.
- Overnight intervals retain the creating time zone and cover both affected calendar dates.
- Clinical Session lifecycle states include Scheduled, Awaiting Confirmation, Completed, Cancelled, and Missed with only valid transitions allowed.
- Unit tests cover daylight-saving boundaries, midnight crossing, invalid input, date-driven status, and exact-minute duration.

