# Implement Reminder Policy and Platform Notifications

Type: task
Status: resolved
Blocked by: 67, 68, 74, 75

## Objective

Implement the synchronized reminder policy and Windows, iOS, and Android notification adapters from [`spec.md`](../spec.md#6-attention-reminders-and-notifications).

## Acceptance criteria

- Default schedules exist for upcoming commitments, confirmation, Protected Days, Evaluation Plans, weekly summaries, deadlines, backup age, and sync health.
- Quiet hours delay every notification until their end; time-zone behavior preserves the commitment's intended local time.
- Permission, delivery enablement, and detailed lock-screen previews are per device; snooze state synchronizes.
- Default previews omit Preceptor, location, note, and Clinical Placement details.
- Dismissal never resolves underlying state, while completing the underlying workflow cancels obsolete deliveries.
- Configurable and non-disableable categories match the specification exactly.
- Fake-clock policy tests and platform integration tests cover every default schedule, snooze choice, quiet hours, permission state, restart, and duplicate prevention.

## Answer

Implemented repository-backed reminder scheduling and native Windows/Android/iOS notification adapters with exact default cadences, DST-safe commitment-zone behavior, universal quiet hours, privacy-safe previews, synchronized snooze state, native actions, restart/duplicate protection, device-specific permission/delivery/privacy policy, and expanded Settings controls. Production now derives current scheduling/evaluation/backup/sync candidates and routes notification interactions into existing workflows. Full repository quality, Windows debug, and Android debug gates pass; iOS runtime remains hardware-deferred.
