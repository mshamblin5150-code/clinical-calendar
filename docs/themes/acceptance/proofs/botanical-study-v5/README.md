# Botanical Study repair candidate v5

Issue: [#164](https://github.com/mshamblin5150-code/clinical-calendar/issues/164)

Status: **implementation candidate awaiting physical SM-X920 review**. The
approved issue #115 landscape remains the normative visual target, amended by
the maintainer decisions in #159 and #164. Automated evidence does not grant
physical acceptance. The decision on parent issue #139 remains **Pending**.

## Repair evidence

- `approved-concept-landscape.png`: untouched approved issue #115 concept.
- `runtime-landscape-1586x992.png`: deterministic Flutter render at the
  concept's native 1586 x 992 viewport and 100% text scale.
- `landscape-concept-vs-runtime.png`: labeled, equal-size side-by-side proof.
- `runtime-portrait-900x1440.png`: intentional portrait composition.
- `runtime-portrait-200-percent-900x1440.png`: 200% text-scale and overflow
  evidence.
- `runtime-destination-clinical-placements-1586x992.png`: focused proof that a
  top-level destination uses the Botanical Study crown, ruler, clipped
  research-paper bay, and specimen-border language around the shared live
  Clinical Placement workflow.

Renderer contract: `botanical-study-owned-research-desk-v1`.

The live crown now places the canonical Axion delta before **Clinical
Calendar**. The mark is loaded through the shared `CanonicalDeltaMark` source
established by #159 and remains excluded from semantics. No theme-local delta
drawing or duplicate asset was introduced.

All ten application-menu destinations render through one Botanical-owned
destination crown and shaped border bay rather than the generic additive
destination card. The destination wrapper changes presentation only; routing,
callbacks, state, persistence, validation, and the live destination children
remain shared.

The shared Add Assignment workflow from #166 keeps its existing callback and
calendar data source. Botanical Study now gives only its control a
theme-specific clipped specimen-label housing, while the fictional pending
Academic Assignment on August 31 proves the shared due-date projection in the
deterministic Calendar render.

The landscape similarity ratchet remains whole-image 0.94. The crown ratchet
is 0.948 to accommodate the maintainer-directed delta-first order, and the
Calendar ratchet is 0.929 to accommodate the required Academic Assignment
control and due-date projection. Placements, Planning, progress, attention,
and navigation retain their prior independent ratchets.

Containment Drone 47-Alpha code, assets, protected hashes, and goldens are
unchanged.

## SHA-256

```text
55a52746a1c8c0be62247d3e8840a3c4dd9cc0010b5f6aa8fb65abad91671329  approved-concept-landscape.png
41ed9a5275313cabdef4d130c03304feb38aa61544188d746a68449460479119  landscape-concept-vs-runtime.png
43641d51e953b2ee0fed0ea02b49bcb0ba38d5c5a542db5e7487ebfc0bdbb34f  runtime-destination-clinical-placements-1586x992.png
4a88988f4e69bc21ad87cf5d4f50373c1579678f1ee9fc64b9f95cee5373a46b  runtime-landscape-1586x992.png
98c69aa660d54698daf5a5b3d5a81397a6e97346ed85f8dd484943b13401f1e4  runtime-portrait-200-percent-900x1440.png
3bd09c04987e8fa40634790b09ff21c57fbdefd6c9c5b52de0fb6cc4317c12bc  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **not performed - Pending on #139**. No file in this package is a
physical-device capture, and no Accepted decision is inferred.
