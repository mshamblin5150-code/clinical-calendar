# Coastal Light concept-fidelity proof v4

Issue: [#136](https://github.com/mshamblin5150-code/clinical-calendar/issues/136)

Status: **AWAITING EXPLICIT MAINTAINER VISUAL APPROVAL**.

This revision supersedes the rejected v1, v2, and v3 proofs. It is review
evidence, not an acceptance baseline. The approved 1586×992 concept remains
normative until a maintainer explicitly accepts this runtime proof. Physical
Android-tablet acceptance remains pending under #139.

## What changed after v3 rejection

- Added the Axion delta/orbit mark to the Coastal crown as a visible,
  high-contrast sea-glass brand lockup at landscape and portrait sizes.
- Preserved the crown's menu action and the compact/200% action layout while
  keeping the mark visible when the text label is suppressed.
- Matched the concept's uppercase `AUGUST 2026` period-title treatment through
  a Coastal-only viewport policy; every other theme retains its existing title
  presentation.
- Matched the concept's compact `SUN`–`SAT` weekday headings and uppercase
  `MONTH / WEEK / AGENDA` selector labels through the same opt-in policy.
- Added deterministic assertions for the Axion mark and uppercase period title.

## Evidence

- `approved-concept-landscape.png` — untouched normative concept.
- `runtime-landscape-1586x992.png` — deterministic exact-viewport runtime.
- `landscape-concept-vs-runtime.png` — equal-size concept/runtime comparison;
  the adjacent files retain the full 1586×992 evidence.
- `runtime-portrait-900x1440.png` — intentional portrait composition.
- `runtime-portrait-200-percent-900x1440.png` — 200% text composition with
  crown actions, Settings, and bottom navigation still reachable.

## SHA-256

```text
50d4f44923d6710d9bcea35c82027c6dce20d14f08fa5ff993b7ad1e151d9741  approved-concept-landscape.png
a47dd3641adae164e6f1885230f18ff64cd46db1bfaffd210c18b9c854e9c4f2  landscape-concept-vs-runtime.png
a1644b8f8e7fc631bb87158c466d9f9c076f450fda5e29b282da7d46255294fd  runtime-landscape-1586x992.png
161f0e87dcd68c751675542a8d6872075850df14d64f243ede711e3ba622b279  runtime-portrait-200-percent-900x1440.png
639bea9d9ed951ec2b12b3c1877bfab5fb62d5564ce7b6ea0c0127f14f27acda  runtime-portrait-900x1440.png
```

## Verification

- `flutter analyze`
- `flutter test test/calendar_period_view_test.dart`
- `flutter test test/coastal_light_visual_proof_test.dart`
- full presentation suite and repository quality ratchet before publication
