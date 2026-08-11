# Coastal Light repair proof v5

Issue: [#163](https://github.com/mshamblin5150-code/clinical-calendar/issues/163)

Status: **Accepted on the physical SM-X920.** The maintainer explicitly
accepted Coastal Light from the signed `b91f5f7` catalog candidate under #139
after the complete objective matrix passed.

This proof supersedes Coastal Light v4 only for the #163 repair. The approved
1586×992 concept remains the normative visual target. These files are
deterministic test renders with fictional data, not physical-device captures,
and they do not infer physical acceptance under #139.

## Repaired composition

- The crown keeps the catalog-owned canonical Axion delta source and now
  exposes Add Placement, Help, and the shared Student Profile control.
- My Placements, Planning, Clinical Placement, and Needs Attention use
  Coastal Light-owned live housings. Their production controllers, callbacks,
  validation, persistence, and workflow widgets remain shared.
- The shared Add Assignment workflow and academic due-date Calendar projection
  remain inside the Coastal Calendar bay without a theme-local fork.
- Needs Attention is integrated into the Coastal insight rail rather than
  retaining the generic tactical box.
- Clinical, Work, and Protected remain on a dedicated legend line below the
  Calendar grid, preserving their icons and accessible meaning.
- Coastal destinations use one owned crown and sculpted content housing.
- Containment Drone 47-Alpha source, assets, and goldens are unchanged.

## Evidence

- `approved-concept-landscape.png` — untouched approved concept.
- `runtime-landscape-1586x992.png` — deterministic exact-viewport runtime.
- `landscape-concept-vs-runtime.png` — labeled equal-size comparison; neither
  source image is cropped or rescaled relative to the other.
- `runtime-portrait-900x1440.png` — intentional portrait recomposition.
- `runtime-portrait-200-percent-900x1440.png` — deterministic 200% text proof;
  crown actions and fixed bottom navigation remain hit-testable, while the
  content viewport owns scrolling.

## SHA-256

```text
50d4f44923d6710d9bcea35c82027c6dce20d14f08fa5ff993b7ad1e151d9741  approved-concept-landscape.png
54d4b4d03a6c8e46324d81b1f87b2ce3eeaff794e7af0a89a8aa861eb89f8aea  landscape-concept-vs-runtime.png
0f6e22ba84ecb282ce30b8d24928be15109c723813afeca910e7824432c73d68  runtime-landscape-1586x992.png
f7ed8b4997e38df1b757f5c40a453702b05baf1a19950f49e926d96cd4cc23da  runtime-portrait-200-percent-900x1440.png
16763945969dfbf6229966adf37944494a158129ad849dd9d073c172b9ac2a03  runtime-portrait-900x1440.png
```

## Verification boundary

Focused tests cover crown routing, destination Back/Close chrome, canonical
delta consumption, separate Calendar legend geometry, 200% reachability, and
the four Coastal-owned shared live workflow housings. The complete repository
quality gate passes. Independent Standards/Spec review is recorded with the
implementation handoff.

## Physical Android-tablet acceptance

State: **Accepted for Android tablet under #139.** The private
original-resolution physical matrix and signed-candidate provenance are
recorded in the
[#139 objective checkpoint](https://github.com/mshamblin5150-code/clinical-calendar/issues/139#issuecomment-5256232237).
The files in this directory remain deterministic proof renders rather than
physical captures. No Windows or physical-phone acceptance is claimed.
