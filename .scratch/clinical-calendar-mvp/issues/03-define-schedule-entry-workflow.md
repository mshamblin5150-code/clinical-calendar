# Define the Schedule Entry and Editing Workflow

Type: grilling
Status: resolved
Blocked by: none

## Question

How should the Student quickly enter, duplicate, bulk-place, edit, move, cancel, and miss variable Work Shifts and Clinical Sessions while military time, Schedule Conflicts, and the weekly Protected Day remain hard constraints?

## Comments

## Answer

The MVP uses explicit, non-recurring schedule entry optimized for variable monthly schedules:

- A creation flow first selects Work Shift or Clinical Session, then one or several nonconsecutive dates, one military-time interval, and—when clinical—the Clinical Placement and Preceptor.
- A single submission may create identical commitments on multiple dates. A review screen validates every date against Schedule Conflicts and Protected Days; the batch is all-or-nothing and remains unsaved until every conflict is fixed or removed.
- Date-free Schedule Templates store a name, commitment type, time interval, and, for Clinical Sessions, the Clinical Placement and Preceptor. Applying a template still requires selecting the current dates. Editing a template never changes commitments already created from it.
- Existing commitments use deliberate form-based editing with full revalidation. Drag-and-drop rescheduling is deferred until a later enhancement.
- Cancelled and Missed commitments remain in history and contribute no hours. Delete permanently removes only erroneous or duplicate entries and requires confirmation.
- Monthly planning occurs in this order: enter Work Shifts, enter available Clinical Sessions, then choose one empty Protected Day for each week. A week may temporarily lack a Protected Day while planning, but the month remains Planning Incomplete until every intersecting week has one.
- Selecting or moving a Protected Day is blocked while any commitment touches that date; the Student must first move, cancel, or delete those commitments.
- Overnight commitments are supported. The entry form clearly indicates an end on the following day; conflict and Protected Day validation covers the entire interval across both dates.
- The first day of the week is configurable and defaults to Sunday. Week boundaries control the calendar layout, Protected Day requirement, planning completeness, and weekly summaries. Changing the setting previews any invalidated weeks and requires correction before acceptance.
- Weeks remain continuous across month boundaries. A spanning seven-day week has exactly one Protected Day, which may fall in either month and appears in both month views.
