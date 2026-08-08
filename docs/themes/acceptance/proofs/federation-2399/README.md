# Federation 2399 acceptance proofs

Issue: [#134](https://github.com/mshamblin5150-code/clinical-calendar/issues/134)

Status: **rejected by the maintainer on 2026-08-08** because the runtime is not
visually close enough to the approved concept. These files are retained as
historical comparison evidence only. They are not an acceptance baseline or a
target for the next implementation. Keep issue #134 open.

The landscape capture is the golden exemplar. It renders the production
`Federation2399ShellRenderer` at 1536 x 1024 with fictional calendar data. The
portrait capture renders the same shell contract at 900 x 1440 with an
intentional tablet reflow. Both are deterministic Flutter runtime captures at
1.0 text scale, not photographs from a physical tablet.

Files:

- `approved-concept-landscape.png`: approved issue #114 concept reference.
- `implemented-runtime-landscape-1536x1024.png`: landscape runtime golden.
- `implemented-runtime-portrait-900x1440.png`: portrait runtime golden.
- `landscape-concept-vs-runtime.png`: labeled side-by-side comparison.

Renderer contract: `federation-2399-owned-responsive-console-v2`

SHA-256:

```text
a96da3c7cd060348aded17ec783c093128ef1e6ed3b31f53d1a3ec7793913cc8  approved-concept-landscape.png
997c92714c24cc558fd261560e32f65195caa35f47d7a9da84ca4900db557285  implemented-runtime-landscape-1536x1024.png
1f649a149fe17b0e21ec44ddca28282a4021fe6dcd1289a1ce8474d5f9974e9c  implemented-runtime-portrait-900x1440.png
4b928e6d6afd0bcd3fce547f075350e6c3361dbf2828cdf4b99d952a82a1c7f3  landscape-concept-vs-runtime.png
```

Physical Android tablet acceptance was not performed for this rejected
candidate. No debug build was installed over an existing device package. A
replacement candidate requires fresh deterministic proofs before physical
acceptance.

The replacement must follow
`docs/themes/concept-fidelity-renderer-contract.md` and produce a new,
independently versioned proof package.
