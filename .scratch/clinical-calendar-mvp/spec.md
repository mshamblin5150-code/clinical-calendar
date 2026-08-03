# Clinical Calendar MVP Specification

Status: decision-complete

Last consolidated: 2026-08-03

## 1. Purpose and authority

Clinical Calendar is an installable, offline-first scheduling and clinical-training progress application for one Student. It coordinates Work Shifts, Clinical Sessions, weekly Protected Days, Clinical Placement hours, Preceptors, Evaluation Plans, reminders, backup, and synchronization without storing patient information.

This document is the implementation-facing MVP specification. It consolidates the decisions in tickets 01-55, the canonical language in [`CONTEXT.md`](../../CONTEXT.md), and the accepted Variant F prototype. If prototype behavior conflicts with a settled rule in this specification or `CONTEXT.md`, the settled rule wins; the React prototype remains a disposable interaction reference rather than production source code.

## 2. Product boundary

### 2.1 Student and devices

- The Student is the only application operator and owns all entered data.
- The MVP supports Windows, iPhone, and Android tablet from one Flutter/Dart codebase.
- Every device keeps a complete local working database and remains usable without a network connection after initial sign-in.
- The devices edit one synchronized calendar when connectivity is available.

### 2.2 MVP outcomes

The Student can:

1. plan variable Work Shifts, Clinical Sessions, and Protected Days without recurring-series machinery;
2. prevent Schedule Conflicts and commitments that touch a Protected Day;
3. track exact Completed, Scheduled, Remaining, Unscheduled, Awaiting Confirmation, and Over-Target Hours by Clinical Placement and Preceptor;
4. document configurable Evaluation Plan requirements;
5. see and act on planning, confirmation, evaluation, deadline, backup, and synchronization attention states;
6. continue working offline and safely reconcile multi-device changes;
7. back up, restore, export, and delete owned data through explicit guarded workflows.

### 2.3 Out of scope

- Patient identifiers, encounter details, diagnoses, clinical notes, or other patient information.
- Accounts or application access for Preceptors, schools, coordinators, or employers.
- Automated Medatrax integration or storage of evaluation documents and credentials.
- Public distribution, app-store launch operations, general-audience onboarding, and multi-Student administration.
- Drag-and-drop rescheduling, automatic recurring series, and automatic schedule ingestion.
- Comprehensive keyboard-first desktop optimization for the first MVP. Standard platform semantics and readable, operable controls remain required, but a dedicated keyboard workflow is not a release-defining product goal.

## 3. Canonical model and invariants

### 3.1 Principal records

- **Student Profile:** display name, automatically derived initials, optional avatar, program, account identity, and preferences.
- **Clinical Placement:** name, Target Hours, Start Date, Completion Deadline, lifecycle state, one Primary Preceptor, attached Preceptors, and an Evaluation Plan.
- **Preceptor:** reusable person record with required name and optional organization/site, phone, email, and scheduling notes. Notes must prohibit patient information.
- **Work Shift:** time-zone-specific employment commitment with planned start and end.
- **Clinical Session:** time-zone-specific commitment assigned to exactly one Clinical Placement and one attached Preceptor.
- **Protected Day:** one all-day reservation independently selected for each configured calendar week.
- **Historical Hours Entry:** aggregate pre-adoption Completed Hours attached to a Clinical Placement and optionally a Preceptor.
- **Evaluation Requirement:** generated requirement with type, threshold or boundary, status, documented date, documentation location, and optional reference or note.
- **Schedule Template:** date-free commitment defaults containing name, type, start, end, and optional Clinical Placement and Preceptor.
- **Notification State:** reminder schedule, snooze state, resolution source, and per-device delivery state.

### 3.2 Hard invariants

1. Active Work Shifts and Clinical Sessions cannot overlap.
2. No active commitment may touch any part of a Protected Day, including an overnight interval crossing into it.
3. Each calendar week has at most one Protected Day; a completed monthly plan has exactly one for every week intersecting the displayed month.
4. Every Clinical Placement has exactly one Primary Preceptor selected from its attached Preceptors.
5. Every Clinical Session belongs to one Clinical Placement and one Preceptor attached to that placement.
6. Clinical Sessions cannot fall outside the Clinical Placement's Start Date and Completion Deadline.
7. Completed Hours equal exact elapsed minutes between confirmed actual start and end, with no break deduction or automatic rounding.
8. Remaining Hours and Unscheduled Hours never become negative. Over-Target Hours are retained and reported separately.
9. Cancelled and Missed Sessions remain in history and contribute no hours.
10. Documented Evaluation Requirements remain documented after later hour or plan changes.
11. Completed Placements reject ordinary edits and new Clinical Sessions until explicitly reopened.
12. Local and server-side validation enforce the same scheduling, ownership, and relationship invariants.

## 4. Scheduling experience

### 4.1 Calendar views and navigation

- Month, Week, and Agenda are distinct views over the same commitment state.
- Previous and next navigation change the visible period without discarding staged scheduling state.
- The configured week start defaults to Sunday and controls grid layout, weekly Protected Day boundaries, summaries, and Planning Incomplete calculations.
- Today is identified with the Variant F optic-red date treatment, text available to assistive semantics, and layering that remains visible with commitment, Protected Day, and selection states.
- Work Shift and Protected Day semantic treatments remain recognizable in Month, Week, and Agenda.

### 4.2 Batch creation

The creation flow is staged but remains one unsaved transaction:

1. Select Work Shift, Clinical Session, or Protected Day.
2. Select one or more nonconsecutive dates directly on the calendar.
3. For timed commitments, select a template or enter start and end times.
4. For Clinical Sessions, select a Clinical Placement and attached Preceptor.
5. Review all dates, calculated durations, assignments, and conflicts.
6. Apply the batch only when every selected date is valid.

Rules:

- A batch applies all-or-nothing. Any invalid date blocks the entire save until corrected or removed.
- Selecting an already-selected date deselects it before any underlying commitment opens.
- Ordinary Add Schedule starts a fresh Clinical Session batch.
- A Planning Incomplete attention action starts a fresh expanded batch with Protected Day selected while preserving existing date selections.
- The wheel-selected Clinical Placement and its Primary Preceptor are the default for a Clinical Session batch. The Student may override them for the batch.
- Work Shifts and Protected Days never inherit a Clinical Placement or Preceptor.
- Applying a Schedule Template copies its current values; later template edits do not alter existing commitments.
- Protected Days may be created on multiple conflict-free selected dates in one batch.

### 4.3 Time entry and duration

- Stored times use 24-hour `HH:MM`; display follows the Student's military-time or 12-hour preference.
- Military input accepts `HHMM` or `HH:MM` and normalizes to valid `HH:MM`.
- Twelve-hour entry exposes distinct time and AM/PM controls without overlap at supported widths.
- Duration is derived from start and end. An end earlier than the start means the following day.
- Overnight conflict and Protected Day validation covers the entire elapsed interval.
- Each commitment stores the time zone in which it was created. Travel and daylight-saving changes must not silently shift its intended local start time.

### 4.4 Commitment lifecycle

- Selecting a Work Shift or Clinical Session opens its details.
- The Student may correct its date and times through a deliberate form.
- Moving preserves type, Clinical Placement, Preceptor, history, and recorded data unless the date-driven status rule changes the Clinical Session state.
- A move to an occupied or Protected date is rejected without changing the original.
- A past Clinical Session is Awaiting Confirmation until explicitly Completed, Cancelled, or Missed.
- A scheduled Clinical Session moved into the past becomes Awaiting Confirmation.
- A Completed Session moved to today or the future becomes Scheduled and no longer contributes Completed Hours until reconfirmed.
- Confirmation pre-fills planned times and Preceptor but allows correction before saving.
- Multiple past sessions may be confirmed together only when their planned times and Preceptors are accurate.
- Permanent deletion is reserved for erroneous or duplicate entries and requires confirmation. Ordinary cancellation and missed-session workflows preserve history.

### 4.5 Protected Day lifecycle

- A Protected Day may be opened, moved, or removed.
- Moving it requires an empty destination and preserves the weekly planning calculation.
- Selecting a day containing an active commitment is blocked until that commitment is moved, cancelled, or deleted.
- A week may temporarily lack a Protected Day while planning; affected months and the attention center remain Planning Incomplete.
- A week spanning two months still owns only one Protected Day, visible from both month views.

## 5. Clinical Placement and progress experience

### 5.1 Clinical Placement management

- A Clinical Placement requires name, Target Hours, Start Date, Completion Deadline, a Primary Preceptor, and an Evaluation Plan.
- The Student may add and edit Clinical Placements and Preceptors and change the Primary Preceptor without rewriting history.
- Target or date edits show their projected impact before saving.
- A date change is blocked while a Clinical Session would fall outside the proposed window.
- An empty Clinical Placement created by mistake may be permanently deleted. One with sessions, Historical Hours Entries, or evaluations may not.
- The active Clinical Placement is shared by the management surface, desktop placement dock, circular progress wheel, and scheduling defaults.
- Selecting or adding a placement in management makes it active; cycling the wheel changes the same active selection.

### 5.2 Progress calculations

For each active Clinical Placement:

- `Completed Hours = sum(Completed Session exact minutes + Historical Hours Entries)`.
- `Scheduled Hours = sum(planned duration of Scheduled and Awaiting Confirmation Sessions)`.
- `Awaiting Confirmation Hours` are the Scheduled Hours attributable to past unresolved Sessions and are called out separately.
- `Remaining Hours = max(Target Hours - Completed Hours, 0)`.
- `Unscheduled Hours = max(Target Hours - Completed Hours - Scheduled Hours, 0)`.
- `Over-Target Hours = max(Completed Hours - Target Hours, 0)`.

Additional requirements:

- Calculations use exact stored minutes; displayed values do not change the stored total.
- The same derived ledger supplies the placement dock, wheel, Total Progress, attention state, and Preceptor breakdown.
- Per-Preceptor Completed and Scheduled Hours sum to the placement totals except Historical Hours Entries without a Preceptor, which appear as Unattributed.
- When Completed plus Scheduled Hours reach the target, show a Projected Completion Date. Otherwise show Unscheduled Hours and the additional average weekly pace required by the deadline.
- Over-target scheduling and confirmation are allowed after a clear warning.
- Desktop and mobile use the same eight-segment Total Progress calculation across all Clinical Placements.

### 5.3 Evaluation Plan

Each Clinical Placement configures:

- Initial Self-Assessment: Required or Not required.
- Interim Review cadence in Completed Hours, defaulting to every 90 hours.
- Final Self-Assessment: Required or Not required.
- Final Placement Review: Required or Not required.

Behavior:

- Each Interim Review has two separately documented parts: the Student's review of the Primary Preceptor and the Primary Preceptor's review of the Student.
- Interim thresholds use combined Completed Hours across all Preceptors.
- Requirements show Not Due, Approaching, Due, or Documented.
- Documentation records date, location defaulting to Medatrax, and optional reference or note; no document or credentials are stored.
- Editing the plan preserves documented items and regenerates only undocumented future requirements after an impact preview.
- A new threshold already passed becomes Due immediately.
- Changing the Primary Preceptor does not invalidate documented reviews; future undocumented reviews use the new Primary Preceptor.

### 5.4 Clinical Placement lifecycle

A Clinical Placement is Ready to Complete only when:

1. Completed Hours meet or exceed Target Hours;
2. every required Evaluation Plan item is Documented;
3. no past Clinical Session remains Awaiting Confirmation; and
4. no future Clinical Session remains Scheduled.

The Student explicitly closes a Ready-to-Complete Clinical Placement. Reopen Placement restores active tracking without deleting history. There is no Discontinued Placement state.

## 6. Attention, reminders, and notifications

### 6.1 Shared behavior

- In-app attention indicators exist on every device and derive from the underlying unresolved state.
- System-notification permission and detailed lock-screen previews are per device; reminder resolution and snoozing synchronize.
- Phone delivery defaults on after permission. Tablet and desktop require opt-in.
- Quiet hours default to 21:00-07:00 local time; no reminder bypasses them.
- Dismissing a system notification does not resolve its underlying requirement.
- Actions route directly to the relevant confirmation, Protected Day, Evaluation Plan, backup, deadline, or sync workflow.

### 6.2 Default reminder policy

- Work Shifts and Clinical Sessions: 24 hours and 2 hours before start; configurable separately and overridable per commitment.
- Clinical Session confirmation: 30 minutes after scheduled end, next morning at 09:00, then every three days until resolved.
- Missing next-week Protected Day: three days and one day before the configured week begins; Planning Incomplete persists after the week starts.
- Initial Self-Assessment: seven days and one day before Start Date, on Start Date, then every three days while overdue.
- Interim Review: Approaching within 10 Completed Hours and when the next Scheduled Session crosses the threshold; Due at the threshold, then every three days until both parts are documented.
- Final evaluations: Approaching within 10 Completed Hours of target or seven days of the Completion Deadline, whichever occurs first; Due when target is met and no future Sessions remain.
- Weekly summary: Sunday at 18:00 by default, configurable.
- Portable backup: seven days after setup if none exists, at 30 days old, then weekly.
- Sync: conflict immediately; continuous failure after one hour; unsynchronized local changes again after 24 hours.

Upcoming reminders, weekly summaries, and backup notifications may be disabled. In-app indicators for Sync Conflicts, missing Protected Days, Awaiting Confirmation Sessions, deadline risk, and Due Evaluation Requirements cannot be hidden while unresolved.

## 7. Settings, profile, Help, and visual contract

### 7.1 Settings and profile

- Settings include week start, military/12-hour display, theme, synchronization mode/status, notification preferences, and Schedule Templates.
- Student Profile derives initials from the first two name parts and accepts an optional avatar. Removing the avatar restores initials.
- The desktop and mobile headers expose the same profile identity.
- Desktop application menu and mobile Settings navigation expose Clinical Placements, Student Profile, Settings, Notifications, and Help.
- A surface opened from the application menu returns to it with Back; a directly opened surface closes to its source without an unnecessary Back step.

### 7.2 Help

- Help is reachable from desktop, mobile, and the application menu.
- Shared guidance covers calendar states, batch scheduling, completion, Protected Days, progress, Preceptors, Evaluation Plans, attention, settings/profile, and storage limitations.
- Theme-specific visual-state guidance is supplied through a theme guide registry. Unknown themes receive a safe generic fallback without duplicating workflow guidance.

### 7.3 Variant F presentation

Variant F - Borg Tactical Console is the MVP's accepted theme and visual hierarchy:

- matte near-black and charcoal-green structure;
- pale bone primary text and muted secondary text;
- Collective green for Clinical Sessions and active/progress states;
- gunmetal with muted green-steel machinery treatment for Work Shifts;
- striped dormant graphite with regeneration silver for Protected Days;
- industrial ochre for scheduled progress and restrained optic red for Today and urgent attention;
- shallow corners, clipped-corner accents, inset borders, narrow system sans typography, and tabular numerals;
- no generic bright SaaS cards or decorative soft gradients.

The architecture remains themeable; theme additions replace semantic tokens and Help's visual-state guide without changing workflows.

### 7.4 Responsive contract

- Desktop uses a top command bar, left Clinical Placement dock, central period view, right progress/attention rail, and staged tray below the calendar.
- Phone and short-landscape layouts use the compact calendar, selected-placement wheel, Total Progress, in-flow planning tray, and bottom navigation.
- Short landscape phones remain in the mobile experience. Tablet landscape may use the compact desktop toolbar only when the full three-column layout fits.
- The required responsive verification matrix is 320x568, 390x844, 844x390, 768x1024, 932x430, 1024x768, and 1440x900 logical pixels.
- At every required viewport: no horizontal page overflow, clipped primary copy, overlapping time controls, hidden actions, or planning-tray overlay; meaningful secondary text is at least 12 px; phone controls provide a 44 px minimum touch target where physically applicable.

## 8. Production architecture

### 8.1 Application stack and boundaries

Use Flutter/Dart with these logical modules:

1. **Domain:** value objects, lifecycle rules, progress formulas, Schedule Conflict validation, Protected Day rules, and Evaluation Plan rules.
2. **Application:** use cases and transactions for scheduling, confirmation, movement, progress, completion, backup, restore, and conflict resolution.
3. **Local data:** encrypted SQLite, schema migrations, repositories, and transactional outbox. The UI reads and writes local state only.
4. **Synchronization:** replaceable adapter over durable outbound operations, inbound cursor processing, and explicit conflict state.
5. **Presentation:** shared responsive Flutter widgets implementing Variant F with narrow-phone, tablet, and desktop composition.
6. **Platform adapters:** notifications, secure credentials, biometric/device authentication integration, file pickers, export, and installation concerns.

Business rules must not be duplicated in widgets or server-specific client code.

### 8.2 Local-first persistence

- Every user-visible save commits locally without waiting for the network.
- The domain change and its outbox operation commit in one SQLite transaction.
- App relaunch, device restart, network loss, and process termination must not discard a successful local save.
- SQLite encryption keys live in platform secure credential storage.
- Schema migrations are forward-only, versioned, tested against supported prior versions, and transactional where the platform permits.

### 8.3 Synchronization contract

Supabase/Postgres is the reference managed backend behind a replaceable adapter.

1. Every mutable entity has a UUID, `student_id`, integer revision, update timestamp, and deletion tombstone.
2. Every outbox operation has a unique idempotency key and base entity revision.
3. A server database function applies an operation atomically and rejects stale or invariant-breaking writes.
4. Accepted operations receive a monotonically ordered server cursor.
5. Devices pull all changes after their last cursor and apply them idempotently.
6. Realtime delivery, if used, is only a wake-up hint; correctness depends on the durable cursor.
7. Stale or mutually invalid offline changes remain visible as Sync Conflicts. The Student chooses either original or composes a corrected version.
8. Server authorization uses Row Level Security keyed to the authenticated `student_id`; privileged service credentials never ship in an application build.
9. Sync status distinguishes Synced, Offline with locally saved changes, Syncing, Conflict Needs Attention, and Sync Failed, including last success and pending count.

## 9. Ownership, backup, recovery, and privacy

### 9.1 Identity and connected devices

- Passwordless email with a one-time code is the synchronization identity; a Google account is not required.
- A signed-in device may change the email after verifying the replacement.
- Connected Devices shows device name, platform, and last synchronization time and allows revocation.
- Revocation blocks future synchronization but cannot remotely erase an offline copy.
- Sign Out and Remove This Device's Copy reports pending changes, removes only that local copy, and never deletes the account or other devices.

### 9.2 Recovery behavior

- Eligible deletions enter synchronized Trash for 30 days.
- Permanent deletion requires confirmation; clearing all Trash requires reauthentication.
- Daily recovery snapshots are retained for 30 days. Recovery creates a preview before touching live state.
- A portable backup contains all owned application records, settings, plans, and history; it is encrypted with a Student-chosen passphrase and saved through the system file picker.
- Restore works without the synchronization service, validates encryption/checksum/schema/all records before writing, and is all-or-nothing.
- Restore into populated data merges by permanent identity, keeps newer nonconflicting data, and asks about genuine conflicts. There is no unguarded Replace Everything action.

### 9.3 Export and account deletion

- A Clinical Placement report exports to printable PDF and optionally CSV with dates, target, progress totals, session ledger, Preceptor breakdown, and Evaluation Plan status.
- Complete machine-readable JSON export requires reauthentication and a privacy warning.
- Delete Account and All Data is separate from sign-out, requires reauthentication, offers backup first, and has a 30-day recovery period.
- After the grace period, active data, Trash, device registrations, and authentication records are removed. Residual encrypted operational snapshots expire within 30 additional days.

### 9.4 Privacy constraints

- The service may use data only for synchronization, backup, recovery, and requested exports.
- Advertising, sale, model training, and behavioral profiling are prohibited.
- Diagnostic telemetry excludes schedule contents, Preceptor details, notes, and exported files.
- Default lock-screen notifications omit Preceptor names, locations, notes, and Clinical Placement details.
- Support cannot inspect private data or bypass account ownership.

## 10. Packaging and installation gate

Before feature-scale implementation proceeds, a Flutter vertical slice must prove the selected stack on physical target devices:

1. render one responsive week view on Windows, iPhone, and Android tablet;
2. create a Clinical Session using military time;
3. persist it in encrypted local SQLite and recover it after an offline restart;
4. reject a Schedule Conflict and a commitment touching a Protected Day through shared domain rules;
5. produce an installable Windows artifact, signed Android APK, and provisioned iPhone build.

Windows and Android development may remain Windows-hosted. iPhone packaging requires Xcode on macOS, locally or in CI, and an Apple provisioning route. Early private iPhone distribution may use a registered-device development/ad hoc build; TestFlight is the preferred repeatable beta path. Public store submission remains out of scope.

If Flutter fails this gate for a framework-specific reason, reassess .NET MAUI before feature-scale implementation. BeeWare/Toga is considered only if Python becomes a hard requirement.

## 11. Prototype-to-production boundary

The React Variant F prototype proves product hierarchy and interaction intent only. Production must not inherit these prototype shortcuts:

| Prototype behavior | Production requirement |
| --- | --- |
| Fictional in-memory state resets on reload | Encrypted SQLite is durable across restart and offline use |
| Fixed August 2026 demonstration data | Real Student-owned calendar and current date/time-zone behavior |
| `Synced` represents local demonstration state | Sync status reflects durable outbox and server acknowledgement |
| Session-local avatar | Avatar persists in encrypted Student-owned data and synchronizes according to the data policy |
| Browser responsive approximation | Flutter layouts pass the required device and viewport matrix |
| Client-only conflict checks | Shared local domain validation plus authoritative server transaction checks |
| Demonstration notification center | Scheduled platform notifications plus synchronized reminder state |
| No authentication, backup, restore, or export | Passwordless identity and the complete ownership/recovery contract above |

## 12. MVP acceptance suite

Implementation is MVP-complete only when the following end-to-end scenarios pass on the applicable target devices.

### 12.1 Scheduling

- Create a valid multi-date Clinical Session batch and verify every commitment has the chosen times, Clinical Placement, and Preceptor.
- Include one conflicting date and verify nothing is saved until the conflict is removed or corrected.
- Create an overnight commitment and verify conflicts and Protected Days are checked on both dates.
- Batch-create Protected Days, move one, remove one, and verify Planning Incomplete updates immediately.
- Move a Work Shift and a Clinical Session, verifying data preservation, collision rejection, and date-driven Clinical Session status.
- Switch military/12-hour display and verify stored instants and calculated duration do not change.

### 12.2 Progress and evaluations

- Confirm a past Clinical Session with corrected times and Preceptor and verify exact placement, Preceptor, Total Progress, and Awaiting Confirmation totals.
- Add attributed and Unattributed Historical Hours Entries and verify both rollups.
- Exceed Target Hours and verify Remaining/Unscheduled floor at zero while Over-Target remains visible.
- Change Interim Review cadence and required boundary evaluations and verify only undocumented requirements regenerate.
- Reach Ready to Complete, close the placement, verify edits are locked, then reopen it without losing history.

### 12.3 Offline and synchronization

- Create, edit, and read all core records while disconnected; restart the app and verify the state remains.
- Reconnect and verify pending operations synchronize exactly once.
- Edit the same record differently on two offline devices and verify neither version is silently lost.
- Create concurrent records that would overlap and verify the server rejects the invalid combined state and the Student receives a resolvable Sync Conflict.
- Revoke a device and verify it cannot synchronize again while other devices remain intact.

### 12.4 Ownership and recovery

- Create and restore an encrypted backup without server access.
- Attempt a damaged, wrong-passphrase, and newer-schema restore and verify current data remains untouched.
- Restore into populated data and verify preview, safe merge, and explicit conflict handling.
- Export PDF, CSV, and JSON and verify required fields, privacy warning, and reauthentication gates.
- Restore a record from Trash and exercise the account-deletion grace-period cancellation path.

### 12.5 Presentation and notifications

- Pass the responsive matrix with no horizontal overflow, clipped primary copy, hidden actions, or overlapping controls.
- Verify Variant F semantic treatments remain distinct in Month, Week, and Agenda without relying on color labels alone.
- Verify the active Clinical Placement stays synchronized across management, wheel, progress, and scheduling default while allowing local scheduling override.
- Exercise each notification action and verify it opens the correct underlying workflow and clears only when the underlying state resolves.
- Verify quiet hours, privacy-minimized previews, synchronized snooze, and per-device notification enablement.

### 12.6 Release quality

- Domain and application tests cover every hard invariant and progress formula.
- SQLite migration, outbox idempotency, server conflict, backup/restore, and Row Level Security tests pass.
- Production builds contain no patient data, fictional prototype records, privileged server credentials, or diagnostic payloads containing private schedule data.
- Install, upgrade, offline restart, and uninstall/reinstall recovery paths pass on Windows, iPhone, and Android tablet.

## 13. Implementation decomposition boundary

The next planning pass may create implementation tickets, but it must preserve these module boundaries and sequence:

1. physical-device Flutter/SQLite vertical-slice gate;
2. domain model and invariant test harness;
3. encrypted local schema, migrations, repositories, and outbox;
4. scheduling and Clinical Placement application use cases;
5. responsive Variant F presentation against local repositories;
6. notifications and device adapters;
7. Supabase/Postgres synchronization and conflict resolution;
8. backup, restore, export, Trash, connected devices, and account deletion;
9. cross-device acceptance, packaging, and private installation.

Implementation tickets may refine technical details but may not change product rules in this specification without a new explicit product-decision ticket.
