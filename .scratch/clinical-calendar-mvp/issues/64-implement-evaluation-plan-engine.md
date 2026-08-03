# Implement the Evaluation Plan Engine

Type: task
Status: resolved
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

## Answer

Implemented the dependency-free Evaluation Plan model and engine in
`packages/clinical_calendar_domain`:

- Each plan independently configures required Initial Self-Assessment, positive
  Interim Review cadence (default 90 hours), required Final Self-Assessment, and
  required Final Placement Review.
- Stable semantic requirement identities use the Evaluation Plan, requirement
  kind, and exact Interim threshold. Primary Preceptor identity is historical
  detail rather than part of the requirement identity.
- Interim thresholds are positive cadence multiples strictly below Target Hours.
  Each generates two independently documentable requirements: the Student's
  review of the Primary Preceptor and the Primary Preceptor's review of the
  Student.
- Evaluation context derives Not Due, Approaching, Due, or Documented from exact
  Completed Minutes, placement dates, Target Hours, and ordered future Scheduled
  Session minutes. Initial, Interim, and final boundaries follow the accepted
  seven-day, ten-hour, next-session-crossing, target, and no-future-session rules.
  A missed Completion Deadline without Target Hours does not falsely make final
  requirements Due.
- Documentation validates its date, location (default Medatrax), and optional
  reference/note. Documented state always wins after hour corrections; only
  documented records may be retained as history.
- Every edit produces an explicit impact preview before application. It preserves
  documented identities and historical Primary Preceptors, removes/regenerates
  only undocumented requirements, makes newly introduced passed thresholds Due,
  and assigns the current Primary Preceptor to future undocumented Interim parts.
- The evaluation snapshot exposes whether every currently required item is
  documented and feeds that exact result into `PlacementCompletionEvidence` for
  Ready-to-Complete gating.

Tests cover defaults and toggles, invalid cadence, two-part threshold generation,
all state boundaries, next-session crossing, early documentation, invalid
documentation, hour corrections, cadence and toggle impact previews, passed new
thresholds, Primary changes, overdue placement behavior, final Due rules,
documented-history preservation, and completion gating. The domain package has
73 passing tests, and the repository-wide quality gate also passes.
