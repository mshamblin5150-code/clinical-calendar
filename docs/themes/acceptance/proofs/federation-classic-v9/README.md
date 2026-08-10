# Federation Classic repair candidate v9

Issue: [#161](https://github.com/mshamblin5150-code/clinical-calendar/issues/161)

Status: **deterministic candidate; physical SM-X920 review Pending**. Passing
tests and these captures do not grant visual acceptance.

This repair preserves the maintainer-approved v8 Calendar composition and its
1586 by 992 landscape exemplar while completing the application-wide
Federation Classic mechanism:

- a direct, 44 logical-pixel Help control now sits in the LCARS crown without
  moving the approved Student identity or Axion delta, and the same Help
  action remains present in portrait;
- Placements, Planning, Clinical Placement, and Needs Attention keep their
  shared production workflows while rendering through Federation
  Classic-owned asymmetric LCARS housings;
- the shared Add Academic Assignment callback is presented through a
  Federation Classic-owned control housing, and its due-date projection is
  visible in the deterministic Calendar fixture;
- every top-level destination consumes one Federation Classic-owned crown and
  rail console while retaining the shared live destination child; and
- the focused Clinical Placements capture mounts the production
  `PlacementManagementSurface`, not a parallel proof-only workflow.

Containment Drone 47-Alpha output and assets are outside this candidate and
unchanged.

## Evidence

- `approved-concept-landscape.png`: untouched approved #113 concept, identical
  to the v8 normative source.
- `runtime-landscape-1586x992.png`: deterministic production Federation
  Classic Calendar shell with fictional placements, an Academic Assignment,
  Planning, progress, and attention content.
- `landscape-concept-vs-runtime.png`: labeled equal-size comparison; neither
  panel is resized.
- `runtime-portrait-900x1440.png`: deterministic portrait recomposition.
- `runtime-portrait-200-percent-900x1440.png`: deterministic maximum text-scale
  and overflow evidence.
- `runtime-destination-clinical-placements-1586x992.png`: focused production
  destination golden with fictional Clinical Placement data.

The automated destination matrix also mounts all ten top-level destinations,
checks the owned shell/crown/bay keys, proves the canonical delta remains in
the destination crown, rejects the generic additive and Containment Drone
frames, and exercises Back at 200 percent text.

## SHA-256

```text
9d7de52026ffe05e7bca073693a65be502afc74c7d805a28005e56d2c1877a14  approved-concept-landscape.png
a61cbdae07d26c3ff1455cdf1cd81482c1f0e4092705c090ccd4c7ea435e64a5  landscape-concept-vs-runtime.png
a89d25dae5595c157bf9ddf975256be08081eb5613fccd7115aa63ce0b71297e  runtime-destination-clinical-placements-1586x992.png
efea63b8d0649697e4ee2e60c6945fc3c14b01f275a545b5d40f3723a068dd14  runtime-landscape-1586x992.png
fc032efe0843dd1c3df158da1b68346f2d24735c5afa8209a9ce332e0f82ffc7  runtime-portrait-200-percent-900x1440.png
c3b7fa5c8dd8aba0303c69851c098ab313f9092eab1061156ac1a189dd4188e8  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **not performed — Pending under #139**. No image in this directory is
a physical-device capture, and no maintainer Accepted decision is inferred.
