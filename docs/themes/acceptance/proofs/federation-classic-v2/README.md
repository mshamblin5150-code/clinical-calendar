# Federation Classic concept-fidelity candidate v2

Issue: [#133](https://github.com/mshamblin5150-code/clinical-calendar/issues/133)

Status: **candidate prepared for maintainer visual approval**. Physical
Android-tablet acceptance is **pending under #139**. Passing automation and
this proof package do not claim physical-device acceptance.

The approved issue #113 concept is copied byte-for-byte because it is the
normative visual reference. The exact landscape exemplar is the concept's
native 1586 by 992 viewport.

## Evidence

- `approved-concept-landscape.png`: untouched approved issue #113 concept.
- `runtime-landscape-1586x992.png`: deterministic full-screen Flutter test
  render at the exact approved-concept viewport, 100% text scale, fictional
  data.
- `landscape-concept-vs-runtime.png`: labeled side-by-side comparison with
  both 1586 by 992 images displayed at equal size.
- `runtime-portrait-900x1440.png`: deterministic full-screen Flutter test
  render of the intentional portrait composition, 100% text scale,
  fictional data.
- `runtime-portrait-200-percent-900x1440.png`: deterministic full-screen
  Flutter test render at 200% text scale. The Calendar remains the first live
  region, with explicit horizontal Calendar scrolling and vertical console
  scrolling for the remaining portrait regions.

Renderer contract: `federation-classic-owned-responsive-console-v2`.

The candidate consumes the production shared Calendar, Planning, Clinical
Placements, progress, attention, and navigation seams. Federation
Classic-owned Flutter geometry supplies its command crown, asymmetric LCARS
elbows, landscape proportions, integrated navigation deck, and portrait
recomposition. No clinical state, validation, persistence, or workflow logic
is theme-local.

## SHA-256

```text
9d7de52026ffe05e7bca073693a65be502afc74c7d805a28005e56d2c1877a14  approved-concept-landscape.png
91dd3ecdafa725de0843c65a043b42142f237a490445ab04ea1ccf440d4ea132  landscape-concept-vs-runtime.png
6257914284bf2dfc37a318830b3bd278db65b9752c8acc04a29b2e0b9c27506b  runtime-landscape-1586x992.png
c4bd5eee4a5c330e53451ab2b1fe706a027513f48c13b020414d7f1cc2c28561  runtime-portrait-200-percent-900x1440.png
dba16c57918902953870c48453f5a60e6ba889c40ec441aa38e3d6bdf6d3de69  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **not performed — pending under #139**.

No file in this package is a physical-device capture. No physical build was
installed, no signing material was accessed, and no device acceptance is
inferred. Fresh physical evidence must use fictional data and remain part of
the final catalog-device acceptance owned by #139.
