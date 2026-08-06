# Federation 2399 semantic palette

Status: research complete
Scope: original, mature Picard-era-inspired visual system for Clinical Calendar
Evidence date: 2026-08-05

## Conclusion

Federation 2399 should be a restrained evolution rather than a dark recolor of Federation Classic: charcoal-black depth, desaturated plum and burgundy, muted amber, cool instrument light, fine segmentation, and shallow layered panels. All exact colors and semantic assignments below are original design inferences for Clinical Calendar; they are not claimed to be production values.

## Primary-source rationale

### Evidence

- The production team's Art Directors Guild awards submission names its interface work "LCARS 2.0" and presents the Picard-era sets and graphics as an evolution built for the production, making it a first-party visual reference. [Star Trek: Picard Season 2 production-design submission (PDF)](https://assets.adg.org/media/submissions/2022-10-11_21-31-57/STAR_TREK_PICARD_S2_ADG_AWARDS.pdf)
- Twisted Media's creative director and motion designer say they referenced older series and film design, used TNG and DS9 visual callbacks, and were guided by original LCARS designer Michael Okuda during seasons two and three. They also distinguish season one's holographic emphasis from the later focus on practical real-time playback. [Maxon interview with the Picard UI production team](https://www.maxon.net/en/article/creating-effects-to-connect-star-treks-past-and-present)
- Chris Kieffer, the production vendor's creative director, describes season one's work as keeping authenticity to the established universe while adding new visual layers and reimagining classic systems. This supports continuity plus refinement rather than replication. [Chris Kieffer: Picard Season 1](https://www.chriskieffer.com/work/picard-s1)
- WCAG 2.2 AA requires at least 4.5:1 contrast for normal text, 3:1 for large text, and 3:1 for visual information needed to identify controls and states. WCAG also prohibits color as the only visual means of conveying information. [WCAG 2.2, criteria 1.4.1, 1.4.3, and 1.4.11](https://www.w3.org/TR/WCAG22/)

### Design inference

Federation 2399 should preserve recognizable rounded terminals and asymmetric rails, but use thinner divisions, small gaps, recessed layers, and fewer large saturated blocks than Federation Classic. Dark plum, burgundy, aged amber, and cool white-blue translate the production evidence into a mature static interface. Translucency may be suggested by opaque layered values; real blur, animation, glow, and transparency behind calendar content are unnecessary and can impair legibility.

The housing should be an original high-resolution nine-slice raster with transparent exterior corners, a large uninterrupted content bay, fine segmented rails, and shallow inset layers. It must contain no logos, ship names, character imagery, pseudo-technical labels, copied screen geometry, or screen-specific graphics.

## Standard semantic tokens

All colors are opaque sRGB. `onAccent` is the only text/icon color permitted on bright accent fills. `primaryText` and `secondaryText` are for dark surfaces.

| Token | Hex | Intended use |
| --- | --- | --- |
| `canvas` | `#07080D` | App background and exterior gaps |
| `structure` | `#11131A` | Primary content bay |
| `structureRaised` | `#1A1D26` | Cards, dialogs, layered regions |
| `insetBorder` | `#9B7A92` | Essential boundaries and segmented structure |
| `primaryText` | `#F4F1EB` | Headings, body text, values |
| `secondaryText` | `#C8C0CC` | Supporting text and metadata |
| `accentPrimary` | `#C893B8` | Primary actions and active navigation |
| `onAccent` | `#150F16` | Text/icons on every bright accent fill |
| `control` | `#1B1F2A` | Resting control fill |
| `controlActive` | `#332735` | Pressed/active control fill |
| `controlBorder` | `#9B7A92` | Control outline |
| `focus` | `#F5D27A` | Keyboard/accessibility focus outline |
| `selection` | `#C893B8` | Selected date/card outline and marker |
| `clinical` | `#C893B8` | Clinical Session accent |
| `clinicalFill` | `#3A2635` | Clinical Session card/cell fill |
| `work` | `#273443` | Work Shift card/cell fill |
| `workMachinery` | `#A9C8D8` | Work Shift accent |
| `protectedDay` | `#383341` | Protected Day cell fill |
| `protectedDayAccent` | `#D6C9D9` | Protected Day outline and marker |
| `completed` | `#95BD99` | Completed Hours/progress |
| `scheduled` | `#D8A65E` | Scheduled Hours/progress |
| `unscheduled` | `#A9A3AE` | Unscheduled Hours/progress |
| `overTarget` | `#D98298` | Over-Target Hours/progress |
| `today` | `#89BFD2` | Today marker only |
| `urgent` | `#EF7D82` | Urgent attention and destructive emphasis |
| `warning` | `#E4B85E` | Warning state |
| `error` | `#EF7D82` | Error state |
| `success` | `#95BD99` | Successful operation |
| `info` | `#89BFD2` | Informational status |
| `disabled` | `#6F6F79` | Disabled content only; never actionable text |
| `shadow` | `#000000` at 78% | Elevation outside content bays |

## Contrast results

Ratios use the WCAG relative-luminance formula and unrounded sRGB values; displayed results are rounded to two decimals. AA thresholds are 4.5:1 for normal text and 3:1 for essential non-text UI. [W3C Understanding SC 1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum) and [W3C Understanding SC 1.4.11](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast)

| Required pairing | Ratio | Gate |
| --- | ---: | --- |
| `primaryText` / `canvas` | 17.75:1 | Pass text |
| `primaryText` / `structure` | 16.46:1 | Pass text |
| `primaryText` / `structureRaised` | 14.93:1 | Pass text |
| `secondaryText` / `structure` | 10.48:1 | Pass text |
| `primaryText` / `work` | 11.23:1 | Pass text |
| `primaryText` / `protectedDay` | 10.84:1 | Pass text |
| `insetBorder` / `structure` | 4.94:1 | Pass non-text |
| `clinical` / `structure` | 7.35:1 | Pass non-text |
| `workMachinery` / `structure` | 10.55:1 | Pass non-text |
| `protectedDayAccent` / `structure` | 11.68:1 | Pass non-text |
| `selection` / `structure` | 7.35:1 | Pass non-text |
| `focus` / `structure` | 12.71:1 | Pass non-text |
| `onAccent` / `clinical` | 7.48:1 | Pass text |
| `onAccent` / `scheduled` | 8.58:1 | Pass text |
| `onAccent` / `completed` | 9.01:1 | Pass text |
| `onAccent` / `overTarget` | 6.83:1 | Pass text |
| `onAccent` / `error` | 7.13:1 | Pass text |

These results do not make hue sufficient as a state cue. WCAG 1.4.1 requires visible information in addition to color when color carries meaning. [W3C Understanding SC 1.4.1](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color)

## Calendar-state mapping

| State | Color treatment | Mandatory non-color cue |
| --- | --- | --- |
| Clinical Session | `clinicalFill`, `clinical` fine leading rail | Visible `CLINICAL` label; one continuous leading rail |
| Work Shift | `work`, `workMachinery` segmented leading rail | Visible `WORK` label; two separated rail segments |
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

Enhanced accessibility keeps the restrained identity but increases luminance separation and reduces decorative layering.

| Token | Standard | Enhanced |
| --- | --- | --- |
| `primaryText` | `#F4F1EB` | `#FFFFFF` |
| `secondaryText` | `#C8C0CC` | `#EEE9F0` |
| `insetBorder` / `controlBorder` | `#9B7A92` | `#D6C5D1` |
| `clinical` / `selection` | `#C893B8` | `#E7B3D5` |
| `workMachinery` | `#A9C8D8` | `#C8E5F0` |
| `protectedDayAccent` | `#D6C9D9` | `#EFE4F2` |
| `completed` / `success` | `#95BD99` | `#B1D5B3` |
| `scheduled` | `#D8A65E` | `#F0BE72` |
| `unscheduled` | `#A9A3AE` | `#D0C9D3` |
| `overTarget` | `#D98298` | `#F39CB2` |
| `warning` | `#E4B85E` | `#F7CF76` |
| `urgent` / `error` | `#EF7D82` | `#FF979B` |
| `today` / `info` | `#89BFD2` | `#A8D5E5` |
| `focus` | `#F5D27A` | `#FFE28E` |
| `onAccent` | `#150F16` | `#120C12` |

All Enhanced accent-to-`structure` and `onAccent`-to-accent pairings are at least 8.97:1; `primaryText`/`structure` is 18.55:1. Enhanced mode also:

- makes every semantic leading rail at least 4 logical pixels wide;
- always shows the labels and glyphs in the mappings above, even where compact mode would otherwise abbreviate decoration;
- thickens selected and focus outlines without moving controls;
- removes tertiary hairlines and nonessential layer shadows;
- renders all content bays fully opaque;
- preserves Android text scaling and platform accessibility behavior independently of this option.

## Prohibited pairings and uses

- Never place `primaryText` or `secondaryText` on a bright accent fill; use `onAccent`.
- Never place `onAccent` on `canvas`, `structure`, `structureRaised`, `work`, or `protectedDay`.
- Never place `clinicalFill`, `work`, or `protectedDay` directly against `canvas` as the only boundary; retain an accent rail or essential outline.
- Never use `urgent` for Today. Today and urgency must remain separate semantics.
- Never distinguish Clinical Session, Work Shift, Protected Day, or progress states by hue alone.
- Never use low-opacity glass behind calendar data, forms, or controls.
- Never use glow as the only focus, selection, or state indicator.
- Never use `disabled` for enabled controls or required instructional text.
- Never render live text, controls, or data into the raster housing.
- Never sample, trace, or reproduce a production screen, insignia, label set, or screen-specific panel arrangement.

## Implementation handoff

The existing `ClinicalCalendarColors` contract covers the core calendar tokens but not all tokens in this brief. A later implementation ticket should extend the semantic contract before theme widgets consume concrete colors. Approval requires an Android-tablet Calendar dashboard concept and a Theme-gallery card using this exact standard palette; production artwork must wait for concept approval.
