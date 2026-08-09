# Federation Classic concept-fidelity candidate v6

Issue: [#133](https://github.com/mshamblin5150-code/clinical-calendar/issues/133)

Status: **REJECTED by the maintainer on 2026-08-09**. V6 corrected the outer
panel silhouettes, but the progress wheel still used a generic partial-ring
facsimile and the raster rails retained visible luminance bands that read as
an overlay. The text crown also did not carry the maintainer's Axion delta
identity. This package is retained only as a negative baseline.

The approved issue #113 concept is the independent normative source. V6 keeps
v5's seven-row Calendar, compact weekday labels, amber period state, stacked
navigation, condensed crown, and concept-density live regions. It replaces
the incorrect lower-left chassis block and two pill-shaped navigation endcaps
with concept-measured asymmetric LCARS elbows, branches, black separation
gaps, and the curved amber lower cap.

## Evidence

- `approved-concept-landscape.png`: untouched approved #113 concept.
- `runtime-landscape-1586x992.png`: deterministic production shell renderer
  with the production `CalendarPeriodView`, a deterministic Android system-bar
  fixture, and representative fictional live-slot content.
- `landscape-concept-vs-runtime.png`: equal-size labeled comparison.
- `runtime-portrait-900x1440.png`: intentional portrait recomposition.
- `runtime-portrait-200-percent-900x1440.png`: 200% text-scale proof.

Renderer contract: `federation-classic-owned-responsive-console-v6`.

The panel-shape regression measures boundary F1 independently from broad
colored-area overlap. At four-pixel tolerance, every isolated chassis segment
must score at least `0.80`; the rejected v5 lower-left cap and navigation caps
scored `0.6215`, `0.7409`, and `0.7268`. V6 scores `1.0000`, `0.8630`, and
`0.8700` respectively. The broader crown, left rail, right rail, and
navigation similarity ratchets remain in force. These automated checks make
the result reviewable but cannot grant visual approval.

## SHA-256

```text
9d7de52026ffe05e7bca073693a65be502afc74c7d805a28005e56d2c1877a14  approved-concept-landscape.png
c7d1ea127f22f304951dd4beafdd96dfbce42f61a7d42ae8dd5dc11d7d8bc4b2  landscape-concept-vs-runtime.png
bb9944d3f803a8ab124637eb4cc0e0dc522fdfb8c145941181a0b723ea10ed68  runtime-landscape-1586x992.png
580f324dceb5a38f54d57891959b868824bd1e4121870b9f4c74f7d36d38b714  runtime-portrait-200-percent-900x1440.png
f482a1f582db39eda7bf33bfea8b7a0ced60a2e0bb0b53e7ee2849826cb965da  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **not performed — pending under #139**. No file here is a physical
device capture, and no signing or protected release material was accessed.
