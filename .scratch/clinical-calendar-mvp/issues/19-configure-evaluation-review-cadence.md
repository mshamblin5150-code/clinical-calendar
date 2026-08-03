# Configure Evaluation Review Cadence

Type: task
Status: resolved
Blocked by: none

## Parent issue

Reported during QA of ticket 07.

## What's wrong

The Interim Review cadence is fixed invisibly instead of being part of the Clinical Placement configuration.

## What I expected

Each Clinical Placement exposes an editable review cadence in hours, defaulting to 90 hours for the current Student.

## Steps to reproduce

1. Open Clinical Placement management.
2. Inspect the placement fields.
3. Observe that review cadence cannot be viewed or changed.

## Blocked by

None - can start immediately.

## Answer

Each Clinical Placement exposes an Interim Review cadence in Completed Hours. Changing it immediately changes the Evaluation Plan threshold labels; the current default is 90 hours.
