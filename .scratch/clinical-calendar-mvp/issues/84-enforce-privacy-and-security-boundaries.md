# Enforce Privacy and Security Boundaries

Type: task
Status: resolved
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

## Answer

Completed a fresh, exhaustive standard Codex Security scan of all 534 repository files and remediated all seven validated findings (four medium, three low). Permanent purge now removes historical private synchronization payloads without reopening an anti-resurrection receipt path; Android release signing fails closed without external production credentials; release transport requires HTTPS; evaluation documentation accepts only a constrained non-clinical external reference; CSV formula prefixes are neutralized; and portable-backup parsing and KDF work are strictly bounded.

Added [`docs/release-security-checklist.md`](../../../docs/release-security-checklist.md) to cover the complete privacy, credential, telemetry, encrypted-storage, notification, RLS, export/backup, revocation, erasure, artifact, and support boundary. The full repository quality gate passed, including focused Flutter/Dart tests, 117 Supabase pgTAP assertions, static synchronization checks, a concurrent permanent-purge race, Android debug build, fail-closed unsigned release check, and source/APK credential-signature scans. Verification of the certificate fingerprint on an actually production-signed Android artifact remains correctly assigned to Ticket 86 because no signing secret is stored in or available to this repository.

Canonical scan artifacts are under scan `a216b205-c273-4ac9-9013-ec2084e69f2d`; its required fix evidence is recorded in `artifacts/fix_report.md`.
