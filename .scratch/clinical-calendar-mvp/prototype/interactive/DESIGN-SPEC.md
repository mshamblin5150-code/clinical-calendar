# Variant F Prototype Design Inventory

> One accepted Variant F experience on the throwaway `/` route. This prototype tests the calendar, placement progress, attention hierarchy, and staged multi-date scheduling interaction.

## Accepted concept

- Source: [`../concepts/Variant F - Borg Tactical Console.png`](../concepts/Variant%20F%20-%20Borg%20Tactical%20Console.png)
- Native concept size: 1536 × 1024
- Surfaces shown: desktop command console and phone adaptation

## Visual system

- Background: matte near-black `#070b09`
- Primary surface: charcoal-green `#0d120f`
- Raised surface: `#151a16`
- Border: oxidized metal `#3b4039`
- Primary text: pale bone `#ddd9c9`
- Muted text: `#908f82`
- Active/status: desaturated green `#92be59`
- Clinical/scheduled: olive `#778f45`
- Warning: amber `#f2a31b`
- Threat/attention: red `#eb4b3f`
- Protected day: muted plum `#4b344b`
- Corners: shallow 4–8px radii with clipped-corner accents
- Elevation: inset borders and restrained black shadows; no soft SaaS cards or decorative gradients
- Typography: narrow system sans, uppercase section labels, compact control text, tabular numerals
- Icons: thin outlined utility glyphs with squared geometry

## Container model

- Desktop: top command bar; left Clinical Placement dock; dominant month grid; right progress/attention rail; collapsible staged command tray below the grid.
- Phone: compact month grid; progress and attention stack; compact command tray; bottom navigation ordered Today, Calendar, Placements, Attention, Settings.

## Allowed primary-screen copy

Clinical Calendar; Add schedule; August 2026; Month; Week; Agenda; My placements; Family Medicine; Internal Medicine; Pediatrics; Billing & Coding; Total progress; 270 h target; 126 h completed; 108 h scheduled; 36 h unscheduled; Interim review approaching; View progress; Needs attention; 1 needs confirmation; Planning incomplete; Synced; 4 dates selected; Day Shift; 1 conflict; Expand; Review; Template; Placement; Review conflicts; Back; Next; Today; Calendar; Placements; Attention; Settings.

## Prototype interactions

1. Select or deselect nonconsecutive calendar dates.
2. Expand/collapse the planning tray.
3. Choose a template and Clinical Placement.
4. Move Back/Next through Template, Placement, and Review stages.
5. Review the all-or-nothing conflict and clear it from the staged flow.
6. Select a Clinical Placement in the left dock.
7. Switch Month, Week, and Agenda controls while preserving the chosen schedule state.

## Intentional prototype limits

- Fictional in-memory data only; no persistence, authentication, sync, or backend.
- Calendar month navigation is presentational.
- The accepted Borg-inspired theme is the current theme, while production architecture remains themeable.
