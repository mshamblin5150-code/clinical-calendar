# Implement Clinical Placement Application Use Cases

Type: task
Status: open
Blocked by: 66

## Objective

Implement transactional application services for Clinical Placement, Preceptor, progress, Evaluation Plan, and lifecycle workflows.

## Acceptance criteria

- Create and edit Clinical Placement validates dates, Target Hours, Primary Preceptor, and the Evaluation Plan.
- Date and Target Hours changes return an impact preview before the confirmed save.
- Preceptors can be attached, edited, detached when eligible, and made Primary without rewriting history.
- Historical Hours Entries support attributed and Unattributed records and immediately recalculate progress.
- Documenting an Evaluation Requirement records the settled metadata and updates attention state.
- Complete and Reopen Placement enforce Ready-to-Complete and locked-state rules.
- Queries expose one shared active Clinical Placement selection for management, progress, and scheduling defaults.
- Application tests cover all progress and evaluation scenarios in [`spec.md`](../spec.md#122-progress-and-evaluations).

