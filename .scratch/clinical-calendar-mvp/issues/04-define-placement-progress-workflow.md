# Define the Clinical Placement Progress Workflow

Type: grilling
Status: resolved
Blocked by: none

## Question

What complete workflow and edge-case rules should govern Clinical Placements, Primary and additional Preceptors, session confirmation, actual-hour corrections, per-Preceptor breakdowns, over-target hours, Review Milestones, and placement completion?

## Comments

## Answer

### Placement definition and boundaries

- Every Clinical Placement requires a name, Target Hours, Start Date, Completion Deadline, Primary Preceptor, and configurable Evaluation Plan.
- The placement is the persistent program requirement, independent of a clinical site or particular Preceptor. Replacing a site or Preceptor never resets progress.
- Clinical Sessions are prohibited outside the placement window. A changed school deadline must be recorded before late sessions can be scheduled.
- Target Hours and placement dates remain editable while active. Saving shows an impact preview; a date change is blocked while existing sessions fall outside the proposed window. Target changes recalculate progress, projections, and undocumented future evaluation requirements without rewriting history.

### Hours and progress

- Completed Hours use confirmed actual start and end times, count the full elapsed interval without break deductions, and are stored to the exact minute without automatic rounding.
- Completion pre-fills scheduled times and Preceptor. The Student may correct actual times or the supervising Preceptor; the original schedule remains in history and all progress figures recalculate. When a session runs longer than scheduled, its full actual elapsed time counts, including any portion that pushes the placement beyond its target.
- Multiple past sessions may be completed together when their scheduled times and Preceptors are accurate; sessions needing corrections are handled individually.
- Over-target scheduling and completion are allowed with a clear warning. Remaining and Unscheduled Hours floor at zero, while Over-Target Hours are reported separately.
- Past Scheduled Sessions remain provisionally inside Scheduled Hours until completed, cancelled, or missed. Their planned duration is also called out as Awaiting Confirmation and never counts as Completed Hours.
- Historical Hours Entries support students adopting the app mid-placement. An entry records aggregate hours, effective date, placement, optional Preceptor, and optional note; Unattributed entries appear separately in the Preceptor breakdown. They count toward Completed Hours and Interim Review thresholds without becoming calendar commitments.
- The dashboard shows exact totals and per-Preceptor Completed and Scheduled Hours. It shows a Projected Completion Date when completed plus scheduled time reaches the target; otherwise it emphasizes Unscheduled Hours and the average additional weekly pace required by the deadline.

### Preceptors

- Preceptors are reusable person records that may attach to more than one Clinical Placement. Name is required; organization/site, phone, email, and scheduling notes are optional, and patient-related notes are prohibited.
- Each placement designates exactly one attached Preceptor as Primary. Clinical Sessions select one attached Preceptor.
- Changing the Primary Preceptor preserves all past sessions and documented Interim Reviews. Undocumented future Interim Reviews use the new Primary Preceptor.
- No user-facing inactive-preceptor workflow is needed. The Student simply chooses another Preceptor or changes the Primary designation; history remains attached to the original person.

### Evaluation Plan

- The Evaluation Plan is configurable per placement. The default supports an Initial Self-Assessment, recurring two-part Interim Reviews, a Final Self-Assessment, and a Final Placement Review; each requirement type may be enabled, disabled, or configured for different programs.
- The Initial Self-Assessment is required before the placement begins but does not block scheduling or truthful hour entry. It becomes overdue at the Start Date and prevents placement completion until documented.
- Each Interim Review occurs at the configured combined Completed Hours interval across all Preceptors—90 hours for the current program. Its two separately tracked parts are the Student's review of the Primary Preceptor and the Primary Preceptor's review of the Student.
- The Final Self-Assessment and Final Placement Review are distinct end-of-placement requirements. The current program has no separate final Preceptor evaluation beyond recurring Interim Reviews.
- Each requirement tracks Not Due, Approaching, Due, or Documented status; date documented; documentation location defaulting to Medatrax; and an optional reference or note. The MVP stores no evaluation documents, credentials, or patient information.
- Documented evaluations remain satisfied if later hour corrections place them before their threshold. They are shown as documented early and never become undone.
- Editing an Evaluation Plan preserves documented requirements and regenerates only undocumented ones after an impact preview. Newly introduced thresholds already passed become immediately Due.

### Placement lifecycle

- A placement becomes Ready to Complete only after Completed Hours meet or exceed the target, every Evaluation Plan requirement is documented, no past session awaits confirmation, and no future Clinical Session remains scheduled.
- The Student explicitly completes a Ready-to-Complete placement. Completed Placements are locked against ordinary edits and new sessions.
- A guarded Reopen Placement action restores active tracking without deleting history, supporting accidental completion or later school corrections.
- There is no Discontinued Placement state: loss of a site or Preceptor leaves the underlying requirement active with its completed and remaining hours intact.
- Permanent deletion is available only for an empty placement created by mistake, with no sessions, Historical Hours Entries, or evaluations.
