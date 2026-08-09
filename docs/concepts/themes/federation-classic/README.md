# Federation Classic implementation evidence

Status: concept-fidelity renderer candidate prepared for GitHub issue #133.

The maintainer approved both visual-direction surfaces in GitHub issue #113:

- `calendar-dashboard-concept-v3.png` fixes the Android-tablet direction;
- `theme-gallery-concept-v1.png` fixes the comparison-gallery identity.

The production bundle follows the exact semantic tokens in
`docs/research/themes/federation-classic-palette.md`. The concept images are
review evidence only; they are not runtime thumbnails or frame source art.

## Production frame creation record

`packages/clinical_calendar_presentation/assets/federation_classic_raster/panel-nine-slice-v1.png`
was generated as new artwork with the approved Calendar concept used only as a
visual-direction reference. No Containment Drone image was supplied or used.

The generation request specified one standalone 1536 by 1024 front-facing
housing, a flat green chroma exterior, a single uninterrupted near-black plum
content bay, broad asymmetric lilac/amber/salmon rails, and normalized source
cuts at 120/145/120/170. It explicitly prohibited text, controls, data,
insignia, copied screen geometry, and Containment Drone mechanical imagery.

The flat background was removed with the installed image-generation chroma
helper using automatic border sampling, a soft matte, thresholds 12/220, and
despill. Automated validation records:

- dimensions: 1536 by 1024;
- SHA-256: `d88711508354961c147c5d31064c48b205f3c71c511d2ee6500b0810da107689`;
- corner alpha, clockwise from top-left: `0, 0, 0, 0`;
- center-bay alpha range: `255..255`;
- operational text, icons, controls, and data: absent.

The runtime gallery thumbnail remains renderer-generated from the pinned
fictional Android-tablet fixture rather than using either concept image.

## Concept-fidelity landscape chassis

`docs/themes/acceptance/proofs/federation-classic-v2/rejected-dashboard-chassis-landscape-v1.png`
is retained as rejected v2 provenance only and is excluded from production
assets and preflight. Production no longer stretches this complete dashboard
bitmap. Landscape uses independently positioned
nine-slice raster rails measured at the approved concept's native 1586 by 992
viewport; the normalized transparent nine-slice remains the primary frame for
portrait, compact, and destination surfaces.

The piecewise landscape rails use
`packages/clinical_calendar_presentation/assets/federation_classic_raster/lcars-rail-nine-slice-v2.png`,
a 512 by 512 neutral material tile edited with the built-in image-generation
workflow from the rejected v1 tile. The edit removed every scratch, band, and
dark seam while preserving a smooth neutral gradient, rounded silhouette, and
transparent exterior corners. Each independently positioned LCARS rail clips
and tints the tile, while only its 384 by 384 center and edge seams stretch.
SHA-256:
`7859e0b60dde47fa259c6eafe12b96b5ce59facb39487a5f2e8557c76cc10b77`.
All four corner alpha values are zero; the center is fully opaque; and the tile
contains no text, symbols, controls, or operational data. The v1 material is
excluded from production after its scratches and seams contributed to the
rejected v4 comparison.

The chassis was generated with the built-in image-generation workflow using
`calendar-dashboard-concept-v3.png` only as a reference for silhouette,
dominant bay proportions, asymmetric elbows, command crown, bottom deck, and
classic LCARS material language. The final targeted edit removed two
decorative rails from the right live-content bay. The request prohibited
text, controls, data, meaningful symbols, operational content, Containment
Drone geometry, Federation 2399 geometry, cyan accents, and tactical texture.

Automated validation records:

- dimensions: 1536 by 1024;
- SHA-256: `e969582b7efdad72d6bf97f6ae8cade2820833257d17c4546d4b840754ebc3bf`;
- operational text, icons, controls, and data: absent;
- live-content bays: opaque, near-black, and uninterrupted.

The rejected deterministic v2 through v5 proofs remain under their versioned
acceptance-proof directories as immutable negative baselines. The replacement
candidate is under `docs/themes/acceptance/proofs/federation-classic-v6/`.
All use the approved concept's native 1586 by 992 landscape viewport, but v6
is the only current review candidate.
