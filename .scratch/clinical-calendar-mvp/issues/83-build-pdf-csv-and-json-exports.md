# Build PDF, CSV, and JSON Exports

Type: task
Status: open
Blocked by: 68, 69

## Objective

Implement human-readable Clinical Placement reporting and complete machine-readable data portability.

## Acceptance criteria

- Default Clinical Placement PDF includes dates, Target Hours, Completed/Scheduled/Remaining/Over-Target totals, session ledger, Preceptor breakdown, and Evaluation Plan status.
- Advanced CSV exports stable documented columns and exact machine-readable dates, times, durations, statuses, and identities needed for analysis.
- Complete JSON export includes all Student-owned portable records with a versioned schema.
- JSON export requires reauthentication and a clear privacy warning before the system file picker opens.
- Exports never include authentication secrets, encryption keys, internal service credentials, or deleted data outside the documented export boundary.
- Output is verified with zero, typical, over-target, multiple-Preceptor, Unattributed, and non-ASCII fixtures on every target platform.

