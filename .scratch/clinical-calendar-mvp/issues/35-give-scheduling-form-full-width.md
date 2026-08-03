# Give Scheduling Form Full Width

Type: task
Status: resolved
Blocked by: none

## What's wrong

The expanded scheduling tray squeezes its form into a narrow column, clips text and controls, shrinks Back/Next, and duplicates expand behavior with both a chevron and an Expand button.

## What I expected

The form uses the full tray width; Commitment and Template occupy a complete first row; Start, End, and calculated duration occupy the next row; Back/Next retain normal button sizes; and one chevron controls expand/collapse.

## Answer

The tray body now uses one full-width content column plus a full-width action footer. Commitment and Template share the first row; Start, End, and automatic duration share the second row and stack on narrow phones. QA measured equal client/scroll widths throughout the tray, 112px desktop Back/Next buttons, and exactly one expand/collapse chevron with no duplicate Expand button.
