# Heritage Field Notes palette research

Status: research recommendation, ready for Android concept work; display name
remains provisional until concept approval

## Decision

Heritage Field Notes should be a warm light theme that evokes a carefully kept
clinical field journal through warm stone/parchment content bays, forest ink,
walnut structure, muted brass indexing, and a restrained oxblood accent. It
must feel scholarly and durable, not rustic, faux-military, or like a literal
leather notebook. Stitch, tab, paper-fiber, and archival details belong only
in the high-resolution nine-slice housing and noninteractive chrome.

## Evidence and design inference

### First-party and institutional evidence

- The Library of Congress treats books, paper, and archival housings as
  distinct preservation materials and emphasizes preventive storage and
  careful handling. This supports a vocabulary of paper leaves, bindings,
  housings, and tabs rather than generic “vintage” distress. [Library of
  Congress Collections Care](https://www.loc.gov/preservation/care/index.html)
- Its paper guidance defines permanent paper through composition and
  durability requirements, not a particular cream color. Therefore parchment,
  ivory, and warm-stone hues in this proposal are aesthetic inferences, not a
  claim that archival paper has one canonical color. [Library of Congress
  Paper FAQ](https://www.loc.gov/preservation/about/faqs/paper.html)
- The National Park Service Museum Handbook separately covers curatorial care
  of paper, metal, and leather/skin objects. This supports the theme's layered
  material references while also arguing against collapsing everything into a
  simulated leather texture. [NPS Museum Handbook Part I](https://www.nps.gov/subjects/museums/mh1.htm)
- The Library of Congress notes that light can permanently alter the
  appearance and structure of paper, parchment, and dyed or undyed leather.
  The palette therefore presents controlled, clean materials rather than
  yellowed, damaged, or heavily faded artifacts. [Library of Congress,
  Limiting Light Damage](https://www.loc.gov/preservation/care/light.html)
- Flutter's `ColorScheme` defines role-based primary, secondary, tertiary,
  surface, outline, error, and matching `on*` colors. It specifically reserves
  `outlineVariant` for decorative boundaries where 3:1 is not required. The
  table below follows those roles rather than using material names as widget
  instructions. [Flutter `ColorScheme` API](https://api.flutter.dev/flutter/material/ColorScheme-class.html)

### Explicit design inference

Every proposed hex value is a **design inference**. No archival authority
publishes a canonical “parchment,” “walnut,” “brass,” “forest ink,” or
“oxblood” UI palette. Warm neutral surfaces evoke clean paper and stone;
forest provides the principal action/Clinical Session color; walnut provides
secondary structure; oxblood is a controlled contrasting accent; brass is an
index/highlight color. A blue-gray archival-ink role is introduced only where
Scheduled Hours and neutral information need to remain clearly distinct.

The theme must not reproduce stains, foxing, torn edges, red rot, corrosion,
or handwriting as decoration. The Library of Congress describes red rot as
deterioration and advises isolating affected books; it is not an aesthetic
target. [Library of Congress book repair guidance](https://guides.loc.gov/preserving-your-books/repairing)

## Accessibility method

The ratios below use WCAG 2.2's sRGB relative-luminance and contrast formula.
Standard Heritage Field Notes targets at least 4.5:1 for ordinary text and
3:1 for required control/state graphics. Enhanced accessibility lifts all
persistent text/state strokes toward 7:1 and adds redundant shape/pattern
cues. [WCAG 2.2 Contrast Minimum](https://www.w3.org/TR/WCAG22/#contrast-minimum),
[W3C Non-text Contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast)

Labels remain visible because W3C prohibits using color as the only visual
means of conveying meaning. [W3C Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color)

## Standard semantic tokens

Hex values are opaque sRGB unless an alpha is stated. “On” roles are paired
foregrounds and must not be substituted by a visually similar material hue.

### Core and component roles

| Token | Hex | Required use |
| --- | --- | --- |
| `canvas` / `surfaceContainerLow` | `#E9E0CD` | Warm-stone app background outside housings |
| `surfaceDim` / `surfaceSunken` | `#DED1B8` | Recessed journal/index regions |
| `surface` / `surfaceContainer` | `#F8F1E3` | Default parchment content bay |
| `surfaceContainerLowest` | `#FFFDF7` | Lightest input/read surface |
| `surfaceContainerHigh` / `surfaceRaised` | `#FFF9ED` | Cards and raised sheets |
| `surfaceContainerHighest` | `#E6D9C1` | Selected neutral layer |
| `surfaceBright` | `#FFFDF7` | Highest neutral surface |
| `onSurface` / `textPrimary` | `#231D17` | Primary ink/text/icons |
| `onSurfaceVariant` / `textSecondary` | `#50473B` | Secondary ink/text |
| `textMuted` | `#6D6253` | Metadata |
| `disabledForeground` | `#8B8172` | Disabled-only content, paired with semantics |
| `outline` | `#675D4C` | Functional boundaries |
| `outlineVariant` | `#B9AA8F` | Decorative rules/stitching only |
| `primary` | `#25543A` | Main action, active navigation, Clinical Session |
| `onPrimary` | `#FFFFFF` | Content on `primary` |
| `primaryContainer` | `#D3E5D3` | Lower-emphasis forest container |
| `onPrimaryContainer` | `#173623` | Content on `primaryContainer` |
| `secondary` | `#704A2E` | Walnut structure/secondary action |
| `onSecondary` | `#FFFFFF` | Content on `secondary` |
| `secondaryContainer` | `#E9D6C4` | Lower-emphasis walnut container |
| `onSecondaryContainer` | `#402817` | Content on `secondaryContainer` |
| `tertiary` | `#7B3041` | Oxblood contrasting accent |
| `onTertiary` | `#FFFFFF` | Content on `tertiary` |
| `tertiaryContainer` | `#F2D5DB` | Lower-emphasis oxblood container |
| `onTertiaryContainer` | `#501C29` | Content on `tertiaryContainer` |
| `focus` | `#1E6663` | Keyboard/accessibility focus ring; 3 px minimum |
| `selection` | `#C9DED1` | Selected-date fill |
| `onSelection` | `#173A29` | Selected-date content |
| `shadow` | `#2B2117` | Warm-neutral shadow source |
| `scrim` | `#231D17` at 54% | Modal scrim |
| `inverseSurface` | `#332B23` | Inverse notification surface |
| `onInverseSurface` | `#FFF9ED` | Content on inverse surface |
| `inversePrimary` | `#86C49E` | Forest action on inverse surface |
| `surfaceTint` | `#704A2E` | Optional low-alpha tonal elevation only |

### Clinical Calendar and operational roles

| Token | Hex | Container | Meaning |
| --- | --- | --- | --- |
| `clinicalSession` | `#25543A` | `#D3E5D3` | Clinical Session |
| `workShift` | `#7B3041` | `#F2D5DB` | Work Shift |
| `protectedDay` | `#806317` | `#F1E1AE` | Protected Day |
| `today` | `#1E6663` | `#C9DED1` | Today marker; separate from warnings |
| `scheduledSession` / `scheduledHours` | `#3F607A` | `#D7E2E8` | Scheduled Session or Scheduled Hours |
| `awaitingConfirmation` | `#806317` | `#F1E1AE` | Past session awaiting Student action |
| `completedSession` / `completedHours` | `#2D6143` | `#D3E5D3` | Completed Session or Completed Hours |
| `unscheduledHours` | `#806317` | `#F1E1AE` | Hours not yet scheduled |
| `overTargetHours` | `#704A2E` | `#E9D6C4` | Valid hours beyond target |
| `cancelledSession` | `#675D4C` | `#E1D9CA` | Cancelled Session retained in history |
| `missedSession` | `#922F35` | `#F1D4D3` | Missed Session retained in history |
| `success` / `syncCurrent` | `#2D6143` | `#D3E5D3` | Successful operation/current sync |
| `info` | `#3F607A` | `#D7E2E8` | Neutral information |
| `warning` / `syncOffline` | `#806317` | `#F1E1AE` | Caution/offline state |
| `error` / `syncFailed` / `scheduleConflict` | `#922F35` | `#F1D4D3` | Error, failed sync, Schedule Conflict |
| `syncing` | `#1E6663` | `#C9DED1` | Active synchronization |
| `syncIdle` | `#6D6253` | `#E6D9C1` | No active sync work |

## Required mappings and redundant cues

| Meaning | Standard presentation | Enhanced accessibility addition |
| --- | --- | --- |
| Clinical Session | Forest outline/fill + visible label | Medical-cross/calendar glyph + solid left tab |
| Work Shift | Oxblood outline/fill + visible label | Briefcase glyph + 45-degree stripe tab |
| Protected Day | Brass outline/fill + visible label | Shield glyph + dot-hatch tab |
| Scheduled Session | Blue-gray time chip + “Scheduled” | Clock glyph |
| Awaiting Confirmation | Brass chip + explicit phrase | Clock-alert glyph + double outline |
| Completed Session | Forest-green chip + “Completed” | Check-circle glyph |
| Cancelled Session | Walnut-gray chip + “Cancelled” | Strike-through header + ban glyph |
| Missed Session | Deep red chip + “Missed” | X-circle glyph + cross hatch |
| Selected date | Pale sage fill + dark date | 3 px inner forest ring plus outer light separation ring |
| Today | Teal outline/corner + visible/semantic “Today” | Center dot plus 3 px outline |
| Completed Hours | Forest progress arc/segment | Solid segment + check in legend |
| Scheduled Hours | Blue-gray arc/segment | Forward diagonal hatch |
| Unscheduled Hours | Brass arc/segment | Dotted segment |
| Over-Target Hours | Walnut outer arc | Separate thin outer rail + `+` label |
| Syncing/current/offline/failed | Teal/forest/brass/red plus status text | Spinner/check/cloud-off/error glyph respectively |

Do not rename Unscheduled Hours to Remaining Hours. Remaining Hours include
both Scheduled and Unscheduled Hours, while the brass segment is specifically
the portion not yet scheduled.

## Verified contrast results

Ratios are calculated results rounded to two decimals for reporting. Re-run automated
checks after gradients, antialiasing, alpha, and imagery are composed.

| Foreground / background | Ratio | Gate |
| --- | ---: | --- |
| `textPrimary` / `canvas` | 12.71:1 | AAA |
| `textPrimary` / `surface` | 14.83:1 | AAA |
| `textSecondary` / `surface` | 8.10:1 | AAA |
| `textMuted` / `surface` | 5.30:1 | AA body |
| `outline` / `surface` | 5.75:1 | UI 3:1 |
| `onPrimary` / `primary` | 8.72:1 | AAA |
| `onPrimaryContainer` / `primaryContainer` | 10.02:1 | AAA |
| `onSecondary` / `secondary` | 7.76:1 | AAA |
| `onSecondaryContainer` / `secondaryContainer` | 9.70:1 | AAA |
| `onTertiary` / `tertiary` | 8.97:1 | AAA |
| `onTertiaryContainer` / `tertiaryContainer` | 9.95:1 | AAA |
| `focus` / `surface` | 5.96:1 | UI 3:1 |
| `onSelection` / `selection` | 8.87:1 | AAA |
| Clinical / Work / Protected over `surface` | 7.76 / 7.98 / 5.03:1 | UI 3:1 |
| Completed / Scheduled / Unscheduled / Over-Target over `surface` | 6.44 / 5.90 / 5.03 / 6.90:1 | UI 3:1 |
| Cancelled / Missed over `surface` | 5.75 / 6.97:1 | UI 3:1 |
| Primary text over all state containers | 11.89–12.80:1 | AAA |
| Warning / Error / Success / Info over `surface` | 5.03 / 6.97 / 6.44 / 5.90:1 | UI 3:1 |

`outlineVariant` is 2.03:1 against `surface`. It is suitable only for
decorative rules/stitching and cannot identify a control, state, or focus.

## Enhanced accessibility overrides

The global Enhanced accessibility switch layers these changes over Heritage
Field Notes; it does not create another theme.

| Token/behavior | Standard | Enhanced |
| --- | --- | --- |
| `textMuted` | `#6D6253` (5.30:1 on surface) | `#50473B` (8.10:1) |
| `outline` | `#675D4C` (5.75:1) | `#50473B` (8.10:1) |
| `outlineVariant` | `#B9AA8F` decorative | `#675D4C` (5.75:1), still non-semantic |
| `focus` | `#1E6663` (5.96:1) | `#174F4D` (8.26:1) plus 1 px light separation ring |
| Protected/Unscheduled/Warning | `#806317` (5.03:1) | `#624A0D` (7.46:1) |
| Completed/Success | `#2D6143` (6.44:1) | `#25543A` (7.76:1) |
| Scheduled/Info | `#3F607A` (5.90:1) | `#304F67` (7.66:1) |
| Over-Target | `#704A2E` (6.90:1) | `#6B452A` (7.44:1) |
| Missed/Error | `#922F35` (6.97:1) | `#862A30` (7.83:1) |
| Calendar/progress states | Label + color | Add the glyph/pattern mappings above |
| Housing decoration | Full approved static housing | Remove paper grain near content and reduce nonsemantic brass detail by 50% |

Android text scaling and system accessibility settings remain active in both
modes; the global toggle must never suppress them.

## Prohibited combinations and drift controls

- Never use `outlineVariant #B9AA8F` as the sole visible edge of a field,
  button, selection, or calendar state.
- Never set body text in `protectedDay #806317`, forest, oxblood, or blue-gray
  over the matching pale container without using the tested `on*` text color.
- Never use oxblood/red alone to distinguish Work Shift from Missed Session;
  labels and different glyph/pattern cues are mandatory.
- Never use brass alone for both Protected Day and warning. Protected Day uses
  a shield/dot language; warning uses an alert glyph and explicit wording.
- Never put faux parchment grain, handwriting, ruled lines, stitch holes,
  walnut texture, brass reflections, stains, or distressed edges behind live
  text, calendar cells, charts, fields, or controls.
- Never simulate red rot, foxing, torn paper, corrosion, camouflage, tactical
  webbing, or military insignia.
- Never use a literal leather notebook page curl, binding animation, or noisy
  skeuomorphic control. Material references remain housing-only and static.
- Never reuse or recolor Containment Drone 47-Alpha's nine-slice asset.

## Concept acceptance checklist

The Android concept is ready for approval only when the Calendar dashboard and
Theme-gallery card demonstrate the complete semantic map; the housing feels
scholarly and durable without military/rustic drift; all live content sits on
flat, high-contrast bays; standard and Enhanced accessibility treatments are
both shown; and rendered/composited contrast is rechecked. Finalize or replace
the display name only after that concept is visible.
