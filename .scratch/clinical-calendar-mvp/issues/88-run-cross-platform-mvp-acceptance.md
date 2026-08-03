# Run Cross-Platform MVP Acceptance

Type: task
Status: open
Blocked by: 70, 71, 72, 73, 74, 75, 76, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87

## Objective

Execute the complete acceptance suite in [`spec.md`](../spec.md#12-mvp-acceptance-suite) and produce the private MVP release candidate.

## Acceptance criteria

- Every scheduling, progress, evaluation, offline/sync, ownership/recovery, presentation, notification, and release-quality scenario has recorded pass/fail evidence.
- The responsive matrix passes with no horizontal overflow, clipped primary copy, hidden actions, or overlapping controls.
- Two-device and three-platform tests demonstrate offline edits, idempotent convergence, explicit conflict resolution, and no silent data loss.
- Install, upgrade, offline restart, backup restore, and recovery pass on physical Windows, iPhone, and Android tablet targets.
- Domain, migration, outbox, backend concurrency, RLS, notification, backup, export, privacy, and packaging test suites pass from pinned commands.
- Any failed criterion creates a narrower blocking defect ticket; the release candidate is not declared complete with an unexplained failure.
- The final report identifies supported platform versions, artifact versions, known limitations, and deferred public-distribution and keyboard-first work.
