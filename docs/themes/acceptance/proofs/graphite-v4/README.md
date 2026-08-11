# Graphite destination-coherence candidate v4

Issue: [#160](https://github.com/mshamblin5150-code/clinical-calendar/issues/160)

Status: **Pending after physical SM-X920 review.** The maintainer reviewed the
signed `b91f5f7` catalog candidate under #139 and kept Graphite Pending. #174
owns the required follow-up: make the canonical delta the Application Menu
trigger and stop the preceptor-expanded wheel and Needs Attention chrome from
painting across the ownership boundary between their upper and lower boxes.

Graphite continues to declare **1536 by 1024** as its exact landscape golden
viewport. Renderer contract: `graphite-owned-responsive-instrument-v4`.

## Repair evidence

- The landing-page placements slot now has dedicated Graphite machinery: a
  signal rail, precision top rule, and status cells replace the shared generic
  instrument bay while retaining the live `PlacementDock` workflow.
- The Clinical Placements destination no longer delegates to the generic
  additive destination scaffold or uses a Graphite/Containment-style
  nine-slice box. Its production shell now owns a matte graphite crown,
  canonical Axion delta, recessed edge grid, cool-silver rails, restrained
  emerald status machinery, and a clipped opaque live-content bay.
- One parameterized production-shell test renders all ten top-level
  destinations through that same hierarchy and proves that neither
  `GraphiteNineSliceFrame` nor `VariantFNineSliceFrame` is present.
- The landscape golden pins the repaired production placements housing, and
  the focused Clinical Placements golden renders the real
  `PlacementManagementSurface` with a real controller and fictional,
  domain-valid repository records. No test-only replacement surface is used.
- The landscape insight rail uses the production `PlacementProgressRail` plus
  `AttentionRail` composition, including live fictional attention items.
- The Calendar proof consumes the shared
  `AcademicAssignmentCalendarWorkspace`. Graphite gives its existing shared
  Add Academic Assignment callback a compact 54-pixel precision housing; the
  editor, domain model, validation, persistence, calendar projection, and
  callback remain shared.
- The Graphite Calendar crown and destination crown both consume
  `CanonicalDeltaMark`; no Graphite-local delta painter or asset exists.
- Portrait and 200-percent text proofs remain deterministic and operable. A
  focused destination test also exercises the production shell at 200 percent
  text with bounded title/action geometry.
- Containment Drone renderer files, assets, geometry, and accepted goldens are
  unchanged.

## Direct comparison gate

The landscape test still loads the untouched approved concept directly from
`docs/concepts/themes/graphite/calendar-dashboard-concept-v1.png` and compares
it to the complete production render at 384 by 256 using deterministic area
averaging. The v4 bounds were recalibrated after replacing the test-only
placement and attention imitations with the real production widgets:

- mean RGB-channel similarity at least `0.925`;
- pixels within 32 levels in every RGB channel at least `0.805`.

The production-backed v4 runtime passes both bounds. The rejected v2 landscape
has a close-pixel ratio of about `0.7877`, so it still fails the combined gate.
The proof therefore keeps a deterministic concept-fidelity ratchet without
substituting hand-built visual fixtures for live application surfaces.

## Files

- `approved-concept-landscape.png`: untouched approved issue #117 concept.
- `runtime-landscape-1536x1024.png`: deterministic full-screen Flutter render
  with fictional, domain-valid data, the live placement widgets, and the
  shared Add Academic Assignment control.
- `landscape-concept-vs-runtime.png`: labeled equal-size comparison; both
  images are displayed at 768 by 512 pixels.
- `runtime-portrait-900x1440.png`: deterministic intentional portrait
  recomposition.
- `runtime-portrait-200-percent-900x1440.png`: deterministic 200-percent text
  and overflow evidence.
- `runtime-destination-clinical-placements-1536x1024.png`: deterministic
  focused proof of the repaired destination shell around the production
  Clinical Placements workflow. It is a test render, not a physical-device
  capture.

## SHA-256

```text
1d37e9c2c0f97a2428fbebfd0fc2b5d6e85e3281a634fa16ca2c67479ec24e4e  approved-concept-landscape.png
2ac1d1a4c39c8986c41499ddaebafdd8351171be439c7ee1ebd60423ab4827e1  landscape-concept-vs-runtime.png
2fc63b61dedd2f839592f5044008d45d9e6bb37a8fca3986318ea8ef96498867  runtime-destination-clinical-placements-1536x1024.png
d0265a70aa47d3632cda43c322dd49f3231ffc339b28ce6d6aa6850a11f615b9  runtime-landscape-1536x1024.png
6f46bbbd58e1987224218899585753ed34eb8239ef9fd9a7f14d948a0744c126  runtime-portrait-200-percent-900x1440.png
099e1ceff6a9c260419e6ddb8743ace7ecdf6ecdecddf6e7ea1382650817e137  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **Pending — follow-up #174 blocks a new decision on #139.**

The signed `b91f5f7` candidate was reviewed on the physical SM-X920 using the
private original-resolution matrix recorded in the
[#139 objective checkpoint](https://github.com/mshamblin5150-code/clinical-calendar/issues/139#issuecomment-5256232237).
The evidence passed the objective gates, but the maintainer explicitly kept
Graphite Pending for the delta routing and box-ownership defects above. No
Windows or physical-phone acceptance is claimed.
