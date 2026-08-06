# Coastal Calm semantic palette research

Research date: 2026-08-05

## Recommendation

Use an airy, light palette built from shell white, mist blue, sea-glass teal, warm sand, and one controlled coral signal. The interface should feel clean and restorative through layered cool surfaces and generous quiet space, without waves, shells, beach icons, or vacation imagery.

Every hex value below is an **original, accessibility-calibrated design inference for Clinical Calendar**. No source cited here defines an official “Coastal Calm” palette.

## Source rationale

- NOAA explains that shallow water and suspended sediment can appear light blue in true-color imagery, while the National Park Service documents white quartz-rich sand and shell/calcium-carbonate beaches. Those first-party observations support mist blue, shell white, and warm mineral neutrals as a coherent material vocabulary. ([NOAA/NESDIS](https://www.nesdis.noaa.gov/news/viirs-sees-irma-churned-sediments-around-florida-bahamas), [National Park Service coastal sediments](https://home.nps.gov/articles/coastal-sediments-sand-colors.htm))
- An NPS account of Acadia's Sand Beach explicitly describes deep blue water rimmed with white, blond beach grass, and multicolored shell/rock material. This supports a restrained blue-white-sand range without implying that one exact coastal palette is universal. ([National Park Service](https://home.nps.gov/articles/sand-beach-in-winter.htm))
- NOAA notes that coral color comes from symbiotic algae and shows coral environments with a broad color range. A sparse coral accent is therefore an atmospheric design inference, not a claim that coral reefs have one canonical coral-pink value. ([NOAA coral color](https://oceanservice.noaa.gov/education/tutorial_corals/media/supp_coral02d.html), [NOAA soft corals](https://oceanservice.noaa.gov/education/tutorial_corals/media/supp_coral03c.html))
- USWDS publishes graduated mint-cool and blue-cool color families and recommends a small, role-based subset chosen for project needs. Android likewise recommends role-based colors, tonal surfaces, limited semantic complexity, sufficient contrast, and non-color affordances. ([USWDS system tokens](https://designsystem.digital.gov/design-tokens/color/system-tokens/), [USWDS color guidance](https://designsystem.digital.gov/design-tokens/color/overview/), [Android color guidance](https://developer.android.com/design/ui/mobile/guides/styles/color), [Android accessibility guidance](https://developer.android.com/design/ui/mobile/guides/foundations/accessibility))
- WCAG 2.2 supplies the measurable floor: 4.5:1 for ordinary text, 3:1 for large text and necessary non-text boundaries, and information must not depend on hue alone; enhanced ordinary text uses 7:1. ([WCAG 2.2](https://www.w3.org/TR/WCAG22/#contrast-minimum), [Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color), [Non-text Contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast), [Contrast Enhanced](https://www.w3.org/WAI/WCAG22/Understanding/contrast-enhanced))

**Design inference:** shell white and mist surfaces establish calm; sea-glass teal anchors Clinical activity; clear blue distinguishes Work Shifts; warm sand marks protected/rest time; coral is reserved for urgent attention and focus. Smooth layered forms may appear in the nine-slice housing only. Content bays remain flat and motif-free.

## Complete semantic token table

| Token | Hex | Intended use |
|---|---:|---|
| `canvas` | `#EEF5F4` | App background / mist field |
| `housing-base` | `#C8DEDD` | Nine-slice sea-glass housing base |
| `housing-shadow` | `#4B686F` | Housing depth only; never a content fill |
| `surface` | `#FFFCF6` | Shell-white content bays, dialogs, calendar cells |
| `surface-alt` | `#E6F1F2` | Secondary panes and table bands |
| `surface-raised` | `#F4EBDD` | Raised cards / warm mineral layer |
| `border` | `#687E80` | Necessary component boundaries |
| `divider` | `#AABDBD` | Nonessential separators |
| `text-primary` | `#18343C` | Body and heading text |
| `text-secondary` | `#4C6268` | Supporting text |
| `text-inverse` | `#FFFFFF` | Text/icons on dark accents |
| `primary` | `#1F6F68` | Primary action and Clinical identity |
| `primary-container` | `#DDEEEA` | Low-emphasis teal container |
| `on-primary` | `#FFFFFF` | Text/icons on `primary` |
| `on-primary-container` | `#173B38` | Text/icons on `primary-container` |
| `secondary` | `#2F6584` | Secondary action / clear-water blue |
| `secondary-container` | `#DFEBF2` | Low-emphasis blue container |
| `on-secondary` | `#FFFFFF` | Text/icons on `secondary` |
| `on-secondary-container` | `#1E3848` | Text/icons on `secondary-container` |
| `selected-surface` | `#D7E9ED` | Selected date/card fill |
| `selected-border` | `#2F6584` | Selected outline |
| `focus-ring` | `#A13E32` | Controlled coral focus outline |
| `disabled-surface` | `#E2E8E7` | Inactive controls |
| `disabled-content` | `#6B7777` | Inactive label/icon only |
| `clinical-surface` | `#DDEEEA` | Clinical Session event background |
| `clinical-accent` | `#1F6F68` | Clinical Session rail/icon/border |
| `clinical-content` | `#173B38` | Clinical Session label/time |
| `work-surface` | `#DFEBF2` | Work Shift event background |
| `work-accent` | `#2F6584` | Work Shift rail/icon/border |
| `work-content` | `#1E3848` | Work Shift label/time |
| `protected-surface` | `#F0E7D5` | Protected Day warm-sand background |
| `protected-accent` | `#7A653F` | Protected Day outline/shield |
| `protected-content` | `#423721` | Protected Day label |
| `progress-target` | `#687E80` | Target/reference ring or track |
| `progress-completed` | `#1F6F68` | Completed Hours |
| `progress-scheduled` | `#805515` | Scheduled Hours |
| `progress-unscheduled` | `#A13E32` | Unscheduled Hours requiring attention |
| `progress-over-target` | `#5A597B` | Over-Target Hours / deep horizon violet |
| `status-success` | `#1F6F68` | Successful save/synchronization |
| `status-info` | `#2F6584` | Informational and active synchronization state |
| `status-warning` | `#805515` | Offline, queued, or deadline attention |
| `status-error` | `#A13E32` | Error, destructive action, Schedule Conflict |
| `status-on-color` | `#FFFFFF` | Text/icons on any dark status fill |

## Calendar-state mapping

| State | Color mapping | Required non-color cue |
|---|---|---|
| Clinical Session | `clinical-surface/accent/content` | Medical-services icon plus visible “Clinical Session” label |
| Scheduled Session | Clinical mapping | Clock badge and solid left rail |
| Completed Session | Clinical mapping | Check badge and “Completed” text |
| Cancelled Session | `surface-alt`, `text-secondary`, `border` | Slash/cancel icon and “Cancelled” text |
| Missed Session | `surface-alt`, `status-error`, `text-primary` | Missed-event icon and “Missed” text |
| Work Shift | `work-surface/accent/content` | Work icon plus visible “Work Shift” label |
| Protected Day | `protected-surface/accent/content` | Shield icon, full-cell outline, and visible “Protected Day” label |
| Today | `surface` with `status-error` inset marker | “Today” text or accessible current-date semantics |
| Selected date | `selected-surface` + `selected-border` | Persistent 2 px outline and selected semantics |
| Schedule Conflict | `status-error` on `surface` | Conflict icon, explicit message, and error semantics |
| Outside month / unavailable | `surface-alt` + `disabled-content` | Reduced emphasis plus unavailable/disabled semantics |

## Progress and synchronization mapping

| Meaning | Color | Required companion |
|---|---:|---|
| Target/reference | `#687E80` | Labeled outer track / target value |
| Completed Hours | `#1F6F68` | Solid segment + check in legend |
| Scheduled Hours | `#805515` | Diagonal segment + clock in legend |
| Unscheduled Hours | `#A13E32` | Dotted segment + open-calendar icon in legend |
| Over-Target Hours | `#5A597B` | Crosshatched outer segment + explicit value |
| Synchronized | `#1F6F68` | Check icon + “Synchronized” |
| Synchronizing | `#2F6584` | Motion from shared app behavior + “Synchronizing” |
| Queued/offline | `#805515` | Queue/cloud-off icon + explanatory text |
| Synchronization error/conflict | `#A13E32` | Error/conflict icon + actionable text |

## Verified contrast results

Ratios were calculated from the WCAG sRGB relative-luminance formula using the opaque hex values above. Threshold comparisons must use unrounded values in implementation tests.

| Foreground on background | Ratio |
|---|---:|
| `text-primary` on `surface` | 12.85:1 |
| `text-secondary` on `surface` | 6.30:1 |
| `text-primary` on `canvas` | 11.91:1 |
| `border` on `surface` | 4.20:1 |
| `on-primary` on `primary` | 5.95:1 |
| `on-secondary` on `secondary` | 6.33:1 |
| `clinical-content` on `clinical-surface` | 10.18:1 |
| `clinical-accent` on `clinical-surface` | 4.95:1 |
| `work-content` on `work-surface` | 10.09:1 |
| `work-accent` on `work-surface` | 5.22:1 |
| `protected-content` on `protected-surface` | 9.50:1 |
| `protected-accent` on `protected-surface` | 4.55:1 |
| `selected-border` on `selected-surface` | 5.06:1 |
| `focus-ring` on `surface` | 6.31:1 |
| `focus-ring` on `canvas` | 5.85:1 |
| `status-warning` on `surface` | 6.35:1 |
| `status-error` on `surface` | 6.31:1 |
| `status-info` on `surface` | 6.19:1 |
| `status-on-color` on `status-success` | 5.95:1 |
| `status-on-color` on `status-info` | 6.33:1 |
| `status-on-color` on `status-warning` | 6.51:1 |
| `status-on-color` on `status-error` | 6.46:1 |

The specified standard pairs clear AA and the 3:1 non-text boundary target. Final rendered Android screens must be remeasured because opacity, blending, gradients, anti-aliasing, and artwork can change effective contrast.

## Enhanced accessibility overrides

Enhanced accessibility is an optional layer over Coastal Calm, not a separate theme.

| Token | Standard | Enhanced |
|---|---:|---:|
| `canvas` | `#EEF5F4` | `#FFFCF6` |
| `text-primary` | `#18343C` | `#102A31` |
| `text-secondary` | `#4C6268` | `#3E5359` |
| `border` | `#687E80` | `#4F6669` |
| `selected-border` | `#2F6584` | `#214F6A` |
| `focus-ring` | `#A13E32` | `#7E281F` |

- Target at least 7:1 for ordinary active text and 4.5:1 for essential boundaries in final rendered screens. Enhanced `text-secondary` on `surface` is 7.93:1 and enhanced `border` on `surface` is 5.97:1.
- Increase selection and focus outlines to at least 3 px; use a two-color ring wherever focus crosses variable backgrounds. ([W3C Focus Appearance](https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html))
- Always show category icons and labels. Add patterns to progress: completed solid, scheduled diagonal, unscheduled dotted, over-target crosshatched.
- Suppress glass-like translucency, housing texture, atmospheric gradients, and low-contrast dividers in enhanced mode. System text scaling is always honored independently.

## Prohibited pairings and treatments

- Do not use pale mist, sea-glass, sand, or shell colors as ordinary-size text on `surface`; use `text-primary` or `text-secondary`.
- Do not use `divider` as the sole boundary of a control; use `border`.
- Do not use coral decoratively throughout the interface. `#A13E32` is reserved for focus, urgent attention, errors, conflicts, destructive actions, and Unscheduled Hours.
- Do not place white text on warm sand, mist blue, or pale teal containers.
- Do not distinguish Clinical Sessions, Work Shifts, Protected Days, progress, lifecycle, or synchronization states by hue alone.
- Do not place waves, shells, beach photographs, water texture, glass blur, or weathered texture behind calendar data or controls. Decorative treatment is limited to the nine-slice housing and noninteractive chrome.
- Do not use transparency for semantic colors without recomputing contrast against every actual background.

## Decision

Advance this palette to the Android-tablet Calendar and Theme-gallery-card concept stage. “Coastal Calm” remains a working title until visual approval.
