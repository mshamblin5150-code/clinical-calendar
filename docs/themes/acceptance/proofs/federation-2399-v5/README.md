# Federation 2399 repair candidate v5

Issue: [#162](https://github.com/mshamblin5150-code/clinical-calendar/issues/162)

Status: **candidate awaiting physical SM-X920 review**. The deterministic
proofs pass automation, but Federation 2399 remains **Pending** until the
maintainer explicitly records an Accepted decision on #139.

This candidate retains the approved issue #114 silhouette and v4 bay geometry
while repairing the physical-review findings from #162:

- the crown now integrates Help, Add Placement, and the Student profile in one
  Federation 2399 command bank;
- Planning and Needs Attention use Federation 2399-owned recessed housings
  instead of the shared generic panel treatment;
- the Needs Attention label, accent rail, and `ON • count` capsule form one
  semantic heading and remain legible at standard and 200% text scale;
- the shared Academic Assignment workflow keeps its production callback and
  receives a Federation 2399-owned Add Assignment control housing;
- the crown and Calendar continue to consume the canonical #159 Axion delta;
  no theme-local delta copy or workflow logic was introduced; and
- Containment Drone 47-Alpha assets, renderer files, and accepted goldens are
  unchanged.

Renderer contract: `federation-2399-owned-responsive-console-v5`.

## Evidence

- `approved-concept-landscape.png`: untouched approved issue #114 concept.
- `runtime-landscape-1536x1024.png`: deterministic full-screen Flutter render
  at 100% text scale with fictional data.
- `landscape-concept-vs-runtime.png`: labeled comparison with both images
  displayed at 1536 by 1024.
- `runtime-portrait-900x1440.png`: deterministic intentional portrait
  composition at 100% text scale.
- `runtime-portrait-200-percent-900x1440.png`: deterministic initial portrait
  state at 200% text scale.
- `runtime-portrait-200-percent-scrolled-900x1440.png`: the lower 200% state,
  proving the Planning and Needs Attention content remains reachable above the
  fixed navigation deck.

All captures use fictional data. None is a physical-device capture.

## SHA-256

```text
a96da3c7cd060348aded17ec783c093128ef1e6ed3b31f53d1a3ec7793913cc8  approved-concept-landscape.png
5c15b234f5b0c3f180d3f5acbd58049f6f2a480d1c192eb53e3b2ec5540f0572  landscape-concept-vs-runtime.png
dbf77fe24adf80c91b62e6aec36f1cf21fef0ec134513faba68dd0ae1d08e466  runtime-landscape-1536x1024.png
023797504280802df1962d061acdbe2616335a98b32146876c73cd58d6f42fcc  runtime-portrait-200-percent-900x1440.png
4124db405bb9aec5bb0fc3f49279e72bdc9bda1f60ef6e3494508f047f05674d  runtime-portrait-200-percent-scrolled-900x1440.png
538a410fb55d012e3f164209a925ac4ce048d5f265ef8cf33e7af347bdb35b7a  runtime-portrait-900x1440.png
```

## Physical Android-tablet acceptance

State: **Pending — maintainer action required on #139**.

No build was installed and no physical-device acceptance is inferred by this
proof package. The next signed candidate must be reviewed on the approved
Samsung SM-X920 with fictional data before the maintainer may mark Federation
2399 Accepted.
