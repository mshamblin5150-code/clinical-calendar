---
status: accepted
---

# A Ticket stays private and reaches GitHub only through a reviewed sweep

Sign-ups are open, so Students other than the Maintainer need a way to say something is wrong, suggest an idea, or ask a question. This repository is public, and a student in clinicals may type patient detail or a Preceptor's name into any free-text box. **A Ticket is stored privately in the app and read only by the Maintainer. What reaches GitHub is a drone-written issue that never quotes the Ticket, drafted in a `ticket-sweep` Claude Code session and published only after the Maintainer approves each draft.** This adopts gift-for-taylor's [ADR-0026](https://github.com/mshamblin5150-code/gift-for-taylor/blob/main/docs/adr/0026-a-ticket-stays-private-and-reaches-github-only-through-a-reviewed-sweep.md) in full, apart from the differences below. That ADR records the rejected alternatives: posting straight to GitHub with a disclaimer, an in-app GitHub token, and making the repository private. Grilled in #230.

## Differences from gift-for-taylor

- **The Maintainer is a grant on the Maintainer's own Student account.** It covers Tickets and nothing else: no private-data viewer and no ownership bypass, as `docs/release-security-checklist.md` requires. The Maintainer sees only what the sender saw and approved before sending.
- **There is no Repair.** No one in Clinical Calendar has authority over another Student's data, so a Ticket never leads to a break-glass action.
- **A diagnostic is attached only on request.** When a problem depends on the shape of a Student's data, the Maintainer asks in the Ticket's private thread. The Student previews a content-free structural snapshot and chooses Attach or Decline. The snapshot holds counts, states, numbers, settings, time zone and build, and never names, notes, locations, Preceptors, class titles or feed URLs. Asking for one uses one of the drone's two allowed questions.
- **The sender and the Maintainer hear about activity through the app plus a content-free email** ("You have a Ticket update – open Clinical Calendar"). Emails to the Maintainer are combined. Once Web Push exists, push replaces the email for anyone who can receive it.
- **Done means live on the web app,** because that is the release every Student has.
- **The sweep cannot check drafts against Preceptor names,** because the Maintainer cannot read Students' calendars. The never-quote rule carries that weight alone.
