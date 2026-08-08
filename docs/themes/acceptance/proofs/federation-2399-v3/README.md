# Federation 2399 concept-fidelity candidate v3

Issue: [#134](https://github.com/mshamblin5150-code/clinical-calendar/issues/134)

Status: **candidate awaiting explicit maintainer visual approval**. Physical
Android-tablet acceptance is **pending**. Passing automation and this proof
package do not approve the theme.

This package replaces, but does not delete, the rejected `d1cfbff` evidence
under `../federation-2399/`. No rejected runtime image or golden was reused.
The approved issue #114 concept is copied byte-for-byte because it remains the
normative visual reference.

## Evidence

- `approved-concept-landscape.png`: untouched approved issue #114 concept.
- `runtime-landscape-1536x1024.png`: deterministic full-screen Flutter test
  render at the declared golden viewport, 100% text scale, fictional data.
- `landscape-concept-vs-runtime.png`: labeled equal-size comparison of the
  approved concept and the candidate runtime.
- `runtime-portrait-900x1440.png`: deterministic full-screen Flutter test
  render of the intentional portrait composition, 100% text scale,
  fictional data.
- `runtime-portrait-200-percent-900x1440.png`: deterministic full-screen
  Flutter test render at 200% text scale. The initial viewport keeps the live
  Calendar primary, exposes a deliberate vertical scroll owner for the
  remaining portrait regions, and keeps navigation reachable.

Renderer contract: `federation-2399-owned-responsive-console-v3`.

The candidate uses the production Federation 2399 raster chassis and live
shared Calendar, Planning, Clinical Placements, progress, attention, and
navigation surfaces. Theme-owned Flutter geometry supplies the concept's
deeper crown, landscape proportions, sculpted nested bays, integrated bottom
deck, and portrait re-composition. No clinical state or workflow logic is
theme-local.

## SHA-256

```text
a96da3c7cd060348aded17ec783c093128ef1e6ed3b31f53d1a3ec7793913cc8  approved-concept-landscape.png
ce33946e021dca5ba2d9cd795c0e1f81b82a5170d2cb8cf8979497e25aa7190a  landscape-concept-vs-runtime.png
2af41b87e5e15ceb4895400933cdb1c3addcf880f94bc0bd53e2b68b77f94292  runtime-landscape-1536x1024.png
644421db0e34407d5875a0d3efecb086145ff307b009077a005bf23a4f5e0c46  runtime-portrait-900x1440.png
e1b768380862a93f6ab7a5741484c0140005703d8ced9edd773203528e8f7042  runtime-portrait-200-percent-900x1440.png
```

## Physical Android-tablet acceptance

State: **not performed — maintainer action required after visual approval**.

No file in this package is a physical-device photograph. No physical build
was installed, no signing material was accessed, and no acceptance decision
is inferred. Fresh physical evidence must use fictional data and be added
only after the maintainer accepts this deterministic landscape candidate.
