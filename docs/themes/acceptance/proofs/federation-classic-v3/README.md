# Federation Classic concept-fidelity candidate v3

Issue: [#133](https://github.com/mshamblin5150-code/clinical-calendar/issues/133)

Status: **candidate awaiting explicit maintainer visual approval**. This
package does not claim approval or physical Android-tablet acceptance. The
rejected v2 proof remains immutable historical evidence and was not used as a
baseline.

The approved issue #113 concept is the independent normative source. The
landscape runtime uses concept-measured live-region rectangles at the native
1586 by 992 exemplar and piecewise Flutter-painted LCARS rails; it does not
stretch the rejected full-dashboard raster.

## Evidence

- `approved-concept-landscape.png`: untouched approved #113 concept.
- `runtime-landscape-1586x992.png`: deterministic production renderer with
  fictional Calendar, Planning, Clinical Placements, progress, and attention
  data.
- `landscape-concept-vs-runtime.png`: equal-size labeled comparison.
- `runtime-portrait-900x1440.png`: Federation Classic's distinct vertical
  LCARS-spine portrait recomposition.
- `runtime-portrait-200-percent-900x1440.png`: the same public renderer at
  200% text scale with explicit vertical console and horizontal Calendar
  scrolling.

Renderer contract: `federation-classic-owned-responsive-console-v3`.

Automated checks prove independent concept-measured geometry, shared live
content visibility, callback routing, responsive behavior, and immutable
goldens. They support review but cannot grant visual approval.

## SHA-256

```text
9d7de52026ffe05e7bca073693a65be502afc74c7d805a28005e56d2c1877a14  approved-concept-landscape.png
e53e7c53a45f1ea3bd5b0dda002b36d5660d1b74ef4b9b42b357126a3f4805f8  landscape-concept-vs-runtime.png
0ac3a75fea4f067b091124560cf35836d792e67079b368c25acf6bd7c931740a  runtime-landscape-1586x992.png
e4656bd8861911882e9b41d00f0c1c056f506728ec780910c6993decb4e7cecd  runtime-portrait-200-percent-900x1440.png
1b8f83fea1dadd06be45959eb4ad46d92770a6d80b3f15f57e0e0f38d48faec5  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **not performed — pending under #139**. No file here is a physical
device capture, and no signing or protected release material was accessed.
