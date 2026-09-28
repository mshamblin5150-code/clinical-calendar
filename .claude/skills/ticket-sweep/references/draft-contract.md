# Draft contract

Return exactly one draft per Ticket. Use plain language and repeat no Ticket or
thread sentence verbatim.

## Decide the type

### Issue

Use when code and app evidence make the work sufficiently specified. Write an
agent-ready GitHub issue in this repository's style and select an applicable
type label plus a canonical triage label mapped in
`docs/agents/triage-labels.md`. Its body must say **from a Ticket** and contain
the current problem, expected behavior, relevant non-private context, and
acceptance checks. Put non-private reproduction evidence in a separate
proposed GitHub issue comment, not in the issue body. Neither part contains
sender identity, device, Preceptor name, or patient detail, and neither quotes
Ticket or thread text.

### Question

Use only after checking the app context and codebase leaves one fact that
changes the decision. Ask one plain-language question and give one likely
answer the sender can confirm with a tap. Use this type only when the Ticket is
Seen, no question or diagnostic is awaiting the sender, and fewer than two
questions or diagnostics have already been requested. If a request is already
waiting, return **Nothing yet**. `needs-info` stays in the app and is not a
GitHub label or issue.

When two questions have already been asked, return **Nothing yet** and include
`Maintainer follow-up: Ask in person`.

### Close note

Read [github-evidence.md](github-evidence.md) before returning this type.

- **Done** requires a public issue URL explicitly supplied by the Maintainer for
  this Ticket, a closed issue, and a successful GitHub Pages deployment
  containing the fixing commit. Write a short note for a Student about the
  behavior now live, without repository or deployment jargon.
- **Won't do** requires a Maintainer-supplied public issue URL whose issue is
  closed with the canonical `wontfix` label. Explain the product reason in
  plain language.

If either proof is incomplete, return **Nothing yet**.

### Nothing yet

Use for an open issue, missing deployment evidence, the third would-be
question, or any state where no action is due. Give one line saying why. This
type has no approval and causes no mutation.

## Batch shape

Use this shape exactly so dry-run evals and the Maintainer can audit a batch:

```text
## Ticket <private working key>
Patient detail: yes — Redact recommended|no
Draft type: Issue|Question|Close note|Nothing yet
### Draft
Kind: <Ticket kind>
Screen: <screen|not attached>
Build: <build|not attached>
Refusal codes: <codes|none>
<the complete proposed issue, question plus suggested answer, close note, or one-line reason>
Approval: Pending|Not applicable
```

For an Issue, the complete proposal separates `Issue body` from `Evidence
comment` so the approved workflow can create the issue first and then add the
evidence as a comment. The four context fields appear in every draft type.

Use `Approval: Pending` for Issue, Question, and Close note. Use
`Approval: Not applicable` for Nothing yet.
