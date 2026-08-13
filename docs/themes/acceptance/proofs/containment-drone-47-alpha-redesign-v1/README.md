# Containment Drone 47-Alpha redesign v1

Issue: [#146](https://github.com/mshamblin5150-code/clinical-calendar/issues/146)

Status: **proposed concept; maintainer approval pending**.

This directory records the pre-change shipping baseline and the first
replacement landscape proposal. It does not amend the Variant F preservation
boundary and does not authorize edits to frozen assets, renderer geometry,
goldens, or production behavior.

## Accepted shipping baseline

- Accepted Android-tablet catalog issue: #139.
- Accepted repository commit: `1d5f278761669f30ae06bbc06023c65bc90cd92f`.
- Immutable theme ID: `variant-f`.
- Public display name: Containment Drone 47-Alpha.
- Physical target: Samsung SM-X920, Android 16.
- Current frozen asset, renderer-source, responsive-render, Help-render, and
  Standard/Enhanced-off restoration hashes are recorded in
  `shipping-baseline-manifest.json`.
- The signed physical captures and their hashes remain referenced by
  `docs/themes/acceptance/variant-f/manifest.json`; they are not copied or
  relabelled here.

## Proposed landscape concept

`proposed-concept-landscape-1536x1024.png` is a generated approval artifact,
not a runtime capture and not production raster art. The accepted current
Gallery runtime was used only as an identity and palette reference.

Declared golden viewport: **1536 x 1024 logical pixels**.

The proposal preserves the Containment Drone identity through a continuous
gunmetal command chassis, dark black-green live-content bays, shallow squared
controls, compact uppercase labels, restrained green status lighting, and the
existing clinical semantic palette. It intentionally strengthens hierarchy:

1. compact command crown;
2. left Clinical Placements bay;
3. dominant central Calendar bay;
4. shallow Planning strip below the Calendar;
5. right Progress and Needs Attention stack; and
6. theme-owned bottom navigation rail.

Generated text and fictional fixture details are illustrative. Production
implementation must use shared live application widgets/slots and the
repository's exact domain language, workflows, callbacks, validation, and
persistence.

## Proposed portrait recomposition

Declared portrait proof viewport: **900 x 1440 logical pixels**.

Portrait is not a scaled landscape. The theme-owned outer shell owns one
vertical scroll path with this semantic reading order:

1. compact command crown and current destination;
2. Calendar controls and full Calendar region;
3. Clinical Placements;
4. Planning;
5. Progress; and
6. Needs Attention.

The bottom navigation remains outside that scroll path and reachable as a
compact persistent command rail. Live panels do not introduce competing
page-level vertical scroll owners; bounded internal collections may scroll
only when their shared production slot already owns that behavior. At 200%
text scale, panels expand vertically, required actions remain present, and the
single outer scroll path exposes the entire ordered composition.

## Approval gate

Before production implementation begins, the maintainer must explicitly:

1. accept or reject the proposed landscape concept;
2. accept or revise the declared landscape and portrait viewports/composition;
3. authorize a preservation-boundary amendment naming the frozen renderer or
   geometry that may change; and
4. confirm the public test seams for the TDD implementation.

Rejected proposals remain labelled historical evidence and are never used as
acceptance baselines.
