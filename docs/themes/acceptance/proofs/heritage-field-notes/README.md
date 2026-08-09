# Field Archive approved concept-fidelity proof

Issue: [#137](https://github.com/mshamblin5150-code/clinical-calendar/issues/137)

Status: **maintainer approved on 2026-08-09** in the implementation task, as
recorded in the [#137 completion comment](https://github.com/mshamblin5150-code/clinical-calendar/issues/137#issuecomment-5232111332).
Physical Android-tablet acceptance is **pending** and remains part of catalog
device acceptance in #139. The approval applies to this exact proof package;
future visual changes require refreshed evidence and approval.

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
reserves the concept-derived dark leather and dimensional aged brass for that
outer chassis. Its right-side index tabs are part of the same raster chassis
and visibly join the journal page edge instead of floating independently. The
live page is backed by parchment and its interior bays use single quiet rules
without nested rims or cast shadows, matching the concept's border hierarchy.
The insight rail reserves a separate content inset beside its green section
rule so `INTERNAL MEDICINE` never paints beneath the accent. It also
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

## Leather-and-brass chassis record

The landscape renderer uses
`assets/heritage_field_notes_materials/field-archive-chassis.png`, produced
with the built-in image tool from the untouched approved concept. The edit
preserved only its outer aged-leather cover, embossed edge treatment, antique
brass perimeter and fasteners, and the connected page-edge index tabs. All
text, controls, icons, paper content, and live panels were removed onto a flat
magenta key; the installed chroma-removal helper produced the transparent
product overlay. The final 1536 by 1024 asset has SHA-256
`5b4001634b5ea68a49a2389021d1398499f6bd7cc30bc03372ba9ce841ccc83e`.

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
19a57d43e8d98945d42c9c3bca6ffd39c1b22d362f6c7b7f58adbc4c668de6c4  landscape-concept-vs-runtime.png
b34d95376c7fc319eda3b8fbb5a10221f2edd470903e7fa05a3620920c60409c  runtime-landscape-1536x1024.png
f478aee3077f7430518ffc41b867b3d3ca60c72db794491da935e0cb406fc41f  runtime-portrait-900x1440.png
8abfea4d5498a60e9faae0bb2e250b62cbfed6984c92e5426ab3a8b875d99345  runtime-portrait-200-percent-900x1440.png
21f3f6a7c3f4cc67ad0c86943d8191c622a2030ca6d51dd5c1dabf4d37327c06  axion-delta.png
5b4001634b5ea68a49a2389021d1398499f6bd7cc30bc03372ba9ce841ccc83e  field-archive-chassis.png
```

## Physical Android-tablet acceptance

State: **Pending — final catalog device acceptance remains #139**.

No file in this package is a physical-device capture. No physical build was
installed and no signing material was accessed. Fresh physical evidence must
use fictional data and must not be inferred from deterministic goldens.
