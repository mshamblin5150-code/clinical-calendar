# Deselect a Conflicting Calendar Date Directly

Type: task
Status: resolved
Blocked by: none

## What's wrong

If a date is already part of the current batch selection and also contains a Work Shift, Clinical Session, or Protected Day, clicking the date opens that stored item. The Student cannot undo the accidental selection directly and must instead reach the Review step's conflict resolution.

## What I expected

A selected date always gets first-click priority: clicking it again removes only that date from the current batch without opening or changing the underlying calendar data. Once deselected, a later click resumes the normal behavior of opening the stored item. The accessible label and tooltip explain the direct deselection behavior.

## Answer

Selected dates now get first-click priority across desktop and phone. QA used the initially conflicting August 28 Work Shift: one click reduced the batch from four dates to three, removed its selection marker, preserved the Work Shift, opened no modal, and reported that existing calendar data was unchanged. Clicking August 28 again after deselection opened its Work Shift details normally. The accessible label says `Selected; click to deselect`, the production build passes, the browser console is clean, and the 390 px layout has no horizontal overflow.
