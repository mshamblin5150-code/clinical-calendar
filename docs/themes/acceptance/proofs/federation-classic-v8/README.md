# Federation Classic concept-fidelity candidate v8

Issue: [#133](https://github.com/mshamblin5150-code/clinical-calendar/issues/133)

Status: **candidate awaiting explicit maintainer visual approval**. Passing
tests and similarity checks do not grant approval.

V8 addresses the maintainer's rejection of v7:

- the Axion delta remains in the crown and the `CLINICAL CALENDAR` product
  name is restored in both landscape and portrait;
- the Student identity is centered at the approved amber-rail center
  `(1501, 74)` rather than at the crown's geometric center;
- the lower-left salmon segment is one continuous dark-salmon elbow without
  the overlapping rectangle that produced a square protruding strip; and
- the upper-left elbow and its thin lilac divider now preserve the concept's
  deliberate black separation gap.

The equal-size landscape comparison uses the approved #113 concept as the
independent normative source. The runtime capture mounts the production
Federation Classic shell and Calendar renderer with representative fictional
slot fixtures. Separate application integration tests mount the real Calendar,
Planning, PlacementDock, progress, Attention, and primary Planning action.

## Evidence

- `approved-concept-landscape.png`: untouched approved #113 concept.
- `runtime-landscape-1586x992.png`: deterministic production-shell capture.
- `landscape-concept-vs-runtime.png`: equal-size labeled comparison.
- `runtime-portrait-900x1440.png`: intentional portrait recomposition.
- `runtime-portrait-200-percent-900x1440.png`: 200% text-scale proof.

Renderer contract: `federation-classic-owned-responsive-console-v8`.

The automated ratchet checks every major LCARS junction independently:
upper-left and lower-left elbows, all three crown seams, the lower-right elbow,
and both navigation elbows. It also checks isolated chassis boundary F1,
broad crown/rail/navigation overlap, the production progress wheel, and crown
material banding. V8 records:

- crown/left rail/right rail/navigation IoU: `0.9183 / 0.9846 / 0.9700 / 0.7602`;
- upper-left/lower-left boundary F1: `0.9099 / 0.9601`;
- every other isolated chassis boundary F1: at least `0.8630`;
- progress-wheel IoU: `0.9142`; and
- runtime crown banding: `0.0000` versus concept `0.0041`.

These checks prevent a strong average elsewhere from hiding a broken corner,
but they cannot replace maintainer review.

## SHA-256

```text
9d7de52026ffe05e7bca073693a65be502afc74c7d805a28005e56d2c1877a14  approved-concept-landscape.png
f9796fad649a9af5d800b1e948c39212b1349d6814b68cd3767f189b35e4b308  landscape-concept-vs-runtime.png
5577c2e065f9a53f385602e8f1d2201623bf49c8d7b3975c8d2b78ce35352187  runtime-landscape-1586x992.png
2d07ac9d1dfd067017ebec7ef7eb81042befc17c1e1547ef8892f3a897c5366f  runtime-portrait-200-percent-900x1440.png
bb616f86ccdcb78865fe25df19c64629a133157ba5f58bc8fa4f1745b23ae7fd  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **not performed — pending under #139**. No file here is a physical
device capture, and no signing or protected release material was accessed.
