# Field Archive concept-fidelity candidate

Issue: [#137](https://github.com/mshamblin5150-code/clinical-calendar/issues/137)

Status: **candidate awaiting explicit maintainer visual approval**. Physical
Android-tablet acceptance is **pending** and remains part of catalog device
acceptance in #139. Passing automation and this proof package do not approve
the runtime composition.

The approved issue #118 concept is copied byte-for-byte and remains the
normative landscape reference. Every runtime capture uses fictional data.

## Evidence

- `approved-concept-landscape.png`: untouched approved issue #118 concept.
- `runtime-landscape-1536x1024.png`: deterministic full-screen Flutter test
  render at the declared 1536 by 1024 landscape golden viewport.
- `landscape-concept-vs-runtime.png`: labeled equal-size comparison of the
  approved concept and deterministic runtime.
- `runtime-portrait-900x1440.png`: deterministic full-screen Flutter test
  render of the intentional portrait reading order.
- `runtime-portrait-200-percent-900x1440.png`: deterministic full-screen
  Flutter test render at 200 percent text scale with explicit vertical and
  Calendar-horizontal scroll ownership and reachable navigation.

Renderer contract: `heritage-field-notes-owned-archive-v1`.

The production renderer consumes the shared live Calendar, Planning, Clinical
Placements, progress, attention, navigation, and callback slots. Theme-owned
layout supplies the approved crown, tall archive bays, central Calendar and
Planning hierarchy, right status rail, indexed bottom navigation, and portrait
recomposition. It owns no clinical state, persistence, validation, or workflow
logic. Default rendering paths for every other theme remain unchanged.

## Original frame creation record

The production `panel-nine-slice-v1.png` was generated with the built-in image
generation tool using the approved issue #118 concept as a visual reference.
The request specified one standalone front-facing Field Archive panel with a
large empty live-content bay, walnut book-board rails, muted-brass corner and
index details, a thin forest rule, and flat warm parchment. It prohibited text,
controls, icons, semantic content, faux distress, military or tactical styling,
and any derivation from Containment Drone 47-Alpha. Generation used a flat
magenta chroma background; the installed chroma-removal helper produced the
bundled alpha PNG. The final asset is 1536 by 1024, has transparent exterior
corners, uses source cuts 120/145/120/170, and has SHA-256
`5bdc8587d9e35595868e5ee6e983c2cfb35d06bc110bd5cbf5885345c1f2645b`.

## SHA-256

```text
bf131014c71df2adc4b34b70c99e3e5ed94e54f0e1753d3979d0b6e85da66c75  approved-concept-landscape.png
89e9da5aa75dbd1be5978a7e2f5999685a0c17cbd48ab5ad5bc81b1f9586abef  landscape-concept-vs-runtime.png
f933ce80dcce7bb0ae7eaf24ae9337a6dd69cd9cb92e0fd6d76d561392eabf2a  runtime-landscape-1536x1024.png
d8902ef4722ee0979e0dfff448d7b38e5707e0feff4e111c5ad196bfc333da8c  runtime-portrait-900x1440.png
6b48ea16f81c45057f18c3ca9f678dd1591c5d3da1920c406d4e82b5264abaf2  runtime-portrait-200-percent-900x1440.png
```

## Physical Android-tablet acceptance

State: **Pending — final catalog device acceptance remains #139**.

No file in this package is a physical-device capture. No physical build was
installed and no signing material was accessed. Fresh physical evidence must
use fictional data and must not be inferred from deterministic goldens.
