---
status: accepted
---

# Personal Calendar Feeds import only busy events, as title and times

A Personal Calendar Feed mirrors the Student's own calendar so that Personal Commitments take part in Schedule Conflicts, but a personal calendar is full of events the Student is not committed to, and full of sensitive detail. **Only events the calendar marks as busy are imported; free, tentative and cancelled events are listed on the feed's page but never become Personal Commitments. All-day events follow the same busy rule rather than being skipped. Each imported event keeps only its title and times; descriptions, locations, attendees and links are dropped during import and never stored or synced.** Grilled in #250.

## Considered options

- **Import everything and flag every overlap, like Work Schedule Feeds.** Rejected. Tentative invites and "free" holds would bury the Student in Schedule Conflicts for events they never meant to attend.
- **Import everything but never let imported personal events conflict.** Rejected. It turns Personal Commitments back into a note beside the schedule.
- **Skip all-day events, as Work Schedule Feeds do.** Rejected. A busy week away is exactly what a monthly planner must see, and calendar apps save birthdays and holidays as free by default, so the busy rule already filters them.
- **Keep location and description too.** Rejected. Planning needs only what and when, and anything kept sits at rest in the Student's synced data.

## Consequences

- Personal Calendar Feeds have no skip words and no team-feed refusal: two Personal Commitments overlapping each other is not a Schedule Conflict.
- Recurring events are expanded into one Imported Personal Commitment per occurrence, up to 12 months ahead, honouring deleted and moved occurrences. Work Schedule Feeds never needed this because employer systems send each shift separately.
- Adding more fields later is easy; any field kept today is hard to take back from existing synced copies.
