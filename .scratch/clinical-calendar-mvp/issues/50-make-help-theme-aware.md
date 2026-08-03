# Make Help Theme-Aware

Type: task
Status: resolved
Blocked by: none

## What's wrong

The Help guide hard-codes Borg visual language into otherwise universal workflow documentation. Future themes would either show incorrect color guidance or require duplicating the entire Help experience.

## What I expected

Help identifies the active theme and sources its visual-state legend from a theme-specific guide definition. Universal scheduling, progress, evaluation, notification, and storage guidance remains shared. Unknown future themes receive a safe fallback until their guide is supplied.

## Answer

Help now separates universal workflow documentation from a themeHelpGuides registry. The active `Borg Tactical Console` guide supplies its own summary and Calendar States legend for Clinical Sessions, Work Shifts, Protected Days, and Today; future themes can replace that legend independently and receive a safe fallback until defined. Meaningful Help text is at least 12 px everywhere and 13 px for dense mobile guidance. QA at 390x844, 932x430, and 1024x768 found no sub-12 px meaningful copy, clipping, or horizontal overflow.
