# Fix Responsive Readability and Rotation

Type: task
Status: resolved
Blocked by: none

## What's wrong

The 900 px width-only breakpoint sends wide landscape phones into the desktop console. Tablet landscape correctly reaches desktop mode, but the Month/Week/Agenda switch clips at 1024 px and desktop secondary text frequently renders at 9–11 px.

## What I expected

Phones use the mobile experience in portrait and landscape, including short wide screens. Tablet landscape uses the desktop console without clipped toolbar controls. Meaningful desktop/tablet secondary text is at least 12 px, excluding compact status badges and the development-only prototype marker.

## Answer

Responsive mode selection now considers both width and short landscape height: 390x844, 844x390, 768x1024, and 932x430 all use the mobile experience, while 1024x768 uses the desktop console. The tablet toolbar was compacted without removing actions; Month, Week, and Agenda all fit, and rendered QA confirmed Agenda remains actionable. Meaningful desktop/tablet secondary text is now at least 12 px; only the compact notification badge and development-only prototype marker remain 10 px. All tested viewports have zero horizontal overflow and no clipped text or controls, the browser console is clean, and the production build passes.
