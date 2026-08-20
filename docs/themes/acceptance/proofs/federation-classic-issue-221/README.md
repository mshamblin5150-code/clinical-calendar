# Federation Classic portrait navigation repair

Issue: [#221](https://github.com/mshamblin5150-code/clinical-calendar/issues/221)

Status: **Automated tablet evidence passes; physical Android-tablet
acceptance remains pending.**

This repair preserves the accepted Federation Classic identity, landscape
composition, live workflows, and navigation mappings. At the 900 by 1440
portrait tablet viewport, the five-action Federation Classic navigation deck
now spans the bottom of the theme-owned shell instead of occupying a left
rail. Calendar, Planning, Clinical Placements, and attention retain their
existing scroll ownership and semantic reading order.

## Deterministic evidence

The production proof harness pins the new captures without changing the
accepted v9 baselines:

- `packages/clinical_calendar_presentation/test/goldens/federation_classic_issue_221/federation_classic_portrait_900x1440.png`
  is the standard-text deterministic portrait render;
- `packages/clinical_calendar_presentation/test/goldens/federation_classic_issue_221/federation_classic_portrait_200_percent_900x1440.png`
  is the deterministic 200 percent text-scale render; and
- `theme_bundle_test.dart` proves bottom placement, scroll reading order,
  destination callback reachability, 200 percent text behavior, and unchanged
  rendering paths for every other theme.

All captures use the proof harness's fictional Student data. They are test
renders, not physical-device screenshots.

## SHA-256

```text
bd85184da0fbba4f8e90e3d0758b80f7397c2441949e26a089c19496e819727c  federation_classic_portrait_900x1440.png
8bb102b093b5f8959643baa1ac8fb59f091e470bb697c194c3e27ba7fc16c5fd  federation_classic_portrait_200_percent_900x1440.png
```

## Physical Android-tablet gate

The maintainer must still verify the portrait Calendar on the Android tablet,
including all five bottom-deck actions, TalkBack order, and 200 percent system
text. Automated evidence does not grant visual approval.
