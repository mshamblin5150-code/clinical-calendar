# Build Clinical Placement and Progress Surfaces

Type: task
Status: resolved
Blocked by: 68, 69

## Objective

Implement repository-backed Clinical Placement management, progress wheel, dock, Total Progress, and Preceptor breakdown.

## Acceptance criteria

- Clinical Placement management edits required fields, Target Hours, dates, attached Preceptors, and Primary designation with impact previews.
- The active Clinical Placement is synchronized across management, desktop dock, progress wheel, and scheduling defaults.
- The wheel cycles Clinical Placements and shows Target, Completed, Scheduled, Unscheduled, and Over-Target values from the shared engine.
- Per-Preceptor Completed and Scheduled Hours reconcile with the selected Clinical Placement and show Unattributed Historical Hours separately.
- Desktop and mobile render the same eight-segment Total Progress calculation.
- Projected Completion Date or required weekly pace is shown according to the progress engine result.
- Completed Placements visibly lock ordinary editing and expose guarded Reopen Placement.

## Answer

Implemented repository-backed Clinical Placement management, synchronized active-Placement selection, desktop/mobile progress surfaces, Total Progress, Preceptor and Unattributed breakdowns, completion projections, impact previews, and guarded completed-Placement behavior. The surfaces are integrated into the Variant F shell and pass the repository-wide quality gate.
