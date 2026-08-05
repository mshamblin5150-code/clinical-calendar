# Variant F Raster Frame Workflow

This guide is the implementation and acceptance procedure for the Clinical
Calendar's Containment Drone 47-Alpha mechanical UI housings. It exists to
prevent three recurring defects:

- scaling a small full-panel bitmap until its chrome becomes pixelated;
- positioning live text or controls over mechanical rails and corners;
- allowing Calendar, placement, planning, or attention content to paint
  outside the visible sprite housing.

The procedure below was verified on the physical Android tablet with signed
private-release build 37 and across the presentation package's responsive test
matrix.

## Required architecture

Use a high-resolution, standalone frame raster and render it as a nine-slice.
Do not scale a complete panel bitmap uniformly, and do not pack overlapping
panels into a nominal grid atlas.

The current production asset is:

`packages/clinical_calendar_presentation/assets/variant_f_raster/panel-nine-slice-v2.png`

Its requirements are:

- 1536 by 1024 pixels;
- transparent exterior corners;
- one continuous, front-facing mechanical housing;
- a large, uninterrupted dark interior bay;
- crisp gunmetal corners, rails, clamps, vents, and restrained green lights;
- no text, icons, controls, shadows outside the housing, or UI content;
- enough source detail that Android normally shrinks the chrome rather than
  enlarging it.

`VariantFNineSliceFrame` renders the asset. The source border cuts are 120 px
left, 145 px top, 120 px right, and 170 px bottom. Only the seams and dark
center between those cuts stretch. Corners and mechanical joints retain their
detail.

## Generating a replacement raster

Use the built-in image-generation workflow with the existing production asset
as the visual reference. Generate on a flat magenta chroma background because
the frame contains green indicators.

Prompt requirements:

```text
Use case: stylized-concept
Asset type: high-resolution Android UI nine-slice sprite source
Primary request: one standalone, front-facing mechanical panel frame matching
the Containment Drone 47-Alpha gunmetal tactical housing, with a large empty
rectangular interior bay for live Calendar UI
Style: crisp high-resolution raster, detailed plates, recessed seams, clamps,
vents, subtle wear, restrained green indicators; not pixel art
Backdrop: perfectly flat solid #ff00ff chroma key
Constraints: at least 2x the apparent detail resolution of the previous frame;
no text, icons, controls, interior content, perspective, cropped edges, cast
shadow, reflection, neighboring sprites, watermark, or magenta in the frame
```

Keep the generated chroma source outside the bundled asset directory. Remove
the background with the installed image-generation helper:

```powershell
python "$env:USERPROFILE\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py" `
  --input <source.png> `
  --out <panel-nine-slice-next.png> `
  --auto-key border `
  --soft-matte `
  --transparent-threshold 12 `
  --opaque-threshold 220 `
  --despill
```

Before use, verify all four output corner pixels have alpha 0, inspect the
asset at original resolution, and confirm there is no magenta fringe.

## Layout ownership

The frame widget owns the content boundary. Callers must not position content
independently over a background image.

- `VariantFNineSliceFrame` paints the nine-slice, reserves chrome insets, and
  clips its child.
- `VariantFRasterPanelFrame` applies the larger safe insets required by the
  Calendar dashboard's Calendar, placement, planning, and status bays.
- `VariantFTacticalFrame` uses the same raster frame for shared panels across
  phone, tablet, landscape/desktop, destination screens, headers, and bottom
  navigation.
- `VariantFRasterPanelInterior` tells nested panels not to repaint an opaque
  competing shell.

The dashboard minimum content insets are deliberately panel-specific:

| Panel | Left | Top | Right | Bottom |
| --- | ---: | ---: | ---: | ---: |
| Calendar | 38 | 46 | 38 | 46 |
| Placements | 30 | 44 | 30 | 44 |
| Planning | 34 | 46 | 34 | 42 |
| Status/attention | 30 | 44 | 34 | 44 |

A caller may request larger insets but must not reduce these minima. Do not
move headings upward into the top rail to recover space. Make the interior
scroll or adapt instead.

## Responsive rules

- Keep raster framing enabled at every Calendar layout size.
- Reduce destination chrome reservation on compact surfaces; do not remove the
  raster and fall back to a vector outline.
- Flexible Calendar-cell adornments must consume remaining width instead of
  imposing a rigid minimum that overflows after chrome is reserved.
- Never stretch the whole source image. Extend only the nine-slice center and
  edge seams.
- Do not place opaque content outside the frame and rely on visual coincidence.
  The child must be under the frame's padding and `ClipRect` boundary.

## Required tests

At minimum, run:

```powershell
flutter test packages/clinical_calendar_presentation/test/tactical_frame_test.dart
flutter test packages/clinical_calendar_presentation
```

The regressions must prove that:

- `VariantFTacticalFrame` contains `VariantFNineSliceFrame` and a clip;
- oversized content is clipped inside `VariantFRasterPanelInterior`;
- the required responsive matrix renders without overflow;
- narrow Calendar day cells adapt their selected indicator;
- the 320 px Settings layout remains valid.

Run the repository quality and contract checks before publication. A visual
change does not require re-running completed security scans unless its diff
introduces a new scoped security concern.

## Physical Android acceptance

Install the next signed private-release build as an upgrade. Verify the version
code, approved signing certificate, and preservation of fictional acceptance
data. Do not print signing material or protected release configuration.

Capture a new original-resolution screenshot of the live Calendar and inspect:

1. the placement dock heading and cards are inside the left dark bay;
2. the complete Calendar grid is inside the center frame;
3. planning begins below the top armor and remains inside its bay while
   scrolling;
4. the progress wheel, metrics, attention cards, and action are inside the
   right dark bay;
5. no text or control paints across a corner, rail, clamp, or transparent
   exterior;
6. no panel is being uniformly enlarged into visible pixelation.

Then capture and inspect every top-level destination: Clinical Placements,
Student Profile, Connected Devices, Trash & Recovery, Backup & Restore,
Exports, Synchronization, Settings, Notifications, and Help. Confirm the live
UI tree title before accepting each screenshot so an underlying Calendar
dialog is not mistaken for a destination capture.

Use fictional test data only. Do not expose account identifiers, credentials,
OTPs, database keys, signing secrets, or backup passphrases in reports. Do not
change device firmware, recovery state, network configuration, or broad device
settings to obtain screenshots.
