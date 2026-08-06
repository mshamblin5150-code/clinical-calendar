# Botanical Study semantic palette research

Research date: 2026-08-05

## Recommendation

Use a warm, light academic palette: ivory and paper-like surfaces, eucalyptus/sage as the primary clinical color, dusty rose for Work Shifts, pale orchid for Protected Days, and deep aubergine for text, selection, and over-target emphasis. The result should read as a contemporary botanical study desk, not floral wallpaper.

Every hex value below is an **original, accessibility-calibrated design inference for Clinical Calendar**. No source cited here defines an official “Botanical Study” palette.

## Source rationale

- Kew's official description of its Stella Ross-Craig display places monochrome and color botanical illustrations alongside reference specimens, printed volumes, archival material, and drawing equipment. That supports an academic illustration-and-specimen direction rather than decorative florals. ([Royal Botanic Gardens, Kew](https://www.kew.org/kew-gardens/whats-on/flora-dissected))
- The U.S. Web Design System (USWDS) treats color as role-based project tokens selected from a limited number of color families, and its official system palette includes graduated green and red-cool families. Its grade model ties light/dark separation to predictable contrast. This supports using restrained sage and rose families while assigning values by function, not by plant name. ([USWDS color guidance](https://designsystem.digital.gov/design-tokens/color/overview/), [USWDS system tokens](https://designsystem.digital.gov/design-tokens/color/system-tokens/))
- Android's first-party guidance says schemes should map colors to roles, use surface space to contain content, avoid similar-tone pairings, and never make color the only affordance. It also recommends at least 4.5:1 for text and 3:1 for non-text elements. ([Android color guidance](https://developer.android.com/design/ui/mobile/guides/styles/color), [Android accessibility guidance](https://developer.android.com/design/ui/mobile/guides/foundations/accessibility))
- WCAG 2.2 requires 4.5:1 for ordinary text, 3:1 for large text and necessary non-text UI boundaries, and a non-color means of conveying information. Its enhanced-text criterion uses 7:1 for ordinary text. ([WCAG 2.2](https://www.w3.org/TR/WCAG22/#contrast-minimum), [Use of Color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color), [Non-text Contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast), [Contrast Enhanced](https://www.w3.org/WAI/WCAG22/Understanding/contrast-enhanced))

**Design inference:** warm ivory recalls paper; sage/eucalyptus recalls specimens; dusty rose and orchid recall restrained color plates; aubergine supplies the dark tonal anchor needed for sustained reading. Botanical line work belongs only in the nine-slice housing and noninteractive chrome. Content bays remain flat, quiet, and motif-free.

## Complete semantic token table

The `on-*` token is the only text/icon color approved for its paired container unless a separately tested pairing appears below.

| Token | Hex | Intended use |
|---|---:|---|
| `canvas` | `#F4EFE6` | App background / warm ivory field |
| `housing-base` | `#D8DED2` | Nine-slice botanical housing base |
| `housing-shadow` | `#75666F` | Housing depth only; never a content fill |
| `surface` | `#FFFDF8` | Primary content bays, dialogs, calendar cells |
| `surface-alt` | `#F8F3EA` | Secondary panes and table bands |
| `surface-raised` | `#F1E9E4` | Cards and floating controls |
| `border` | `#8A7D72` | Necessary component boundaries |
| `divider` | `#B5AAA0` | Nonessential separators; not a sole control boundary |
| `text-primary` | `#33212F` | Body and heading text |
| `text-secondary` | `#655665` | Supporting text |
| `text-inverse` | `#FFFFFF` | Text/icons on dark accents |
| `primary` | `#496B55` | Primary action and Clinical identity |
| `primary-container` | `#E1EBDD` | Low-emphasis primary container |
| `on-primary` | `#FFFFFF` | Text/icons on `primary` |
| `on-primary-container` | `#263529` | Text/icons on `primary-container` |
| `secondary` | `#815165` | Secondary action / dusty rose accent |
| `secondary-container` | `#F1DFE7` | Low-emphasis rose container |
| `on-secondary` | `#FFFFFF` | Text/icons on `secondary` |
| `on-secondary-container` | `#3E2832` | Text/icons on `secondary-container` |
| `selected-surface` | `#E9D8E3` | Selected date/card fill |
| `selected-border` | `#6B3D67` | Selected outline and aubergine emphasis |
| `focus-ring` | `#6B3D67` | Keyboard/directional focus outline |
| `disabled-surface` | `#E6E0DC` | Inactive controls |
| `disabled-content` | `#786F74` | Inactive label/icon only |
| `clinical-surface` | `#E1EBDD` | Clinical Session event background |
| `clinical-accent` | `#496B55` | Clinical Session rail/icon/border |
| `clinical-content` | `#263529` | Clinical Session label/time |
| `work-surface` | `#F1DFE7` | Work Shift event background |
| `work-accent` | `#815165` | Work Shift rail/icon/border |
| `work-content` | `#3E2832` | Work Shift label/time |
| `protected-surface` | `#ECE8F0` | Protected Day background |
| `protected-accent` | `#655A73` | Protected Day outline/shield |
| `protected-content` | `#332D3A` | Protected Day label |
| `progress-target` | `#8A7D72` | Target/reference ring or track |
| `progress-completed` | `#496B55` | Completed Hours |
| `progress-scheduled` | `#805B16` | Scheduled Hours |
| `progress-unscheduled` | `#A63D4E` | Unscheduled Hours requiring attention |
| `progress-over-target` | `#5E4776` | Over-Target Hours |
| `status-success` | `#496B55` | Successful save/synchronization |
| `status-info` | `#4F627D` | Informational and active synchronization state |
| `status-warning` | `#805B16` | Offline, queued, or deadline attention |
| `status-error` | `#A63D4E` | Error, destructive action, Schedule Conflict |
| `status-on-color` | `#FFFFFF` | Text/icons on any dark status fill |

## Calendar-state mapping

| State | Color mapping | Required non-color cue |
|---|---|---|
| Clinical Session | `clinical-surface/accent/content` | Medical-services icon plus visible “Clinical Session” label |
| Scheduled Session | Clinical mapping | Clock badge and solid left rail |
| Completed Session | Clinical mapping | Check badge and “Completed” text; do not signal completion by darkening alone |
| Cancelled Session | `surface-alt`, `text-secondary`, `border` | Slash/cancel icon and “Cancelled” text |
| Missed Session | `surface-alt`, `status-error`, `text-primary` | Missed-event icon and “Missed” text |
| Work Shift | `work-surface/accent/content` | Work icon plus visible “Work Shift” label |
| Protected Day | `protected-surface/accent/content` | Shield icon, full-cell outline, and visible “Protected Day” label |
| Today | `surface` with `status-error` inset marker | “Today” text or accessible current-date semantics; never coral fill alone |
| Selected date | `selected-surface` + `selected-border` | Persistent 2 px outline and selected semantics |
| Schedule Conflict | `status-error` on `surface` | Conflict icon, explicit message, and error semantics |
| Outside month / unavailable | `surface-alt` + `disabled-content` | Reduced emphasis plus unavailable/disabled semantics |

## Progress and synchronization mapping

| Meaning | Color | Required companion |
|---|---:|---|
| Target/reference | `#8A7D72` | Labeled outer track / target value |
| Completed Hours | `#496B55` | Solid segment + check in legend |
| Scheduled Hours | `#805B16` | Diagonal segment + clock in legend |
| Unscheduled Hours | `#A63D4E` | Dotted segment + open-calendar icon in legend |
| Over-Target Hours | `#5E4776` | Crosshatched outer segment + explicit value |
| Synchronized | `#496B55` | Check icon + “Synchronized” |
| Synchronizing | `#4F627D` | Motion from the shared app behavior + “Synchronizing” |
| Queued/offline | `#805B16` | Queue/cloud-off icon + explanatory text |
| Synchronization error/conflict | `#A63D4E` | Error/conflict icon + actionable text |

## Verified contrast results

Ratios were calculated from the WCAG sRGB relative-luminance formula using the opaque hex values above. Threshold comparisons must use unrounded values in implementation tests.

| Foreground on background | Ratio |
|---|---:|
| `text-primary` on `surface` | 14.76:1 |
| `text-secondary` on `surface` | 6.72:1 |
| `text-primary` on `canvas` | 13.10:1 |
| `border` on `surface` | 3.93:1 |
| `on-primary` on `primary` | 5.97:1 |
| `on-secondary` on `secondary` | 6.37:1 |
| `clinical-content` on `clinical-surface` | 10.55:1 |
| `clinical-accent` on `clinical-surface` | 4.87:1 |
| `work-content` on `work-surface` | 10.58:1 |
| `work-accent` on `work-surface` | 4.99:1 |
| `protected-content` on `protected-surface` | 11.01:1 |
| `protected-accent` on `protected-surface` | 5.32:1 |
| `selected-border` on `selected-surface` | 6.19:1 |
| `focus-ring` on `surface` | 8.30:1 |
| `focus-ring` on `canvas` | 7.37:1 |
| `status-warning` on `surface` | 6.03:1 |
| `status-error` on `surface` | 6.08:1 |
| `status-info` on `surface` | 6.12:1 |
| `status-on-color` on `status-success` | 5.97:1 |
| `status-on-color` on `status-info` | 6.22:1 |
| `status-on-color` on `status-warning` | 6.13:1 |
| `status-on-color` on `status-error` | 6.18:1 |

The standard palette therefore clears AA for the specified ordinary-text pairs and the 3:1 non-text boundary target. Opacity, blending, gradients, anti-aliasing, and artwork can change effective contrast; rendered Android acceptance must remeasure the final pixels.

## Enhanced accessibility overrides

Enhanced accessibility remains one optional global mode, not another theme. It keeps the identity but applies these overrides:

| Token | Standard | Enhanced |
|---|---:|---:|
| `canvas` | `#F4EFE6` | `#FFFDF8` |
| `text-primary` | `#33212F` | `#21131F` |
| `text-secondary` | `#655665` | `#514452` |
| `border` | `#8A7D72` | `#5C5048` |
| `selected-border` | `#6B3D67` | `#4D1F55` |
| `focus-ring` | `#6B3D67` | `#4D1F55` |

- Target at least 7:1 for ordinary active text and 4.5:1 for essential boundaries in final rendered screens. For example, enhanced `text-secondary` on `surface` is 8.99:1 and enhanced `border` on `surface` is 7.66:1.
- Increase selection and focus outlines to at least 3 px; use a two-color ring when the indicator crosses variable backgrounds, consistent with WCAG's focus guidance. ([W3C Focus Appearance](https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html))
- Always show category icons and labels. Add patterns to progress: completed solid, scheduled diagonal, unscheduled dotted, over-target crosshatched.
- Suppress botanical line art, paper grain, translucent washes, and low-contrast dividers in enhanced mode. System text scaling remains independent and is always honored.

## Prohibited pairings and treatments

- Do not use `secondary` (`#815165`) or `primary` (`#496B55`) as ordinary-size text on `canvas` without a measured background pairing; use `text-primary` or `text-secondary`.
- Do not place `text-secondary` over `housing-base`, botanical artwork, gradients, or translucent imagery without remeasurement.
- Do not use `divider` as the sole boundary of a control; it is intentionally quieter than `border`.
- Do not put white text on `progress-scheduled`, `progress-unscheduled`, or other accents unless the exact pairing is tested; legends should normally use dark text on `surface` beside swatches.
- Do not distinguish Clinical Sessions, Work Shifts, Protected Days, progress, lifecycle, or synchronization states by hue alone.
- Do not place foliage, stems, flowers, paper grain, or specimen labels behind calendar data or controls. Motifs are limited to the nine-slice housing and noninteractive chrome.
- Do not use transparency for semantic colors without recomputing contrast against every actual background.

## Decision

Advance this palette to the Android-tablet Calendar and Theme-gallery-card concept stage. “Botanical Study” remains a working title until visual approval.
