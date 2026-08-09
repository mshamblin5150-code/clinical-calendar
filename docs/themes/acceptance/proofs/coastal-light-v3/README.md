# Coastal Light concept-fidelity proof v3

Issue: [#136](https://github.com/mshamblin5150-code/clinical-calendar/issues/136)

Status: **AWAITING EXPLICIT MAINTAINER VISUAL APPROVAL**.

This revision supersedes the rejected v1 and v2 proofs. It is review evidence,
not an acceptance baseline. The approved 1586×992 concept remains normative
until a maintainer explicitly accepts this runtime proof. Physical Android
tablet acceptance remains pending under #139.

## What changed after v2 rejection

- Matched the concept's solid selected Month control, filled Add Schedule
  button, red Planning Incomplete action, and separate Collapse button.
- Reworked the bottom navigation selection tile and enlarged the icon/label
  treatment, including the Settings destination.
- Rebuilt the hour breakdown with semantic icons, aligned values, a concept-
  weighted completion number, pace card, and action rows.
- Rebuilt the attention rail with red warning treatment, four detailed rows,
  visible due states, and the complete confirmation label.
- Added safe responsive fallback behavior for the widened landscape period
  selector and explicit 200% hit-test coverage for Settings.

## Evidence

- `approved-concept-landscape.png` — normative concept.
- `runtime-landscape-1586x992.png` — revised exact-viewport runtime.
- `landscape-concept-vs-runtime.png` — equal-size concept/runtime comparison;
  the adjacent files retain the full 1586×992 evidence.
- `runtime-portrait-900x1440.png` — intentional portrait composition.
- `runtime-portrait-200-percent-900x1440.png` — 200% text composition with
  menu, Add Schedule, Settings, and bottom navigation still reachable.

## SHA-256

```text
50d4f44923d6710d9bcea35c82027c6dce20d14f08fa5ff993b7ad1e151d9741  approved-concept-landscape.png
95602f1406aec82edcb4b7138f3c7e91ffe356ee4e20ed9e063626a54144a28b  landscape-concept-vs-runtime.png
0074b0cd68538af7bcd185a5bcc524d7de6609d773e944cc93cba0448591084e  runtime-landscape-1586x992.png
18c6e6edd67ba607cdc184dc149509d4c439c204f7ab55d91850b14ebba97253  runtime-portrait-200-percent-900x1440.png
eb8d26af19bb299cb98ccf051dbad62bef580c9db1c6004ceb553496475a12e2  runtime-portrait-900x1440.png
```

## Verification

- `flutter analyze`
- `flutter test test/coastal_light_visual_proof_test.dart`
- `flutter test test/calendar_period_view_test.dart`
- full presentation test suite
- repository quality ratchet before commit
