# Containment Drone 47-Alpha redesign v2

Issue: [#146](https://github.com/mshamblin5150-code/clinical-calendar/issues/146)

Status: **concept approved; deterministic runtime implemented on issue #146;
physical Android-tablet approval pending**.

Declared landscape golden viewport: **1536 x 1024 logical pixels**.
Declared portrait proof viewport: **900 x 1440 logical pixels**.

`proposed-concept-landscape-1536x1024.png` is a generated approval artifact,
not a runtime capture or production raster asset. It uses fictional data.

`concept-vs-runtime-landscape-1536x1024.png` is the labelled equal-size review
sheet. Its left half is the approved concept; its right half is the
deterministic Flutter runtime at the same 1536 x 1024 logical viewport. The
runtime source golden is captured at the Android test device pixel ratio and
downsampled only for this review sheet. It is not a production raster asset.

The authoritative runtime proofs live in
`packages/clinical_calendar_presentation/test/baselines/containment_drone_v2`.
They include exact logical landscape and portrait targets, a 200% text proof,
compact rendering, Settings, and all ten destination mounts. The deterministic
fixture uses fictional Family Medicine data. The single cross-host reference
set and renderer metadata are pinned in `runtime-proof-manifest.json`; Windows
must match it exactly and Linux CI validates the same files under the
repository's bounded proof comparator. No Linux-authored capture is claimed.

## Maintainer-directed identity

- The shared canonical Axion Delta is integrated as the actionable
  Application Menu trigger.
- A large live Clinical Placement progress wheel is the dominant right-side
  instrument and exposes Completed Hours, Scheduled Hours, Remaining Hours,
  Unscheduled Hours, and Over-Target Hours.
- Dense irregular hull plates, conduits, ribs, recessed circuits, clamp-like
  joints, and localized green illumination make the theme materially more
  Borg-like than v1 while preserving readable live-content bays.
- The crown presents the shared Add Schedule, Help, Notifications,
  Synchronization, and Student Profile callbacks.
- Bottom navigation retains the shared Today, Calendar, Placements, Attention,
  and Settings targets.
- Calendar, Clinical Placements, Planning, Progress, and Needs Attention remain
  shared live workflows inside theme-owned housings. Domain state, validation,
  persistence, and callbacks are not forked.

## Portrait recomposition

Portrait owns one outer vertical scroll path with this reading order:

1. Axion Delta Application Menu and compact crown actions;
2. Calendar controls and Calendar;
3. Clinical Placements;
4. the progress wheel and metrics;
5. Planning; and
6. Needs Attention.

The five-item navigation rail remains fixed outside that scroll path. At 200%
text scale, live panels grow vertically and the outer scroll path retains all
required actions. A bounded shared child may scroll only where its production
widget already owns that behavior.

## Orientation and interaction targets

- `proposed-concept-landscape-1536x1024.png`: main landscape Calendar; the
  selected Clinical Placement is Family Medicine, the wheel exposes
  Unscheduled Hours, and the circular Student Profile avatar contains
  fictional initials.
- `proposed-concept-portrait-900x1440.png`: intentional main portrait
  recomposition at the declared viewport.
- `proposed-concept-landscape-menu-open-1536x1024.png` and
  `proposed-concept-portrait-menu-open-900x1440.png`: the Axion Delta opens the
  same ten real top-level destinations in each orientation, with explicit
  Close and scroll ownership.
- `proposed-concept-landscape-progress-open-1536x1024.png`: tapping the Family
  Medicine wheel opens its live detail surface with all five hour metrics,
  target/deadline, Primary and attached Preceptors, upcoming Clinical
  Sessions, and the exact Evaluation Plan requirement types.
- `proposed-concept-landscape-destination-clinical-placements-1536x1024.png`
  and `proposed-concept-portrait-destination-clinical-placements-900x1440.png`:
  the representative shared destination shell. All ten destinations consume
  this orientation-aware outer contract while retaining their own shared live
  child and callback behavior.

Implementation proof must mount all ten destinations in landscape, portrait,
compact, and 200% text states. The representative concept pair defines the
shell; it does not waive per-destination automated and physical inspection.

## SHA-256

```text
f945ebb59c5086460bd9edb9cc1b61e1966819e60508e59bfa62c60e875a0643  proposed-concept-landscape-1536x1024.png
bc887a60f7ad07110c81f10fae07aa1167e8941c1a53d1419775c0e1d2d70098  proposed-concept-landscape-destination-clinical-placements-1536x1024.png
e62ebcbaf75013abe841ae782b2eb7d906f904a1f9631f880f425e3debe17fce  proposed-concept-landscape-menu-open-1536x1024.png
a494026f439b90abdebac0702fb65205e1b5defd49cfe449ed7b6e8f6d45fb31  proposed-concept-landscape-progress-open-1536x1024.png
0b31d96763efdeb72e5fb9fe8ebb0292e4e0a467d811c59e7c6d5389abbcd824  proposed-concept-portrait-900x1440.png
a6ceee436794e23f4b04f28295a7caf49f3ee9490a5d7a45e89748553d421f75  proposed-concept-portrait-destination-clinical-placements-900x1440.png
5b1203392e4046104071493358eb30a20ace3fd628a8acaf0d21f2cd0bd0f356  proposed-concept-portrait-menu-open-900x1440.png
```

## Reference boundary

The user-supplied Borg references are material/form references only: irregular
hull plating, radial green instrumentation, recessed conduits, and internal
illumination. The proposal does not reproduce people, characters, movie
scenes, slogans, or reference-image text.

The exact built-in generation prompt and reference hashes are recorded in
`generation-prompt.md`. The first proposal remains under the adjacent v1
directory and is explicitly labelled rejected.

The maintainer approved this concept and the exact issue-146 preservation
amendment on 2026-08-13, then clarified that the approved concept must ship as
the working selectable theme. That clarification authorizes the new
Containment-only `assets/containment_drone_v2/chassis-conduit-bridge.png`
production ornament while all protected legacy rasters remain immutable. The
ornament is non-interactive and sits outside the safe live-content boundary.
Its generation provenance and final prompt are recorded in
`production-chassis-asset.md`.
Release acceptance remains blocked only on fresh physical inspection on the
SM-X920 target; no physical-device capture is represented by this deterministic
proof package.
