# Recalculate Placement and Overall Progress From Shared State

Type: task
Status: resolved
Blocked by: none

## Parent issue

Reported during QA of ticket 07.

## What's wrong

Adding Clinical Sessions to a non-Family Medicine Clinical Placement does not reliably update that placement, Total Progress, or the circular progress breakdown.

## What I expected

Every Clinical Session updates its selected Clinical Placement's Scheduled Hours and Preceptor breakdown. Placement totals, Total Progress, Remaining Hours, Unscheduled Hours, Over-Target Hours, and the circular breakdown all derive from the same state and update immediately.

## Steps to reproduce

1. Select dates and create 36 Scheduled Hours for Internal Medicine.
2. Select Internal Medicine in My Placements.
3. Compare its Scheduled Hours, circular breakdown, and Total Progress.
4. Observe missing or inconsistent updates.

## Blocked by

None - can start immediately.

## Answer

A single commitment ledger now derives Clinical Placement, Preceptor, Total Progress, and circular breakdown values. Target Hours are the denominator; the circle shows Completed, Scheduled, and Unscheduled proportions.
