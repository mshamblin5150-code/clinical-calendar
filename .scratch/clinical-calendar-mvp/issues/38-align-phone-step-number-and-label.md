# Align Phone Step Number and Label

Type: task
Status: resolved
Blocked by: none

## What's wrong

The phone scheduling-step label rides into its numbered circle because overlapping grid rules reserve less space than the circle occupies.

## What I expected

Each phone step displays as a single horizontal pair: a fixed numbered circle followed by a vertically centered label, with a visible gap and no overlap at supported phone widths.

## Answer

Phone step tabs now use an explicit centered flex row instead of competing grid rules. At 390px and 320px rendered QA, every circle precedes its label by a 5px gap, all labels remain inside their tab, and no circle/label bounding boxes overlap.
