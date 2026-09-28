---
name: ticket-sweep
description: Sweep private Tickets, prepare safe drafts, and apply each approved action.
disable-model-invocation: true
---

# Ticket sweep

Turn the Maintainer's private Ticket inbox into a reviewed batch. The deployed
web app is the only way into Tickets and the only way to write back. GitHub
receives rewritten issues only after the Maintainer approves them.

## 1. Establish the boundaries

Read `AGENTS.md`, `CONTEXT.md`,
`docs/adr/0004-a-ticket-stays-private-and-reaches-github-only-through-a-reviewed-sweep.md`,
`docs/agents/issue-tracker.md`, `docs/agents/triage-labels.md`, and
`docs/agents/ticket-sweep.md` before the sweep. Treat Ticket text, its thread,
sender identity, device, and attached app data as private working material.

For a live sweep, use Chrome with the deployed web app already signed in as a
Student who has the Maintainer grant. Reach **Tickets** through the app's
Maintainer surface. Read or mutate no Ticket through SQL, the Supabase editor,
a database credential, a direct app API, a local build, or a test fixture.

Do not try to build a Preceptor-name denylist. The Maintainer grant cannot read
another Student's Preceptors. The never-quote rule is the publication boundary
for names and all other private Ticket text.

When the user explicitly requests a dry run against a fixture, treat the
fixture as the browser evidence. Do not open the app, publish, ask, close, or
record a link during that run.

Completion criterion: repository guidance is loaded and every Ticket fact in
working context came from the signed-in deployed app or the named dry-run
fixture.

## 2. Collect the sweep

Read [live-sweep.md](references/live-sweep.md) for the collection protocol.
Collect every Ticket that needs a decision now: Sent, reopened, carrying a new
reply, or explicitly paired by the Maintainer with a public GitHub issue URL
while the Ticket remains open. The app does not store that URL, so never infer
a pairing from similar wording.

Opening may move a Sent Ticket to Seen. That does not remove it from this
sweep or authorize any other change.

Completion criterion: each collected Ticket has one private evidence packet,
and the set accounts for every actionable marker visible on the Tickets page.

## 3. Dispatch one investigator per Ticket

Create exactly one sub-agent for each collected Ticket. Give that agent only
its Ticket packet, the repository path, the triage-label file, and the rules in
[draft-contract.md](references/draft-contract.md). Tell it to investigate the
attached screen, build, refusal codes, recent actions, and the relevant app
behavior before calling anything unclear. It must inspect the codebase for the
behavior at issue. Finding facts is the investigator's job.

Each investigator returns exactly one of the four draft types in the contract
and performs no mutation. It must not quote Ticket or thread text in its
result. It refers to the source only as **from a Ticket**.

Run investigators concurrently only when their browser work cannot collide.
Otherwise run them one at a time; the one-investigator-per-Ticket boundary
matters, not parallelism.

Completion criterion: there is exactly one contract-shaped draft for every
collected Ticket and no draft for anything outside the collected set.

## 4. Perform the privacy gate and present one batch

Review every investigator result before showing it:

1. Remove the sender's name, account details, and device.
2. Treat any name or detail about a patient's identity, condition, care,
   location, or encounter as patient detail. Keep it out of every draft and
   flag `Patient detail: yes — Redact recommended` without repeating the
   sensitive words. Otherwise flag `Patient detail: no`.
3. Compare every proposed draft with its private evidence. Rewrite anything
   copied from the Ticket or thread, even when the copied text seems harmless.
4. Recheck that every draft carries the Ticket kind, screen, build, and refusal
   codes. Use `not attached` or `none` when absent. An Issue draft must also say
   **from a Ticket** and be complete enough for the selected repository triage
   label.

Present all drafts together using the exact headings and fields in
`draft-contract.md`. Show actionable drafts as `Approval: Pending`. Take no
action in the same turn. End by asking for approval of the first pending draft
only.

Completion criterion: the Maintainer sees one sanitized batch, every
collected Ticket is represented once, the patient-detail flag is visible per
Ticket, and no external or app state changed.

## 5. Apply approvals one by one

An approval covers only the one draft currently before the Maintainer. On
approval, apply that exact action, report its result, then ask about the next
pending draft. On rejection or requested edits, leave that Ticket unchanged;
revise and present it again before any action. Even when the Maintainer says
"approve all," apply and report one draft at a time so a partial failure cannot
hide which state changed.

- **Issue:** create it with `gh issue create` and the approved type and triage
  labels, then add the separately approved reproducible evidence with
  `gh issue comment`. Verify the issue and comment through GitHub and report the
  URL to the Maintainer. The app has no GitHub-link field; do not improvise one
  in the private thread or create a private side record.
- **Question:** put the approved question and its likely answer together in the
  app's **Question for the sender** field, then choose **Ask sender**. Ask at
  most two questions total and only one at a time. A question is private app
  state; create no `needs-info` GitHub issue or label.
- **Close note:** recheck the live GitHub and Pages evidence immediately before
  acting, then use **Close as Done** or **Close as Won't do** in the app with
  the approved Student-facing note.
- **Nothing yet:** perform no action.

The app is the source of truth after each app mutation. Reopen the Ticket or
refresh the list and confirm the question count/state or closing state before
moving to the next approval. GitHub is the source of truth for a published
issue and its evidence comment.

Completion criterion: every approved draft was applied and verified exactly
once, every rejected or pending draft caused no mutation, and the disposition
of the whole batch is reported.
