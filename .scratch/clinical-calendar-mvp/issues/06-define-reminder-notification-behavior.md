# Define Reminder and Notification Behavior

Type: grilling
Status: resolved
Blocked by: 04

## Question

Which reminders and device notifications should exist for upcoming commitments, unresolved past sessions, Protected Day selection, aging portable backups, and approaching, due, or overdue Evaluation Plan requirements, and how may the Student configure them without losing hard safety rules?

## Comments

## Answer

### Delivery and privacy

- Reminder state synchronizes across the Student's devices, while system-notification permission is configured per device. Phone delivery is enabled by default after permission is granted; tablet and desktop delivery require opt-in to avoid three-device duplication.
- Important in-app indicators appear on every device regardless of system-notification settings.
- Lock-screen text is privacy-minimized by default and omits Preceptor names, locations, notes, and placement details. A per-device setting may enable detailed previews.
- Per-device quiet hours default to 21:00–07:00 local time. All notifications wait until quiet hours end because none are emergencies.
- Dismissing a system notification clears only that device's visible notification; it never resolves the underlying requirement. Snoozing a reminder synchronizes across devices so another enabled device does not immediately repeat it.

### Upcoming commitments and confirmation

- Work Shifts and Clinical Sessions default to reminders 24 hours and 2 hours before starting. Defaults are configurable separately by commitment type, and individual commitments may override or disable them.
- Each commitment stores its own time zone, defaulting to the creating device's current zone. Travel or daylight-saving changes never silently shift its local start time or reminder meaning.
- A Clinical Session prompts for confirmation 30 minutes after its scheduled end, with a direct path to confirm or correct actual times and Preceptor.
- If it remains unresolved, reminders occur the following morning at 09:00 and then every three days until it is completed, cancelled, or missed. Needs Confirmation remains persistently visible in the app.

### Protected Day and planning

- If the next week lacks a Protected Day, reminders occur three days before the configured week begins and again the day before. For a Sunday-start week, these fall on Thursday and Saturday.
- Once an unprotected week begins, Planning Incomplete remains visible in the app until an empty Protected Day is chosen.

### Evaluation Plan requirements

- Interim Review Approaching notification occurs within a configurable number of Completed Hours, defaulting to 10, plus a warning when the next scheduled Clinical Session would cross the threshold.
- Interim Review Due notification occurs immediately when confirmed hours meet or pass the threshold, followed every three days until both separately tracked review parts are documented.
- Initial Self-Assessment reminders occur seven days and one day before the placement Start Date, on the Start Date if missing, and every three days while overdue.
- Final Self-Assessment and Final Placement Review become Approaching within 10 Completed Hours of the target or seven days of the Completion Deadline, whichever occurs first. They become Due when the target is met and no future Clinical Sessions remain, then repeat every three days until documented.
- A deadline reached without enough completed hours produces an overdue-placement warning rather than falsely making final evaluations due.

### Planning, deadline, backup, and sync health

- A configurable weekly summary defaults to Sunday at 18:00 and reports upcoming commitments, the week's Protected Day, sessions awaiting confirmation, hours still needing scheduling, completion projections, approaching or due evaluations, and sync and backup health.
- If a schedule change moves projected completion beyond the deadline, one immediate notification and a persistent in-app warning appear. It does not repeat daily; the weekly summary continues reporting the risk.
- Portable-backup reminders occur seven days after setup if no encrypted backup exists, when the latest backup becomes 30 days old, and weekly thereafter until a new backup is created. Backup age appears in the weekly summary.
- Sync Conflicts notify immediately. Brief failures retry silently; continuous failure notifies after one hour, and local changes still unsynchronized after 24 hours produce a further warning. Successful synchronization clears these warnings automatically.

### Snoozing and customization boundaries

- Contextual snooze choices are: 15 minutes or 1 hour for an upcoming commitment; 1 hour or tomorrow morning for session confirmation; later today, tomorrow, or three days for Protected Day and evaluation requirements; and one week for a backup reminder.
- Snoozing changes only the next delivery time and never changes a requirement's due date or in-app state.
- Upcoming commitment reminders, weekly summaries, and backup notifications may be disabled. Times and repetition intervals may be customized, and system notifications may be disabled per device.
- In-app indicators for Sync Conflicts, missing Protected Days, unresolved sessions, deadline risk, and due Evaluation Plan requirements cannot be hidden until resolved.
