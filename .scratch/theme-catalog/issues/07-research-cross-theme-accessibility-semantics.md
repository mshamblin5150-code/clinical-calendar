# Research Cross-Theme Accessibility and Semantic Color Requirements

Type: research
Status: resolved
Blocked by:

## Question

What authoritative accessibility requirements and platform guidance must govern text, controls, focus, selection, calendar states, progress states, decoration, patterns, icons, and the optional Enhanced accessibility mode across all six new themes?

## Answer

Adopt WCAG 2.2 AA as the measurable cross-theme baseline, implemented and tested with first-party Android and Flutter guidance. Every new theme must pass with Enhanced accessibility off; the optional global mode raises contrast and focus targets, adds stronger redundant marks/patterns, and quiets decoration without changing workflows or replacing system accessibility settings. The research defines calendar/progress semantics, scaling and target-size gates, test matrices, and prohibited patterns in [the cross-theme accessibility and semantic-color contract](../../../docs/research/themes/cross-theme-accessibility-semantics.md).
