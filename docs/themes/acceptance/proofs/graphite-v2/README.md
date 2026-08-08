# Graphite concept-fidelity candidate v2

Issue: [#128](https://github.com/mshamblin5150-code/clinical-calendar/issues/128)

Status: deterministic concept-fidelity candidate. The approved #117 concept
remains the normative visual reference. Physical Android-tablet acceptance is
**Pending** under #139; no deterministic render is presented as a device
capture.

Graphite declares **1536 by 1024** as its exact landscape golden viewport.
The renderer uses the Graphite-owned precision-instrument composition and
production nine-slice asset while consuming the shared live Calendar,
Planning, Clinical Placements, progress, attention, and navigation slots. It
does not own clinical state, validation, persistence, callbacks, or workflow
logic.

## Evidence

- `approved-concept-landscape.png`: untouched approved issue #117 concept.
- `runtime-landscape-1536x1024.png`: deterministic full-screen Flutter render
  at 100% text scale with fictional data.
- `landscape-concept-vs-runtime.png`: labeled equal-size comparison; both
  images are displayed at 768 by 512 pixels.
- `runtime-portrait-900x1440.png`: deterministic full-screen Flutter render of
  the intentional portrait recomposition at 100% text scale.
- `runtime-portrait-200-percent-900x1440.png`: deterministic full-screen
  Flutter render at 200% text scale. Calendar remains first in the reading
  order; one vertical scroll owner reaches Planning, placement, and attention,
  and Calendar owns the explicit horizontal overflow path.

Renderer contract: `graphite-owned-responsive-instrument-v2`.

The landscape silhouette follows the approved three-column hierarchy: a
monolithic crown, left Clinical Placements dock, Calendar over Planning in the
dominant center bay, right progress/attention rail, and full-width bottom
navigation. Graphite uses its own matte charcoal, silver-edge, emerald-signal,
and coral-attention language. No Federation 2399, Federation Classic, or
Containment Drone artwork is imported or rendered.

## SHA-256

```text
1d37e9c2c0f97a2428fbebfd0fc2b5d6e85e3281a634fa16ca2c67479ec24e4e  approved-concept-landscape.png
d634a03a3e1b70f8fffb3c10ed07416e4c89b0770289a6123124a29040e08464  landscape-concept-vs-runtime.png
85af47272104230dc698e6d940164677078ab40029bd232eae21e53db0709deb  runtime-landscape-1536x1024.png
256d40b21484561ac7fb2b13985b2df30a1a7c1cecfdad1147cdcf72fc132e73  runtime-portrait-200-percent-900x1440.png
5de8e6887261c9ab863eb4fd20ded413005ba97928fc377199afb1feb976ad24  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **Pending — deferred to #139**.

No physical build was installed and no signing material was accessed for this
ticket. Fresh physical evidence must use fictional data and must be attached
to #139 for final catalog device acceptance.
