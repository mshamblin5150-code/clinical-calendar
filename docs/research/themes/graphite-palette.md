# Graphite palette research

Status: research recommendation, ready for Android concept work

## Decision

Graphite should be a deliberately dark, mineral-neutral theme whose brand
continuity comes from the existing launcher master: near-black graphite,
layered charcoal, cool silver, and one restrained green-teal signal. It should
not borrow Containment Drone 47-Alpha's mechanical housing or its visual
language. Graphite is the neutral default for a new Student profile and the
fixed presentation for the signed-out in-app email/code verification surface.
It does **not** style the email message itself. A signed-in Student's saved
theme remains authoritative.

The palette below is implementation-ready for the Android concept. The exact
housing texture and typography remain concept decisions.

## Evidence and design inference

### First-party evidence

- The repository's [launcher master](../../../apps/clinical_calendar/assets/branding/clinical_calendar_app_icon_master.png)
  is a 1280 px square image built from black/charcoal housings, silver metal,
  and a very small emerald-teal indicator. A 16-color median-cut inspection of
  the local file places the dominant dark families around `#0E1013`,
  `#15161B`, `#1F2025`, `#232529`, and `#282A2E`; the bright neutral family is
  around `#DFDFE1`. These measurements are local evidence, not a claim that
  the raster has an authored source palette.
- The first-party [icon generation script](../../../tool/branding/generate_app_icons.py)
  derives Android, iOS, and Windows icons from that single master. Graphite can
  therefore align to a stable product artifact rather than inventing a second
  signed-out identity.
- The U.S. Geological Survey describes graphite as gray to black, opaque, and
  metallic in luster. That supports the dark neutral/silver material premise;
  it does not prescribe UI hex values. [USGS Graphite Statistics and
  Information](https://www.usgs.gov/centers/national-minerals-information-center/graphite-statistics-and-information)
- Flutter's `ColorScheme` assigns neutral roles to surfaces, primary to key
  controls and active states, secondary to lower-emphasis components, and
  tertiary to contrasting accents. It also expects readable `on*` partners and
  distinguishes `outline` (functional boundary) from `outlineVariant`
  (decorative boundary). [Flutter `ColorScheme` API](https://api.flutter.dev/flutter/material/ColorScheme-class.html)
- Android's Material 3 guidance similarly treats primary, secondary, and
  tertiary as roles rather than arbitrary decoration and warns that custom
  roles must not be mismatched. [Android Material 3 color usage](https://developer.android.com/develop/ui/compose/designsystems/material3#color_scheme)

### Explicit design inference

The teal and cobalt values below are **design inferences** from the launcher,
not sampled brand constants. The launcher's green indicator is too small and
too heavily shaded to serve as a flat UI token. `#37D6B4` retains its
green-teal signal while being bright enough for controls on charcoal;
`#72B7FF` introduces the requested restrained cobalt family for Clinical
Session and informational semantics. Cool violet is confined to Work Shift
and Over-Target Hours so Graphite does not drift into Federation 2399's
plum-led identity.

Texture is also an inference: a fine mineral grain may appear only in the
nine-slice housing/noninteractive chrome. Content surfaces stay flat so the
calendar remains measurable and calm.

## Accessibility method

All ratios below were calculated from the sRGB relative-luminance and contrast
formula in WCAG 2.2. Standard Graphite targets at least 4.5:1 for ordinary
text and 3:1 for required control/state graphics; Enhanced accessibility
raises persistent text to 7:1 where practical and adds non-color cues. WCAG
requires 4.5:1 for ordinary text, 3:1 for large text, and 3:1 for required
non-text UI information. [WCAG 2.2 contrast requirements](https://www.w3.org/TR/WCAG22/#contrast-minimum),
[W3C non-text contrast explanation](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast)

Contrast alone does not make hue-coded calendar meaning sufficient. W3C says
color must not be the only visual means of conveying state, so labels remain
mandatory in standard mode and Enhanced accessibility adds icons/patterns.
[W3C Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color)

## Standard semantic tokens

Hex values are opaque sRGB unless an alpha is stated. “On” roles are paired
foregrounds, not interchangeable accent colors.

### Core and component roles

| Token | Hex | Required use |
| --- | --- | --- |
| `canvas` / `surfaceContainerLowest` | `#0D1013` | App background and signed-out verification backdrop |
| `surfaceDim` / `surfaceSunken` | `#090B0D` | Recessed bays only |
| `surface` | `#151A1F` | Default content bay and form surface |
| `surfaceContainerLow` | `#12171B` | Low-emphasis grouped region |
| `surfaceContainer` / `surfaceRaised` | `#1C2329` | Cards, verification card |
| `surfaceContainerHigh` | `#222A31` | Hover/pressed-neutral layer |
| `surfaceContainerHighest` | `#29333B` | Selected neutral layer |
| `surfaceBright` | `#303A43` | Highest neutral emphasis; never body-text foreground |
| `onSurface` / `textPrimary` | `#F4F6F7` | Primary text and icons |
| `onSurfaceVariant` / `textSecondary` | `#C2CBD1` | Secondary text |
| `textMuted` | `#98A4AD` | Metadata; not disabled-state meaning |
| `disabledForeground` | `#737E87` | Disabled-only content, always with disabled semantics |
| `outline` | `#6F7C86` | Input, control, and selected-item boundaries |
| `outlineVariant` | `#3E4851` | Decorative dividers only |
| `primary` | `#37D6B4` | Main action, active navigation, syncing |
| `onPrimary` | `#06251E` | Text/icon on `primary` |
| `primaryContainer` | `#12483D` | Lower-emphasis teal container |
| `onPrimaryContainer` | `#C8FFF2` | Content on `primaryContainer` |
| `secondary` | `#72B7FF` | Informational/cobalt accent |
| `onSecondary` | `#08243E` | Content on `secondary` |
| `secondaryContainer` | `#173C5D` | Lower-emphasis cobalt container |
| `onSecondaryContainer` | `#DAEBFF` | Content on `secondaryContainer` |
| `tertiary` | `#C69BFF` | Rare violet accent |
| `onTertiary` | `#27123D` | Content on `tertiary` |
| `tertiaryContainer` | `#43265D` | Lower-emphasis violet container |
| `onTertiaryContainer` | `#F1E3FF` | Content on `tertiaryContainer` |
| `focus` | `#FFD166` | Keyboard/accessibility focus ring; 3 px minimum |
| `selection` | `#1E6557` | Selected-date fill |
| `onSelection` | `#E6FFF9` | Selected-date content |
| `shadow` | `#000000` | Shadow source only |
| `scrim` | `#000000` at 72% | Modal scrim |
| `inverseSurface` | `#E3E8EB` | Inverse notification surface |
| `onInverseSurface` | `#172027` | Content on inverse surface |
| `inversePrimary` | `#006B57` | Teal action on inverse surface |
| `surfaceTint` | `#37D6B4` | Optional low-alpha tonal elevation only |

### Clinical Calendar and operational roles

| Token | Hex | Container | Meaning |
| --- | --- | --- | --- |
| `clinicalSession` | `#70BFFF` | `#173F61` | Clinical Session |
| `workShift` | `#CF9DFF` | `#492A61` | Work Shift |
| `protectedDay` | `#F2C96D` | `#4B3B16` | Protected Day |
| `today` | `#37D6B4` | `#12483D` | Today marker; never warning/error |
| `scheduledSession` / `scheduledHours` | `#72B7FF` | `#173C5D` | Scheduled Session or Scheduled Hours |
| `awaitingConfirmation` | `#F5C86B` | `#4B3912` | Past session awaiting Student action |
| `completedSession` / `completedHours` | `#55D9A6` | `#164A39` | Completed Session or Completed Hours |
| `unscheduledHours` | `#F2C96D` | `#4B3B16` | Hours not yet scheduled |
| `overTargetHours` | `#C69BFF` | `#43265D` | Valid hours beyond target |
| `cancelledSession` | `#A8B0B7` | `#343B41` | Cancelled Session retained in history |
| `missedSession` | `#FF958A` | `#57272A` | Missed Session retained in history |
| `success` / `syncCurrent` | `#55D9A6` | `#164A39` | Successful operation/current sync |
| `info` | `#73BCFF` | `#173E5D` | Neutral information |
| `warning` / `syncOffline` | `#F5C86B` | `#4B3912` | Caution/offline state |
| `error` / `syncFailed` / `scheduleConflict` | `#FF8D86` | `#5A2428` | Error, failed sync, Schedule Conflict |
| `syncing` | `#37D6B4` | `#12483D` | Active synchronization |
| `syncIdle` | `#98A4AD` | `#29333B` | No active sync work |

## Required mappings and redundant cues

| Meaning | Standard presentation | Enhanced accessibility addition |
| --- | --- | --- |
| Clinical Session | Cobalt outline/fill + visible “Clinical Session” label | Medical-cross/calendar glyph + solid left rail |
| Work Shift | Violet outline/fill + visible “Work Shift” label | Briefcase glyph + 45-degree stripe rail |
| Protected Day | Brass outline/fill + visible “Protected Day” label | Shield glyph + dot-hatch rail |
| Scheduled Session | Cobalt time chip + “Scheduled” | Clock glyph |
| Awaiting Confirmation | Amber chip + explicit phrase | Clock-alert glyph + double outline |
| Completed Session | Green chip + “Completed” | Check-circle glyph |
| Cancelled Session | Gray chip + “Cancelled” | Strike-through header + ban glyph |
| Missed Session | Coral chip + “Missed” | X-circle glyph + cross hatch |
| Selected date | Teal filled cell with date text | 3 px inner/outer selection ring |
| Today | Teal corner/outline + “Today” in semantics/expanded views | Center dot plus 3 px outline; never red |
| Completed Hours | Green progress arc/segment | Solid segment + check in legend |
| Scheduled Hours | Cobalt progress arc/segment | Forward diagonal hatch |
| Unscheduled Hours | Brass progress arc/segment | Dotted segment |
| Over-Target Hours | Violet outer arc | Separate thin outer rail + `+` label |
| Syncing/current/offline/failed | Teal/green/amber/coral plus status text | Spinner/check/cloud-off/error glyph respectively |

The progress wheel must preserve the domain distinction: Remaining Hours are
the target minus Completed Hours; Unscheduled Hours are the target minus both
Completed and Scheduled Hours. Do not label the brass segment “Remaining.”

## Verified contrast results

Ratios are calculated results rounded to two decimals for reporting; prototypes should
re-run automated checks against rendered/alpha-composited colors.

| Foreground / background | Ratio | Gate |
| --- | ---: | --- |
| `textPrimary` / `canvas` | 17.60:1 | AAA |
| `textPrimary` / `surface` | 16.15:1 | AAA |
| `textSecondary` / `surface` | 10.64:1 | AAA |
| `textMuted` / `surface` | 6.88:1 | AA body |
| `outline` / `surface` | 4.09:1 | UI 3:1 |
| `primary` / `surface` | 9.54:1 | AAA if used as text |
| `onPrimary` / `primary` | 8.86:1 | AAA |
| `onPrimaryContainer` / `primaryContainer` | 9.43:1 | AAA |
| `onSecondary` / `secondary` | 7.46:1 | AAA |
| `onTertiary` / `tertiary` | 7.69:1 | AAA |
| `focus` / `canvas` | 13.23:1 | UI 3:1 |
| `focus` / `surfaceContainerHighest` | 9.56:1 | UI 3:1 |
| `onSelection` / `selection` | 6.56:1 | AA body |
| Clinical / Work / Protected accents over `surface` | 8.83 / 8.27 / 11.13:1 | UI 3:1 |
| Completed / Scheduled / Unscheduled / Over-Target over `surface` | 9.89 / 8.28 / 11.13 / 7.95:1 | UI 3:1 |
| Cancelled / Missed over `surface` | 7.97 / 8.27:1 | UI 3:1 |
| White primary text over all six state containers | 9.35–11.20:1 | AAA |
| Warning / Error / Success / Info over `surface` | 11.14 / 7.84 / 9.89 / 8.64:1 | UI 3:1 |

`outlineVariant` is only 1.88:1 against `surface`; that is intentional only
for decorative separators. It cannot identify an input, control, focus,
selection, or state.

## Enhanced accessibility overrides

The global Enhanced accessibility switch does not create an eighth theme.
Apply these deterministic overrides on top of Graphite:

| Token/behavior | Standard | Enhanced |
| --- | --- | --- |
| `textMuted` | `#98A4AD` (6.88:1 on surface) | `#B8C2CA` (9.68:1) |
| `outline` | `#6F7C86` (4.09:1) | `#98A4AD` (6.88:1) |
| `outlineVariant` | `#3E4851` decorative | `#6F7C86` (4.09:1), still non-semantic |
| `selection` / `onSelection` | `#1E6557` / `#E6FFF9` (6.56:1) | `#154B40` / `#F4F6F7` (9.17:1) |
| Focus | 2–3 px product default | 3 px `#FFD166` plus 1 px dark separation ring |
| Calendar/progress states | Label + color | Add the glyph/pattern mappings above |
| Housing decoration | Full approved static housing | Remove grain behind/near content and dim nonsemantic lights by 50% |

Android text scaling and system accessibility settings remain respected in
both modes; the toggle must not gate those platform behaviors.

## Signed-out in-app verification contract

The existing [passwordless sign-in surface](../../../packages/clinical_calendar_presentation/lib/src/identity/passwordless_sign_in_surface.dart)
contains the email request and one-time-code verification stages in one card.
For both stages, use `canvas` for the screen, `surfaceContainer` for the card,
`surface` for fields, `outline` for input boundaries, `primary/onPrimary` for
the main action, `error/errorContainer` for failures, and the launcher mark or
existing calendar glyph in silver/teal. Do not load a Student theme before
authentication and do not theme the delivered email HTML.

## Prohibited combinations and drift controls

- Never use `outlineVariant #3E4851` as the sole visible boundary of a control.
- Never put `primary #37D6B4`, cobalt, violet, amber, or coral body text on the
  matching bright accent; use the defined `on*` partner.
- Never use teal alone to mean both Today and success without a label/icon.
- Never use red/coral for Today; reserve it for Missed, error, failed sync, or
  Schedule Conflict semantics.
- Never put `missedSession #FF958A` or oxblood-like tones on `canvas` as small
  unlabelled marks; protanopia can weaken red-on-black distinctions, and W3C
  explicitly advises against relying on predominantly long-wavelength colors
  against dark colors. [W3C enhanced-contrast rationale](https://www.w3.org/WAI/WCAG22/Understanding/contrast-enhanced.html)
- Never use violet as a large ambient wash. That would collapse Graphite into
  Federation 2399; violet is a rare domain accent only.
- Never import, recolor, or modify Containment Drone 47-Alpha's raster housing.
- Never place mineral grain, metallic highlights, gradients, or launcher-style
  reflections behind calendar data, text, fields, or controls.
- Never apply Graphite styling to the actual one-time-code email message.

## Concept acceptance checklist

The Android concept is ready for approval only when it shows the Calendar
dashboard and Theme-gallery card, plus the signed-out email-entry and
code-verification states; visibly aligns with the launcher without imitating
Containment Drone; uses every domain mapping above; demonstrates standard and
Enhanced accessibility; and re-verifies all composited contrast pairs.
