# Implement the Scheduling Invariant Engine

Type: task
Status: resolved
Blocked by: 60, 61

## Objective

Create one deterministic domain service for Schedule Conflicts, Protected Days, calendar weeks, and batch validity.

## Acceptance criteria

- Active Work Shifts and Clinical Sessions that overlap are rejected; Cancelled and Missed Sessions do not block time.
- Any commitment touching any portion of a Protected Day is rejected, including overnight intervals.
- Configurable week starts produce continuous seven-day weeks across month boundaries.
- At most one Protected Day is allowed per week, and monthly planning completeness reports every intersecting week lacking one.
- Batch validation reports every invalid date without mutating state and permits a commit only when the complete batch is valid.
- The engine has no Flutter, SQLite, or server dependency.
- Property and example tests cover boundaries, adjacency, overnight intervals, cross-month weeks, and all-or-nothing batches.

## Answer

Implemented one dependency-free `SchedulingInvariantEngine` and its immutable
input/result types in `packages/clinical_calendar_domain`:

- Active Work Shifts plus Scheduled, Awaiting Confirmation, and Completed
  Clinical Sessions block overlapping time. Cancelled and Missed Sessions do
  not. Intervals are half-open, so exact adjacency remains valid.
- Completed Sessions use their confirmed actual interval. UTC instants decide
  overlap, while each error reports the conflict date in the proposed
  commitment's retained local time zone.
- A commitment touching any part of a Protected Day is rejected, including an
  overnight interval entering that date. Ending exactly at its midnight is
  valid adjacency.
- `CalendarWeekConfiguration` partitions dates into continuous seven-day weeks
  for any configured start weekday. Cross-month weeks keep one stable identity.
- Proposed Protected Days cannot share a week, and monthly completeness returns
  every intersecting week without a Protected Day, including weeks whose start
  lies in an adjacent month.
- Batch validation collects all invalid proposed dates without changing either
  input. It returns a new immutable schedule snapshot only when the entire batch
  is valid.

Deterministic property-style and example tests cover all weekdays, continuous
partitions, overlap symmetry, adjacency, active/inactive states, overnight and
midnight Protected Day boundaries, cross-zone conflict dates, cross-month
planning completeness, multiple Protected Days, and all-errors/all-or-nothing
batches. The integrated repository gate passes with 57 domain tests.
