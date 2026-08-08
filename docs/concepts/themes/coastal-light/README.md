# Coastal Light Android concept

Status: dashboard direction and final display name approved by the maintainer
in GitHub issue #116.

This concept is grounded in direct inspection of National Park Service coastal
sediment and winter-shore imagery, NOAA explanations of shallow-water color,
and NOAA bathymetric contour presentation, alongside the approved Coastal Calm
semantic palette. It is a concept reference, not production UI, a golden, or
raster-frame source art.

## Visual evidence translated

- Winter coastal imagery contributes long horizontal composition, clear blue
  distance, shell-white light, and warm mineral sand.
- Quartz and carbonate sediment references contribute restrained ivory, pearl,
  sand, and sparse coral mineral accents.
- Bathymetric maps contribute nested depth bands, contour transitions, and
  precise datum ticks as an abstract structural vocabulary.
- The concept translates those traits into original Clinical Calendar chrome.
  It does not reproduce a shoreline, chart, institution, or navigation symbol.

## Review surface

- `calendar-dashboard-concept-v1.png` preserves the Android-tablet Calendar
  regions inside an airy shell-white and sea-glass nine-slice housing.
- Broad nested contour rails give the housing a distinct silhouette without
  using literal water, waves, shells, boats, or beach decoration.
- Opaque content bays isolate calendar data from every atmospheric treatment.
- Icons, rails, outlines, patterns, and complete text labels keep calendar and
  progress semantics redundant rather than color-only.

## Final-name recommendation

Use **Coastal Light**. The name describes the interface's clear horizon rules,
shell-white illumination, sea-glass structure, and restorative spaciousness.
It is more specific to the approved visual result than the working title
Coastal Calm and avoids resort or spa connotations.

## Approval boundary

Approve the direction only if the dashboard establishes:

- a recognizable contemporary coastal-observatory identity without literal
  beach, vacation, resort, or nautical decoration;
- shell-white surfaces, sea-glass structure, clear blue rules, warm mineral
  inlays, and controlled coral reserved for urgent attention and focus;
- layered bathymetric contours confined to inactive outer chrome;
- calm, fully opaque content bays with no water texture behind live data;
- unchanged Calendar regions, controls, navigation, and domain language;
- complete visible labels with wrapping instead of ellipses or truncation; and
- visible CLINICAL, WORK, PROTECTED, TODAY, selected-date, attention, and
  progress cues.

The exact token values and semantic assignments remain authoritative in
`docs/research/themes/coastal-calm-palette.md`. Image-generation text and
miniature details are illustrative and must not be treated as implementation
copy or color measurements.

Production Flutter, final nine-slice artwork, implementation goldens, Theme
Gallery concept, and physical Android acceptance remain outside this approval
step.

## Production asset record

Issue #136 implemented the approved direction with two original raster assets
generated through the built-in image-generation workflow using only
`calendar-dashboard-concept-v1.png` as a visual reference:

- `assets/coastal_light_raster/panel-nine-slice-v1.png` is a 1536×1024 RGBA
  primary frame with transparent exterior corners and normalized
  `120/145/120/170` cuts. Its SHA-256 is
  `449bee6b6097389d0fc860069160f20def2425043c20bb1e3daf29fe3f55e22f`.
- `assets/coastal_light_raster/dashboard-chassis-landscape-v1.png` is the
  opaque, fixed 1536×1024 secondary landscape composition. Its SHA-256 is
  `b308df3a6f1ed8049c23231d82add92e49d83ee9de8dec5ddd4717154f5cbb23`.

The primary prompt requested one front-facing coastal-observatory nine-slice
housing on a flat magenta chroma background, with a calm empty bay, repeat-safe
stretch bands, shell-white and sea-glass contour rails, clear-blue datum rules,
and sparse mineral inlays. The secondary prompt requested the approved crown,
three-column hierarchy, Calendar-over-Planning center, right progress and
attention rail, and five-segment navigation as decoration-only chassis art.
Both prompts prohibited text, controls, operational content, literal beach or
nautical imagery, and all borrowed military or science-fiction geometry.
