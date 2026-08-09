# Federation 2399 production frame

Status: production raster generated for GitHub issue #134 from the maintainer-
approved Android direction in issue #114.

The approved concept set remains versioned on commit
`27cbd28f37bce92ddcca80ab94399ad685d99c51`:

- `calendar-dashboard-concept-v1.png`
- `theme-gallery-concept-v1.png`

Those concepts are visual references, not runtime assets or goldens.

## Production asset record

The runtime asset is
`packages/clinical_calendar_presentation/assets/federation_2399_raster/panel-nine-slice-v1.png`.
It was generated with the built-in image-generation workflow on 2026-08-08,
then replaced during the landscape-fidelity pass with a dark integrated
outer chassis generated from the approved issue #114 dashboard as a style
reference. The final flat-magenta output was converted with the installed
`remove_chroma_key.py` helper using auto border sampling, a soft matte,
thresholds 12/220, and despill. A deterministic nine-slice alignment pass
mapped the generated dark-bay seams to the mandated cuts without introducing
or moving semantic content.

Validated properties:

- dimensions: 1536 × 1024 RGBA;
- source cuts: left 120, top 145, right 120, bottom 170;
- all four corner pixels have alpha 0;
- every pixel in the center stretch rectangle is fully opaque and its sampled
  cut-boundary pixels are dark charcoal;
- no visible magenta-like pixels remain after despill; and
- SHA-256: `1a11f86edb76286e6bf35c58188b23fee0a4414c0d173c8bd28f602732ec49aa`.

## Generation prompt

```text
Use case: stylized-concept
Asset type: high-resolution Android UI nine-slice sprite source for the Clinical Calendar Federation 2399 theme
Primary request: create one original standalone front-facing futuristic panel housing with a very large empty rectangular interior bay for live Calendar UI
Scene/backdrop: perfectly flat solid #ff00ff chroma-key background for local background removal; the background must be one uniform color with no shadows, gradients, texture, reflections, floor plane, or lighting variation
Subject: a single continuous Federation 2399 housing, with sweeping sculpted ivory and cool-silver outer lips, restrained burgundy and desaturated plum underlayers, fine segmented cyan instrument-light channels, small aged-amber markers, and deep charcoal-black structure; calm opaque uninterrupted interior bay
Style/medium: crisp high-resolution raster, refined cinematic science-fiction interface housing, shallow layered depth, fine segmentation, mature and precise; original design informed by the approved Clinical Calendar concept, not a reproduction of any production screen
Composition/framing: exact 3:2 landscape composition; perfectly front-facing and orthographic; one centered frame fully visible with generous chroma padding at all four corners; source intended for 1536x1024 nine-slice cuts at left 120, top 145, right 120, bottom 170; keep all distinctive joints and decoration outside the stretchable center seams
Color palette: #07080D charcoal canvas, #11131A dark structure, #9B7A92 restrained plum boundary, #C893B8 burgundy-pink accent, #A9C8D8 cool light, #D8A65E aged amber, ivory/silver outer lip
Materials/textures: smooth composite hull lips, satin burgundy understructure, dark opaque inset bay, crisp luminous but non-glowing cyan channels
Constraints: exactly one standalone housing; no text, letters, numbers, logos, insignia, icons, controls, buttons, data, calendar content, meaningful symbols, pseudo-technical labels, character imagery, perspective, cropped edges, cast shadow, reflection, neighboring sprites, watermark, or magenta inside the frame; no decoration inside the live-content bay; no resemblance to Containment Drone gunmetal tactical hardware; no chunky retro Federation Classic elbows; no transparent glass or blur; crisp edges and generous padding for chroma removal
```

## Refinement prompts

```text
Edit this exact transparent 1536 x 1024 sci-fi clinical calendar panel frame
for robust nine-slice scaling. Preserve the Federation 2399 materials and
corners, but remove every decorative midpoint module, badge, joint, notch,
flare, or mechanical interruption from all four edge spans. Between the
corner zones, make every horizontal and vertical edge one continuous,
repeat-safe stretch seam. Keep the center bay uniformly dark and opaque, the
exterior corners transparent, and all text, symbols, controls, and semantic
content absent.

Replace the exterior background with a perfectly flat #FF00FF chroma field,
then remove the two small amber side markers and replace them with the same
continuous burgundy/charcoal/cyan rail pattern above and below. Preserve the
front-facing composition and introduce no unique details in any stretch band.
```

## Integrated chassis prompt

```text
Use case: stylized-concept
Asset type: production 1536x1024 Android tablet nine-slice outer dashboard
chassis for the Clinical Calendar Federation 2399 theme
Input images: the approved landscape concept is a style/material/proportion
reference only; the prior production frame is the geometry/edit target
Primary request: create one original, standalone, front-facing outer tablet
dashboard chassis in the concept's dark integrated Federation 2399 language:
deep charcoal sculpted structure, restrained burgundy/plum inner layers, a
narrow cool-silver lip, fine cyan channels, restrained aged-amber corner
lights, and subtle pink edge accents
Composition: exact 1536x1024, flat #FF00FF exterior chroma field, fixed cuts
120/145/120/170, repeat-safe middle edge spans, distinctive hardware only in
the four corner zones, and one fully opaque uninterrupted dark center bay
Constraints: no internal panel dividers, text, logos, symbols, controls,
calendar content, perspective, external shadows, or semantic raster content
```

## Originality boundary

The asset is newly generated for Federation 2399. It does not import, recolor,
trace, or modify Containment Drone 47-Alpha or Federation Classic artwork. It
contains no operational content, protected production screen geometry,
insignia, labels, or meaningful controls.

## Concept-fidelity landscape chassis

Issue #134 adds the secondary concept-composition asset
`packages/clinical_calendar_presentation/assets/federation_2399_raster/dashboard-chassis-landscape-v1.png`.
It is a 1536 x 1024 opaque, non-semantic housing for the declared landscape
golden exemplar. SHA-256:
`3fd166d137f73eb9c5f9e4136b02cabd6003bb92b484f11f72d599df93de9794`.

The built-in image-generation workflow edited the approved issue #114 concept
as the normative geometry and material reference. The pass preserved its
outer silhouette, crown sweep, layered lips, understructure, light channels,
major bay proportions, and bottom-navigation housing while removing every
label, number, icon, grid, event, progress indicator, control, selection,
status mark, and other semantic element. Each content region is an opaque
charcoal bay populated only by live Flutter widgets at runtime.

This fixed chassis is used only by Federation 2399's exact landscape tablet
composition; it is not the bundle's primary normalized frame and is never
nine-slice scaled. `panel-nine-slice-v1.png` remains the transparent-corner,
120/145/120/170-cut primary frame required by the additive contract, and owns
portrait, compact, and destination framing. Neither asset imports, recolors,
traces, or modifies Containment Drone artwork.
