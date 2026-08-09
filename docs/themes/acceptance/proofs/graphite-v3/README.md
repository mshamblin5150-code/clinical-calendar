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

The accepted candidate measures above both bounds. The test uses the same
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
2930bd0862872803a9c46d33aea66c98f522992050d24b357e37473c246ceb11  landscape-concept-vs-runtime.png
e5cfc5731b641ab4fb75ebfc8339d361242b3c7e418d7be6add9a301f595b584  runtime-landscape-1536x1024.png
a1e5299b5de137c9140dfc2b8f6de8144012ee01fba58324929ea5c65053db9f  runtime-portrait-200-percent-900x1440.png
af4db6a8f9827d9a11bb86a7a93aac830e44e42fc3f48a308bcc2f621f2cff8c  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **Pending — deferred to #139**.

No physical build was installed and no signing material was accessed. Fresh
physical evidence must use fictional data and be attached to #139 for final
catalog device acceptance.
