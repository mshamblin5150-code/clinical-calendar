# Improve Phone Legibility and Touch Targets

Type: task
Status: resolved
Blocked by: none

## What's wrong

Calendar labels, progress details, helper copy, evaluation rows, and phone navigation use 8-10px text, while several controls are shorter than comfortable touch targets.

## What I expected

Phone secondary text is at least 12px, primary and control text is 14-16px, interactive targets are at least 44px tall where practical, and the larger typography causes no clipping or horizontal overflow.

## Answer

Phone typography now uses 12px minimum secondary text, 13px calendar dates, 14px form and notification headings, and 16px form controls. Calendar rows are 48px, navigation is 72px, and all visible phone buttons, selects, and inputs pass a 44px minimum-height audit. Portrait and landscape rendered QA found no horizontal overflow; notification and evaluation dialogs also retain equal client and scroll widths.
