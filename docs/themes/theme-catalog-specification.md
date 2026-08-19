# Seven-theme Clinical Calendar catalog specification

Status: decision-complete draft for the final task in the planning record under
[GitHub issue #104](https://github.com/mshamblin5150-code/clinical-calendar/issues/104).

Owning task: [GitHub issue #122](https://github.com/mshamblin5150-code/clinical-calendar/issues/122).

This specification consolidates the resolved decisions from issues #105–#121.
It is normative for later implementation planning. The linked palette briefs,
approved concepts, [additive theme contract](additive-theme-contract.md),
[theme acceptance contract](theme-acceptance-contract.md), and
[cross-theme accessibility contract](../research/themes/cross-theme-accessibility-semantics.md)
remain normative detail where this document references them rather than
duplicating their complete token tables or evidence procedures.

## Problem Statement

Clinical Calendar currently has one accepted visual identity, Containment
Drone 47-Alpha. The Student needs a small, curated choice of identities without
turning presentation into a source of workflow drift, inaccessible state,
unreliable persistence, partial theme mixtures, or regression in the accepted
Containment Drone experience.

Adding themes is broader than changing Flutter `ThemeData`. The current
identity also owns shell composition, raster frames, painters, semantic marks,
gallery presentation, typography, and theme-specific Help. A safe catalog must
therefore resolve each identity as one complete presentation bundle at the app
root while keeping domain services, Student data, workflows, responsive
behavior, and control locations shared.

The planning outcome is exactly seven curated themes: the unchanged existing
identity plus six original additions. Graphite must provide a neutral default,
a complete fallback, and a fixed signed-out identity. Theme selection must be
recognizable before commitment, reversible, synchronized only after explicit
Apply, and compatible with one independent Enhanced accessibility setting.

The catalog is not releasable merely because its individual screens look
plausible. It needs measurable, non-compensating gates for runtime tokens,
complete bundles, original raster assets, exact Containment Drone regression,
switching and persistence, performance, Help, accessibility, and physical
Android-tablet approval.

## Solution

Ship one closed, compile-time catalog of exactly seven complete visual bundles.
Each bundle changes presentation only. Every theme uses the same Clinical
Calendar domain language, information architecture, Student data, workflows,
responsive breakpoints, navigation, live content surfaces, and control
locations.

### Catalog

Identifiers are immutable persisted values. Display names may be refined
without migrating stored preferences.

| Identifier | Approved display name | Presentation character and binding source |
| --- | --- | --- |
| `variant-f` | Containment Drone 47-Alpha | The existing accepted gunmetal tactical identity. It is preserved by isolation and is not redesigned, reimplemented, or re-accepted by this catalog specification. |
| `federation-classic` | Federation Classic | Original near-black plum, warm amber and salmon, and lilac semantics; broad rounded rails, asymmetric elbows, large black content bays, and complete visible labels. See the [palette brief](../research/themes/federation-classic-palette.md) and [approved Android concept](https://github.com/mshamblin5150-code/clinical-calendar/tree/d977416a66641da1336e099384d70fe258afb426/docs/concepts/themes/federation-classic). |
| `federation-2399` | Federation 2399 | Original charcoal, restrained plum and burgundy, aged amber, ivory and cool-light semantics; fine segmentation, sculpted hull lips, burgundy understructure, cyan system channels, and warm amber markers. See the [palette brief](../research/themes/federation-2399-palette.md) and [approved Android concept](https://github.com/mshamblin5150-code/clinical-calendar/tree/27cbd28f37bce92ddcca80ab94399ad685d99c51/docs/concepts/themes/federation-2399). |
| `botanical-study` | Botanical Study | A contemporary scientific research desk: warm ivory paper, sage and eucalyptus structure, dusty rose Work Shift identity, orchid and aubergine rules, restrained botanical linework, and specimen-label details. Botanical motifs remain noninteractive chrome. See the [palette brief](../research/themes/botanical-study-palette.md) and [approved Android concept](https://github.com/mshamblin5150-code/clinical-calendar/tree/141c552d5a4c2137220bb65cf1da8e98861962c4/docs/concepts/themes/botanical-study). |
| `coastal-calm` | Coastal Light | A contemporary coastal observatory: shell-white and mist surfaces, sea-glass teal structure, clear-blue rules, warm mineral inlays, and controlled coral attention cues, without literal beach imagery. See the [palette brief](../research/themes/coastal-calm-palette.md) and [approved Android concept](https://github.com/mshamblin5150-code/clinical-calendar/tree/36322aee5deab262a4045a8eeb35bba1116133da/docs/concepts/themes/coastal-light). |
| `graphite` | Graphite | A neutral precision slate anchored to the launcher: matte graphite, layered charcoal, cool silver, restrained emerald signals, and role-bound cobalt, violet, brass, and coral semantics. It is the new-Student default, complete fallback, and fixed signed-out in-app identity. See the [palette brief](../research/themes/graphite-palette.md) and [approved Calendar and verification concepts](https://github.com/mshamblin5150-code/clinical-calendar/tree/4fb118967d19b83fbef5fbfe40d237132ca5a9e6/docs/concepts/themes/graphite). |
| `heritage-field-notes` | Field Archive | A scholarly archival identity with flat parchment content bays, forest ink, walnut housing, muted brass indexing, and oxblood Work Shift semantics. It has no faux distress, faux-military styling, or readability-heavy texture. See the [palette brief](../research/themes/heritage-field-notes-palette.md) and [approved Android concept](https://github.com/mshamblin5150-code/clinical-calendar/tree/030cfcc455947df7e824012886cd6d99d49b5180/docs/concepts/themes/heritage-field-notes). |

Themes are preference choices only. They are never gender-labelled,
gender-gated, ranked, downloaded, or generated by the Student.

### Theme Gallery and reversible Preview

Settings replaces the one-option theme selector with the approved
[Variant B master-list gallery](../concepts/themes/theme-gallery/README.md):

- all seven identity rows remain visible in a master list;
- the selected candidate receives a large detail region containing its
  deterministic Calendar thumbnail, personality description, five labelled
  semantic swatches, and Preview action;
- the five swatches always appear as Canvas, Structure, Clinical Session,
  Work Shift, and Urgent, with semantic role and plain-language color name in
  each accessible label;
- **Selected** means only that a candidate is being inspected; it does not
  change the Calendar;
- **Applied** identifies the authoritative persisted theme;
- Containment Drone 47-Alpha uses the same current-state labels as every other
  theme, without a historical preservation label;
- selecting a row never exposes direct Apply; a successful full-app Preview is
  required before commitment; and
- during Preview, a persistent control names the previewed identity, says
  **Not saved**, identifies the authoritative applied theme, and exposes
  separate Revert and Apply actions.

Preview preflights and decodes the complete candidate off the live renderer.
A failure leaves the applied theme visible, reports **Preview unavailable**,
disables Apply, and writes no preference. A success atomically swaps the whole
presentation without crossfading or interpolating token and asset sets.

Preview is signed-in, full-app, session-only state. It preserves the current
destination, Calendar period and selection, scroll positions, open forms,
unsaved field values, valid focus, controllers, and loaded Student data. It
survives background/resume within the live process, but explicit Revert,
sign-out, or process termination discards it. It is never synchronized,
backed up, restored, or exported. Theme-specific Help follows the effective
preview bundle.

Apply is transactional. `StudentSettings.themeId` becomes authoritative only
after persistence succeeds. A failed Apply leaves the old ID authoritative,
keeps the Preview visibly unsaved, reports the error, and offers Retry and
Revert. If synchronization delivers a newer theme during Preview, that theme
becomes the new authoritative base, Preview remains visible, the Student is
notified, Revert returns to the newer base, and Apply uses revision checks
rather than silently overwriting it.

### Enhanced accessibility

Enhanced accessibility is one optional, reversible, account-synchronized
boolean layered over any of the seven themes. It is independent of theme
selection and Preview/Apply state and does not create fourteen themes. The
approved [Variant B interaction treatment](../concepts/themes/enhanced-accessibility/README.md)
provides:

- stronger semantic contrast targets;
- an unobscured 3 px dual-tone focus perimeter;
- visually independent Today, selection, focus, and commitment states;
- full category wording plus stable silhouettes, marks, and patterns;
- a persistent expanded legend; and
- quieter content bays without erasing theme identity.

Every new theme must already meet WCAG 2.2 AA with Enhanced accessibility off.
System text scaling, bold text, reduced motion, TalkBack, color inversion, and
other platform accessibility preferences remain authoritative in both modes.

The signed-out Graphite surface exposes a device-local Enhanced toggle so the
authentication flow is accessible before account settings load. After sign-in,
the synchronized Student setting becomes authoritative; the device-local value
is not merged into or written to the account. Signed-in changes take effect
immediately and persist transactionally. A failed save restores the previous
value. Changing Enhanced accessibility during theme Preview survives theme
Revert.

With Enhanced accessibility off, Containment Drone stays exactly frozen. Its
explicit Enhanced overlay may strengthen live text, focus, outlines, redundant
marks, and decorative restraint, but may not change asset bytes, frame
geometry, responsive layout, identity, workflows, domain content, or control
locations. Disabling it restores the exact accepted Standard rendering.

### Signed-out, fallback, and migration behavior

Graphite owns all unauthenticated in-app states: launch, email entry, code
entry, resend and cooldown, validation, offline and error states, expired
session, and sign-out confirmation. The Supabase email message itself is not
themed. No cached signed-in theme or Student data is revealed before
authentication and authoritative settings resolution complete.

After authentication, the app stays in a Graphite loading transition and
keeps the authenticated shell hidden until it can enter directly in the
resolved applied theme. A valid complete offline cache may be used.

An unknown or unavailable applied ID remains stored and synchronized while the
complete Graphite bundle renders for the session. Settings explains that the
saved theme is temporarily unavailable and labels Graphite **Fallback in use**,
not **Applied**. No available card is falsely marked as the stored choice. The
Student may replace the unknown ID only by successfully previewing and applying
an available theme.

If an optional Preview candidate fails, the current valid applied theme stays
visible; Graphite fallback is not invoked merely for that failure. If Graphite
itself cannot construct or decode, the app fails closed to a small code-only
accessible surface using Graphite base colors. It shows no Calendar or Student
data, borrows no other theme assets, and offers Restart plus non-sensitive
diagnostic guidance.

Before Graphite becomes the new-Student default, migration preserves or creates
`variant-f` for every pre-catalog Student, including normalized legacy
`borg_tactical` selections. Only Students created after the migration default
to `graphite`. The applied ID and Enhanced boolean travel with synchronized
Student settings, portable backup/restore, and settings-inclusive exports;
assets and Preview state do not. Unknown IDs are preserved through those
flows.

### Release shape

The catalog is atomic. The current Containment Drone-only experience remains
authoritative until all seven complete bundles pass all applicable acceptance
gates in the same candidate release. No partial gallery, hidden placeholder,
or subset of approved themes ships.

## User Stories

### Discover and compare themes

As the Student, I can see exactly seven curated identities in a visual gallery
so I can compare their actual Calendar character without changing my applied
theme.

Acceptance boundaries:

- every row shows its approved name and personality, deterministic runtime
  thumbnail, five ordered and labelled swatches, and current state;
- Applied, Selected, Previewing, Not saved, and Fallback in use are distinct
  and never inferred from color alone; and
- the gallery never exposes theme download, customization, gender labels,
  automatic light/dark switching, or direct Apply.

### Preview safely before commitment

As the Student, I can preview a complete theme across the signed-in app so I
can judge it with my workflows before deciding to save it.

Acceptance boundaries:

- successful Preview changes presentation only and preserves all working UI
  and Student state;
- the Preview control remains available while navigating;
- Revert restores the latest authoritative applied theme;
- candidate load failure cannot corrupt or replace the valid applied bundle;
  and
- sign-out or process termination cannot accidentally persist Preview.

### Apply and synchronize deliberately

As the Student, I can explicitly apply the theme I previewed so the preference
survives restart and follows my synchronized settings.

Acceptance boundaries:

- Apply is transactional and revision-aware;
- failures leave the prior preference authoritative and clearly identify the
  Preview as unsaved;
- valid themes survive online and offline restart, synchronization,
  backup/restore, and settings-inclusive export; and
- a concurrent synchronized change is never silently overwritten.

### Retain an existing identity

As a pre-catalog Student, I retain Containment Drone 47-Alpha and its exact
accepted rendering unless I explicitly preview and apply another theme.

Acceptance boundaries:

- migration selects `variant-f` before the default changes;
- every round trip into and out of Containment Drone preserves workflow state;
- Enhanced off produces exact accepted reference images and frozen asset
  hashes; and
- catalog work does not modify its name, identifier, palette, typography,
  artwork, frame geometry, Help guide, responsive behavior, or output.

### Authenticate without leaking a saved identity

As the Student, I see the stable Graphite identity while signed out so account
state is not disclosed and authentication remains visually consistent.

Acceptance boundaries:

- all signed-out in-app states use Graphite and never cached Student data;
- the delivered email is unaffected;
- the authenticated shell appears only after settings resolve; and
- the device-local accessibility choice helps authentication without mutating
  the synchronized account choice.

### Recover from an unavailable theme

As the Student, I can continue in Graphite when my stored theme is unavailable
without the app silently destroying that preference.

Acceptance boundaries:

- the unknown ID remains stored;
- Graphite is labelled as a temporary fallback rather than the applied choice;
- Help and the entire presentation resolve from one complete Graphite bundle;
  and
- an available ID replaces it only after Preview and successful Apply.

### Use every identity accessibly

As the Student, I can understand Calendar commitments, progress, feedback,
focus, selection, and gallery state in every theme without relying on color
alone.

Acceptance boundaries:

- Standard mode meets WCAG 2.2 AA;
- full domain labels, semantics, stable marks, shapes, patterns, positions, and
  boundaries provide redundant meaning;
- Enhanced accessibility strengthens the approved presentation without
  becoming a new theme; and
- platform accessibility settings remain honored.

## Implementation Decisions

### Atomic bundle seam

The stable architectural unit is a complete theme bundle resolved at the app
root before `MaterialApp` and the shell are built. Each selectable bundle owns:

1. immutable ID, approved display name, and personality description;
2. opaque Standard semantic tokens and Enhanced overrides;
3. complete Flutter `ThemeData`;
4. shell and chrome renderer;
5. normalized nine-slice descriptor and original theme assets;
6. deterministic gallery thumbnail metadata and five runtime swatches;
7. stable non-color Calendar and status marks; and
8. a complete theme-specific Help guide.

Compile-time and contract validation reject duplicate IDs and incomplete
bundles. A bundle never borrows a missing palette, frame, mark, thumbnail, or
Help entry from another identity. Runtime registration, remote definitions,
downloaded packs, user-authored colors, and partial placeholders are forbidden.

Concrete type and file names may change during implementation planning; the
atomic ownership and root-resolution boundaries may not.

### Renderer lanes and shared behavior

The initial implementation has two presentation lanes over the same workflow
controllers, domain services, loaded Student data, and live content surfaces:

- `variant-f` delegates to its existing theme builder, responsive application
  shell, frames, painters, raster loaders, typography, and Help unchanged; and
- the six new identities use one additive responsive shell with fixed content
  slots, breakpoints, navigation, and control locations, parameterized only by
  complete bundles.

Preservation is by isolation, not by forcing Containment Drone through a new
generalized renderer. Later convergence to one renderer requires its own issue
and may remove the legacy lane only after exact reference-image equality,
unchanged assets and geometry, full responsive regression, and new physical
Android-tablet approval.

### Semantic presentation seam

Components consume semantic roles rather than theme names or concrete colors.
Every palette provides complete surface, text, control, Calendar, progress,
feedback, synchronization, Standard, and Enhanced mappings, plus permitted and
prohibited pairings. The six palette briefs linked in the Catalog table are the
normative token definitions.

Across identities, meaning remains stable:

- Clinical Session, Work Shift, Protected Day, Today, selected date,
  Scheduled Session, Completed Session, Cancelled Session, Missed Session,
  awaiting confirmation, and Schedule Conflict each retain explicit wording,
  semantics, and a stable non-color cue;
- Completed Hours, Scheduled Hours, Unscheduled Hours, and Over-Target Hours
  retain distinct labelled marks or patterns in both content and legends; and
- status, focus, selection, disabled, pressed, inverse, and asynchronous states
  use their own semantic channels rather than decorative accents.

Decoration cannot carry operational meaning, enter the semantic tree, or sit
behind live Calendar data. Themes may change drawing style but not the meaning,
order, or accessible name of semantic marks.

### Frame and content seam

Each new identity owns original high-resolution nine-slice artwork and may not
import, recolor, trace, or modify Containment Drone art. Every new primary frame
uses:

- a 1536 × 1024 transparent source;
- left/top/right/bottom cuts of 120/145/120/170 pixels;
- transparent exterior corners;
- the existing panel-safe content insets;
- one calm, opaque, uninterrupted live-content bay; and
- no baked-in text, controls, meaningful icons, state, semantic nodes, or
  shadows outside the housing.

Artwork may differ radically, but switching themes cannot move live controls,
change responsive breakpoints, reduce usable content space, or put motifs under
Student data.

Containment Drone keeps its frozen assets, frame geometry, painter behavior,
safe insets, palette, typography, component styling, Help, and renderer path as
defined by the [additive contract](additive-theme-contract.md) and
[Variant F raster-frame workflow](../agents/variant-f-raster-frames.md). Its
Standard path cannot be re-baselined inside catalog work.

### Gallery evidence seam

Gallery thumbnails are deterministic renders from each real complete bundle,
using one pinned fictional Android-tablet Calendar fixture and viewport. They
are not hand-painted marketing images and contain no real Student data. The
five ordered swatches are read from runtime semantic tokens. A relevant
renderer or token change regenerates and re-reviews the thumbnail.

### State and persistence seams

Keep these state axes independent:

- authoritative synchronized `themeId`;
- transient session-only preview ID;
- synchronized Enhanced accessibility boolean; and
- device-local platform and signed-out accessibility settings.

Effective theme resolution always returns one whole bundle. It never resolves
palette, assets, shell, marks, or Help independently. Authentication, cached
settings, synchronized settings, fallback, Preview failure, and terminal
Graphite failure follow the behavior described in Solution.

Theme Apply and signed-in Enhanced changes use transactional persistence.
Theme Apply also uses revision checks. Synchronization, portable settings
backup/restore, and settings-inclusive export carry only immutable IDs and the
Enhanced boolean, not assets or Preview state.

### Help seam

Shared workflow Help remains theme-independent. Every complete bundle provides
the same five ordered visual entries: Clinical Session, Work Shift, Protected
Day, Scheduled progress, and Today or urgent. Each entry contains the runtime
swatch, plain-language visual description, stable redundant non-color cue, and
Enhanced behavior. Help resolves from the currently effective bundle, so it
follows Preview and uses complete Graphite guidance during fallback.

### Platform and approval seam

Android tablet is the only current visual concept and physical acceptance
target. The maintainer is the sole visual approver. Automated evidence can
establish measurable conformance but cannot override a visual rejection;
visual approval cannot waive a failed objective gate.

## Testing Decisions

Theme acceptance is strict and non-compensating. A theme is **Pending** or
**Accepted**; there is no score, conditional pass, or accepted-with-risk state.
The catalog ships only when all seven themes are Accepted for the same signed
candidate build.

### Evidence manifests

Each theme owns a versioned manifest under
`docs/themes/acceptance/<theme-id>/` recording the candidate commit and signed
build, approved display name, physical tablet and display conditions, fixture
and evidence date, asset hashes, machine-readable reports, CI run, original
captures, manual checklists, any exact Enhanced contrast exception, and the
maintainer's final decision. Evidence uses fictional data, remains retrievable,
and contains no account identifiers, credentials, codes, keys, signing
material, or backup passphrases.

### Runtime tokens

Audit tokens constructed by the candidate runtime bundle, including composited
alpha and state layers, rather than copied palette hexes. Enumerate every
permitted foreground/background and adjacent-graphic pairing in Standard and
Enhanced modes and prove prohibited pairings are unreachable.

| Content | Standard minimum | Enhanced target |
| --- | ---: | ---: |
| Normal text | 4.5:1 | 7:1 |
| Large text | 3:1 | 4.5:1 |
| Necessary controls, focus, state boundaries, and graphics | 3:1 | 4.5:1 |

The machine-readable report has zero unexplained failures. Only an exact
Enhanced-mode pairing may receive a documented, measured, redundant-cue,
maintainer-approved exception; the Standard WCAG floor still applies. No other
gate is waivable.

### Bundle, registry, asset, and thumbnail gates

Static checks prove exactly seven immutable IDs, complete independently owned
bundles, Graphite fallback and signed-out ownership, and exclusion of partial
or runtime-defined entries.

For every raster asset, record path, SHA-256, dimensions, cuts,
transparent-corner results, and safe-inset geometry. Byte length may be
diagnostic but is not an acceptance gate. Automated geometry checks and human
source-record review establish correct construction and originality; image
similarity scores cannot substitute for maintainer judgment. A changed accepted
hash invalidates the affected asset and visual evidence.

Thumbnail evidence records fixture version, renderer version, dimensions, and
SHA-256 and proves that the real bundle generated the image and five swatches.

### Exact Containment Drone regression

With Enhanced accessibility off, a pinned environment must show exact
reference-image equality between the pre-catalog direct renderer and
catalog-resolved `variant-f` for every accepted fixture, unchanged protected
asset paths and hashes, no protected-renderer edits, and clean responsive,
workflow, Help, and presentation suites. No tolerance or incidental golden
re-baselining is allowed. Enhanced on tests the approved overlay; turning it
off restores exact Standard output.

### Switching and state preservation

Automated tests exercise all 42 directed swaps between distinct themes and
prove atomic replacement plus preservation of destination, Calendar period and
selection, scroll, forms, unsaved fields, focus, controllers, and loaded data.

The suite also covers selection without mutation; Preview success and failure;
Revert; Apply, retry, and failure; process termination; Containment-to-new and
new-to-Containment round trips; incoming synchronization during Preview;
unknown-ID fallback without stored-ID mutation; Enhanced changes during
Preview and Revert; Help resolution; Graphite terminal recovery; and signed-out
privacy.

On the physical tablet, every new theme completes Preview, Revert, Apply, and
restart round trips through both Graphite and Containment Drone.

### Persistence and migration

Integration tests cover transactional Apply, every valid theme across online
and offline restart, synchronization, portable backup/restore, and
settings-inclusive export; exclusion of Preview from every persistent flow;
unknown-ID preservation with Graphite fallback; pre-catalog migration to
`variant-f`; and post-migration new-Student default to `graphite`.

For every theme, physical evidence covers Apply, process restart, offline
restart, and sign-out/sign-in restoration. A synchronization-behavior change
requires fresh multi-device evidence; otherwise a second physical device is
not required.

### Performance

Capture a profile-mode pre-catalog baseline on the same Android tablet, build
configuration, refresh rate, and fictional fixture used for the candidate.
Every theme must satisfy all of these limits:

- steady-state p95 UI-thread and raster-thread work stays inside the device
  frame interval and within 10% of the pinned baseline;
- after off-renderer preflight, an atomic theme swap reaches its complete
  stable frame within 250 ms;
- 25 consecutive Preview/Revert/Apply cycles show no monotonic retained-memory
  growth, and cleaned-up retained memory returns within 10% of the post-launch
  baseline; and
- release-size growth is measured and attributable to approved manifest
  assets.

There is no arbitrary total size cap, but unexplained growth fails.

### Help and accessibility

Parameterized tests resolve the five required Help entries from every Standard
and Enhanced runtime bundle, then verify Preview, Revert, and invalid-ID
fallback. Physical review verifies accurate, readable, scrollable, complete
Help at default and 200% Android text scaling.

All four accessibility evidence layers are mandatory:

1. automated contrast, tap-target, label, semantics, and visual-state checks;
2. default and 200% nonlinear text scaling, bold text, and supported text
   spacing layouts;
3. grayscale plus common red/green and blue/yellow color-vision-deficiency
   review; and
4. physical Android-tablet TalkBack and keyboard or switch traversal where
   available.

The pass permits no decorative focus stops, incorrect or duplicate labels,
unreachable actions, obscured focus, lost state, clipping, or drift from
`CONTEXT.md` domain language. Android Accessibility Scanner findings are
resolved or explicitly adjudicated; scanner silence alone is not acceptance.

### Physical Android-tablet visual acceptance

Install the signed candidate as an upgrade on the approved tablet. Record the
version code and signer without exposing signing material. Use fresh
original-resolution captures and confirm each screen against the live UI tree.

In Standard mode, inspect Calendar and all ten top-level destinations for every
theme in the canonical orientation: Clinical Placements, Student Profile,
Connected Devices, Trash & Recovery, Backup & Restore, Exports,
Synchronization, Settings, Notifications, and Help. In the other orientation,
inspect Calendar, Settings, Help, and the densest form. Confirm safe insets,
fixed control locations, legible state, quiet content bays, and undistorted
assets.

In Enhanced mode for every theme, inspect Calendar, Theme Gallery, Help,
progress, a dense form, independent focus/selection/Today states, and
Preview/Apply/Revert. Separately verify signed-out Graphite, TalkBack, 200%
text, and theme round trips. Containment Drone repeats its documented physical
upgrade and boundary audit.

Windows and phone tests may supply behavioral and responsive regression
evidence only. They cannot be represented as visual acceptance.

### Re-acceptance

- A theme-owned token, asset, semantic mark, thumbnail, Help guide, or bundle
  change reopens that theme's applicable gates plus registry and Containment
  regression.
- A shared renderer, Theme Gallery, switching state machine, persistence path,
  accessibility overlay, or responsive layout change reopens all seven themes.
- An unrelated workflow change runs normal regression and reopens visual
  acceptance only when it changes a rendered evidence surface.

Invalidated manifests remain historical and cannot be presented as current.

## Out of Scope

- Production Flutter implementation, implementation-ticket decomposition,
  signed builds, deployment, rollout sequencing, or release publication.
- Any change to Containment Drone 47-Alpha's name, ID, palette, artwork,
  framing, typography, Help, behavior, or Standard rendered output.
- Reimplementing Containment Drone in the additive renderer or completing the
  later single-renderer convergence.
- More or fewer than seven themes; runtime theme registration; remote or
  downloadable packs; user-authored colors; or hidden partial identities.
- Gender labels or access gates for any theme.
- Automatic light/dark switching, theme-specific audio, voice, notification
  sounds, or looping animation.
- Styling the Supabase email message itself.
- External NP-student cohort testing; the maintainer is the sole visual
  approver for this catalog.
- Claiming Windows or physical-phone visual acceptance before those targets
  receive their own concepts, evidence, and approval.
- Rediscovering or changing palette, concept, accessibility, persistence,
  platform, or acceptance decisions already resolved by issues #105–#121.

## Further Notes

### Normative decision record

- [Parent Wayfinder map #104](https://github.com/mshamblin5150-code/clinical-calendar/issues/104)
  is the ticket index and concise decision log.
- Palette and accessibility research is versioned under
  [`docs/research/themes`](../research/themes/).
- [Additive theme contract](additive-theme-contract.md) owns complete-bundle,
  Preview, persistence, fallback, migration, Help, frame, and Containment
  preservation details.
- [Theme acceptance contract](theme-acceptance-contract.md) owns the exact
  evidence and release gates.
- [Theme Gallery](../concepts/themes/theme-gallery/README.md) and
  [Enhanced accessibility](../concepts/themes/enhanced-accessibility/README.md)
  record the two approved catalog-wide interaction treatments.
- The pinned concept links in the Catalog table are the approved visual
  directions for the six additions. They guide original production art but are
  not themselves production Flutter assets.

### Interpretation rules for implementation planning

Later implementation planning may choose concrete class names, packages, file
layout, and ticket sequencing. It must not reopen the closed product and visual
decisions in this specification merely to fit an existing code shape.

When two sources appear to differ, apply this precedence:

1. the latest explicit resolution in issues #105–#121;
2. this consolidated specification;
3. the additive and acceptance contracts;
4. approved concept decision records; and
5. research briefs.

The final approved display names in this specification supersede provisional
research names while retaining their immutable IDs: Coastal Light keeps
`coastal-calm`, and Field Archive keeps `heritage-field-notes`.

Implementation planning should decompose work at stable seams—catalog and
bundle validation, root resolution, additive shell, original asset production,
Gallery and Preview state, persistence and migration, accessibility overlay,
Help, and acceptance evidence—without treating this specification as a
file-by-file change list.
