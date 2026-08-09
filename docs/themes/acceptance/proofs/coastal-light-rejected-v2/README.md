# Coastal Light rejected concept-fidelity proof v2

Status: **REJECTED by the maintainer on 2026-08-09**.

This directory is historical evidence only and is not an acceptance baseline.
The maintainer reported that the buttons, Settings navigation, hour breakdown,
and attention rail still did not match the approved concept closely enough.
The approved 1586×992 concept remains normative. Physical-device acceptance is
tracked separately by #139.

## What changed after rejection

- Matched the concept's left, center, and right column proportions and the
  calendar/planning split.
- Restored the populated month-card density, neutral day cells, centered period
  control, calendar legend, and concept-sized planning controls.
- Split progress and attention into distinct right-rail regions and matched the
  placement-card progress presentation.
- Preserved live calendar behavior, shell callbacks, portrait ordering, 200%
  text access, and Enhanced-mode decorative restraint.
- Added independent geometry and event-density assertions so the golden cannot
  approve itself.

## Evidence

- `approved-concept-landscape.png` — normative concept.
- `runtime-landscape-1586x992.png` — revised exact-viewport runtime.
- `landscape-concept-vs-runtime.png` — at-a-glance concept/runtime comparison;
  the adjacent files retain the full 1586×992 evidence.
- `runtime-portrait-900x1440.png` — portrait composition.
- `runtime-portrait-200-percent-900x1440.png` — 200% text composition.

## SHA-256

- `approved-concept-landscape.png`: `50d4f44923d6710d9bcea35c82027c6dce20d14f08fa5ff993b7ad1e151d9741`
- `landscape-concept-vs-runtime.png`: `699cb636d2f5a15648a6941a03815bc371dd5165398165885baed9cd3e24e8b9`
- `runtime-landscape-1586x992.png`: `9d5ac21dc32d4d119d2d6d9acda76da6ee0d28d73f5e19e2b19cf884cb9f7d73`
- `runtime-portrait-200-percent-900x1440.png`: `90ab2d861769e79b7b567140ef381813edab60c9c1791afd50fe1870624c6d22`
- `runtime-portrait-900x1440.png`: `d6799b0072b6d605be562448d159f96f33f375043ebf6819e5cd01f6f55fa388`

## Verification

- `flutter analyze`
- `flutter test test/coastal_light_visual_proof_test.dart`
- `flutter test test/theme_bundle_test.dart --plain-name "Coastal Light"`
- full presentation test suite and repository quality ratchet before commit
