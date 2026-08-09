# Botanical Study rejected proof (historical)

Issue: [#135](https://github.com/mshamblin5150-code/clinical-calendar/issues/135)

Status: **rejected as a fidelity baseline**. This package records the earlier
1600 x 1000 sparse-shell candidate and must not be used for acceptance or
golden approval. The replacement candidate is in `../botanical-study-v2/`.
Physical
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
4a7e571475dee8520268a6b80dd11d7f707043d352398d600d7398cb8b5b7e6b  landscape-concept-vs-runtime.png
b0fe1f8adda4c9de9e169cc61a6deb3feb77159b1556e315549a65115c35ef71  runtime-landscape-1600x1000.png
1f35f33d8bd2376add0b1e04672ff974811f9b71bda2ca6139414361be62c3e4  runtime-portrait-900x1440.png
f1153a633fb7b77598655538cc5f08b95aabc7ed6ee01e34dbafe36425359720  runtime-portrait-200-percent-900x1440.png
```

## Physical Android-tablet acceptance

State: **not performed - pending in #139 after maintainer visual approval**.

No file in this package is a physical-device capture. No physical build was
installed, no signing material was accessed, and no acceptance decision is
inferred. Fresh physical evidence must use fictional data.

## Automated gate evidence

The following repository-standard gates passed on Windows at the candidate
commit using the checked-in fictional fixtures and production assets:

- Botanical bundle, callback, portrait-order, Enhanced-token, and unchanged
  existing-renderer tests;
- deterministic landscape, portrait, 200%-text, and real-renderer thumbnail
  goldens, independently;
- the Botanical-applicable non-compensating harness checks, including Standard
  and Enhanced runtime contrast, normalized asset geometry and SHA-256,
  thumbnail provenance, Help, fallback, persistence, and every cross-theme
  Preview/Revert/Apply transition;
- the full `clinical_calendar_presentation` suite; and
- `dart run tool/quality.dart` across every package and application.

The partial registry intentionally remains fail-closed and non-selectable until
all seven complete bundles exist, as required by the additive-theme contract.
Botanical Study can be previewed and its setting persisted in this development
slice; restart resolves Graphite fallback until the closed catalog activates.
Accordingly, the catalog-wide registry-activation manifest remains `pending`;
it is not represented as a passing Botanical gate.
