# Research the Synchronization and Storage Model

Type: research
Status: resolved
Blocked by: none

## Question

Which synchronization and storage model best supports the same offline-first calendar on Windows, iPhone, and Android tablet? Compare a Google Drive app-managed file or folder with a small managed sync backend, covering Google authorization, user setup, concurrent offline edits, conflict safety, backups, privacy, operating cost, and later distribution.

## Comments

## Answer

Use a small managed relational sync backend, with Supabase/Postgres as the MVP reference, plus a complete local SQLite database and durable record-level outbox on every device. Server transactions and explicit entity revisions must reject stale or invariant-breaking writes; conflicts are surfaced for resolution rather than silently resolved by upload order or last-write-wins. Do not use a shared Google Drive file as the authoritative sync store. Google Drive may later be an explicit encrypted export/backup destination.

Research, comparison, citations, costs, and the required synchronization contract: [Synchronization and Storage Model Research](../research/02-sync-storage-model.md).
