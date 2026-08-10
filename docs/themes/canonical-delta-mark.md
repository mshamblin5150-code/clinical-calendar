# Canonical Axion delta mark

Issue: [#159](https://github.com/mshamblin5150-code/clinical-calendar/issues/159)

The six non-Containment themes use one catalog-owned Axion delta-and-orbit
source:

`packages/clinical_calendar_presentation/assets/shared_brand/axion-delta-mark.png`

- Dimensions: 1254 by 1254 pixels
- SHA-256: `9e5c841e8781d518fe4b8052f7febe921a3a26899cc1deb769ddf0feacfeacc7`
- Approved appearance: the transparent metallic silver delta-and-orbit source
  already used byte-for-byte by the accepted Botanical Study and Federation
  2399 compositions before #159

## Pre-consolidation inventory

| Theme | Previous source | #159 result |
| --- | --- | --- |
| Graphite | Theme-local `_GraphiteLogoPainter` approximation | Shared raster through `CanonicalDeltaMark` |
| Coastal Light | Theme-local `_CoastalLightAxionDeltaPainter` approximation | Shared raster with Coastal-owned color treatment |
| Botanical Study | `botanical_study_raster/axion-delta-mark-v2.png` | Approved bytes moved to the shared path |
| Field Archive | Resized `heritage_field_notes_brand/axion-delta.png` copy | Shared raster in the Field Archive-owned menu crown |
| Federation Classic | Cropped `federation_classic_raster/axion-delta-v1.png` copy | Shared raster in the Federation Classic-owned crown |
| Federation 2399 | Byte-identical `federation_2399_raster/axion-delta-mark-v1.png` | Shared raster with no rendered-byte change |

Containment Drone 47-Alpha has no dependency on this source. Its protected
assets, renderer path, geometry, and accepted output are unchanged.

## Enforcement

`canonical_delta_mark_test.dart` renders all six production shells and
requires exactly one shared mark widget in each. It also pins the approved
hash, rejects filename and byte-for-byte asset duplicates, rejects local
Axion/delta painter classes, and verifies that the only direct delta asset
literal in production source is the canonical path.

The refreshed goldens record only the expected crown-mark change for Graphite,
Coastal Light, Field Archive, and Federation Classic. Botanical Study and
Federation 2399 remained golden-stable. Theme-specific repair acceptance and
physical Android-tablet acceptance remain governed by their own tickets and
parent issue #139.
