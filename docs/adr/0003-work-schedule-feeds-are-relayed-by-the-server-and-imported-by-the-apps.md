---
status: accepted
---

# Work Schedule Feeds are relayed by the server and imported by the apps

A Student can connect one or more Work Schedule Feeds, which are private calendar (ICS) subscription URLs from an employer's scheduling system. The first is the Maintainer's own ER Schedule feed. Browsers cannot fetch third-party ICS feeds because the hosts send no CORS headers (`docs/research/work-schedule-feed-sources.md`), so a server has to download them for the web app. **A Supabase function is only a delivery relay: it downloads a feed that is saved on the signed-in Student's own account, and nothing else. Whichever app is open runs the import itself, using the same Dart domain rules as every other calendar change.** Grilled in #230.

## Considered options

- **A scheduled server importer that writes Imported Work Shifts into the sync store**, for example every hour. Rejected. It would re-implement the Work Shift and import rules in TypeScript, so the rules would live in two languages and drift apart. It would also spend function usage on a timer rather than on use.
- **Fetching feeds straight from each app.** Impossible on web because of CORS.

## Consequences

- New shifts appear the next time any app opens: on open if the feed was last checked more than 60 minutes ago, or through "Refresh now". Nothing polls in the background. The relay downloads each feed at most once per 15 minutes and answers any sooner request with the last result.
- Two devices importing at once must produce the same Imported Work Shifts, so each one's identity is derived from its feed and the event's UID, with a fallback match on time when a vendor changes its UIDs.
- The relay must never become an open proxy. It accepts only `https`/`webcal` URLs saved on the caller's account, refuses private and loopback addresses, and caps response size and time.
- A feed URL is a credential. It never appears in exports, logs, support diagnostics or Tickets, and it is shown masked.
- Anything that must happen with no app open, such as Web Push reminders, needs its own decision about whether the server may know a Student's shifts.
