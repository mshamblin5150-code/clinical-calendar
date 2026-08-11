# Botanical Study delta-menu repair candidate v6

Issue: [#176](https://github.com/mshamblin5150-code/clinical-calendar/issues/176)

Status: **Pending physical SM-X920 review.** This deterministic package proves
the implementation candidate; it does not mark Botanical Study Accepted or
replace the explicit maintainer decision required on #139.

## Repair evidence

- `approved-concept-landscape.png`: untouched approved issue #115 concept.
- `runtime-landscape-1586x992.png`: deterministic Flutter render at the
  approved landscape viewport and 100% text scale.
- `landscape-concept-vs-runtime.png`: labeled equal-size concept/runtime
  comparison; neither source image is modified or stretched.
- `runtime-portrait-900x1440.png`: intentional portrait composition.
- `runtime-portrait-200-percent-900x1440.png`: 200% text-scale and overflow
  evidence.
- `runtime-destination-clinical-placements-1586x992.png`: unchanged proof of
  the Botanical-owned destination crown and border language around the shared
  Clinical Placement workflow.

The sole Botanical Study Application Menu control is now the catalog-owned
`CanonicalDeltaMark` established by #159. The landscape title is plain text,
the prior title-button and portrait/compact grid or hamburger affordances are
removed, and the unchanged 42 px delta receives a theme-owned approximately
2 px correction so its visible-ink center aligns with the `CLINICAL CALENDAR`
title line. Portrait and compact layouts use the same delta control; at 200%
text the title yields while the menu remains reachable.

Deterministic widget coverage proves one `Open menu` button semantic with a
tap action, direct pointer activation, keyboard Enter activation, switch-style
Space activation, exact callback routing, the
absence of competing menu/grid icons, visible-ink landscape centerline
alignment within 0.5 logical pixels, portrait behavior, compact behavior, and 200% text
behavior. The shared compact shell gained only an opt-in menu-control slot;
all other themes retain their existing default rendering.

The whole-image landscape similarity ratchet remains 0.94. The crown ratchet
is 0.946 after the explicit #176 crown revision; Calendar, Placements,
Planning, progress, attention, and navigation retain their prior independent
ratchets. Containment Drone 47-Alpha code, assets, protected hashes, and
goldens are unchanged.

## SHA-256

```text
55a52746a1c8c0be62247d3e8840a3c4dd9cc0010b5f6aa8fb65abad91671329  approved-concept-landscape.png
acfb349490cec05b101f995251ac0ff1a488b4736e75fcc143f5d379d0bede87  landscape-concept-vs-runtime.png
43641d51e953b2ee0fed0ea02b49bcb0ba38d5c5a542db5e7487ebfc0bdbb34f  runtime-destination-clinical-placements-1586x992.png
b93db7bd82d3e55d03810d7b631b97309437a8fb5c21ecbc634e8ff0386aa9ca  runtime-landscape-1586x992.png
3961c54787ae81d99149be67dd6bc2a3f21b1307b828d000c1e4b9ce1a506ae8  runtime-portrait-200-percent-900x1440.png
180d5e88f9a38d46af1b6c467a6c457fe0ad4749ecad6625659185caecefa303  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **Pending.** A new signed candidate must repeat physical Samsung
SM-X920 review under #139. Automated evidence cannot mark Botanical Study
Accepted, and no Windows or physical-phone acceptance is claimed.
