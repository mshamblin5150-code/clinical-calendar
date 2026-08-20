# Federation Classic portrait navigation repair

Issue: [#221](https://github.com/mshamblin5150-code/clinical-calendar/issues/221)

Status: **Automated tablet evidence passes; maintainer visual acceptance was
approved on the physical Android tablet on 2026-08-20.**

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

The maintainer approved the physical portrait Calendar composition on
2026-08-20 after build 46 was installed in place on the intended Samsung
SM-X920. The physical interaction pass confirmed that all five bottom-deck
actions reach their intended destinations and return successfully.

Manual TalkBack and physical 200 percent system-text checks were not performed.
The deterministic accessibility evidence covers semantic order, minimum target
size, destination reachability, and the 200 percent portrait composition; those
automated checks pass. This approval records visual acceptance without
misrepresenting the unperformed manual accessibility checks.
