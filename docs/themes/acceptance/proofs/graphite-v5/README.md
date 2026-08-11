# Graphite Application Menu and ownership-boundary candidate v5

Issue: [#174](https://github.com/mshamblin5150-code/clinical-calendar/issues/174)

Status: **Pending physical SM-X920 review.** This package is deterministic
Flutter evidence only. It does not record a signed-device install or infer a
maintainer acceptance decision under #139.

Graphite continues to declare **1536 by 1024** as its exact landscape golden
viewport. Renderer contract: `graphite-owned-responsive-instrument-v5`.

## Repair evidence

- The catalog-owned `CanonicalDeltaMark` is now the Graphite Application Menu
  `IconButton`. The former 3-by-3 grid painter and destination grid glyph are
  absent, leaving one menu trigger with the existing callback, tooltip,
  keyboard/switch activation, focus, and TalkBack button semantics.
- The live `PlacementProgressRail` and `AttentionRail` are passed through a
  Graphite-owned decomposition without changing the shared responsive-shell
  contract used by any other theme.
- Landscape placement progress is clipped and scrollable inside the fixed
  upper housing. Needs Attention is independently clipped and scrollable
  inside the fixed lower housing. Their borders have a visible gap and neither
  child can paint across the ownership boundary.
- The expanded-Preceptors golden uses the production controller and production
  `PreceptorProgressBreakdown`, scrolls the upper housing, and shows the
  Primary Preceptor row confined above the unchanged Needs Attention housing.
- Portrait, 200-percent text, the theme-owned Calendar, the Clinical
  Placements destination, Academic Assignment control, and all ten destination
  housings remain covered by the production proof and theme-contract suites.
- Containment Drone renderer files, shared responsive-shell code, protected
  raster assets, geometry, hashes, and accepted goldens are unchanged.

## Files

- `approved-concept-landscape.png`: untouched approved issue #117 concept.
- `runtime-landscape-1536x1024.png`: collapsed production landing surface with
  fictional, domain-valid placement and attention data.
- `runtime-landscape-preceptors-expanded-1536x1024.png`: production expanded
  Preceptors state, scrolled within the upper ownership box.
- `landscape-concept-vs-runtime.png`: labeled equal-size concept/runtime
  comparison; neither image is stretched.
- `runtime-portrait-900x1440.png`: deterministic portrait recomposition.
- `runtime-portrait-200-percent-900x1440.png`: deterministic 200-percent text
  and overflow evidence.
- `runtime-destination-clinical-placements-1536x1024.png`: production Clinical
  Placements destination inside Graphite-owned destination chrome.

## SHA-256

```text
1d37e9c2c0f97a2428fbebfd0fc2b5d6e85e3281a634fa16ca2c67479ec24e4e  approved-concept-landscape.png
612c4228b0a0fd907f51bf97e82de7a29350f0f78054a610d41d4858f4c8b283  landscape-concept-vs-runtime.png
02e31bc7f9d9e3cfbbd1cbaf584ed035f1595e885deb9fe8478e54d010cae7f1  runtime-destination-clinical-placements-1536x1024.png
e762a147acfd0c9b5cf9ad01f256196b36c26fda0e167b2313284d03bc049a4a  runtime-landscape-1536x1024.png
475bf6c03ecfbea056fa834613021c38f9894c46843ebe26cd18c1af46ae516b  runtime-landscape-preceptors-expanded-1536x1024.png
d64df899a3b3f003554b5cf5233249492e89320c6c8fa0f7668728543a20cfd9  runtime-portrait-200-percent-900x1440.png
95312beff4d28fbab107ef53bb43e773cbf75b11ca2b8fcc34c03523d02f88de  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **Pending.** The repaired candidate must be included in a new signed
private-release upgrade, repeated on the Samsung SM-X920 with original-size
screenshot/UI-tree evidence, and explicitly accepted or kept Pending by the
maintainer on #139. Automated tests and this proof package cannot satisfy that
gate.
