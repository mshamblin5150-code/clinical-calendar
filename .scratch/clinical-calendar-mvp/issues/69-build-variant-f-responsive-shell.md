# Build the Variant F Responsive Application Shell

Type: task
Status: resolved
Blocked by: 59

## Objective

Implement the production Flutter shell, semantic theme tokens, navigation, and responsive compositions from [`spec.md`](../spec.md#7-settings-profile-help-and-visual-contract).

## Acceptance criteria

- Variant F semantic tokens implement the accepted Borg Tactical Console palette, typography, borders, corners, and state hierarchy without embedding workflow logic.
- Desktop composes the command bar, Clinical Placement dock, central content, right insight rail, and lower planning region.
- Phone and short-landscape compose the compact header, content stack, in-flow planning region, and bottom navigation.
- Mobile Settings and the application menu expose Clinical Placements, Student Profile, Settings, Notifications, and Help.
- Contextual Back returns to the application menu while direct entry uses Close.
- Theme and theme-specific Help guide interfaces allow future themes without duplicating workflows.
- Golden/widget tests cover every required viewport and report no horizontal overflow or clipped primary actions.

## Answer

Implemented the production Variant F responsive shell in
`packages/clinical_calendar_presentation`:

- Theme extensions expose semantic colors for structure, Clinical Sessions,
  Work Shifts, Protected Days, scheduled progress, Today/urgent attention, text,
  and borders plus shallow-corner, inset-border, touch-target, and typography
  metrics. Workflow widgets consume meanings rather than concrete Variant F
  colors.
- Replaceable visual-theme and theme-specific Help guide interfaces allow future
  themes. Shared workflow Help remains independent, and unknown themes receive a
  safe generic calendar-state guide.
- Desktop activates only when the three-column composition fits and supplies the
  command bar, Clinical Placement dock, central scrollable content, right
  progress/attention rail, and lower in-flow planning region.
- Phone, portrait tablet, and short-landscape sizes retain the compact header,
  placement summary, central content stack, in-flow planning region, and bottom
  navigation. Settings opens the complete five-destination application menu.
- Clinical Placements, Student Profile, Settings, Notifications, and Help share
  the same destination contract. Menu-origin surfaces use Back and return to the
  menu; direct entry uses Close.
- The existing production-foundation content remains as a truthful placeholder;
  no prototype records or workflow logic entered the shell.

Twelve presentation tests cover all required logical viewports (`320x568`,
`390x844`, `844x390`, `768x1024`, `932x430`, `1024x768`, and `1440x900`),
desktop/mobile composition, primary-action visibility and 44px sizing, absence
of Flutter overflow exceptions, the complete menu, contextual Back/direct Close,
theme Help fallback, and Variant F semantic tokens. App composition and the
integrated repository-wide quality gate also pass.
