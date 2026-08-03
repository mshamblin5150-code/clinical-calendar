# Build the Staged Batch Scheduling Flow

Type: task
Status: open
Blocked by: 67, 70

## Objective

Implement the responsive staged creation tray and all-or-nothing review workflow from [`spec.md`](../spec.md#42-batch-creation).

## Acceptance criteria

- The tray supports type and time, Clinical Placement and Preceptor, and review stages with working Back and Next navigation.
- Ordinary Add Schedule resets to Clinical Session; Planning Incomplete resets to Protected Day; existing selected dates remain available.
- Template choice fills times, flexible military/12-hour entry works, and calculated duration is read-only and accurate.
- The active Clinical Placement and Primary Preceptor default correctly while per-batch overrides persist through the staged flow.
- Review lists every selected date and conflict and cannot apply until all conflicts are corrected or removed.
- Apply invokes one application transaction and shows the persisted result; failure retains the unsaved batch.
- The mobile tray stays in document flow, provides 44 px touch targets, and does not overlap the progress wheel or bottom navigation.

