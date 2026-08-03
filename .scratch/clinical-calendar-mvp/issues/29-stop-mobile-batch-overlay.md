# Stop Mobile Batch Overlay

Type: task
Status: resolved
Blocked by: none

## What's wrong

The mobile planning tray sticks over the progress wheel and obscures it.

## What I expected

The tray participates in normal mobile document flow and never covers the wheel.

## Answer

The phone planning tray now uses normal document flow instead of sticky overlay positioning. At a 390x844 viewport, both collapsed and expanded rendered QA showed no wheel/tray overlap and no horizontal page overflow.
