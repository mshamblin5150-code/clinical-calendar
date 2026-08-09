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
layout now resolves the approved #118 landscape coordinates directly from the
untouched 1536 by 1024 concept (excluding comparison labels): the
deep walnut-and-brass book-board chassis, two-line archival crown, tall
placement bays, central Calendar and Planning hierarchy, right progress and
attention rail, indexed hardware, and bottom navigation deck. Field Archive
also opts into the concept's uppercase archival month toolbar, forest-selected
period controls, abbreviated weekday row, filled semantic Calendar bars, and
bottom legend while every other theme keeps its established default. The proof
fixture reproduces the concept's placement subtitles, progress metrics,
Over-Target row, Planning step and controls, preceptor action, detailed
attention rows, and Due markers. The renderer owns no clinical state,
persistence, validation, or workflow logic.

The earlier `30d7401` and `5deb099` proofs were rejected by the maintainer and
are retained under their matching `rejected/` directories only as historical
evidence. Neither is an acceptance or golden baseline.

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
65c36133d8d30b839236d17d30a9023dc01b3f1901622a61723eeda7c8838514  landscape-concept-vs-runtime.png
683acf628974d37d983902f95c28b912df00f66b2120f4a9673e72edf8bd95b7  runtime-landscape-1536x1024.png
56ce51e9e45d6045271032d890fe3d1936a5cee3d8bff0a829a90e86fb2686d3  runtime-portrait-900x1440.png
1fa104522ef4c3f793cf6675fe1be2f3624e3af05ee2831d23eab71f21f1a0cb  runtime-portrait-200-percent-900x1440.png
```

## Physical Android-tablet acceptance

State: **Pending — final catalog device acceptance remains #139**.

No file in this package is a physical-device capture. No physical build was
installed and no signing material was accessed. Fresh physical evidence must
use fictional data and must not be inferred from deterministic goldens.
