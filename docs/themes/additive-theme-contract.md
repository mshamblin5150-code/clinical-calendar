# Additive theme contract

Status: amended by the binding concept-fidelity renderer contract on
2026-08-08. Issue #112 remains authoritative for catalog completeness,
behavior, persistence, accessibility, and Variant F preservation; fixed
tablet geometry for concept themes is superseded.

Parent plan: [Plan the Seven-Theme Clinical Calendar Catalog](https://github.com/mshamblin5150-code/clinical-calendar/issues/104).

Evidence: [Containment Drone 47-Alpha additive-preservation research](../research/themes/containment-drone-additive-preservation.md) and [cross-theme accessibility and semantic-color contract](../research/themes/cross-theme-accessibility-semantics.md).

## Outcome

Clinical Calendar ships one closed catalog of exactly seven curated visual
identities. Every identity changes presentation only. All themes preserve the
same domain language, Student data, workflows, information architecture,
workflow reachability, and accessibility semantics. Concept themes may own
responsive composition and control placement under
[`concept-fidelity-renderer-contract.md`](concept-fidelity-renderer-contract.md).

Containment Drone 47-Alpha remains the accepted existing identity. With
Enhanced accessibility off, catalog work must preserve its identifier,
palette, typography, Help guide, frame geometry, raster bytes, widget behavior,
and rendered output exactly.

## Catalog identities

Identifiers are immutable machine values and do not change when an approved
display name is refined.

| Identifier | Display name at contract approval |
| --- | --- |
| `variant-f` | Containment Drone 47-Alpha |
| `federation-classic` | Federation Classic |
| `federation-2399` | Federation 2399 |
| `botanical-study` | Botanical Study (working title) |
| `coastal-calm` | Coastal Calm (working title) |
| `graphite` | Graphite |
| `heritage-field-notes` | Heritage Field Notes (working title) |

The registry is compile-time and closed. It rejects duplicate identifiers and
incomplete bundles. Runtime registration, remote theme definitions,
downloadable packs, placeholders, user-authored colors, and hidden partial
themes are prohibited.

## Complete bundle contract

A selectable `ClinicalCalendarThemeBundle` must provide all of these
components as one atomic unit:

1. immutable identifier, approved display name, and personality description;
2. opaque standard semantic tokens and Enhanced accessibility overrides;
3. complete Flutter `ThemeData`;
4. shell/chrome renderer;
5. normalized nine-slice descriptor and original theme assets;
6. renderer-generated gallery thumbnail and five semantic swatches;
7. stable non-color Calendar and status marks;
8. complete theme-specific Help guide.

Conceptually, resolution returns the whole bundle rather than resolving its
parts independently:

```dart
abstract interface class ClinicalCalendarThemeBundle {
  String get id;
  ThemeCatalogMetadata get metadata;
  ClinicalCalendarSemanticTokens get standardTokens;
  ClinicalCalendarEnhancedOverrides get enhancedOverrides;
  ThemeData createThemeData({required bool enhanced});
  ClinicalCalendarShellRenderer get shellRenderer;
  ThemeFrameDescriptor get frame;
  ThemeGalleryAssets get gallery;
  ClinicalCalendarSemanticMarks get marks;
  ThemeHelpGuide get helpGuide;
}
```

The concrete implementation may refine these type names, but it must preserve
the atomic ownership and validation boundary. A valid bundle may never borrow
a missing palette, frame, mark, gallery asset, or Help entry from another
identity.

Semantic tokens and redundant marks must satisfy the complete requirements in
the cross-theme accessibility contract. `ThemeData` alone is not a complete
theme.

## Renderer lanes

The initial catalog uses two renderer lanes over the same workflow
controllers, domain services, loaded Student data, and live content surfaces:

- `variant-f` delegates to the existing `buildVariantFTheme()`,
  `ResponsiveApplicationShell`, frames, painters, raster loaders, and Help
  guide.
- The six additions consume shared live content slots and workflow callbacks.
  A theme may use the shared additive shell where it satisfies its approved
  concept, or own its tablet composition under the concept-fidelity renderer
  contract. Shared behavior and semantics are fixed; tablet geometry is not.

This separation remains a preservation boundary. A later, separate GitHub
issue may converge implementation infrastructure, but convergence does not
require identical theme geometry. The legacy Variant F lane may be removed
only after the replacement path produces exact reference-image equality for
`variant-f`, leaves its asset hashes and geometry unchanged, passes the full
responsive suite, and receives fresh physical Android-tablet approval.

## Containment Drone preservation boundary

### Frozen assets

The following paths, dimensions, byte lengths, and SHA-256 values are
immutable during additive catalog work:

| Asset | Dimensions and bytes | SHA-256 |
| --- | --- | --- |
| `assets/variant_f_raster/panel-nine-slice-v2.png` | 1536x1024; 1,217,635 | `9ff3968a94d497dc6f76f2b14f370c5a24c3bb4969397ee220da005093c15ad7` |
| `assets/variant_f_raster/hardware-atlas.png` | 1774x887; 628,620 | `0abc02903e8fb954fe80fb91e71aaaa7ee5a5020160e7138cb8b75e516f949e1` |
| `assets/variant_f_raster/panel-atlas.png` | 1254x1254; 1,019,583 | `01df9ab1ee87dc41852dd61c8193a7b453eb92695e323bf1861ba891120d65ae` |
| `assets/variant_f_raster/rail-atlas.png` | 1402x1122; 406,490 | `2acf4e26ad10db07a49fadcf78064e24d04724ad680390508593f06761cb2649` |

Paths are relative to
`packages/clinical_calendar_presentation`. The panel's four corner pixels keep
alpha zero.

### Frozen renderer behavior

- Nine-slice source cuts remain left/top/right/bottom
  `120/145/120/170` pixels.
- The painter retains the same nine `drawImageRect` operations and
  `FilterQuality.high` behavior.
- Frames continue to own padding and `Clip.hardEdge` content clipping.
- Minimum content insets remain:

  | Panel | Left | Top | Right | Bottom |
  | --- | ---: | ---: | ---: | ---: |
  | Calendar | 38 | 46 | 38 | 46 |
  | Placements | 30 | 44 | 30 | 44 |
  | Planning | 34 | 46 | 34 | 42 |
  | Status/attention | 30 | 44 | 34 | 44 |

- `VariantFRasterPanelInterior` continues to suppress nested competing shells.
- The existing palette, typography, component themes, semantic extension,
  metrics, Help title, and Calendar-state descriptions remain unchanged.
- Choosing, previewing, applying, restarting into, or falling back from
  another theme cannot mutate a `variant-f` bundle component.

The initial catalog change must not edit `variant_f_theme.dart`,
`variant_f_raster_assets.dart`, `mechanical_pixel_tiles.dart`,
`tactical_frame.dart`, or `responsive_shell.dart`. Any later proposed change
to these files, the frozen assets, hashes, or accepted goldens is blocked from
an additive catalog PR. Re-baselining requires a separate issue, explicit
maintainer approval, fresh physical Android evidence, and a dedicated PR.

Build 37 and commit `1ef05bd989329da0f97c13009717c339ce9b9807` are the
canonical nine-slice physical baseline. Build 39 and commit
`dcfa83eb87f8e1b773a1d036c801668ddf169ebf` are the latest recorded responsive
physical follow-up.

## New-theme frame contract

Each of the six additions owns original artwork. It must never import,
recolor, trace, or modify Containment Drone raster art.

Every new primary frame uses the normalized geometry contract:

- 1536x1024 transparent source;
- source cuts at `120/145/120/170` pixels;
- the same panel-safe content insets listed above;
- transparent exterior corners;
- one calm, opaque, uninterrupted live-content bay;
- decoration confined to noninteractive chrome;
- no baked-in text, controls, meaningful icons, state information, cast
  shadows outside the housing, or semantic nodes.

Artwork may differ radically. Theme-owned shells may move live controls and
change tablet breakpoints when required by an approved concept, provided they
preserve the behavioral, semantic, accessibility, and evidence requirements
in the concept-fidelity renderer contract. Motifs may never obscure Calendar
data or interactive content.

## Gallery contract

Settings replaces the one-option theme dropdown with an accessible visual
gallery.

Each card contains the approved display name, personality description,
renderer-generated thumbnail, five labelled swatches, selection state, and
Preview action. The five swatches always appear in this order:

1. Canvas;
2. Structure;
3. Clinical Session;
4. Work Shift;
5. Urgent.

Each swatch's accessible label contains its semantic role and the theme's
plain-language color name. Color is not the only cue.

Thumbnails are deterministic renders of the real bundle using one fixed,
fictional Android-tablet Calendar fixture and viewport. They contain no real
Student data and are not separate marketing illustrations. A renderer change
requires regeneration and visual review.

Selecting a card chooses a candidate only. It does not alter the effective or
persisted theme. The Student must successfully Preview the candidate before
Apply becomes available.

## Effective-theme resolution

The app resolves exactly one complete effective bundle before constructing
`MaterialApp` and the shell.

| State | Effective presentation |
| --- | --- |
| Any unauthenticated state | Graphite |
| Authentication succeeded; settings still resolving | Graphite loading transition; authenticated shell remains hidden |
| Valid cached signed-in setting while offline | The cached complete bundle |
| Valid synchronized `themeId` | The matching complete bundle |
| Unknown or unavailable applied ID | Complete Graphite bundle, while preserving the stored ID |
| Valid applied bundle fails runtime validation/loading | Complete Graphite bundle, while preserving the stored ID |
| Optional Preview candidate fails preflight | Keep the valid applied bundle; report Preview unavailable |
| Graphite itself cannot construct or decode | Code-only accessible recovery surface |

An unknown applied ID is never overwritten automatically. Settings states
that the saved theme is unavailable in this app version and that Graphite is
shown temporarily. Graphite is labelled **Fallback in use**, not **Applied**.
No available card is falsely marked as the stored selection. Explicitly
previewing and applying an available theme replaces the unknown ID normally.

The terminal code-only recovery surface uses Graphite base colors, contains no
decorative assets and no Calendar or Student data, and offers Restart plus
non-sensitive diagnostic guidance. It never borrows Containment Drone assets.

## Preview and Apply state machine

Preview is a signed-in, full-app, session-only presentation overlay.

1. The Student selects a candidate card.
2. Preview preflights and decodes the candidate's complete bundle off the live
   renderer.
3. A failed preflight leaves the applied theme visible, reports **Preview
   unavailable**, and keeps Apply disabled.
4. A successful Preview atomically swaps the entire app to the candidate. No
   crossfade or token/asset interpolation is allowed.
5. A persistent **Previewing _theme_** control exposes Apply and Revert while
   the Student navigates through the app.
6. Revert atomically restores the latest authoritative applied theme.
7. Apply writes `StudentSettings.themeId` transactionally. It becomes
   authoritative only after persistence succeeds.
8. Failed Apply keeps the clearly labelled Preview visible, preserves the old
   applied ID, reports the failure, and offers Retry and Revert.
9. Successful Apply removes Preview state and synchronizes through the normal
   settings flow.

Sign-out, app-process termination, or explicit Revert discards Preview. App
background/resume within the same live process retains it. Preview state is
never synchronized, backed up, restored, or exported.

If another device changes the synchronized theme during Preview, the Preview
remains visible while the incoming value becomes the new authoritative base.
The app reports that the applied theme changed on another device. Revert
returns to that latest value. Apply uses revision checks and cannot silently
overwrite a newer settings revision.

Every theme swap changes presentation only. It preserves the current
destination, Calendar period and selection, scroll positions, open forms,
unsaved field values, valid focus, controllers, and loaded Student data.

While Preview is active, theme-specific Help describes the previewed bundle.

## Persistence and migration

Applied theme is an account-level, synchronized Student preference in
`StudentSettings.themeId`. Enhanced accessibility is a separate synchronized
boolean and does not create fourteen themes.

Before changing the new-Student default, migration must preserve or create
`variant-f` settings for every pre-catalog Student. Only Students created after
that migration default to `graphite`. Existing `variant-f` and normalized
legacy `borg_tactical` selections remain authoritative.

The immutable `themeId` and Enhanced boolean travel wherever synchronized
Student settings travel, including portable backup/restore and
settings-inclusive exports. Theme assets and transient Preview state do not.
Restore preserves unknown identifiers and uses the same Graphite fallback.

## Signed-out Graphite and accessibility

Graphite owns every unauthenticated state: launch, email entry, code entry,
resend/cooldown, validation errors, offline/error states, expired session, and
sign-out confirmation. No cached Student theme is revealed before
authentication and settings resolution succeed.

The Graphite verification surface exposes a device-local Enhanced
accessibility toggle so authentication itself can receive the stronger
presentation. After sign-in, the Student's synchronized Enhanced value becomes
authoritative. The signed-out value does not write or merge into the account
setting.

The signed-in Enhanced switch takes effect immediately and saves
transactionally, independently of theme Preview/Apply. Failed persistence
restores the prior value and reports the error. Changing Enhanced while a
theme Preview is active survives theme Revert.

Every theme meets the baseline accessibility contract with Enhanced off.
Enhanced may strengthen semantic tokens, live text, focus, outlines, marks,
and decorative restraint. System text scaling, bold text, reduced motion,
inversion, navigation, and platform accessibility services remain authoritative
in both modes.

For Containment Drone, Enhanced is an explicit overlay exception. It cannot
edit raster bytes, frame geometry, responsive layout, identity, workflows, or
domain content. Turning Enhanced off must restore the exact frozen standard
rendering.

## Help contract

Shared workflow Help is theme-independent. Every bundle's theme guide contains
the same ordered semantic entries:

1. Clinical Session;
2. Work Shift;
3. Protected Day;
4. Scheduled progress;
5. Today or urgent.

Each entry includes the theme-specific swatch, plain-language visual
description, redundant non-color cue, and Enhanced accessibility behavior.
Unknown or invalid applied themes resolve the complete Graphite guide rather
than a generic guide borrowing another theme's colors.

## Acceptance gates

### Static and contract gates

- exactly seven unique immutable IDs;
- every bundle complete and internally owned;
- required semantic tokens, tested pairings, prohibited pairings, and marks;
- frame paths, dimensions, cuts, safe insets, transparent corners, and no
  semantic raster content;
- frozen Variant F paths, bytes, hashes, geometry, palette, typography, Help,
  and renderer files;
- migration preserves all pre-catalog Students on `variant-f`;
- no incomplete bundle or partial catalog can enter the selectable registry;
- concept themes satisfy the landscape-exemplar, portrait, deterministic
  proof, and explicit-maintainer-approval requirements in the
  concept-fidelity renderer contract.

### Automated presentation matrix

All seven themes run with Enhanced off and on across the Android-tablet target
viewport, the 320-logical-pixel compact regression viewport, and the existing
responsive shell matrix. Shared workflow behavior remains one suite;
parameterized theme tests cover bundle completeness, semantics, overflow,
control reachability and callback behavior, theme-owned layout evidence, Help,
Preview/Apply/Revert, fallback, synchronization, and state preservation.

Before catalog plumbing, add automated Variant F asset hash/dimension/corner
checks. Then compare the pre-catalog direct path with catalog-resolved
`variant-f` under identical fixtures using exact `matchesReferenceImage`
comparisons. Add pinned goldens for portrait-tablet, compact, and
landscape/desktop Calendar; 320-pixel Settings; Help; and every top-level
destination. Golden updates are never routine catalog maintenance.

Transition tests cover:

- applied Variant F -> preview another theme -> Revert;
- applied another theme -> preview Variant F;
- restart into Variant F;
- unknown ID -> Graphite fallback without stored-ID mutation;
- incoming synchronized change during Preview;
- Apply persistence failure;
- candidate preflight failure;
- Enhanced on -> off exact Variant F restoration.

### Physical Android-tablet gate

With Enhanced off, inspect Calendar and all ten top-level destinations in all
seven themes: Clinical Placements, Student Profile, Connected Devices, Trash &
Recovery, Backup & Restore, Exports, Synchronization, Settings, Notifications,
and Help.

With Enhanced on, inspect Calendar, Settings/gallery, Help, progress, a dense
form, focus/selection states, and Preview/Apply/Revert in every theme.
Separately verify signed-out Graphite, TalkBack traversal, 200% Android text,
and theme round trips.

Containment Drone receives the repeated upgrade and boundary audit in
`docs/agents/variant-f-raster-frames.md`, compared with the recorded build-39
follow-up. The maintainer is the sole visual approver. Automation supports but
cannot replace that judgment. This is Android-tablet acceptance only and makes
no Windows or physical-phone visual claim.

## Release and evolution rules

The current Containment-only experience remains authoritative until all seven
bundles are complete, approved, and pass every applicable gate. The gallery
does not ship partially.

Theme IDs identify enduring identities rather than visual versions. An
approved refinement ships under the same ID and reaches existing selections
with the app update, but requires its own GitHub issue, refreshed thumbnail and
goldens, accessibility checks, and Android-tablet approval. A replacement
identity or catalog-count change requires a new catalog decision and new ID.

## Deferred and out of scope

- Final display-name approval for Botanical Study, Coastal Calm, and Heritage
  Field Notes belongs to visual concept approval; their machine IDs are fixed.
- Production implementation tickets and sequencing follow this contract.
- The later single-renderer convergence is a separate, evidence-gated issue.
- Windows and physical-phone visual acceptance remain deferred.
- User-authored colors, remote or downloadable packs, automatic light/dark
  switching, theme-specific audio, and styling Supabase email messages remain
  out of scope.
