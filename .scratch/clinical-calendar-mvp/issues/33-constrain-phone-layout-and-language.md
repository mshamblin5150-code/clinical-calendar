# Constrain Phone Layout and Language

Type: task
Status: resolved
Blocked by: none

## What's wrong

The phone surface can grow too wide and tells touch users to click the progress wheel.

## What I expected

Phone layout content and fixed navigation share a centered maximum width, never overflow horizontally, and use touch-appropriate "Tap wheel" wording.

## Answer

The touch layout is now used through 900px, constrained to a centered 760px surface with a matching fixed navigation width. Portrait and landscape QA found no horizontal overflow, and the wheel prompt reads "Tap wheel". Phone landscape remains touch-oriented; desktop activates only when there is enough width for its three-column layout.
