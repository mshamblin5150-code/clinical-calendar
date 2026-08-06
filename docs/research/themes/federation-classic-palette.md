# Federation Classic semantic palette

Status: research complete
Scope: original, TNG-era-inspired visual system for Clinical Calendar
Evidence date: 2026-08-05

## Conclusion

Federation Classic should use a near-black plum field, warm amber/salmon controls, lilac structure, broad rounded rails, and large uninterrupted content bays. The recognizable character comes from the relationship among those elements, not from copied screen layouts, labels, insignia, or exact production colors. All hex values below are original design inferences chosen for Clinical Calendar semantics and contrast; they are not claimed to be canonical LCARS values.

## Primary-source rationale

### Evidence

- StarTrek.com's first-party launch page calls the CBS Interactive PADD app a "faithful reproduction" of LCARS, identifies Michael Okuda as the designer of the TNG computer displays, and records Michael and Denise Okuda approving the functional implementation. Its first-party imagery is therefore a stronger visual reference than fan-made palettes. [Star Trek PADD App Available Today](https://www.startrek.com/en-un/videos/star-trek-padd-app-available-today)
- In StarTrek.com's interview, Michael Okuda says TNG used graphics as a major design element and that they contributed strongly to the era's visual identity. Michael and Denise Okuda also emphasize committing to a consistent look as a key to believability. [Star Trek Archeology with Michael and Denise Okuda](https://www.startrek.com/en-un/news/star-trek-archeology-with-the-okudas)
- The official PADD reference imagery consistently presents high-luminance warm and lavender blocks on a dark field, with elongated capsules, rounded ends, elbows, and asymmetric bands. This is a qualitative visual observation of the cited first-party artifact, not an assertion of exact production paint or RGB values. [Star Trek PADD App Available Today](https://www.startrek.com/en-un/videos/star-trek-padd-app-available-today)
- WCAG 2.2 AA requires at least 4.5:1 contrast for normal text, 3:1 for large text, and 3:1 for visual information needed to identify controls and states. WCAG also prohibits color as the only visual means of conveying information. [WCAG 2.2, criteria 1.4.1, 1.4.3, and 1.4.11](https://www.w3.org/TR/WCAG22/)

### Design inference

Clinical Calendar should translate the evidence into broad rounded rails and pill-ended controls around a calm content bay. It should not recreate any photographed screen, reuse decorative numeric labels, or put pseudo-technical copy into the interface. Warm amber, salmon, and lilac are used as a family resemblance; the proposed values and all semantic assignments are new.

The housing should be a new high-resolution nine-slice raster with transparent exterior corners and a large empty interior. It may use a thick left rail, one or two asymmetric elbows, and capsule terminals, but it must contain no text, icons, controls, insignia, ship names, or copied screen geometry.

## Standard semantic tokens

All colors are opaque sRGB. `onAccent` is the only text/icon color permitted on bright accent fills. `primaryText` and `secondaryText` are for dark surfaces.

| Token | Hex | Intended use |
| --- | --- | --- |
| `canvas` | `#09070C` | App background and exterior gaps |
| `structure` | `#15101C` | Primary content bay |
| `structureRaised` | `#21172B` | Cards, dialogs, raised regions |
| `insetBorder` | `#B88AE8` | Essential boundaries and structural separators |
| `primaryText` | `#FFF4D6` | Headings, body text, values |
| `secondaryText` | `#E6C9FF` | Supporting text and metadata |
| `accentPrimary` | `#F6B44B` | Primary actions and active navigation |
| `onAccent` | `#1A0E06` | Text/icons on every bright accent fill |
| `control` | `#241832` | Resting control fill |
| `controlActive` | `#3B2750` | Pressed/active control fill |
| `controlBorder` | `#B88AE8` | Control outline |
| `focus` | `#FFF06A` | Keyboard/accessibility focus outline |
| `selection` | `#F6B44B` | Selected date/card outline and marker |
| `clinical` | `#F29A72` | Clinical Session accent and completed clinical segment |
| `clinicalFill` | `#44251F` | Clinical Session card/cell fill |
| `work` | `#3B2A4D` | Work Shift card/cell fill |
| `workMachinery` | `#B8A3E0` | Work Shift accent |
| `protectedDay` | `#332D38` | Protected Day cell fill |
| `protectedDayAccent` | `#FFE09A` | Protected Day outline and marker |
| `completed` | `#A9D47A` | Completed Hours/progress |
| `scheduled` | `#F6B44B` | Scheduled Hours/progress |
| `unscheduled` | `#B6A8BE` | Unscheduled Hours/progress |
| `overTarget` | `#E980A4` | Over-Target Hours/progress |
| `today` | `#8DCAE8` | Today marker only |
| `urgent` | `#FF7777` | Urgent attention and destructive emphasis |
| `warning` | `#FFD166` | Warning state |
| `error` | `#FF7777` | Error state |
| `success` | `#A9D47A` | Successful operation |
| `info` | `#8DCAE8` | Informational status |
| `disabled` | `#756B7A` | Disabled content only; never actionable text |
| `shadow` | `#000000` at 72% | Elevation outside content bays |

## Contrast results

Ratios use the WCAG relative-luminance formula and unrounded sRGB values; displayed results are rounded to two decimals. AA thresholds are 4.5:1 for normal text and 3:1 for essential non-text UI. [W3C Understanding SC 1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum) and [W3C Understanding SC 1.4.11](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast)

| Required pairing | Ratio | Gate |
| --- | ---: | --- |
| `primaryText` / `canvas` | 18.30:1 | Pass text |
| `primaryText` / `structure` | 17.07:1 | Pass text |
| `primaryText` / `structureRaised` | 15.68:1 | Pass text |
| `secondaryText` / `structure` | 12.61:1 | Pass text |
| `primaryText` / `work` | 11.80:1 | Pass text |
| `primaryText` / `protectedDay` | 12.18:1 | Pass text |
| `insetBorder` / `structure` | 6.98:1 | Pass non-text |
| `clinical` / `structure` | 8.59:1 | Pass non-text |
| `workMachinery` / `structure` | 8.33:1 | Pass non-text |
| `protectedDayAccent` / `structure` | 14.59:1 | Pass non-text |
| `selection` / `structure` | 10.29:1 | Pass non-text |
| `focus` / `structure` | 15.96:1 | Pass non-text |
| `onAccent` / `clinical` | 8.69:1 | Pass text |
| `onAccent` / `scheduled` | 10.41:1 | Pass text |
| `onAccent` / `completed` | 11.16:1 | Pass text |
| `onAccent` / `overTarget` | 7.29:1 | Pass text |
| `onAccent` / `error` | 7.35:1 | Pass text |

These results do not make hue sufficient as a state cue. WCAG 1.4.1 requires visible information in addition to color when color carries meaning. [W3C Understanding SC 1.4.1](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color)

## Calendar-state mapping

| State | Color treatment | Mandatory non-color cue |
| --- | --- | --- |
| Clinical Session | `clinicalFill`, `clinical` leading rail | Visible `CLINICAL` label; solid leading rail |
| Work Shift | `work`, `workMachinery` leading rail | Visible `WORK` label; two short parallel rail marks |
| Protected Day | `protectedDay`, `protectedDayAccent` outline | Visible `PROTECTED` label; dot-grid corner marker |
| Selected date | `selection` double outline | Inner + outer outline and selected semantics |
| Today | `today` top rule | Visible `TODAY` label; no reuse as urgency |
| Scheduled Session | State's base treatment | Clock glyph plus `SCHEDULED` text |
| Completed Session | State's base treatment | Check glyph plus `COMPLETED` text |
| Cancelled Session | Muted base treatment | Diagonal slash plus `CANCELLED` text |
| Missed Session | `urgent` marker | X marker plus `MISSED` text |
| Awaiting confirmation | `warning` marker | Clock-outline marker plus `CONFIRM` text |

## Progress-state mapping

| Progress meaning | Color | Mandatory non-color cue |
| --- | --- | --- |
| Completed Hours | `completed` | Solid segment; check in legend |
| Scheduled Hours | `scheduled` | Forward diagonal hatch; clock in legend |
| Unscheduled Hours | `unscheduled` | Outline/dotted segment; open circle in legend |
| Over-Target Hours | `overTarget` | Reverse diagonal hatch; plus marker in legend |

Every chart and compact progress rail must retain adjacent text values or an accessible legend. Segment color alone never identifies meaning.

## Enhanced accessibility overrides

Enhanced accessibility remains a single global option. The Classic identity stays warm and dark, but essential accents become brighter and decoration quieter.

| Token | Standard | Enhanced |
| --- | --- | --- |
| `primaryText` | `#FFF4D6` | `#FFFDF5` |
| `secondaryText` | `#E6C9FF` | `#F3E8FF` |
| `insetBorder` / `controlBorder` | `#B88AE8` | `#D9B8FF` |
| `clinical` | `#F29A72` | `#FFB08D` |
| `workMachinery` | `#B8A3E0` | `#D4C5FF` |
| `protectedDayAccent` | `#FFE09A` | `#FFE7AE` |
| `completed` / `success` | `#A9D47A` | `#C1E797` |
| `scheduled` / `selection` | `#F6B44B` | `#FFC45F` |
| `unscheduled` | `#B6A8BE` | `#D4C9DB` |
| `overTarget` | `#E980A4` | `#F39BBA` |
| `warning` | `#FFD166` | `#FFE083` |
| `urgent` / `error` | `#FF7777` | `#FF9292` |
| `today` / `info` | `#8DCAE8` | `#A9DCF3` |
| `focus` | `#FFF06A` | `#FFF27A` |
| `onAccent` | `#1A0E06` | `#160C08` |

All Enhanced accent-to-`structure` and `onAccent`-to-accent pairings are at least 8.71:1; `primaryText`/`structure` is 18.37:1. Enhanced mode also:

- makes every semantic leading rail at least 4 logical pixels wide;
- always shows the labels and glyphs in the mappings above, even where compact mode would otherwise abbreviate decoration;
- thickens selected and focus outlines without moving controls;
- removes nonessential micro-bands and reduces housing texture behind the frame edge;
- preserves Android text scaling and platform accessibility behavior independently of this option.

## Prohibited pairings and uses

- Never place `primaryText` or `secondaryText` on a bright accent fill; use `onAccent`.
- Never place `onAccent` on `canvas`, `structure`, `structureRaised`, `work`, or `protectedDay`.
- Never put `clinicalFill`, `work`, or `protectedDay` directly against `canvas` as the only boundary; retain an accent rail or essential outline.
- Never use `urgent` for Today. Today and urgency must remain separate semantics.
- Never distinguish Clinical Session, Work Shift, Protected Day, or progress states by hue alone.
- Never use `disabled` for enabled controls or required instructional text.
- Never render live text, controls, or data into the raster housing.
- Never sample, trace, or reproduce a production screen, insignia, label set, or screen-specific panel arrangement.

## Implementation handoff

The existing `ClinicalCalendarColors` contract covers the core calendar tokens but not all tokens in this brief. A later implementation ticket should extend the semantic contract before theme widgets consume concrete colors. Approval requires an Android-tablet Calendar dashboard concept and a Theme-gallery card using this exact standard palette; production artwork must wait for concept approval.
