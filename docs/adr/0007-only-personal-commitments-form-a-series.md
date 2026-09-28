---
status: accepted
---

# Only Personal Commitments form a series

Nothing else in the application repeats: Work Shifts and Clinical Sessions are placed with Schedule Templates and batch scheduling, and each one is independent. **A hand-entered Personal Commitment can be a true Personal Commitment Series, edited as "this one" or "this and following". Occurrences that would clash with clinical or work time are skipped or adjusted in a preview before saving, so the Student still never creates a Schedule Conflict. A series edit never changes past occurrences and never undoes an occurrence the Student skipped or changed on purpose. Deleting a series removes only upcoming occurrences, and an open-ended series runs 12 months ahead on a rolling basis.** Grilled in #250.

## Considered options

- **Reuse Schedule Templates and batch scheduling.** Rejected as too clumsy for the Student: "therapy moves to 18:00 from next month" would mean editing every Tuesday.
- **A "repeats" option that creates independent commitments.** Rejected for the same reason; it makes entry easy but leaves later changes one at a time.
- **Series for Work Shifts or Clinical Sessions too.** Deferred. Clinical Sessions carry placement, Preceptor, confirmation and hours, so series edits would reach into hours accounting. Work Shifts already have feeds and batch scheduling; extending series to them is a separate decision.
- **Flag clashing occurrences instead of resolving them before saving.** Rejected. It would be the first way a Student could create a Schedule Conflict.

## Consequences

- There is no "all occurrences" scope: past occurrences are frozen, so "all" would equal "this and following".
- Correcting a mistake in past occurrences means editing them one at a time. That is acceptable because Personal Commitments never count toward any hours.
