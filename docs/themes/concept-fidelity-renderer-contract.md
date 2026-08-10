# Concept-Fidelity Theme Renderer Contract

Status: binding maintainer-directed revision, 2026-08-08.

This contract governs implementation and visual acceptance of Clinical
Calendar themes that have an approved dashboard concept. It supersedes the
fixed-layout requirements in the original additive-theme contract wherever
those requirements prevent a runtime theme from matching its approved
concept. The preservation boundary for Containment Drone 47-Alpha
(`variant-f`) is unchanged.

## Decision

An approved concept is the normative visual specification for its theme, not
an inspirational reference. A renderer does not satisfy this contract merely
because it contains the same generic content regions. At the golden landscape
viewport, the implemented application must read as the same designed object
as the approved concept.

The shared contract fixes clinical behavior. It does not fix tablet shell
geometry.

## Invariants shared by every theme

Every renderer must preserve:

- Student data, domain language, workflows, validation, and persistence;
- the live Calendar, Planning, Clinical Placements, progress, and attention
  capabilities required by the application state;
- destination reachability and the meaning of navigation actions;
- callback behavior, controller/state ownership, focus, and unsaved work;
- semantic roles, reading order, keyboard and touch operation, non-color
  cues, and system accessibility behavior; and
- the closed theme identifier, complete-bundle boundary, fallback behavior,
  Preview/Apply/Revert behavior, and theme-specific Help obligations.

These are behavioral and semantic invariants. They must be tested through
shared production seams rather than copied or reimplemented as theme-local
business logic.

## Presentation owned by a concept theme

A complete concept theme may own all of the following when required for
fidelity:

- landscape and portrait tablet composition;
- panel hierarchy, proportions, nesting, and visual grouping;
- application crown, header, and navigation presentation;
- placement of live controls within their relevant semantic region;
- theme-specific tablet breakpoints and reflow rules;
- raster housings, internal frames, material language, and decorative
  structure; and
- density policies used to fit shared live content into bounded theme bays.

Theme-owned layout must consume shared live widgets or documented shared
slots. It may wrap those widgets in generic opt-in viewport policies, but the
default path for another theme must not change. Theme code must not fork
clinical state, persistence, validation, or workflow logic.

Issue [#159](https://github.com/mshamblin5150-code/clinical-calendar/issues/159)
also establishes one catalog-level visual invariant for the six concept
themes: wherever an approved composition specifies the Axion delta, its
underlying delta-and-orbit mark comes from the same catalog-owned source.
This does not make the crown or shell shared. Each theme continues to own the
mark's placement, scale, optional color treatment, semantics, surrounding
material, and complete responsive composition. Containment Drone 47-Alpha is
not a consumer of the shared mark.

Control coordinates and breakpoint numbers are therefore not catalog-wide
invariants. Reachability, meaning, minimum usable size, semantic order, and
workflow behavior are invariants.

## Landscape golden exemplar

Each concept theme declares one exact landscape tablet viewport as its golden
exemplar. Federation 2399 uses 1536 by 1024.

Visual review compares the runtime and approved concept across all of these
dimensions:

1. outer silhouette and chassis depth;
2. dominant panel proportions and negative space;
3. content hierarchy and reading path;
4. placement of Calendar, Planning, Clinical Placements, progress, and
   attention regions;
5. crown/header and bottom-navigation geometry;
6. control grouping and relative scale;
7. material, color, lighting, border, and corner language; and
8. density and legibility of representative live content.

Matching only the number or order of rectangular slots is insufficient.
Generic cards placed inside a themed border are insufficient when the concept
uses an integrated sculpted console. Raster similarity cannot compensate for
incorrect proportions or hierarchy, and correct proportions cannot
compensate for generic material treatment.

The maintainer is the final visual approver. Automated comparisons and goldens
make changes reviewable but cannot approve a concept on their own.

## Portrait contract

Portrait is an intentional re-composition of the approved landscape identity,
not a uniformly scaled or clipped landscape screen. It must:

- retain the same visual language and recognizable hierarchy;
- keep the live Calendar as the primary region;
- preserve access to Planning, Clinical Placements, progress, attention, and
  navigation;
- define an explicit reading order and scroll ownership;
- support system text scaling without hiding required actions; and
- avoid inventing a second unrelated theme identity.

Portrait approval does not lower the landscape fidelity requirement.

## Evidence requirements

Before asking for visual approval, a theme implementation must provide:

- the untouched approved concept;
- a deterministic full-screen landscape runtime capture at the declared
  golden viewport;
- a labeled concept-versus-runtime comparison at equal displayed size;
- a deterministic full-screen portrait runtime capture;
- goldens that load production raster assets deterministically and pass alone,
  together, and from the repository-standard test entrypoint;
- tests for theme-owned navigation and command callbacks;
- tests showing default rendering paths for other themes remain unchanged;
- 200 percent text-scale and overflow evidence using representative content;
  and
- a clearly marked physical Android-tablet acceptance state.

Fictional data is mandatory for all captures. Proof documentation must state
whether an image is a deterministic test render or a physical-device capture.
A rejected proof is retained only as historical evidence and must be labelled
`rejected`; it can never become a golden acceptance baseline through reuse.

## Containment Drone preservation boundary

This contract does not authorize edits to frozen Variant F assets, geometry,
renderer behavior, or accepted output. Generic policies introduced for a
concept theme must be opt-in and default to the pre-existing behavior.

Moving Variant F to a concept-owned renderer remains a separate convergence
decision requiring exact reference-image equality, protected-asset checks,
the full responsive suite, and fresh physical Android approval.

## Adoption order

Federation 2399 issue #134 is the pilot for this contract. Its currently
rejected implementation must be rebuilt and approved before the renderer
contract is propagated.

After the maintainer approves the Federation 2399 landscape exemplar:

1. close issue #134;
2. reopen Graphite and Federation Classic as separate implementation issues;
3. apply this contract without borrowing Federation 2399 artwork or identity;
4. update the remaining unimplemented theme tickets to reference this
   contract; and
5. keep each theme's visual approval and proof package independent.

No agent may infer approval from passing tests, a committed proof package, or
structural similarity. Explicit maintainer confirmation is required.

## Drone handoff checklist

Before changing a concept theme shell, an implementation drone must read:

1. `AGENTS.md`;
2. `CONTEXT.md`;
3. this contract;
4. `docs/themes/additive-theme-contract.md`;
5. `docs/agents/variant-f-raster-frames.md`; and
6. the active GitHub issue and its latest maintainer feedback.

The drone must identify the approved concept, declared landscape viewport,
current proof status, and protected-theme boundary before editing code. If the
latest maintainer feedback rejects a proof, the issue remains open and that
proof is not an implementation target.
