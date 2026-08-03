# Calculate Hours from Time Range

Type: task
Status: resolved
Blocked by: none

## What's wrong

Counted Hours must be entered separately from start and end times.

## What I expected

Elapsed hours calculate automatically from start/end, including overnight ranges, in both template management and schedule entry.

## Answer

Manual duration fields were removed from batch scheduling, commitment correction, and template management. Duration is derived from start/end times with overnight wraparound; rendered QA verified `07:00-20:30` produces 13.5 hours.
