# Implement Time and Commitment Domain Types

Type: task
Status: resolved
Blocked by: 59

## Objective

Implement the platform-independent time and commitment model defined by [`spec.md`](../spec.md#3-canonical-model-and-invariants).

## Acceptance criteria

- Work Shift, Clinical Session, Protected Day, Schedule Template, local date, local time, time zone, and overnight interval types have explicit validated constructors.
- Military `HHMM` and `HH:MM` input normalizes to stored 24-hour values; 12-hour formatting changes display only.
- Exact elapsed minutes are derived without automatic rounding or break deduction.
- Overnight intervals retain the creating time zone and cover both affected calendar dates.
- Clinical Session lifecycle states include Scheduled, Awaiting Confirmation, Completed, Cancelled, and Missed with only valid transitions allowed.
- Unit tests cover daylight-saving boundaries, midnight crossing, invalid input, date-driven status, and exact-minute duration.

## Answer

Implemented the dependency-free time and commitment model in
`packages/clinical_calendar_domain`:

- `LocalDate` and `LocalTime` validate calendar and minute-precision wall-time
  values. Military `HHMM` and `HH:MM` input normalizes to stored `HH:MM`, while
  12-hour output is display-only.
- `TimeZoneId`, `UtcOffset`, and `ZonedInterval` preserve the creating zone and
  both observed boundary offsets. This makes elapsed minutes deterministic
  across devices and daylight-saving changes without consulting the host
  machine's local zone. Overnight intervals derive the next end date and expose
  every covered calendar date.
- `WorkShift`, `ProtectedDay`, and `ScheduleTemplate` have validated identities,
  required values, assignment rules, and date-free overnight template behavior.
- `ClinicalSession` requires one Clinical Placement and Preceptor, derives
  Scheduled or Awaiting Confirmation from time, and permits only the specified
  Completed, Cancelled, Missed, refresh, restoration, and rescheduling
  transitions. Completed minutes come only from a validated confirmed actual
  interval in the original time zone.
- Conflict, weekly Protected Day, and placement-membership enforcement remain
  outside these record types for Tickets 61 and 62, as planned.

The package has 19 passing tests covering invalid dates/times/zones, military
normalization, display formatting, exact unrounded minutes, midnight crossing,
spring and fall daylight-saving boundaries, date-driven status, lifecycle
transitions, restoration, and reassignment constraints. The repository-wide
format, fatal-info analysis, architecture, and test gate also passes.
