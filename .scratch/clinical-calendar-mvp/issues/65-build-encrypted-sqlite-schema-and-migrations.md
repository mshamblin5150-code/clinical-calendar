# Build the Encrypted SQLite Schema and Migrations

Type: task
Status: resolved
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

## Answer

Implemented a SQLCipher-backed local database with its random 256-bit key supplied through the application `SecureStorage` port. Atomic, forward-only migrations create the complete STRICT SQLite source-of-truth schema, owner-scoped relationships, synchronization metadata, conflicts, Trash, and transactional outbox storage. The public database boundary rejects missing or invalid keys, unavailable SQLCipher, newer schemas, wrong keys, corruption, and failed migrations with typed diagnostics that retain no SQL, keys, or Student content.

Thirteen native SQLCipher tests prove encrypted file headers, offline restart persistence, wrong/missing/invalid-key recovery, corruption preservation, ownership constraints, v1 and v2 fixture upgrades, repeated-open idempotence, newer-version rejection, and complete rollback after an interrupted migration. The full workspace quality gate passed, followed by successful Windows release and Android release APK builds. iPhone compilation remains intentionally deferred to ticket 87 and the approved Mac hardware gate.
