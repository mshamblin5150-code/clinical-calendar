# Synchronize Placement Menu and Progress Wheel

Type: task
Status: resolved
Blocked by: none

## What's wrong

Clinical Placement management maintains a private selected Placement, so it always opens on the first Placement and does not update the active circular progress wheel.

## What I expected

Opening Clinical Placement management defaults to the Placement already active on the wheel. Selecting or adding a Placement in management makes that Placement the active wheel and the default Placement for scheduling.

## Answer

Clinical Placement management now opens on the Placement currently active on the circular wheel. Selecting or adding a Placement there updates the wheel and scheduling default immediately. This is a synchronized default, not a lock: the wheel still cycles normally and the scheduling form can still override the Placement. The interaction was verified live by selecting Internal Medicine, reopening management on Internal Medicine, and then cycling the wheel to Pediatrics.
