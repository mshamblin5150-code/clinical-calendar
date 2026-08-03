# Implement the Scheduling Invariant Engine

Type: task
Status: open
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

