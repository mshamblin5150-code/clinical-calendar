# Write the Decision-Complete MVP Specification

Type: task
Status: resolved
Blocked by: none

## Problem

The accepted Variant F prototype and tickets 01-55 contain the settled product, workflow, architecture, and responsive-interface decisions, but those decisions are distributed across research, issue answers, the domain glossary, and prototype behavior. Implementation cannot yet be decomposed reliably from one authoritative specification with measurable acceptance criteria and explicit production boundaries.

## Acceptance criteria

- `.scratch/clinical-calendar-mvp/spec.md` is the authoritative implementation-facing MVP specification.
- The specification uses the canonical language from `CONTEXT.md` and preserves the decisions recorded in tickets 01-55.
- Product scope, supported devices, workflows, invariants, data ownership, offline behavior, synchronization, notifications, responsive presentation, and production boundaries are explicit.
- Acceptance criteria are measurable and suitable for later decomposition into implementation tickets.
- Prototype-only behavior is clearly separated from production requirements.
- Deferred work is explicit, including public distribution and comprehensive keyboard-first accessibility work.
- No new product behavior is invented while consolidating the settled decisions.

## Comments

- The Student approved this specification transition after the completed-prototype audit on 2026-08-03.
- Keyboard-first operation is not a current priority; modal keyboard refinements remain deferred rather than becoming the next prototype feature.

## Answer

The decision-complete implementation specification is now [`spec.md`](../spec.md). It consolidates the canonical domain model, scheduling and Clinical Placement workflows, progress formulas, Evaluation Plans, reminders, Variant F responsive contract, Flutter/SQLite/Supabase architecture, synchronization invariants, ownership/recovery rules, prototype-to-production boundary, packaging gate, and measurable cross-platform acceptance suite. Comprehensive keyboard-first optimization remains explicitly deferred, and no prototype behavior was changed.
