# Coastal Light concept-fidelity proof

Issue: [#136](https://github.com/mshamblin5150-code/clinical-calendar/issues/136)

Status: implementation evidence complete. Physical Android-tablet catalog
acceptance is **Pending** and remains owned by issue #139. These deterministic
captures are not physical-device photographs.

## Evidence

- `approved-concept-landscape.png`: untouched approved issue #116 concept.
- `runtime-landscape-1586x992.png`: deterministic full-screen Flutter render
  at the concept's exact 1586×992 landscape viewport, 100% text scale, using
  fictional data.
- `landscape-concept-vs-runtime.png`: labeled, pixel-preserving side-by-side
  comparison with both landscape images displayed at equal size.
- `runtime-portrait-900x1440.png`: deterministic full-screen Flutter render
  of the intentional portrait composition at 100% text scale.
- `runtime-portrait-200-percent-900x1440.png`: deterministic portrait render
  at 200% text scale. The Calendar remains first in reading order, the
  portrait content owns its vertical scroll, the enlarged Calendar owns an
  explicit horizontal scroll, and navigation and shell actions remain
  reachable.

Renderer contract: `coastal-light-owned-responsive-observatory-v1`.

The renderer consumes the shared live Calendar, Planning, Clinical
Placements, progress, attention, navigation, profile, and callback slots. It
does not own clinical state, validation, persistence, or workflow logic.
Focused tests prove menu, Add Schedule, Help, Clinical Placements, Attention,
and Settings callbacks; preview/revert/apply/restart behavior; and unchanged
default rendering paths for the previously implemented themes.

The primary Coastal Light frame remains a normalized 1536×1024 RGBA
nine-slice source with `120/145/120/170` cuts and transparent corners. The
secondary chassis is fixed decorative composition art for the declared
landscape exemplar. Both are original Coastal Light assets recorded in the
concept README and contain no operational content.

## SHA-256

```text
50d4f44923d6710d9bcea35c82027c6dce20d14f08fa5ff993b7ad1e151d9741  approved-concept-landscape.png
874a3d907af023f153d0d86a01f6f00282571a7f411a3d19fbd5b61284739f44  landscape-concept-vs-runtime.png
1ff364852d31f185f1618e75ceeff8bd900948ef47e3ad5c6286b61e2a988702  runtime-landscape-1586x992.png
3fa7b29e685a992e02ebc045fd32581e02c8c6798b7c2329827d39e734d26c8f  runtime-portrait-900x1440.png
6c0e76d1b3915fd7cfe32f724ccc1f00a41da5d1ede0a5faff305c1f2a37806c  runtime-portrait-200-percent-900x1440.png
```

## Physical Android-tablet acceptance

State: **Pending — tracked by #139**.

No signed build was installed and no signing material was accessed for this
theme ticket. Fresh device evidence must use fictional data and follow the
catalog-wide acceptance issue.
