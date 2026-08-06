# Plan the Seven-Theme Clinical Calendar Catalog

## Destination

Produce a decision-complete, implementation-ready theme catalog specification for six new Clinical Calendar themes alongside the unchanged Containment Drone 47-Alpha theme, with evidence-backed semantic palettes, approved Android-tablet concepts, theme-selection behavior, accessibility behavior, and measurable acceptance boundaries.

## Notes

- This is a planning map. Production Flutter implementation and release publication are outside the destination.
- Containment Drone 47-Alpha is the existing accepted theme and must not change in name, identifier, palette, artwork, framing, typography, Help guide, or rendered output.
- The catalog contains exactly seven curated, preference-based themes. Themes are never gender-labelled or gender-gated.
- The six additions are Federation Classic, Federation 2399, Botanical Study (working title), Coastal Calm (working title), Graphite, and Heritage Field Notes (working title).
- All themes preserve the same Clinical Calendar information architecture, workflows, domain language, responsive behavior, and control locations. Themes may change semantic colors, typography accents, icons, surfaces, and original high-resolution nine-slice housings.
- Federation Classic and Federation 2399 use original names and artwork: recognizable era-inspired design language without franchise logos, ship names, character imagery, copied screen graphics, meaningless technobabble, or copyrighted audio.
- All themes remain professional and suitable for clinical training. Decorative motifs stay in housing and noninteractive chrome, never behind calendar data or controls.
- Themes are static and visual-only. There are no theme-specific sounds, voice clips, notification sounds, or looping animated chrome.
- Each theme has one intentional luminance character rather than separate light/dark variants.
- Enhanced accessibility is one global optional mode layered over any theme. System text scaling and platform accessibility remain honored regardless of that toggle.
- Graphite is the default for new Students and always styles the signed-out in-app email/code verification surface. Existing Student theme selections remain authoritative after sign-in; the current maintainer Student Profile remains on Containment Drone 47-Alpha.
- Theme settings become a visual gallery with thumbnail, swatches, personality description, reversible Preview, and explicit Apply.
- Android tablet is the only current visual concept and physical acceptance target. Windows visual acceptance is deferred until the Windows app is built; phone hardware acceptance is deferred until equipment is available. Existing compact-layout regression coverage must not deteriorate.
- The maintainer is the sole visual approver. External cohort testing is out of scope.
- Research notes belong under `docs/research/themes/` and must use high-trust primary sources, cite claims, and distinguish sourced facts from design inference.
- Before production panel-art work, follow `docs/agents/variant-f-raster-frames.md`; new themes receive original high-resolution nine-slice assets and never recolor the Containment Drone housing.

## Decisions so far

- [Research the Federation Classic Semantic Palette](issues/01-research-federation-classic-palette.md) — Use an original near-black plum, warm amber/salmon, and lilac system with broad rounded rails, verified contrast, redundant state cues, and no claimed canonical franchise hex values.
- [Research the Federation 2399 Semantic Palette](issues/02-research-federation-2399-palette.md) — Use a distinct original charcoal, restrained plum/burgundy, aged amber, and cool-light system with fine segmentation, verified contrast, and redundant state cues.
- [Research the Botanical Study Semantic Palette](issues/03-research-botanical-study-palette.md) — Use accessibility-calibrated warm ivory, sage/eucalyptus, dusty rose, orchid, and aubergine semantics with botanical motifs confined to noninteractive chrome.
- [Research the Coastal Calm Semantic Palette](issues/04-research-coastal-calm-palette.md) — Use accessibility-calibrated shell white, mist, sea-glass teal, clear blue, warm sand, and controlled coral semantics without literal beach decoration.
- [Research the Graphite Semantic Palette](issues/05-research-graphite-palette.md) — Align the neutral default and signed-out in-app verification identity with the launcher’s charcoal/silver character plus restrained teal, using complete dark semantic mappings and deterministic accessibility overrides.
- [Research the Heritage Field Notes Semantic Palette](issues/06-research-heritage-field-notes-palette.md) — Use an archival-inspired warm stone, forest, walnut, muted brass, and oxblood system without faux distress or military styling; retain the display name as provisional until concept approval.
- [Research Cross-Theme Accessibility and Semantic Color Requirements](issues/07-research-cross-theme-accessibility-semantics.md) — Make WCAG 2.2 AA the baseline with Enhanced accessibility off, then let the optional global mode strengthen contrast, redundant cues, focus, and decorative restraint.

## Not yet specified

- Final names for Botanical Study, Coastal Calm, and Heritage Field Notes remain subject to concept approval.
- Exact Flutter implementation tickets and platform rollout sequencing will be derived after the decision-complete catalog specification.

## Out of scope

- Changing or re-accepting Containment Drone 47-Alpha.
- Production implementation, signed builds, deployment, or release publication.
- User-authored colors, custom themes, downloadable theme packs, and automatic light/dark switching.
- Theme-specific audio, voice, notification sounds, or looping animation.
- Styling the Supabase email message itself.
- External NP-student cohort research or preference testing.
- Claiming Windows or phone visual acceptance before those targets are available.
