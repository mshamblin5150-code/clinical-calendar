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

The 2026-08-09 maintainer amendment adds the supplied Axion delta to the
command crown without the `AXION` wordmark. The Federation bundle owns its
transparent copy as `axion-delta-mark-v1.png`; the runtime displays the
metallic raster directly without a flattening tint. The Planning proof also
shortens the schedule-template row and enforces at least 48 pixels between the
END field and the planning-bay boundary so `16:00` cannot overlap the chrome.

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
138f08a371680cf2e8de22e91451e62152eb8f06be98eacb3410ca6768358eb1  landscape-concept-vs-runtime.png
3d8c2c8408d13066457750b7060e9f96f62dc876202120a54fc4e1f2561356e4  runtime-landscape-1536x1024.png
60240ecef08de85a752f0f3918470c2aac68ab85d28b1586da2af0a40828bd9d  runtime-portrait-200-percent-900x1440.png
804a4af74ae713d795dc1ff869ab2893712b86949e5b291ecd53fe577bbcfb93  runtime-portrait-200-percent-scrolled-900x1440.png
723ed49228f7e388fbc0a14f5c60f306128e9587288b9e55a7cf9b0db8d86d51  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **not performed — maintainer action required after visual approval**.

No file in this package is a physical-device photograph. No physical build was
installed, no signing material was accessed, and no acceptance decision is
inferred. Fresh physical evidence must use fictional data and be added only
after the maintainer accepts this deterministic landscape candidate.
