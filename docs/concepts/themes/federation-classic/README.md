# Federation Classic implementation evidence

Status: approved concept implemented for GitHub issue #133.

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
