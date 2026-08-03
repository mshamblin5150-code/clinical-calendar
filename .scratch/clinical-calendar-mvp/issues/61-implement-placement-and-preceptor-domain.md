# Implement Clinical Placement and Preceptor Domain Types

Type: task
Status: resolved
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

## Answer

Implemented the Clinical Placement aggregate and its related value types in
`packages/clinical_calendar_domain`:

- `Preceptor` is a reusable validated identity with required name and optional
  organization/site, phone, email, and operational scheduling notes.
- `TargetHours` stores a strictly positive target as exact minutes.
- `HistoricalHoursEntry` stores positive aggregate Completed Hours, effective
  date, optional note, and either an attached Preceptor identity or explicit
  Unattributed ownership. It has no calendar interval and cannot become a
  commitment accidentally.
- `ClinicalPlacement` requires a valid inclusive date window, Target Hours,
  Evaluation Plan identity, attached Preceptors, and exactly one attached
  Primary Preceptor. Changing Primary preserves all identities and attachments.
- Placement validation rejects Clinical Sessions assigned to another placement,
  a detached Preceptor, or dates outside the placement window, including an
  overnight end date. Historical Hours attribution receives the same attachment
  validation.
- A Primary or referenced Preceptor cannot be detached. A proposed window that
  strands an existing Clinical Session is rejected.
- `PlacementCompletionEvidence` keeps later progress and Evaluation Plan engines
  behind a narrow interface while enforcing all four Ready-to-Complete rules.
  Completion is explicit, Completed Placements reject ordinary edits, and Reopen
  Placement restores active tracking without changing attached identities or
  history references.
- Permanent deletion is permitted only for an active placement with no Clinical
  Sessions, Historical Hours Entries, or evaluation records.

The domain package now has 30 passing tests, including invalid windows and
targets, Primary changes, detached and referenced Preceptors, overnight window
boundaries, attributed and Unattributed Historical Hours, readiness conditions,
completion locking, reopening, and empty-only deletion. The repository-wide
format, fatal-info analysis, architecture, and test gate also passes.
