# Auto-Dismiss the Action Confirmation Toast

Type: task
Status: resolved
Blocked by: none

## Parent issue

Reported during QA of ticket 07.

## What's wrong

The small confirmation message remains over the working area after actions such as adding a Work Shift.

## What I expected

An action confirmation flies into a nonblocking position, remains readable for about four seconds, and flies away automatically. A newer confirmation replaces it and restarts the timer.

## Steps to reproduce

1. Add a Work Shift.
2. Observe the confirmation message over the work area.
3. Wait and observe that it does not dismiss.

## Blocked by

None - can start immediately.

## Answer

Action confirmations now fly in at the upper-right edge, remain readable for about four seconds, and fly out without covering the central work area.
