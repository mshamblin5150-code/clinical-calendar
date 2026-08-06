# Issue tracker: GitHub Issues

GitHub Issues in `mshamblin5150-code/clinical-calendar` are the canonical tracker for product, planning, research, and implementation work. Files already under `.scratch/` are historical records only; do not create new local Markdown tickets or maintain a second copy of a GitHub issue there.

## Conventions

- One GitHub Issue owns one question or implementation outcome.
- Use the five triage-role labels from `triage-labels.md` and the repository's type labels (`research`, `prototype`, `grilling`, or `task`).
- Use the issue body for the current question and acceptance boundary. Add evidence, decisions, and conversation as issue comments rather than shadow files.
- Store substantial research or specification artifacts under `docs/` and link them from their owning issue.
- Use native GitHub sub-issues for parent/child relationships and native issue dependencies for `blocked by` relationships.
- Do not duplicate GitHub Issues under `.scratch/`.

## When a skill says "publish to the issue tracker"

Create a GitHub Issue in `mshamblin5150-code/clinical-calendar`, apply the appropriate type and triage labels, and return its URL.

## When a skill says "fetch the relevant ticket"

Fetch the referenced GitHub Issue by URL or issue number, including relevant comments, sub-issues, and dependencies.

## Wayfinding operations

Used by `/wayfinder`:

- **Map**: one open GitHub Issue labelled `wayfinder:map`. Its body contains Destination, Notes, Decisions so far, Not yet specified, and Out of scope.
- **Child ticket**: a native GitHub sub-issue of the map labelled with exactly one Wayfinder type (`wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling`, or `wayfinder:task`) plus the matching repository type label.
- **Blocking**: use GitHub's native issue dependency relationship. Do not encode dependency numbers only in prose.
- **Frontier**: the open, unassigned child issues whose native blockers are all closed; when several are available, take the earliest child in map order.
- **Claim**: assign the issue to the developer driving the map before doing any work.
- **Resolve**: post the answer as a resolution comment, close the child issue as completed, and append a linked one-line gist to the map's Decisions so far.
- **Research artifact**: commit the cited note under `docs/research/`, link it from the research issue, then resolve the issue.

The historical `.scratch/clinical-calendar-mvp/` tree remains reference material. It is not the active tracker and must not receive new tickets or status updates.
