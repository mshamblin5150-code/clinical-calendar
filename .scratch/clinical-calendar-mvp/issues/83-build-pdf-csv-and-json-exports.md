# Build PDF, CSV, and JSON Exports

Type: task
Status: resolved
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

## Answer

Implemented privacy-gated PDF, CSV, and complete versioned JSON export workflows with native save dialogs, stable machine-readable fields, and no secret material. Fixture coverage includes zero, typical, over-target, multiple-Preceptor, Unattributed, and non-ASCII cases; rendered PDFs were visually inspected, Windows and Android builds pass, and iOS picker configuration is prepared for deferred Mac/iPhone verification.
