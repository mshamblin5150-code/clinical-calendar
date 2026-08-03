# Carry Theme Colors into Agenda

Type: task
Status: resolved
Blocked by: none

## What's wrong

Work Shifts and Protected Days have distinct Borg treatments in Month and Week views, but Agenda renders every row with the same neutral surface.

## What I expected

Agenda rows preserve the same semantic treatments: Work Shifts use gunmetal/teal and Protected Days use graphite/silver. Visible labels remain present so color is not the only identifier.

## Answer

Agenda rows now retain the event type. Work Shifts render with a teal machinery rail and gunmetal wash; Protected Days render with a silver rail and striped graphite surface. Rendered QA confirmed both computed treatments, visible Work Shift/Protected Day labels, and zero horizontal overflow.
