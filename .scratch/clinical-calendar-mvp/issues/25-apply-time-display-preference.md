# Apply Time Display Preference

Type: task
Status: resolved
Blocked by: none

## What's wrong

Changing Military time to 12-hour time does not change template or scheduling displays.

## What I expected

The time-display preference consistently formats template summaries and scheduling fields while stored times remain unambiguous.

## Answer

The selected preference now formats saved template summaries, template choices, calculated batch ranges, and commitment summaries. Times remain stored in 24-hour `HH:MM` values; rendered QA verified `07:00-19:00` changes to `7:00 AM-7:00 PM` after saving 12-hour time.
