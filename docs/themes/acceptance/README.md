# Theme acceptance evidence harness

Issue: [#132](https://github.com/mshamblin5150-code/clinical-calendar/issues/132)

Theme acceptance is non-compensating. A theme remains **Pending** when any
required gate fails, is missing, or lacks the maintainer's physical
Android-tablet approval. Automated evidence supports that approval; it never
replaces it.

The executable harness lives at the presentation test boundary in
`test/support/theme_acceptance_harness.dart`; it is not shipped in the app. It
currently proves the repeatable contract against Containment Drone 47-Alpha
and Graphite while the closed seven-theme registry remains intentionally
incomplete.

## Automated command

Run from `packages/clinical_calendar_presentation`:

```powershell
$candidate = git rev-parse HEAD
& ..\..\.tooling\flutter\bin\flutter.bat test `
  test\theme_acceptance_report_test.dart `
  --dart-define=THEME_ACCEPTANCE_COMMIT=$candidate `
  --dart-define=THEME_ACCEPTANCE_BUILD=41 `
  --dart-define=THEME_ACCEPTANCE_OUTPUT_DIR=<absolute-output-directory>
```

The report runner writes one directory per implemented bundle containing:

- Standard and Enhanced runtime-token audits generated from constructed
  `ThemeData` and semantic extensions;
- primary-frame SHA-256, decoded geometry, transparent-corner, safe-inset,
  center-bay, creation-record, and originality results;
- explicit Pending records for the still-required runtime thumbnail capture
  and physical performance measurements; and
- a versioned manifest whose state remains Pending until every required report,
  original-resolution capture, and maintainer decision is present.

The full presentation suite also executes registry ownership, decoded
thumbnail dimensions/hash/runtime-swatch provenance, exact Containment Drone
equality, both directed theme swaps, live working-state preservation,
revision-aware persistence, fallback, theme Help, signed-out privacy, and
Standard/Enhanced accessibility checks.

## Physical performance evidence

Use the same approved Android tablet, profile build, display mode, refresh
rate, and `catalog-acceptance-fictional-v1` fixture as the pinned baseline.
Start with
`tool/android/capture_profile_baseline.ps1` for the existing frame-time and
retained-memory capture contract, then record candidate values in
`ThemePerformanceEvidence`:

- UI-thread and raster-thread p95 must fit the refresh interval and remain
  within 10 percent of baseline;
- a preflighted atomic swap must stabilize within 250 ms;
- 25 Preview/Revert/Apply cycles must show no monotonic retained-memory growth
  and finish within 10 percent of post-launch baseline; and
- release growth must be measured and fully attributed to approved manifest
  assets.

Do not invent zero measurements for acceptance. The automated report's
performance record stays `measurement-required` and does not create a passing
gate until real candidate values are supplied.

Acceptance additionally requires the physical Android visual gate, exact CI
run, approved signer-certificate SHA-256, Accessibility Scanner adjudication,
manual checklists, and original-resolution captures. Missing any one keeps the
manifest Pending even when every automated gate passes.

## Evidence safety

Use fictional fixtures only. Manifests reject fixture identifiers that are not
explicitly fictional, incomplete Git/SHA-256 identities, credential-bearing
links, and unapproved contrast exceptions. Never place Student identifiers,
email addresses, credentials, one-time codes, keys, signing material, or backup
passphrases in reports or captures.

Originality remains a maintainer judgment. Every new frame needs a retrievable
creation record and an explicit side-by-side approval against Containment
Drone; the harness deliberately does not substitute a similarity score.
