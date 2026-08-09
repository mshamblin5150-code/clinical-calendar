# Botanical Study concept-fidelity candidate v3

Issue: [#135](https://github.com/mshamblin5150-code/clinical-calendar/issues/135)

Status: **candidate awaiting explicit maintainer visual approval**. The
approved issue #115 landscape remains the normative visual target. Automation
and this package demonstrate fidelity but do not grant visual approval.
Physical Android-tablet acceptance remains pending in #139.

## Evidence

- `approved-concept-landscape.png`: untouched approved issue #115 concept.
- `runtime-landscape-1586x992.png`: deterministic Flutter render at the
  concept's native 1586 x 992 viewport and 100% text scale.
- `landscape-concept-vs-runtime.png`: labeled, equal-size side-by-side proof.
- `runtime-portrait-900x1440.png`: intentional portrait composition.
- `runtime-portrait-200-percent-900x1440.png`: 200% text-scale evidence.

Renderer contract: `botanical-study-owned-research-desk-v1`.

Candidate v3 corrects the Calendar header, Today treatment, grid weight,
Planning workflow enclosure and time controls, placement spacing, progress
semantics, attention list, crown ruler, and navigation geometry. It also
includes the Axion company mark from
`assets/botanical_study_raster/axion-delta-mark-v2.png` in the live command
crown.

The runtime uses the shared Calendar renderer and production application slots.
Botanical Study owns only its concept-derived chassis, placement geometry,
semantic marker treatment, header, navigation, and responsive composition.
All representative words, numbers, icons, clinical state, and workflow data
are rendered live by Flutter.

The landscape proof requires at least 0.94 whole-image RGB similarity and also
ratchets every major region independently: crown 0.95, placements 0.94,
Calendar 0.93, Planning 0.925, progress 0.95, attention 0.94, and navigation
0.95. This prevents the large cream chassis from masking a weak content bay.

## SHA-256

```text
55a52746a1c8c0be62247d3e8840a3c4dd9cc0010b5f6aa8fb65abad91671329  approved-concept-landscape.png
52006ac7fe685f2849ec16834716bc129d908c5a226c61565097180fa78bb6fb  landscape-concept-vs-runtime.png
009558e8231372d9b84d5f42ea45106db5749defbf081ce93dca33ec2515a5b5  runtime-landscape-1586x992.png
798ad02825a8f0d83981f040b376e168d44e5a4dd9dda832da026d15a60e18f8  runtime-portrait-200-percent-900x1440.png
693c9e4edc4d521aae1045655157f0dd6b35977f84883df61cd43a16862928ca  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **not performed - pending in #139 after maintainer visual approval**.
No file in this package is a physical-device capture.
