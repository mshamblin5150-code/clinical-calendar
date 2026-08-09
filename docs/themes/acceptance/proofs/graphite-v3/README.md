# Graphite direct concept-fidelity candidate v3

Issue: [#128](https://github.com/mshamblin5150-code/clinical-calendar/issues/128)

Status: **Pending explicit maintainer visual approval.** This package replaces
the rejected `graphite-v2` candidate for review, but passing automation does
not approve it. Physical Android-tablet acceptance remains **Pending** under
#139; no deterministic render is presented as a physical-device capture.

Graphite declares **1536 by 1024** as its exact landscape golden viewport.
Renderer contract: `graphite-owned-responsive-instrument-v3`.

## Direct comparison gate

The landscape proof test loads the untouched approved concept directly from
`docs/concepts/themes/graphite/calendar-dashboard-concept-v1.png` and creates
its 384 by 256 comparison image in memory with deterministic area averaging,
rather than trusting a separately committed derivative or only comparing
against a self-generated runtime golden. The public
`GraphiteApplicationShell` must satisfy both of these bounds:

- mean RGB-channel similarity at least `0.93`;
- pixels within 32 levels in every RGB channel at least `0.82`.

The current candidate measures above both bounds. The test uses the same
1536 by 1024 live Flutter render recorded below. Runtime goldens remain exact
on the canonical Windows environment; the existing bounded non-Windows font
rasterization policy remains separate from this concept comparison.

The similarity gate deliberately compares the authored Graphite semantic
tokens from `docs/research/themes/graphite-palette.md`, not colors sampled
from the illustrative concept. Shell-only chrome uses separate decorative
material constants where needed; the shared signed-out/fallback and domain
semantic palette remains unchanged.

The concept shows two Protected Days in several calendar weeks. The runtime
deliberately keeps one per calendar week because Student data and domain
invariants remain normative even when a concept fixture conflicts with them.

The crown uses `axion-delta-mark-v2.png`, a delta-only derivative of the Axion
reference supplied by the maintainer on 2026-08-09. The built-in image editor
removed the `AXION` wordmark and gray backdrop while preserving the polished
silver delta-and-orbit identity on a flat magenta key. The standard chroma-key
helper then produced a transparent 1254 by 1254 PNG with four alpha-zero
corners. The runtime displays that metallic raster directly, without a tint;
the code-painted delta remains only as an asset-load failure fallback.

The Planning evidence also reserves at least 48 pixels between the END field
and the outer planning-bay boundary. The current 1536 by 1024 proof measures
68 pixels, preventing the end time from reading across the surrounding chrome.

## Evidence

- `approved-concept-landscape.png`: untouched approved issue #117 concept.
- `runtime-landscape-1536x1024.png`: deterministic full-screen Flutter test
  render at 100 percent text scale with fictional, domain-valid data.
- `landscape-concept-vs-runtime.png`: labeled equal-size comparison; both
  images are displayed at 768 by 512 pixels.
- `runtime-portrait-900x1440.png`: deterministic full-screen Flutter test
  render of the intentional portrait recomposition.
- `runtime-portrait-200-percent-900x1440.png`: deterministic full-screen
  Flutter test render at 200 percent text scale with explicit vertical and
  Calendar-horizontal scroll ownership.

The renderer consumes shared live Calendar, Planning, Clinical Placements,
progress, attention, profile, navigation, and command seams. It does not own
clinical state, validation, persistence, callbacks, or workflows. The
Graphite-only Calendar instrument policy defaults off, leaving every other
theme renderer path unchanged. Containment Drone assets and renderer files
remain untouched.

## SHA-256

```text
1d37e9c2c0f97a2428fbebfd0fc2b5d6e85e3281a634fa16ca2c67479ec24e4e  approved-concept-landscape.png
c00807dfca5db3f6370e3f60a4210cd2d8f67c1742e3533333299f787288e232  landscape-concept-vs-runtime.png
a14c874d9d50faa571ab2edf9e858b8832d4166a1aa5f502dc1e35aa6c76195e  runtime-landscape-1536x1024.png
6f46bbbd58e1987224218899585753ed34eb8239ef9fd9a7f14d948a0744c126  runtime-portrait-200-percent-900x1440.png
bd5a10ce5d2ee4d7d2161b31381b234ca7b431a0d5525936fe743d9e41f216d7  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **Pending — deferred to #139**.

No physical build was installed and no signing material was accessed. Fresh
physical evidence must use fictional data and be attached to #139 for final
catalog device acceptance.
