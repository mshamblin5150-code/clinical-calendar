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
reserves dark walnut and bright brass for that outer chassis: the live page is
backed by parchment and its interior bays use single quiet rules without
nested rims or cast shadows, matching the concept's border hierarchy. It also
opts into the concept's uppercase archival month toolbar, forest-selected
period controls, abbreviated weekday row, filled semantic Calendar bars, and
bottom legend while every other theme keeps its established default. Its
theme-owned Roboto Condensed variable font is distributed with the upstream
SIL Open Font License in `assets/heritage_field_notes_fonts/`; other themes do
not consume it. The proof fixture reproduces the concept's placement
subtitles, progress metrics, Over-Target row, Today stack, Planning step and
controls, medical-cross/work-stripe/shield marks, preceptor action, detailed
attention rows, Due markers, navigation colors, and indexed hardware. The
renderer owns no clinical state, persistence, validation, or workflow logic.

The earlier `30d7401`, `5deb099`, `d3e2a89`, and `2e8e544` proofs were rejected
by the maintainer and are retained under their matching `rejected/`
directories only as historical evidence. None is an acceptance or golden
baseline.

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
3cadb3e098f4b058ff3f0f507c5cf34c29e6891f91da9bc75476feb3f9221622  landscape-concept-vs-runtime.png
f2a0296ded836b0288ce075f9d9a05d7920fbfe156763b5ab0f2a7ab82d8597f  runtime-landscape-1536x1024.png
c0b8d9cb86cb962ead8154e2cfe75bc58725982a4b576fe62b2ec61908894073  runtime-portrait-900x1440.png
f2e0fb3f7bd8049bc88732f06c0cefc540fdd39a45cfd99f8f403ac900624220  runtime-portrait-200-percent-900x1440.png
```

## Physical Android-tablet acceptance

State: **Pending — final catalog device acceptance remains #139**.

No file in this package is a physical-device capture. No physical build was
installed and no signing material was accessed. Fresh physical evidence must
use fictional data and must not be inferred from deterministic goldens.
