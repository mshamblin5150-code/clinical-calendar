# Add Total Progress to Mobile

Type: task
Status: resolved
Blocked by: none

## What's wrong

Desktop shows both placement-specific wheel progress and a segmented Total Progress summary across all Clinical Placements. Mobile only shows the selected placement's wheel.

## What I expected

Mobile displays the same shared Total Progress calculation, completed/target totals, percentage, and eight-segment bar used by desktop. The two layouts render one reusable component so their calculations cannot drift.

## Answer

Desktop and mobile now render one shared TotalProgress component. Mobile places the eight-segment summary directly beneath the selected Placement wheel and above the batch tray. QA confirmed identical text and segment fills in both layouts, zero clipping/overflow at 390x844 and 932x430, and a live completion update from 126/720 (18%) to 138/720 (19%) on both copies.
