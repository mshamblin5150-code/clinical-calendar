# Build the Encrypted SQLite Schema and Migrations

Type: task
Status: open
Blocked by: 60, 61, 64

## Objective

Create the complete encrypted local source-of-truth schema required by [`spec.md`](../spec.md#82-local-first-persistence).

## Acceptance criteria

- Tables represent Student Profile, Clinical Placements, Preceptors and attachments, commitments, Protected Days, Historical Hours Entries, Evaluation Plans and requirements, templates, settings, reminder state, device metadata, Trash, sync cursors, conflicts, and outbox operations.
- Mutable records include permanent UUID, owner identity, revision, timestamps, and deletion tombstone fields where synchronization requires them.
- Foreign keys, uniqueness, and local constraints preserve ownership and relationship invariants without replacing domain validation.
- The database is encrypted and its key is stored through the platform secure-credential adapter.
- Forward-only schema migrations preserve data and fail atomically from every supported prior schema fixture.
- Restart, interrupted migration, wrong-key, and corruption tests leave recoverable state and clear diagnostics without exposing private contents.

