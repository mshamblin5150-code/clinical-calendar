# Containment Drone pre-catalog reference renders

These files freeze the accepted Standard-mode Containment Drone 47-Alpha
presentation before theme-catalog plumbing. The fixture uses deterministic,
fictional January 2026 data and an Android target platform. Exact baselines are
stored separately for Windows development hosts and the pinned Linux CI runner
because Flutter's raster backend is host-dependent.

Coverage includes compact, portrait-tablet, and landscape/desktop Calendar;
320-pixel Settings; and every top-level application-menu destination. The test
loads repository-owned text and Material icon fonts so raster comparisons do
not depend on host fonts.

Run from `packages/clinical_calendar_presentation`:

```powershell
& ..\..\.tooling\flutter\bin\flutter.bat test `
  test\clinical_calendar_app_test.dart `
  --plain-name 'accepted pre-catalog Variant F renders'
```

Do not use `--update-goldens` during catalog maintenance. Re-baselining needs a
separate issue, explicit maintainer approval, new physical Android-tablet
evidence, and a dedicated change.
