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
deep leather-and-brass book-board chassis, Axion-delta archival crown, tall
placement bays, central Calendar and Planning hierarchy, right progress and
attention rail, indexed hardware, and bottom navigation deck. Field Archive
reserves dark leather and dimensional brass for that outer chassis: the live page is
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

The earlier `30d7401`, `5deb099`, `d3e2a89`, `2e8e544`, and `8769486` proofs
were rejected or superseded by the maintainer and are retained under their
matching `rejected/` directories only as historical evidence. None is an
acceptance or golden baseline.

## Axion crown mark record

The crown uses `assets/heritage_field_notes_brand/axion-delta.png`, derived
from the maintainer-supplied Axion artwork (source SHA-256
`c2ca738650ea9f71dbec7aba8cc881035df1cdb0d97399f47ef7ea5a2ef059ab`).
The built-in image tool isolated the supplied metallic delta and orbital mark
on a flat chroma background while removing the `AXION` wordmark; the installed
chroma-removal helper produced the transparent asset, which was cropped and
downscaled for the product crown. The final asset contains no added text and
has SHA-256
`21f3f6a7c3f4cc67ad0c86943d8191c622a2030ca6d51dd5c1dabf4d37327c06`.

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
003752bebdd1493a455ca365f266404dd36de6fdea998af4f23bd675b38fb509  landscape-concept-vs-runtime.png
508a7d69ce730992bc8167e294b95457984f4421dab1ef1ea6b92e676f6a5aa4  runtime-landscape-1536x1024.png
0a97d1bdcb381f45acd2031eb25f39c21a746ad6e4abafb5bfac89193eba9039  runtime-portrait-900x1440.png
8abfea4d5498a60e9faae0bb2e250b62cbfed6984c92e5426ab3a8b875d99345  runtime-portrait-200-percent-900x1440.png
21f3f6a7c3f4cc67ad0c86943d8191c622a2030ca6d51dd5c1dabf4d37327c06  axion-delta.png
```

## Physical Android-tablet acceptance

State: **Pending — final catalog device acceptance remains #139**.

No file in this package is a physical-device capture. No physical build was
installed and no signing material was accessed. Fresh physical evidence must
use fictional data and must not be inferred from deterministic goldens.
