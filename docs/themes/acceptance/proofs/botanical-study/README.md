# Botanical Study concept-fidelity candidate

Issue: [#135](https://github.com/mshamblin5150-code/clinical-calendar/issues/135)

Status: **candidate awaiting explicit maintainer visual approval**. Physical
Android-tablet acceptance is **pending** and remains part of final catalog
device acceptance in #139. Passing automation and this proof package do not
approve the theme.

The approved issue #115 dashboard concept is copied byte-for-byte and remains
the normative visual reference. All runtime captures use fictional data.

## Evidence

- `approved-concept-landscape.png`: untouched approved issue #115 concept.
- `runtime-landscape-1600x1000.png`: deterministic full-screen Flutter test
  render at the declared golden viewport and 100% text scale.
- `landscape-concept-vs-runtime.png`: labeled equal-size comparison of the
  approved concept and deterministic runtime.
- `runtime-portrait-900x1440.png`: deterministic full-screen Flutter test
  render of the intentional portrait composition at 100% text scale.
- `runtime-portrait-200-percent-900x1440.png`: deterministic full-screen
  Flutter test render at 200% text scale. Calendar remains the primary region;
  the explicit vertical scroll owner exposes Planning, Clinical Placements,
  progress, and attention while navigation remains reachable.

Declared landscape exemplar: **1600 x 1000**.

Renderer contract: `botanical-study-owned-research-desk-v1`.

The runtime consumes the shared live Calendar, Planning, Clinical Placements,
progress, attention, and navigation slots. Theme-owned Flutter composition
supplies the research-desk hierarchy, crown, paper bays, bottom navigation,
and portrait re-composition. The original normalized nine-slice raster owns
only decorative nonsemantic chrome; no clinical state or workflow logic is
theme-local.

## SHA-256

```text
55a52746a1c8c0be62247d3e8840a3c4dd9cc0010b5f6aa8fb65abad91671329  approved-concept-landscape.png
288132b2e6f8a65ba08b35218d6ffce956cf448ee19e8023e641ff849b9e4ce7  landscape-concept-vs-runtime.png
2a24acbe1ac752a80c52e62fe64458adabec4025ef23c096ac834f1289f6c690  runtime-landscape-1600x1000.png
33ab786472a7b6244596437b585060b33b685d190821b67ddcba12370618a5ca  runtime-portrait-900x1440.png
f1153a633fb7b77598655538cc5f08b95aabc7ed6ee01e34dbafe36425359720  runtime-portrait-200-percent-900x1440.png
```

## Physical Android-tablet acceptance

State: **not performed — pending in #139 after maintainer visual approval**.

No file in this package is a physical-device capture. No physical build was
installed, no signing material was accessed, and no acceptance decision is
inferred. Fresh physical evidence must use fictional data.
