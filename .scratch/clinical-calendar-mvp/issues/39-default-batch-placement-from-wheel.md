# Default Batch Placement from Wheel

Type: task
Status: resolved
Blocked by: none

## What's wrong

Changing the Clinical Placement displayed by the progress wheel does not update the scheduling tray's default Placement.

## What I expected

When the wheel or Placement dock changes the selected Clinical Placement, the scheduling tray defaults to that same Placement and its Primary Preceptor. The Student may then override either dropdown for the current batch.

## Answer

The scheduling tray now synchronizes its Clinical Session default when the wheel or Placement dock changes. Rendered desktop and phone QA verified Family Medicine -> Internal Medicine also selected `Internal Medicine` and `Dr. Patel - Primary`; a manual override to Billing & Coding persisted while navigating the tray. Work Shifts expose no Placement, and switching back to Clinical Session restores the wheel-selected default.
