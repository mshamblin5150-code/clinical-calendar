# Remove or Move a Protected Day

Type: task
Status: resolved
Blocked by: none

## Parent issue

Reported during QA of ticket 07.

## What's wrong

The Student can add a Protected Day but cannot remove or move it afterward.

## What I expected

The Student can remove an existing Protected Day or move it to another empty date in the same week. A date containing a commitment remains ineligible.

## Steps to reproduce

1. Mark an empty calendar date as a Protected Day.
2. Select the Protected Day again.
3. Observe that no remove or move action is available.

## Blocked by

None - can start immediately.

## Answer

Selecting a Protected Day now opens Move and Remove actions. Moving rejects dates containing an active commitment; removal immediately recalculates planning status.
