# Build Commitment and Protected Day Lifecycle Surfaces

Type: task
Status: open
Blocked by: 67, 70

## Objective

Implement detail, movement, correction, confirmation, cancellation, missed, removal, and guarded deletion surfaces.

## Acceptance criteria

- Work Shift and Clinical Session details show date, planned/actual times, status, and Clinical Placement/Preceptor where applicable.
- Date and time correction uses flexible time controls and displays automatically calculated duration.
- Invalid moves show a specific Schedule Conflict or Protected Day result and preserve the original record.
- Awaiting Confirmation Sessions support confirm with corrected actual times and Preceptor, Cancel, and Mark Missed.
- Completed Sessions moved to today/future and Scheduled Sessions moved into the past visibly adopt the required state.
- Protected Days support Move and Remove with immediate Planning Incomplete recalculation.
- Permanent delete actions identify erroneous-entry semantics, confirm the action, and never substitute for Cancelled or Missed history.

