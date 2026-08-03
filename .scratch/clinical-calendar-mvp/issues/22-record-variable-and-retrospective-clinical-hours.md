# Record Variable and Retrospective Clinical Hours

Type: task
Status: resolved
Blocked by: none

## Parent issue

Reported during QA of ticket 07.

## What's wrong

Every new commitment is forced to 12 hours and a retrospectively added Clinical Session cannot be recorded directly as Completed.

## What I expected

The scheduling workflow accepts exact start, end, and counted hours, permits Scheduled or Completed status, and the commitment details allow correction after creation.

## Steps to reproduce

1. Select an empty date and add a Clinical Session.
2. Try to enter a duration other than 12 hours or mark it Completed.
3. Observe that neither is possible.

## Blocked by

None - can start immediately.

## Answer

New commitments accept exact military start/end, quarter-hour counted duration, and Scheduled or Completed status. Existing sessions accept corrected actual hours and status; Completed Hours can exceed both planned duration and Target Hours, and excess is retained as Over-Target Hours. Completed sessions remain visible and editable on the calendar.
