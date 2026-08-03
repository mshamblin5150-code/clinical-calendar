# Enforce Date-Driven Session Status

Type: task
Status: resolved
Blocked by: none

## What's wrong

Future sessions can be entered as Completed, while retrospective entries can bypass confirmation.

## What I expected

Future/current dates are Scheduled; past dates are Awaiting Confirmation; only confirmation records Completed Hours.

## Answer

Batch creation now derives state from the selected date. Past Clinical Sessions enter Awaiting Confirmation and expose a confirmation action; future/current sessions remain Scheduled and expose only time correction. Rendered QA verified an Aug. 2 confirmation increased Family Medicine Completed Hours from 126 to 138, while an Aug. 16 session had no completion action.
