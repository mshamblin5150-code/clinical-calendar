# Botanical Study concept-fidelity candidate v2

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

The runtime uses the shared Calendar renderer and production application slots.
Botanical Study owns only its concept-derived chassis, placement geometry,
semantic marker treatment, header, navigation, and responsive composition.
The landscape chassis contains no words, numbers, icons, clinical state, or
workflow data; all representative content is rendered live by Flutter.

The landscape proof independently compares a downsampled runtime capture with
the untouched approved concept and requires at least 0.94 RGB similarity. It
also asserts the exact concept-native viewport and theme-owned bay geometry.

## SHA-256

```text
55a52746a1c8c0be62247d3e8840a3c4dd9cc0010b5f6aa8fb65abad91671329  approved-concept-landscape.png
3cd68b445176723a571e66e4143f85ed68a15f108aede3da6d7a446b005f32d9  landscape-concept-vs-runtime.png
fc5671870c970eeceea41f6df07368325e32b17c99f0618700b3704e454fb998  runtime-landscape-1586x992.png
8750db5f925c1a4f2fde7e2f339445f01f37fc6ff04ad08f9c4c5770a7466947  runtime-portrait-200-percent-900x1440.png
75bc6248506c14689859b53a4fa5bf7006b09afe50cc6ac41a5e5b96f767c410  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **not performed - pending in #139 after maintainer visual approval**.
No file in this package is a physical-device capture.
