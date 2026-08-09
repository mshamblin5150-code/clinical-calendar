# Federation Classic concept-fidelity candidate v5

Issue: [#133](https://github.com/mshamblin5150-code/clinical-calendar/issues/133)

Status: **candidate awaiting explicit maintainer visual approval**. This
package does not claim approval or physical Android-tablet acceptance. The
rejected v2 through v4 proofs remain immutable negative baselines.

The approved issue #113 concept is the independent normative source. V5 adds
the concept's seven-row Calendar, compact weekday labels, amber period state,
stacked bottom navigation, selected placement treatment, condensed crown,
clean LCARS rail material, concept-density attention cards, and measured
internal offsets. The comparison includes a deterministic Android system-bar
fixture above the actual production shell; operational application content is
still supplied through the shell's public live slots.

## Evidence

- `approved-concept-landscape.png`: untouched approved #113 concept.
- `runtime-landscape-1586x992.png`: deterministic production shell renderer
  with the production `CalendarPeriodView`, a deterministic Android system-bar
  fixture, and representative fictional Planning, Clinical Placements,
  progress, and attention slot fixtures.
- `landscape-concept-vs-runtime.png`: equal-size labeled comparison.
- `runtime-portrait-900x1440.png`: Federation Classic's distinct vertical
  LCARS-spine portrait recomposition.
- `runtime-portrait-200-percent-900x1440.png`: the same public renderer at
  200% text scale with explicit vertical console and horizontal Calendar
  scrolling.

Renderer contract: `federation-classic-owned-responsive-console-v5`.

The separate `ClinicalCalendarApp` integration test renders the shell with the
actual production `CalendarPeriodView`, Planning region, `PlacementDock`,
`PlacementProgressRail`, and `AttentionRail`, including the real Planning
command surface. The landscape raster is explicitly preloaded before capture;
two consecutive captures produce the same SHA-256. Concept-chrome thresholds
are pinned above rejected v4, and independent structural tests assert seven
Calendar rows, compact weekday labels, stacked navigation, geometry, callback
routing, responsive behavior, and immutable goldens. These checks support
review but cannot grant visual approval.

## SHA-256

```text
9d7de52026ffe05e7bca073693a65be502afc74c7d805a28005e56d2c1877a14  approved-concept-landscape.png
835d584be25853c995773a2da92c2d621e33a3a4c37d5242b43108f6b90a631f  landscape-concept-vs-runtime.png
90ba3b831dcf2443e1df861a742f5db976b413a6d176fad7ce002681048b08df  runtime-landscape-1586x992.png
580f324dceb5a38f54d57891959b868824bd1e4121870b9f4c74f7d36d38b714  runtime-portrait-200-percent-900x1440.png
f482a1f582db39eda7bf33bfea8b7a0ced60a2e0bb0b53e7ee2849826cb965da  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **not performed — pending under #139**. No file here is a physical
device capture, and no signing or protected release material was accessed.
