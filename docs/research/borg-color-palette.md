# Borg color palette for calendar categories

Research date: 2026-08-03

## Recommendation

Use a **cool, desaturated Borg steel/teal** for Work Shifts, a **graphite/silver dormant treatment** for Protected Days, and retain acid green as the dominant Clinical/Collective cue. This is more coherent with the Borg visual language than generic category colors, while preventing the three calendar categories from collapsing into similar shades.

The exact hex values below are **accessibility-calibrated visual inferences for this product, not official Star Trek color specifications**:

| Role | Inferred color | Hex | Intended use |
|---|---|---:|---|
| Work surface | blue-black gunmetal | `#263C3E` | Work Shift event background |
| Work border/dot | muted Borg green-steel | `#7DAD78` | Event rail/outline and compact/mobile dot |
| Work highlight | cold teal steel | `#32545A` | Focus, selected, or hover surface |
| Work text | pale gray-green | `#F1F4EF` | Time and Work Shift label |
| Protected surface | dormant graphite | `#292C2D` | Protected Day background |
| Protected border/icon | regeneration silver | `#9DA6A1` | Outline, ring, or compact/mobile icon |
| Protected text | warm bone | `#E3E0D2` | Protected Day label |
| Existing Collective accent | acid green | `#92BE59` | Keep for Clinical Sessions/progress rather than Work Shifts |

Suggested application:

```css
--work-surface: #263c3e;
--work-border: #7dad78;
--work-highlight: #32545a;
--work-text: #f1f4ef;
--protected-surface: #292c2d;
--protected-border: #9da6a1;
--protected-text: #e3e0d2;
```

```css
.calendar-event.work {
  border-color: var(--work-border);
  background: var(--work-surface);
  color: var(--work-text);
}

.event-dot.work {
  background: var(--work-border);
}

.protected-cell {
  border-color: var(--protected-border);
  background: var(--protected-surface);
  color: var(--protected-text);
}
```

Keep the visible Work Shift and Protected Day labels and existing event semantics, so the distinction does not depend on color alone. On compact mobile cells, prefer a **solid dot for Work Shift** and a **ring or shield/lock glyph for Protected Day**, not merely two differently colored dots.

## Evidence from official Star Trek sources

- Green is the strongest recurring luminous Borg cue. StarTrek.com's Borg Cube guide specifies black/dark-gray structure with black-and-green areas and green light sources; the official Star Trek Shop likewise describes a show-accurate Borg Cube model with internal **green illumination**. ([StarTrek.com Borg Cube guide](https://www.startrek.com/news/glue-guns-and-phasers-the-borg-cube), [official Star Trek Shop product](https://shop.startrek.com/products/star-trek-borg-cube-bluetooth-speaker-with-illumination-and-sound-effects-sc876))
- In *Star Trek: Picard*, the official recap for "Vox" explicitly describes Borg interference appearing as **green markings** on the Titan's monitors. That supports keeping green as the primary Collective/system color rather than assigning it to ordinary Work Shifts. ([StarTrek.com recap](https://www.startrek.com/news/recap-star-trek-picard-309-vox))
- Borg materials repeatedly use black, gray, and metallic surfaces. StarTrek.com describes Borg imagery in terms of mottled gray flesh, matte-black armor, black tubing, white/black paint, and silver metallic highlights. These official descriptions support a dark steel family as an authentic secondary palette. ([official fiction excerpt](https://www.startrek.com/news/star-trek-q-and-false-other-stories-excerpt), [StarTrek.com Borg construction feature](https://www.startrek.com/news/guest-blog-building-a-budget-borg))
- Red is another recognizable Borg light cue: the official Cube guide allows green or red cutting/tractor beams, and StarTrek.com's Borg construction feature calls out a red LED at the eye. In this application, however, red is already semantically useful for danger, unscheduled hours, and overdue attention; it should remain reserved for those states. ([StarTrek.com Borg Cube guide](https://www.startrek.com/news/glue-guns-and-phasers-the-borg-cube), [StarTrek.com Borg construction feature](https://www.startrek.com/news/guest-blog-building-a-budget-borg))
- Official footage and production material span visibly different eras, from the original *The Next Generation* Borg to *First Contact*, *Voyager*, and *Picard*. There is no evidence of one canonical, invariant Borg UI palette. The safe design interpretation is a recurring family: black/graphite structure, metallic gray, green illumination, and sparse signal lights. ([official "Q Who?" history video](https://www.startrek.com/videos/watch-star-trek-history-q-who), [official *Picard* Borg Artifact production video](https://www.startrek.com/videos/watch-producing-picard-the-borg-cube-artifact))

## Why steel/teal for Work Shifts

Clinical activity is the application's primary progress-bearing category, so the strongest Borg cue - acid green - should stay attached to Clinical Sessions and Collective progress. A cool steel/teal is an **accessibility-calibrated, in-theme visual inference** from the Borg's black, gray, metallic, and green vocabulary. It reads as machinery without consuming red (danger), amber (warning/scheduled), or acid green (clinical/progress).

This is intentionally not bright cyan or Starfleet blue. The low-saturation teal keeps the industrial Borg character and remains visibly distinct from the existing Clinical Session background (`#263421`) and border (`#6B8050`).

## Protected Days and progress wheel

The Protected Day treatment should suggest a **dormant/regeneration state**, not an alarm. The graphite/silver recommendation is an **accessibility-calibrated visual inference** from the Borg's matte-black, gray, and metallic construction. It avoids the current plum treatment, which does not recur strongly in the official references, and avoids red, which should continue to mean conflict or urgent attention.

For the progress wheel, keep a Borg-styled semantic hierarchy rather than forcing every segment into one monochrome green:

| Wheel state | Inferred color | Hex | Rationale |
|---|---|---:|---|
| Target/reference | cybernetic silver | `#AFB0A4` | Neutral frame/reference |
| Completed | Collective green | `#789843` | Accomplished, assimilated into total |
| Scheduled | industrial ochre | `#C4A124` | Pending/active without reading as error |
| Unscheduled | muted optic red | `#BF4C42` | Attention needed; reserve vivid red for urgent alerts |

These are **accessibility-calibrated visual inferences, not official Star Trek hex values**. They closely match the prototype's current wheel colors, so the wheel does not need a wholesale recolor. The larger visual problem is Work Shifts sharing the same green family as Clinical Sessions. Keep the adjacent text legend and hour values visible because the wheel colors alone cannot communicate status reliably.

## Contrast and accessibility cautions

Calculated sRGB contrast ratios for the inferred colors:

- `#F1F4EF` text on `#263C3E`: **10.52:1**
- `#E3E0D2` protected text on `#292C2D`: **10.63:1**
- `#7DAD78` Work Shift rail against the calendar's `#0C110E` cell: **7.37:1**
- `#9DA6A1` Protected Day outline against the calendar's `#0C110E` cell: **7.62:1**

These exceed WCAG's 4.5:1 minimum for ordinary text and 3:1 benchmark for necessary non-text UI boundaries. WCAG also requires that color not be the only way information is distinguished; retain visible category labels and event semantics. ([WCAG 2.2 contrast requirements](https://www.w3.org/TR/WCAG22/#contrast-minimum), [WCAG 2.2 use of color](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color), [WCAG non-text contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast))

Use `#F1F4EF` for Work Shift text and `#E3E0D2` for Protected Day text; reserve the category accents for borders, dots, icons, and larger indicators. Recheck contrast after any opacity, gradient, or disabled-state treatment because translucent colors will not preserve the ratios above.
