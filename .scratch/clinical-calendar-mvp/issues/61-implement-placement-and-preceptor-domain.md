# Implement Clinical Placement and Preceptor Domain Types

Type: task
Status: open
Blocked by: 59

## Objective

Implement Clinical Placement, Preceptor, Historical Hours Entry, and lifecycle rules from [`spec.md`](../spec.md#5-clinical-placement-and-progress-experience).

## Acceptance criteria

- A Clinical Placement requires name, positive Target Hours, Start Date, Completion Deadline, one Primary Preceptor, and an Evaluation Plan reference.
- Exactly one attached Preceptor is Primary at all times, and changing Primary preserves record identities and history.
- Clinical Sessions cannot reference a detached Preceptor or fall outside the Clinical Placement window.
- Historical Hours Entries support an attached Preceptor or Unattributed ownership without becoming calendar commitments.
- Ready to Complete, Completed Placement, and Reopen Placement transitions enforce the settled lifecycle rules.
- Only an empty mistaken Clinical Placement is eligible for permanent deletion.
- Unit tests cover invalid date windows, Primary changes, referenced deletion, completion, and reopening.

