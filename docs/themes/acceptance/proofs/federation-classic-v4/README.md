# Federation Classic concept-fidelity candidate v4

Issue: [#133](https://github.com/mshamblin5150-code/clinical-calendar/issues/133)

Status: **candidate awaiting explicit maintainer visual approval**. This
package does not claim approval or physical Android-tablet acceptance. The
rejected v2 and v3 proofs remain immutable historical evidence and were used
only as negative baselines.

The approved issue #113 concept is the independent normative source. V4
corrects the v3 drift by preserving the concept's negative-space rail cutouts,
using measured segment and navigation geometry, and applying Federation
Classic-only presentation policies to the live Calendar, placement-progress,
and attention surfaces. Other themes retain their existing defaults.

## Evidence

- `approved-concept-landscape.png`: untouched approved #113 concept.
- `runtime-landscape-1586x992.png`: deterministic production shell renderer
  with the production `CalendarPeriodView` and representative fictional
  fixtures at the public Planning, Clinical Placements, progress, and
  attention slot boundary.
- `landscape-concept-vs-runtime.png`: equal-size labeled comparison.
- `runtime-portrait-900x1440.png`: Federation Classic's distinct vertical
  LCARS-spine portrait recomposition.
- `runtime-portrait-200-percent-900x1440.png`: the same public renderer at
  200% text scale with explicit vertical console and horizontal Calendar
  scrolling.

Renderer contract: `federation-classic-owned-responsive-console-v4`.

The separate `ClinicalCalendarApp` integration test renders this shell with
the actual production `CalendarPeriodView`, Planning region, `PlacementDock`,
`PlacementProgressRail`, and `AttentionRail`, including the real Planning
command surface. Automated checks also prove independent concept-measured
geometry, callback routing, responsive behavior, and immutable goldens. A
concept-chrome similarity check is pinned against rejected v3 so its rail and
navigation drift cannot recur. These checks support review but cannot grant
visual approval.

## SHA-256

```text
9d7de52026ffe05e7bca073693a65be502afc74c7d805a28005e56d2c1877a14  approved-concept-landscape.png
c496454433212da2610e2bbbc993fc26858058ff9d2426face88c941777e1c67  landscape-concept-vs-runtime.png
3e8b43f3860a5cc2fa232d9feb1dc53567cd6eb55a7c6d5dce33edfffed47a87  runtime-landscape-1586x992.png
5ddefa0af6acb7a9801d09f78b26ec3c5214a41af8b7ee55eefbbed88e228309  runtime-portrait-200-percent-900x1440.png
19cdf9cf7cd836916d3453093fcb536a23d57c9b5b3be3b6622558cc8bd64870  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **not performed — pending under #139**. No file here is a physical
device capture, and no signing or protected release material was accessed.
