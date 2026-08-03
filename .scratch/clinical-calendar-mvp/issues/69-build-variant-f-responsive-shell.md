# Build the Variant F Responsive Application Shell

Type: task
Status: open
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

