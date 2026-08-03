# Highlight the Current Day

Type: task
Status: resolved
Blocked by: none

## What's wrong

The calendar does not visually identify the current system date, and the state would be especially easy to miss when Today also contains a Work Shift, Clinical Session, Protected Day, or batch selection.

## What I expected

Today receives a Borg optic-red date marker and inset outline without replacing other semantic day treatments. Its accessible name also says `Today` so the state does not rely on color alone.

## Answer

The current system date now has an optic-red circular date badge and inset cell outline. Layered styling preserves simultaneous states: QA confirmed August 3 displays both the teal Work Shift treatment and red Today marker, with the accessible name `Mon, Aug 3, Today, Work Shift`. The production build passes, the browser console is clean, and the 390 px layout has no horizontal overflow.
