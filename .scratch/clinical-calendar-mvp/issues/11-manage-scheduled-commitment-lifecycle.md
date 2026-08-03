# Manage a Scheduled Commitment After Creation

Type: task
Status: resolved
Blocked by: none

## Parent issue

Reported during QA of ticket 07.

## What's wrong

Once a Work Shift or Clinical Session is added to the calendar, the Student cannot inspect, cancel, mark missed, or delete it.

## What I expected

Selecting a commitment opens deliberate lifecycle actions. Cancelled and Missed Clinical Sessions remain in history without contributing hours; delete is available for erroneous entries and immediately recalculates Scheduled Hours.

## Steps to reproduce

1. Apply a Work Shift or Clinical Session to an empty date.
2. Select the resulting calendar commitment.
3. Observe that no lifecycle actions are available.

## Blocked by

None - can start immediately.

## Answer

Selecting a commitment opens details. Clinical Sessions can be confirmed, cancelled, marked missed, or deleted as erroneous; Work Shifts can be deleted, with projections recalculated.
