# Containment Drone pre-catalog performance baseline

Issue: [#125](https://github.com/mshamblin5150-code/clinical-calendar/issues/125)

The machine-readable Android-tablet baseline is captured from the installed
profile build with the fixed `containment-drone-fictional-v1` fixture. The
command records Flutter UI and raster-thread p95 frame work, retained PSS
before and after the sample, the active display refresh rate, device/build
metadata, the exact commit, and the profile artifact SHA-256.

From the repository root:

```powershell
& .\tool\android\capture_profile_baseline.ps1 `
  -BuildArtifactSha256 <profile-apk-sha256> `
  -BuildCommit <40-character-commit> `
  -SampleSeconds 10 `
  -AutomateFocusedFlow `
  -OutputPath .\docs\performance\evidence\containment-drone-profile.json
```

Before capture, install a profile build containing only fictional acceptance
data and leave the Calendar visible in its steady state. The command refuses a
non-debuggable installed package, requires a fixture explicitly named
`fictional`, omits the device serial, and does not collect application content.
Keep raw identity, authentication, signing, and release-configuration material
out of the evidence directory.

The committed JSON is the pinned candidate-comparison input. Run
`tool/android/profile_baseline_contract_test.ps1` whenever the capture contract
changes. Do not substitute release-mode or emulator measurements for this
physical Android-tablet profile baseline.

The pinned issue #125 sample exercises Calendar, Week, Agenda, an Agenda
scroll, and Calendar again during a 10-second bounded Flutter timeline. The
automated flow is pinned to the 2960x1848 landscape SM-X920 profile rig and
fails closed on another display geometry. The capture command restarts the app
by default; use `-SkipRestart` only when an external harness has just restarted
and isolated that exact fresh process.
