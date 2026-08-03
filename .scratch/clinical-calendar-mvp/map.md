# Chart the Clinical Calendar MVP

## Destination

Produce a decision-complete MVP product and architecture specification for an installable, offline-first clinical scheduling application supporting Windows, iPhone, and Android tablet, ready to turn into implementation tickets.

## Notes

- This is a single-Student MVP built first for its creator, with an architecture that does not prevent later distribution to other individual students.
- Each device edits the same synchronized calendar and remains usable offline.
- The application stores scheduling and training information only; patient information is prohibited.
- Use the canonical domain language in [`CONTEXT.md`](../../CONTEXT.md).
- Established rules: military time; Work Shifts and Clinical Sessions cannot overlap; one movable Protected Day per week blocks all commitments; manual multi-date entry, templates, and duplication replace recurring series in the MVP.
- Clinical Placements have target hours and multiple Preceptors, exactly one Primary Preceptor, placement-wide progress with per-Preceptor breakdowns, explicit session completion, and a configurable Evaluation Plan.
- Consult the `grilling`, `domain-modeling`, `research`, and `prototype` skills as each ticket requires.

## Decisions so far

- [Research the Cross-Platform Application Architecture](issues/01-research-cross-platform-architecture.md) — Use Flutter/Dart with SQLite as the offline source of truth and synchronization behind a replaceable adapter; Python mobile stacks carry greater packaging or UI risk.
- [Research the Synchronization and Storage Model](issues/02-research-sync-storage-model.md) — Use full local SQLite databases synchronized through a managed Supabase/Postgres backend with explicit revisions and conflict handling; reserve Google Drive for optional export or backup.
- [Define the Schedule Entry and Editing Workflow](issues/03-define-schedule-entry-workflow.md) — Use conflict-checked, all-or-nothing multi-date entry with date-free templates, deliberate form editing, monthly Protected Day completion, configurable week boundaries, and overnight interval support.
- [Define the Clinical Placement Progress Workflow](issues/04-define-placement-progress-workflow.md) — Track exact completed, scheduled, awaiting-confirmation, historical, and over-target hours across reusable Preceptors; govern completion through a configurable Evaluation Plan and explicit placement lifecycle.
- [Define Data Ownership, Backup, and Recovery](issues/05-define-data-ownership-recovery.md) — Give the Student encrypted offline ownership with transparent conflict-safe sync, connected-device control, recoverable deletion, daily snapshots, guarded account erasure, and portable backup plus open PDF/CSV/JSON exports.
- [Define Reminder and Notification Behavior](issues/06-define-reminder-notification-behavior.md) — Use privacy-minimized per-device delivery with synchronized snoozing, quiet hours, configurable commitment alerts, persistent workflow safeguards, and paced reminders for confirmation, planning, evaluations, backups, deadlines, and sync health.

- [Prototype the core calendar and progress experience](issues/07-prototype-core-calendar-progress-experience.md) — Accept responsive Variant F — Borg Tactical Console as the interaction and visual reference, with production behavior governed by `spec.md`.

- [Research private installation and updates](issues/08-research-private-installation-updates.md) — Use signed Windows and Android artifacts plus provisioned iPhone builds, with TestFlight as the repeatable private iPhone beta path and public distribution deferred.

- [Repair the interactive prototype](issues/09-remove-or-move-protected-day.md) — Tickets 09-17 connect Protected Day and commitment lifecycles, period views, shared progress, evaluations, notifications, menus, profile, placement/Preceptor management, and transient confirmations.

- [Finish configurable scheduling controls](issues/18-standardize-management-form-typography.md) — Tickets 18-23 standardize form typography, expose review cadence, make Settings and templates editable, support variable/retrospective/over-target Completed Hours, and restore Variant F segmented Total Progress.

- [Complete scheduling interaction rules](issues/24-add-back-navigation-to-settings-surfaces.md) — Tickets 24-30 add menu Back paths, propagate 12-hour/military display preferences, derive duration from time ranges, enforce date-driven confirmation, batch Protected Days, keep the phone tray below the progress wheel, and make the wheel cycle Clinical Placements.

- [Polish contextual navigation and responsive scheduling](issues/31-preserve-contextual-modal-navigation.md) — Tickets 31-35 add source-aware Back behavior, flexible military/12-hour time entry, touch-safe portrait and landscape sizing, actionable phone notifications, and a full-width unclipped scheduling form.

- [Improve phone legibility and touch targets](issues/36-improve-phone-legibility-and-touch-targets.md) — Raise touch-layout typography, calendar density, form controls, notifications, evaluations, and navigation to readable sizes while retaining 44px targets and overflow-free portrait/landscape layouts.

- [Stop phone summary text clipping](issues/37-stop-phone-summary-text-clipping.md) — Allow the planning summary to wrap complete status text such as `Ready`, preserve full-size actions, and remove the obsolete fixed root minimum width.

- [Align phone step number and label](issues/38-align-phone-step-number-and-label.md) — Render each phone scheduling step as a centered inline circle-label pair without overlap at supported widths.

- [Default batch placement from wheel](issues/39-default-batch-placement-from-wheel.md) — Use the wheel-selected Clinical Placement and its Primary Preceptor as the default for Clinical Sessions while retaining per-batch overrides and leaving Work Shifts/Protected Days unassigned.

- [Apply a cross-era Borg semantic palette](issues/40-apply-cross-era-borg-semantic-palette.md) — Use gunmetal/green-steel for Work Shifts, dormant graphite/regeneration silver for Protected Days, and Collective green/industrial ochre/optic red for the progress wheel, based on recurring TNG, *First Contact*, *Voyager*, and *Picard* imagery rather than a claimed canonical hex palette.

- [Default Planning incomplete to Protected Day](issues/41-default-planning-alert-to-protected-day.md) — Carry the attention action's intent into a reset, expanded batch tray with `Protected Day` selected while leaving ordinary Add Schedule actions defaulted to Clinical Session.

- [Mark the entire Work Shift day](issues/42-mark-entire-work-shift-day.md) — Give Work Shift calendar cells a full gunmetal/teal wash and machinery rail while retaining labels/dots and keeping Protected Days visually distinct.

- [Highlight the current day](issues/43-highlight-current-day.md) — Mark Today with an optic-red date badge and inset outline that layers with Work Shift, Protected Day, selection, and commitment states and is also announced in the accessible name.

- [Deselect a conflicting calendar date directly](issues/44-deselect-conflicting-calendar-date-directly.md) — Give a selected date first-click priority so the Student can remove it from the current batch without opening or changing the Work Shift, Clinical Session, or Protected Day underneath; normal item opening resumes after deselection.

- [Fix responsive readability and rotation](issues/45-fix-responsive-readability-and-rotation.md) — Keep short landscape phones in the mobile experience, allow tablet landscape to use an unclipped compact desktop toolbar, and raise meaningful desktop/tablet secondary text to at least 12 px.

- [Add Total Progress to mobile](issues/46-add-total-progress-to-mobile.md) — Reuse one eight-segment TotalProgress component beneath the mobile placement wheel so desktop and mobile calculations update identically.

- [Configure the Placement Evaluation Plan](issues/47-configure-placement-evaluation-plan.md) — Put Interim Review cadence and Required/Not required beginning/end evaluation requirements in each Clinical Placement's settings and apply them to its checklist.

- [Carry theme colors into Agenda](issues/48-carry-theme-colors-into-agenda.md) — Preserve Work Shift gunmetal/teal and Protected Day graphite/silver treatments across Month, Week, and Agenda views.

- [Add in-product Help](issues/49-add-in-product-help.md) — Expose Help from desktop, mobile, and the application menu with readable guidance for every primary workflow and the prototype's storage limitations.

- [Make Help theme-aware](issues/50-make-help-theme-aware.md) — Separate shared workflow help from a selected-theme visual-state registry so future themes can provide their own Calendar States legend without duplicating Help.

- [Move Work Shifts and Clinical Sessions](issues/51-move-work-and-clinical-days.md) — Move existing commitments from their detail editor while preserving attached data, rejecting collisions, and applying date-driven clinical confirmation rules.

- [Derive initials and allow an optional avatar](issues/52-automatic-initials-and-avatar.md) — Generate initials from the Student's name and let an optional session-local photo replace them in the header.

- [Expose Student Profile and the complete menu on mobile](issues/53-mobile-student-profile-access.md) — Show the photo-or-initials profile control in the mobile header and make the bottom Settings tab match the three-line application menu.

- [Synchronize the Placement menu and progress wheel](issues/54-sync-placement-menu-and-wheel.md) — Use one overridable active Placement across management, the circular wheel, and scheduling defaults.

- [Fix 12-hour Clinical Session overlap](issues/55-fix-12-hour-clinical-session-overlap.md) — Give mobile Actual start/end controls enough room for separate AM/PM selectors and move the calculated range below them.

- [Write the decision-complete MVP specification](issues/56-write-decision-complete-mvp-specification.md) — Consolidate the accepted prototype and tickets 01-55 into the authoritative [`spec.md`](spec.md), with explicit production boundaries, Flutter/SQLite/Supabase architecture, measurable acceptance criteria, and an implementation-decomposition sequence; keyboard-first optimization remains deferred.

- [Decompose the MVP into implementation tickets](issues/57-decompose-mvp-implementation.md) — Create a dependency-ordered production backlog from the physical-device Flutter/SQLite gate through domain, persistence, Variant F presentation, synchronization, recovery, packaging, and cross-platform acceptance.

- [Prove the Flutter and SQLite vertical slice](issues/58-prove-flutter-sqlite-vertical-slice.md) — Approve Flutter and encrypted SQLCipher persistence after automated, physical Windows, and physical Android tablet passes; allow production foundations to proceed under an owner-approved iPhone hardware deferment without treating the iPhone gate as passed.

- [Establish the production Flutter workspace](issues/59-establish-production-flutter-workspace.md) — Enforce inward-only Dart/Flutter package boundaries, explicit application dependency ports, one local/CI quality command, source credential policy, and native Windows/Android builds; retain the approved iOS build deferment for ticket 87.

- [Implement the time and commitment domain](issues/60-implement-time-and-commitment-domain.md) — Use validated local dates and military times plus immutable time-zone boundary snapshots for deterministic DST-aware elapsed minutes; define Work Shift, Clinical Session, Protected Day, Schedule Template, overnight coverage, and guarded Clinical Session lifecycle transitions in the dependency-free domain package.

- [Implement the Clinical Placement and Preceptor domain](issues/61-implement-placement-and-preceptor-domain.md) — Model reusable Preceptors, exact Target Hours, attributed or Unattributed Historical Hours, attached/Primary relationship validity, inclusive Clinical Session windows, guarded completion evidence, Completed Placement locking and reopening, and empty-only permanent deletion.

- [Implement the scheduling invariant engine](issues/62-implement-scheduling-invariant-engine.md) — Use one pure engine for half-open active-commitment overlap, local Protected Day coverage, configurable continuous calendar weeks, cross-month completeness, and immutable all-errors/all-or-nothing batch validation.

- [Implement the Clinical Placement progress engine](issues/63-implement-placement-progress-engine.md) — Derive one exact-minute placement ledger with Scheduled/Awaiting/Completed and Historical Hours, Preceptor plus Unattributed reconciliation, target-crossing projection or required weekly pace, over-target floors, and aggregate eight-segment Total Progress.

## Transition status

- The MVP product and architecture are decision-complete in [`spec.md`](spec.md).
- Ticket 58 approved Flutter for continued implementation after Windows and Android physical-device evidence. The iPhone leg remains explicitly deferred to tickets 87 and 88 until Mac/iPhone hardware is available.
- Ticket 63 established the shared progress ledger and unblocked Ticket 64 as the next numbered production-foundation frontier. Ticket 69 remains in progress as an explicitly parallelized presentation workstream.
- Public distribution and comprehensive keyboard-first optimization remain deferred beyond the first MVP implementation plan.

## Implementation backlog

### Stack gate

- [58 — Prove the Flutter and SQLite vertical slice](issues/58-prove-flutter-sqlite-vertical-slice.md)

### Production foundations

- [59 — Establish the production Flutter workspace](issues/59-establish-production-flutter-workspace.md)
- [60 — Implement time and commitment domain types](issues/60-implement-time-and-commitment-domain.md)
- [61 — Implement Clinical Placement and Preceptor domain types](issues/61-implement-placement-and-preceptor-domain.md)
- [62 — Implement the scheduling invariant engine](issues/62-implement-scheduling-invariant-engine.md)
- [63 — Implement the Clinical Placement progress engine](issues/63-implement-placement-progress-engine.md)
- [64 — Implement the Evaluation Plan engine](issues/64-implement-evaluation-plan-engine.md)
- [65 — Build the encrypted SQLite schema and migrations](issues/65-build-encrypted-sqlite-schema-and-migrations.md)
- [66 — Implement local repositories and the transactional outbox](issues/66-implement-local-repositories-and-outbox.md)

### Application workflows and Variant F presentation

- [67 — Implement scheduling application use cases](issues/67-implement-scheduling-application-use-cases.md)
- [68 — Implement Clinical Placement application use cases](issues/68-implement-placement-application-use-cases.md)
- [69 — Build the Variant F responsive application shell](issues/69-build-variant-f-responsive-shell.md)
- [70 — Build Month, Week, and Agenda calendar views](issues/70-build-calendar-period-views.md)
- [71 — Build the staged batch scheduling flow](issues/71-build-staged-batch-scheduling-flow.md)
- [72 — Build commitment and Protected Day lifecycle surfaces](issues/72-build-commitment-lifecycle-surfaces.md)
- [73 — Build Clinical Placement and progress surfaces](issues/73-build-placement-progress-surfaces.md)
- [74 — Build Evaluation Plan and attention surfaces](issues/74-build-evaluation-and-attention-surfaces.md)
- [75 — Build Settings, Student Profile, templates, and Help](issues/75-build-settings-profile-templates-and-help.md)
- [76 — Implement reminder policy and platform notifications](issues/76-implement-reminder-policy-and-platform-notifications.md)

### Synchronization, ownership, and recovery

- [77 — Build the Supabase synchronization backend](issues/77-build-supabase-sync-backend.md)
- [78 — Implement the synchronization client and health state](issues/78-implement-sync-client-and-health-state.md)
- [79 — Build synchronization conflict resolution](issues/79-build-sync-conflict-resolution.md)
- [80 — Implement passwordless identity and Connected Devices](issues/80-implement-passwordless-identity-and-devices.md)
- [81 — Implement Trash, recovery, and account erasure](issues/81-implement-trash-recovery-and-account-erasure.md)
- [82 — Build encrypted portable backup and restore](issues/82-build-encrypted-portable-backup-and-restore.md)
- [83 — Build PDF, CSV, and JSON exports](issues/83-build-pdf-csv-and-json-exports.md)
- [84 — Enforce privacy and security boundaries](issues/84-enforce-privacy-and-security-boundaries.md)

### Packaging and acceptance

- [85 — Package and verify the Windows application](issues/85-package-and-verify-windows-app.md)
- [86 — Package and verify the Android tablet application](issues/86-package-and-verify-android-app.md)
- [87 — Package and verify the iPhone application](issues/87-package-and-verify-iphone-app.md)
- [88 — Run cross-platform MVP acceptance](issues/88-run-cross-platform-mvp-acceptance.md)

## Out of scope

- Public distribution, app-store launch operations, and support for a general audience.
- Accounts or application access for preceptors, schools, or coordinators.
- Patient identifiers, encounter details, diagnoses, or clinical documentation.
- Automated Medatrax integration; the MVP only tracks whether and where an evaluation was documented.
