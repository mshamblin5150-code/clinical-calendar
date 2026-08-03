# Enforce Privacy and Security Boundaries

Type: task
Status: open
Blocked by: 76, 77, 78, 80, 81, 82, 83

## Objective

Verify that production data handling obeys the privacy, credential, telemetry, notification, and patient-information boundaries in [`spec.md`](../spec.md#94-privacy-constraints).

## Acceptance criteria

- No feature accepts or labels fields for patient identifiers, encounter details, diagnoses, clinical documentation, evaluation files, or credentials.
- Diagnostic telemetry excludes schedule contents, Preceptor data, notes, exports, backup contents, and conflict payload contents.
- Application artifacts contain no privileged server key, signing secret, backup passphrase, local database key, or test account credential.
- Local databases and credentials use the approved encryption and platform secure-storage adapters.
- Default lock-screen notification fixtures contain no Preceptor, location, note, or Clinical Placement details.
- Threat-focused tests cover authorization bypass, RLS isolation, exported-file leakage, log redaction, backup temporary files, revoked devices, and account purge.
- The release checklist records remaining risks and verifies that support cannot inspect private data or bypass ownership.

