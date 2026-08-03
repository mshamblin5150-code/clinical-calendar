# Implement the Evaluation Plan Engine

Type: task
Status: open
Blocked by: 61, 63

## Objective

Implement configurable Evaluation Plans and generated requirement state from [`spec.md`](../spec.md#53-evaluation-plan).

## Acceptance criteria

- Each Clinical Placement independently configures Initial Self-Assessment, Interim Review cadence, Final Self-Assessment, and Final Placement Review.
- Each Interim Review threshold generates two separately documentable requirements using combined Completed Hours.
- Not Due, Approaching, Due, and Documented derive deterministically from hours, dates, future Sessions, and documentation.
- Editing a plan preserves documented requirements and regenerates only undocumented requirements after an impact description is produced.
- Newly added thresholds already passed become Due; corrected hours never undo documented requirements.
- Future undocumented Interim Reviews follow a changed Primary Preceptor without rewriting documented history.
- Unit tests cover requirement toggles, cadence changes, early documentation, overdue placement, and Ready-to-Complete gating.

