# Build Month, Week, and Agenda Calendar Views

Type: task
Status: open
Blocked by: 67, 69

## Objective

Render and navigate Month, Week, and Agenda from the same repository-backed commitment state.

## Acceptance criteria

- Previous and next navigation changes the correct period for Month, Week, and Agenda.
- Week-start preference changes layout and Protected Day week boundaries without altering stored dates.
- Work Shifts, Clinical Sessions, Protected Days, Today, selection, and status remain distinguishable and labeled in every applicable view.
- Work Shift gunmetal/green-steel and Protected Day graphite/silver treatments carry into Agenda.
- Clicking a selected date deselects it before opening any underlying item; an unselected occupied date opens its detail workflow.
- Calendar cells expose complete semantic labels including Today, commitment type, assignment, and selection action.
- Widget tests cover cross-month weeks, overnight commitments, dense days, and the responsive viewport matrix.

