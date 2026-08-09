# Federation 2399 concept-fidelity candidate v4

Issue: [#134](https://github.com/mshamblin5150-code/clinical-calendar/issues/134)

Status: **candidate awaiting explicit maintainer visual approval**. Physical
Android-tablet acceptance is **pending**. Passing automation and this proof
package do not approve the theme.

Candidate v3 is explicitly rejected and remains historical evidence only. V4
addresses the maintainer's rejection by clipping all Federation 2399 day-cell
paint to the owning cell, replacing the Protected Day hatch with the approved
3 x 3 dot marker, using the production progress-wheel panel and both live
actions, restoring the approved 0/8/82-hour state and coral/amber wheel, and
measuring the wheel, action rail, and Calendar header against the approved
issue #114 concept.

## Evidence

- `approved-concept-landscape.png`: untouched approved issue #114 concept.
- `runtime-landscape-1536x1024.png`: deterministic full-screen Flutter render
  at the declared golden viewport, 100% text scale, fictional data.
- `landscape-concept-vs-runtime.png`: labeled, equal-size comparison of the
  approved concept and candidate runtime.
- `runtime-portrait-900x1440.png`: deterministic intentional portrait
  composition at 100% text scale, fictional data.
- `runtime-portrait-200-percent-900x1440.png`: deterministic 200% text-scale
  render with explicit horizontal and vertical scroll owners and reachable
  navigation.
- `runtime-portrait-200-percent-scrolled-900x1440.png`: the same 200% render
  scrolled to the lower extent, proving Placement Status and Needs Attention
  remain reachable above the fixed navigation deck.

Renderer contract: `federation-2399-owned-responsive-console-v4`.

The visual proof uses `PlacementProgressPanel`, the same production panel used
by `PlacementProgressRail`; it does not substitute a proof-only wheel or fake
action labels. Automated evidence independently compares the pixels of the day
preceding Protected Day, asserts the production interaction keys, rejects any
painted Containment Drone frame, and checks concept-measured coordinates.

The 1536 x 1024 bay oracle was measured from the untouched concept before
comparison with runtime. Integer bounds use a 3 px rendering tolerance:

| Region | Approved-concept bounds `(x, y, width, height)` |
| --- | --- |
| Command crown | `(40, 45, 1044, 76)` |
| Placements | `(54, 131, 261, 748)` |
| Calendar | `(361, 133, 734, 458)` |
| Planning | `(361, 625, 734, 251)` |
| Insight | `(1158, 85, 346, 791)` |
| Navigation | `(86, 916, 1364, 70)` |

## SHA-256

```text
a96da3c7cd060348aded17ec783c093128ef1e6ed3b31f53d1a3ec7793913cc8  approved-concept-landscape.png
495f91a78ff365377a269d6337be4e0bf14c8b22040c2f0d95b936cda3305d23  landscape-concept-vs-runtime.png
937dc02adccf49b3f776108d257468d497053b4e54e5fb8987fc03903a8dc410  runtime-landscape-1536x1024.png
9c8b312e8a2554db822d85dba2fe04e938c6231af539fb679af3cae5b6326277  runtime-portrait-200-percent-900x1440.png
1c33f32e6854e1a908d5d15797b076b1c02969eeae8029fbbebfb9825c498757  runtime-portrait-200-percent-scrolled-900x1440.png
3c5ac2b95c8f6a161fc18b0ffbcc6ea46e00e0102c37c6379a5cf9708ac4e26d  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **not performed — maintainer action required after visual approval**.

No file in this package is a physical-device photograph. No physical build was
installed, no signing material was accessed, and no acceptance decision is
inferred. Fresh physical evidence must use fictional data and be added only
after the maintainer accepts this deterministic landscape candidate.
