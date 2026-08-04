# Build Evaluation Plan and Attention Surfaces

Type: task
Status: resolved
Blocked by: 68, 69, 73

## Objective

Implement Clinical Placement Evaluation Plan configuration, documentation, and actionable in-app attention state.

## Acceptance criteria

- Clinical Placement settings configure Interim Review cadence and Required/Not required boundary evaluations independently per placement.
- The checklist shows Not Due, Approaching, Due, and Documented requirements with separate Interim Review parts.
- Documentation captures date, location defaulting to Medatrax, and optional reference/note without accepting uploaded evaluation documents.
- Needs Attention and Notifications derive from unresolved confirmations, Protected Day planning, evaluations, deadlines, backup, and sync state.
- Every attention row opens the exact workflow required to resolve its underlying state.
- Resolving underlying state updates counts and removes the row without a reload.
- Phone evaluation and notification surfaces remain within the viewport and preserve contextual Back navigation.

## Answer

Implemented repository-backed Evaluation Plan configuration, impact preview, checklist state, documentation, and derived actionable attention across confirmation, Protected Day, evaluation, deadline, backup, and synchronization facts. Desktop rail, Notifications center, contextual routes, immediate refresh, mobile viewport, and Back behavior are integrated and pass the full repository quality gate.
