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
layout now resolves the approved #118 landscape coordinates directly: the
deep walnut-and-brass book-board chassis, two-line archival crown, tall
placement bays, central Calendar and Planning hierarchy, right progress and
attention rail, indexed hardware, and bottom navigation deck. Field Archive
also opts into filled semantic Calendar bars matching the concept while every
other theme keeps its established default. The renderer owns no clinical
state, persistence, validation, or workflow logic.

The earlier `30d7401` proof was rejected by the maintainer and is retained
under `rejected/30d7401/` only as historical evidence. It is not an acceptance
or golden baseline.

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
16a6ae3e77dd480d3e6879a8cd92a997e7e4254df4f13b3f0d0b698d83ef485c  landscape-concept-vs-runtime.png
cdac4ff7f3172df27bce13454c8733a368f513c5a6092a455413b4258cadc83d  runtime-landscape-1536x1024.png
44769c3bd9ce838d99f368d418c8c12c22228901093943118bed1dbb81b480cc  runtime-portrait-900x1440.png
7f81600f1a4d04e0856ac8720ddd5dbdc1ef1b24f3a2bff052bd85613b4cdf0b  runtime-portrait-200-percent-900x1440.png
```

## Physical Android-tablet acceptance

State: **Pending — final catalog device acceptance remains #139**.

No file in this package is a physical-device capture. No physical build was
installed and no signing material was accessed. Fresh physical evidence must
use fictional data and must not be inferred from deterministic goldens.
