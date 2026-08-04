# Implement Clinical Placement Application Use Cases

Type: task
Status: resolved
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

## Answer

Implemented transactional Clinical Placement application workflows for aggregate Placement and Evaluation Plan creation, impact-previewed date and Target Hours edits with stale-confirmation protection, reusable Preceptor editing and attachment rules, Primary changes that preserve documented history, attributed and Unattributed Historical Hours, Evaluation Requirement documentation, derived progress and attention, guarded Completion, locked-state enforcement, and Reopen.

The application repository contract and SQLCipher implementation now persist one owner-scoped active Clinical Placement selection in the existing settings record, synchronize it through the transactional outbox, validate its target, support clearing and restart-safe idempotent replay, and preserve unrelated settings. Six application-level scenario groups and a real-SQLCipher integration test cover aggregate rollback/outboxes, selection durability, previews, progress, evaluation metadata, lifecycle locks, and relationship rules. The full workspace quality gate and Windows and Android release builds pass.
