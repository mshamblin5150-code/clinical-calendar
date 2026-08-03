# Build Synchronization Conflict Resolution

Type: task
Status: open
Blocked by: 67, 68, 69, 78

## Objective

Preserve and resolve concurrent offline changes explicitly instead of using silent last-write-wins behavior.

## Acceptance criteria

- A rejected stale operation preserves the local version, remote version, common identity, and rejection reason.
- Same-record conflicts show both versions side by side and allow choosing either or composing a corrected valid version.
- Cross-record Schedule Conflict and Protected Day violations show every affected record and require move, Cancel, Missed, or eligible delete resolution.
- Conflict resolution itself creates a normal revisioned local mutation and outbox operation.
- A conflicted week remains visibly Planning Incomplete when its Protected Day or commitment validity is unresolved.
- Resolution history retains both originals without exposing private contents to support telemetry.
- Two-device integration tests demonstrate that neither original is silently discarded and all devices converge after resolution.

