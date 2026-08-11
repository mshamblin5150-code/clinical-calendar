# Field Archive issue #165 concept-fidelity proof

Issue: [#165](https://github.com/mshamblin5150-code/clinical-calendar/issues/165)

Status: **Pending maintainer visual review**. This package refreshes the
deterministic evidence after the crown, border, flat-field, destination, and
Attention composition repair. It does not replace the untouched approved
issue #118 concept or retroactively alter the maintainer-approved #137 proof.
Physical Android-tablet acceptance remains **Pending** under #139.

Every runtime capture uses fictional data.

## Evidence

- `approved-concept-landscape.png`: byte-for-byte copy of the approved issue
  #118 concept and the normative landscape reference.
- `runtime-landscape-1536x1024.png`: deterministic full-screen Flutter render
  at Field Archive's declared 1536 by 1024 landscape viewport.
- `landscape-concept-vs-runtime.png`: labeled equal-size comparison of the
  untouched concept and the issue #165 deterministic runtime.
- `runtime-portrait-900x1440.png`: deterministic intentional portrait
  composition.
- `runtime-portrait-200-percent-900x1440.png`: deterministic portrait render
  at 200 percent text scale with explicit page, Calendar, Placement-summary,
  and Attention scroll ownership.
- `runtime-destination-clinical-placements-1536x1024.png`: focused production
  Clinical Placements destination proof using the shared live editor inside
  Field Archive-owned parchment framing.

Renderer contract: `heritage-field-notes-owned-archive-v2`.

## Repair record

- The crown exposes Add Schedule, Add Placement, Help, and the shared Student
  Profile control directly. Add Placement and Help route through the shared
  destination callback; the profile widget retains its shared callback.
- My Placements, Planning, the active Clinical Placement, and Needs Attention
  continue to consume the shared production widgets and controllers, but opt
  into flat Field Archive parchment housings. The housings use solid fills and
  ruled borders with no gradients or shadows.
- Needs Attention renders its title and count as one semantic heading
  (`Needs Attention, N items`) and owns bounded scrolling at 200 percent text
  scale, avoiding the former disjointed title/count composition.
- Field Archive owns the outer crown and parchment housing for every
  destination. A destination-local presentation token maps only the interior
  canvas from leather to parchment; domain state, validation, persistence,
  forms, and callbacks remain shared.
- A populated Today cell uses a compact Field Archive-only horizontal Today
  mark so the canonical Academic Assignment due-date projection from #166 can
  coexist without overflow. Other themes retain their existing Calendar path.
- The crown continues to consume the canonical Axion delta source from #159.
  Containment Drone 47-Alpha assets, renderers, geometry, and goldens are
  unchanged.

Automated coverage exercises direct crown controls, all four live housing
roles, flat-decoration contracts, accessible Attention count semantics at
standard and 200 percent text scale, destination-owned framing, deterministic
landscape/portrait goldens, and the focused Clinical Placements golden.

## SHA-256

```text
bf131014c71df2adc4b34b70c99e3e5ed94e54f0e1753d3979d0b6e85da66c75  approved-concept-landscape.png
0578090fbae29aac572b78e7b1a3e390e4ce59f015ae0afbfb887f824f11de35  landscape-concept-vs-runtime.png
9db943910bbc2f9294202a926aaef2bde70162afa930bf8816036825ff3c28da  runtime-destination-clinical-placements-1536x1024.png
51b563a3b7bf46edb32b4422a75a5967eae3a44d0af1da37b21132823aa3e840  runtime-landscape-1536x1024.png
f2580235f075e0eae1e4a613bafdfc49642da170254c867e5aa5316b6eda3ce4  runtime-portrait-200-percent-900x1440.png
e096f55397d8bb352137e0522e5fa7c01d3c0d02d21a1c25528368d754757e36  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **Pending — final catalog device acceptance remains #139**.

No file in this package is a physical-device capture. No physical build was
installed and no signing material was accessed. The maintainer remains the
sole visual approver.
