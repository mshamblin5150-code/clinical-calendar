# Move Work Shifts and Clinical Sessions

Type: task
Status: resolved
Blocked by: none

## Problem

Protected Days can be moved, but Work Shifts and Clinical Sessions cannot. A scheduling correction currently requires deleting and recreating the entry, risking the loss of placement, preceptor, status, and recorded-hour context.

## Acceptance criteria

- Work Shift and Clinical Session detail panels allow changing the commitment date.
- Moving preserves the entry's time, hours, type, Placement, Preceptor, and history/status unless the date-driven clinical completion rule requires a status change.
- A move to an occupied or Protected date is rejected without changing the entry.
- A scheduled Clinical Session moved into the past becomes awaiting confirmation; a completed Clinical Session moved to today or the future becomes scheduled.
- Help explains how commitment movement works.
- Compact user-facing hour abbreviations use `hr`, not `h`.
- Desktop and phone layouts remain readable and usable.

## Resolution

Work Shift and Clinical Session editors now include a Commitment date control. Empty destinations move the existing entry and preserve its time, hours, Placement, Preceptor, and history; occupied or Protected destinations are rejected without changing it. Clinical Sessions moved into the past become awaiting confirmation, while completed sessions moved to today or the future return to Scheduled. Help documents the workflow, compact hour labels now use `hr`, and the 12-hour mobile controls reserve distinct space for time and AM/PM.
