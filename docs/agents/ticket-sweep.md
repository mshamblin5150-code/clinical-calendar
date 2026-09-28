# Ticket sweep

The repository skill at `.claude/skills/ticket-sweep/` turns private Tickets
into drafts for Maintainer review. It implements ADR-0004's boundary: Tickets
stay in the deployed Clinical Calendar web app, and only rewritten,
Maintainer-approved drafts may reach GitHub.

## Run a live sweep

1. Sign in to the deployed web app in Chrome using the Student account that has
   the Maintainer grant.
2. Invoke `ticket-sweep` and let it read the Maintainer Tickets surface. Do not
   supply database credentials or substitute SQL, Supabase, a direct API, a
   local build, or fixtures for the deployed app.
3. Review the sanitized batch. Each Ticket becomes one Issue, Question, Close
   note, or Nothing yet draft. The skill performs no action while presenting
   the batch.
4. Approve, reject, or edit one pending draft at a time. An approval applies
   only to the draft currently presented.

The app does not store GitHub issue URLs. After an approved issue is published,
the skill verifies it and reports its URL. For a later close-note decision, the
Maintainer must explicitly pair that public URL with the open Ticket; the skill
never guesses from similar wording or creates a private side record.

Issue drafts use this repository's type labels and the triage roles documented
in `docs/agents/triage-labels.md`. Questions stay private in the app. Close
notes require fresh GitHub and successful Pages-deployment evidence.

## Privacy guarantees

- Drafts never quote Ticket or thread text.
- Sender identity, account details, device information, Preceptor names, and
  patient detail do not enter a draft.
- Every draft says whether possible patient detail was found; flagged details
  are removed rather than repeated.
- The Maintainer does not inspect another Student's calendar, Preceptors, or
  sync data. There is intentionally no Preceptor-name lookup.
- Publishing or writing back requires explicit approval for that one draft.

## Dry-run evaluation

The synthetic fixture and evaluator live under
`.claude/skills/ticket-sweep/evals/`. Ask the skill to dry-run
`seeded-ticket.md`, save only its public batch output outside the repository,
and pipe that output to the evaluator:

```powershell
Get-Content -Raw <dry-run-output> |
  python .claude/skills/ticket-sweep/evals/check_dry_run.py
```

The evaluator requires the Issue's own Draft block to contain the kind, screen,
build, and refusal codes, plus a patient-detail warning, no seeded private
sentinel text, and `Approval: Pending`. A dry run never opens the app or mutates
app or GitHub state.
