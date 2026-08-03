# Default Planning Alert to Protected Day

Type: task
Status: resolved
Blocked by: none

## What's wrong

The `Planning incomplete` attention action asks the Student to choose Protected Days but currently invokes the one-day protection shortcut instead of opening the batch tray with the matching commitment type.

## What I expected

Clicking `Planning incomplete`, whether from the attention rail or notification center, opens and resets the batch scheduling tray at its first step with `Protected Day` selected. Ordinary `Add schedule` actions continue to default to `Clinical Session`.

## Answer

The attention-rail and notification-center actions now open a freshly reset, expanded batch tray at Step 1 with `Protected Day` selected. Existing date selections are preserved, so the Student can use them or change them without losing work. Desktop and 390 px phone interaction tests passed; ordinary `Add schedule` still resets the tray to `Clinical Session`.
