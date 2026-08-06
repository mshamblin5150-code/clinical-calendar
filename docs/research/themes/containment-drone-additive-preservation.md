# Containment Drone 47-Alpha additive-preservation research

## Answer

The seven-theme catalog can be added without changing the rendered Containment
Drone 47-Alpha identity, but not by treating a theme as `ThemeData` alone. The
safe boundary is **preservation by isolation**: keep `variant-f` as an adapter
over its existing theme builder, shell, raster widgets, painters, assets, and
Help guide; put every new identity behind a separate complete-bundle renderer.
Resolve one complete bundle before constructing `MaterialApp` and the shell.

This is necessary because the current abstraction swaps only `ThemeData`
([`theme_contract.dart`, lines 5-20](../../../packages/clinical_calendar_presentation/lib/src/theme_contract.dart)),
while the rendered shell directly constructs Variant F chassis, tactical
frames, four raster bays, rails, and hardware
([`responsive_shell.dart`, lines 121-220](../../../packages/clinical_calendar_presentation/lib/src/responsive_shell.dart),
[`responsive_shell.dart`, lines 319-440](../../../packages/clinical_calendar_presentation/lib/src/responsive_shell.dart)).
A palette-only catalog would put all six new identities inside Containment
Drone art. Conversely, replacing those calls with a newly generalized frame
implementation would put the accepted Containment render at risk.

## Baseline that exists today

The repeatable framing procedure identifies signed private-release build 37 as
the physical Android verification baseline
([`variant-f-raster-frames.md`, lines 12-14](../../agents/variant-f-raster-frames.md)).
That build corresponds to the high-resolution nine-slice work in commit
`1ef05bd989329da0f97c13009717c339ce9b9807`. The historical physical log records
build 37 (`A15CEADA...6D49`) on a Samsung SM-X920 and inspection of Calendar plus
all ten top-level destinations
([`.scratch/clinical-calendar-mvp/issues/86-package-and-verify-android-app.md`, line 54](../../../.scratch/clinical-calendar-mvp/issues/86-package-and-verify-android-app.md)).

The latest recorded physical follow-up is signed build 39
(`498A4557...A2E34`), sourced by the portrait refinement commit
`dcfa83eb87f8e1b773a1d036c801668ddf169ebf`; it rechecked Calendar and the same
destinations after responsive content changes
([the historical log, line 55](../../../.scratch/clinical-calendar-mvp/issues/86-package-and-verify-android-app.md)).
These are audited render baselines, not a claim of subjective pixel parity with
an external reference.

The current four raster assets are unchanged from their introducing commits.
Their acceptance contract should freeze both bytes and paths:

| Asset | Size | SHA-256 | Introduced |
| --- | ---: | --- | --- |
| `panel-nine-slice-v2.png` | 1536x1024, 1,217,635 bytes | `9ff3968a94d497dc6f76f2b14f370c5a24c3bb4969397ee220da005093c15ad7` | `1ef05bd989329da0f97c13009717c339ce9b9807` |
| `hardware-atlas.png` | 1774x887, 628,620 bytes | `0abc02903e8fb954fe80fb91e71aaaa7ee5a5020160e7138cb8b75e516f949e1` | `c2eb723f48361c7832b9fb55f58def674fda757e` |
| `panel-atlas.png` | 1254x1254, 1,019,583 bytes | `01df9ab1ee87dc41852dd61c8193a7b453eb92695e323bf1861ba891120d65ae` | `c2eb723f48361c7832b9fb55f58def674fda757e` |
| `rail-atlas.png` | 1402x1122, 406,490 bytes | `2acf4e26ad10db07a49fadcf78064e24d04724ad680390508593f06761cb2649` | `c2eb723f48361c7832b9fb55f58def674fda757e` |

The four corner pixels of `panel-nine-slice-v2.png` currently have alpha zero,
consistent with the documented transparent-corner contract
([`variant-f-raster-frames.md`, lines 18-34](../../agents/variant-f-raster-frames.md)).

## Current coupling points

1. **Application resolution is static.** `ClinicalCalendarApp` defaults to
   `VariantFVisualTheme`, constructs `MaterialApp.theme` from it, and passes its
   ID to Help
   ([`clinical_calendar_app.dart`, lines 40-46 and 95-110](../../../packages/clinical_calendar_presentation/lib/src/clinical_calendar_app.dart)).
   Production constructs the app without another theme
   ([`main.dart`, lines 387-425](../../../apps/clinical_calendar/lib/main.dart)).
   Student Settings load later inside the already-themed child host
   ([`clinical_calendar_app.dart`, lines 685-701](../../../packages/clinical_calendar_presentation/lib/src/clinical_calendar_app.dart)).

2. **The shell is the real identity renderer.** Desktop and mobile always use
   `VariantFMechanicalChassis`; compact headers, destination surfaces, and
   navigation use `VariantFTacticalFrame`; the tablet layout creates
   `VariantFRasterPanelFrame` and the Variant F rail/hardware sprites directly
   ([`responsive_shell.dart`, lines 121-220 and 319-440](../../../packages/clinical_calendar_presentation/lib/src/responsive_shell.dart)).
   `VariantFTacticalFrame` always delegates to `VariantFNineSliceFrame`
   ([`tactical_frame.dart`, lines 12-65](../../../packages/clinical_calendar_presentation/lib/src/tactical_frame.dart)).

3. **Some shared-looking code is still palette-specific.** The compact status
   rail and cells reference `VariantFColors` directly
   ([`responsive_shell.dart`, lines 730-786](../../../packages/clinical_calendar_presentation/lib/src/responsive_shell.dart));
   the painters do likewise
   ([`tactical_frame.dart`, lines 145-163 and 246-250](../../../packages/clinical_calendar_presentation/lib/src/tactical_frame.dart)).
   The semantic `ClinicalCalendarColors` extension is sound in principle, but
   its missing-extension fallback is itself Variant F
   ([`variant_f_theme.dart`, lines 416-423](../../../packages/clinical_calendar_presentation/lib/src/variant_f_theme.dart)).

4. **Persistence and rendering are currently disconnected.** `StudentSettings`
   defaults to `variant-f`
   ([`support_models.dart`, lines 175-194](../../../packages/clinical_calendar_application/lib/src/support/support_models.dart));
   SQLite normalizes legacy `borg_tactical` to `variant-f`
   ([`sqlite_repository_registry.dart`, lines 2845-2870 and 3077-3078](../../../packages/clinical_calendar_local_data/lib/src/repositories/sqlite_repository_registry.dart));
   Settings currently offers only Containment Drone
   ([`settings_templates_surface.dart`, lines 232-245](../../../packages/clinical_calendar_presentation/lib/src/support/settings_templates_surface.dart)).
   Saving a different ID would not currently rebuild the root theme or shell.

5. **Help is separate rather than atomic.** The registry contains only the
   Variant F guide and falls back to a generic guide that borrows
   `VariantFColors.muted`
   ([`theme_contract.dart`, lines 45-114](../../../packages/clinical_calendar_presentation/lib/src/theme_contract.dart)).
   That is incompatible with the approved complete-Graphite fallback unless
   Help resolution moves into the same complete bundle resolution.

## Preservation invariants

### Byte invariants

- The four paths, dimensions, byte lengths, SHA-256 values, and transparent
  corners listed above remain unchanged.
- `variant-f` continues to load from `assets/variant_f_raster`; catalog assets
  use other roots. The current loader fixes that root and production panel path
  ([`variant_f_raster_assets.dart`, lines 5-6 and 109-112](../../../packages/clinical_calendar_presentation/lib/src/variant_f_raster_assets.dart)).

### Code invariants

- `variant-f` delegates to the existing `buildVariantFTheme()`; its palette,
  typography, Material component themes, semantic extension, and metrics remain
  the values now defined at
  [`variant_f_theme.dart`, lines 154-413](../../../packages/clinical_calendar_presentation/lib/src/variant_f_theme.dart).
- Its shell delegate is the existing `ResponsiveApplicationShell`, not a
  newly parameterized or copied generic frame implementation.
- Its frames remain `VariantFMechanicalChassis`, `VariantFTacticalFrame`,
  `VariantFNineSliceFrame`, `VariantFRasterPanelFrame`, and the existing
  raster sprites/painters. The first catalog change should not edit
  `variant_f_theme.dart`, `variant_f_raster_assets.dart`,
  `mechanical_pixel_tiles.dart`, `tactical_frame.dart`, or
  `responsive_shell.dart`; any later edit to those files requires explicit
  re-baselining evidence.

### Behavior and geometry invariants

- Nine-slice source cuts remain left/top/right/bottom `120/145/120/170`, with
  the same nine `drawImageRect` operations and `FilterQuality.high`
  ([`variant_f_raster_assets.dart`, lines 211-283](../../../packages/clinical_calendar_presentation/lib/src/variant_f_raster_assets.dart)).
- Frame padding and `Clip.hardEdge` remain owned by the frame
  ([`variant_f_raster_assets.dart`, lines 127-139](../../../packages/clinical_calendar_presentation/lib/src/variant_f_raster_assets.dart)).
- Minimum panel insets remain Calendar `38/46/38/46`, Placements
  `30/44/30/44`, Planning `34/46/34/42`, and Status `30/44/34/44`; caller
  padding may only increase them
  ([`variant_f_raster_assets.dart`, lines 170-208](../../../packages/clinical_calendar_presentation/lib/src/variant_f_raster_assets.dart)).
- `VariantFRasterPanelInterior` continues to suppress nested competing shells
  ([`variant_f_raster_assets.dart`, lines 65-77](../../../packages/clinical_calendar_presentation/lib/src/variant_f_raster_assets.dart)).
- Choosing, previewing, applying, restarting into, or falling back away from
  another theme must not mutate any `variant-f` setting or bundle component.

### Render invariants

At fixed Flutter SDK, platform, surface size, device-pixel ratio, text scale,
locale, font assets, clock, and fixture data, the `variant-f` pre-catalog and
catalog code paths must rasterize identically. This includes Calendar at all
eight current shell viewports, Settings at 320 px, and all top-level
destinations. Flutter's first-party `matchesReferenceImage` matcher is designed
to compare two rendered code paths, while `matchesGoldenFile` stores a master
render; both operate on the first `RepaintBoundary` ancestor of a matched
widget ([`matchesReferenceImage`](https://api.flutter.dev/flutter/flutter_test/matchesReferenceImage.html),
[`matchesGoldenFile`](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html)).

## What current tests do not prove

The existing tests establish valuable structure but no image equivalence:

- `tactical_frame_test.dart` checks that a raster frame, clip, painters, and
  children exist and that asset decoding raises no exception
  ([lines 14-34 and 82-117](../../../packages/clinical_calendar_presentation/test/tactical_frame_test.dart)).
- Its clipping test finds a descendant `ClipRect`, but does not inspect escaped
  pixels; its crop test checks normalized ranges, not rendered atlas content
  ([lines 119-186](../../../packages/clinical_calendar_presentation/test/tactical_frame_test.dart)).
- The app test exercises eight viewports and no-overflow behavior
  ([`clinical_calendar_app_test.dart`, lines 14-84](../../../packages/clinical_calendar_presentation/test/clinical_calendar_app_test.dart))
  and asserts four tablet frames with no nested tactical frame
  ([lines 149-180](../../../packages/clinical_calendar_presentation/test/clinical_calendar_app_test.dart)).
- Theme coverage samples five semantic colors and two metrics only
  ([`clinical_calendar_app_test.dart`, lines 699-723](../../../packages/clinical_calendar_presentation/test/clinical_calendar_app_test.dart)).
- The presentation tests contain no `matchesGoldenFile` or
  `matchesReferenceImage` use, and there is no automated asset-hash test.

Consequently, the suite can pass after a raster replacement, palette drift,
typography drift, changed source cuts, changed filtering, or subtle painter and
inset changes. Flutter documents that its local golden comparator performs an
exact decoded-PNG pixel comparison by default
([`goldenFileComparator`](https://api.flutter.dev/flutter/flutter_test/goldenFileComparator.html)),
while also warning that fonts and platforms can produce differences; the test
environment must therefore be pinned rather than tolerances silently widened.

## Regression and acceptance evidence strategy

1. **Before catalog plumbing**, record the hashes above in a checked-in
   contract test; assert dimensions, four alpha-zero corners, asset paths,
   cuts, insets, and the seven immutable IDs. Fail rather than update a hash
   automatically.
2. **Build the catalog around Variant F**, not through it. A catalog bundle
   owns `ThemeData`, shell/chrome renderer, frame metadata/assets, gallery
   metadata, and Help. The `variant-f` bundle returns existing implementations;
   each new bundle returns its own. Registry validation rejects duplicates and
   incomplete bundles before resolution.
3. **Add a pre/post isolation equivalence harness.** In one test process,
   render the legacy direct `VariantFVisualTheme` + existing shell path and the
   catalog-resolved `variant-f` path under identical fixtures and compare their
   `RepaintBoundary` images with `matchesReferenceImage`. This proves the new
   indirection is additive without making a newly generated image the truth.
4. **Add pinned goldens** for the accepted portrait tablet Calendar, compact
   phone Calendar, landscape/desktop Calendar, 320 px Settings, Help, and every
   top-level destination. Keep the existing structural, clipping, and full
   responsive-matrix tests. Golden updates require an explicit Variant F visual
   review; they are never a routine catalog-update step.
5. **Exercise transitions:** applied Variant F -> preview another theme ->
   Revert; applied another theme -> preview Variant F; restart with Variant F;
   unknown ID -> complete Graphite without altering the stored ID. Capture the
   Variant F frame before and after each round trip and compare it exactly.
6. **Repeat physical Android acceptance** from
   [`variant-f-raster-frames.md`, lines 142-169](../../agents/variant-f-raster-frames.md)
   as an upgrade on the same supported tablet class. Verify signer/version and
   preserved fictional data, capture original-resolution Calendar and all ten
   destinations, and compare against the build-39 audit while checking content
   boundaries and pixelation. Device screenshots supplement deterministic
   test goldens; they do not replace them.

## Research limitation

The current workspace has no `flutter` executable on `PATH`, so the two
documented baseline test commands could not be rerun during this research.
This note reports inspected source, tests, assets, git objects/history, and
recorded physical evidence; implementation acceptance must run the targeted
presentation tests, the full presentation package, and repository quality and
release contracts in the configured Flutter environment.
