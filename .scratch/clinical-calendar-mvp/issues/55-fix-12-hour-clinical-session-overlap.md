# Fix 12-Hour Clinical Session Time Overlap

Type: bug
Status: resolved
Blocked by: none

## What's wrong

The Clinical Session editor gives its start and end time controls columns narrower than the combined time input and AM/PM selector, causing overlap in 12-hour mode.

## What I expected

Start and end each receive a complete readable column, the calculated range appears below them, and narrow phone layouts stack all three fields.

## Answer

The Clinical Session editor now gives Actual start and Actual end complete time-plus-AM/PM columns and places Automatically calculated across the full row below. Portrait phones retain the single-column stack; horizontal phones use two sufficiently wide columns. The existing scheduling tray also remains single-column on mobile. The 12-hour Clinical Session flow was verified at 390 × 844 and 844 × 390, followed by a clean reload with no new console warnings or errors.
