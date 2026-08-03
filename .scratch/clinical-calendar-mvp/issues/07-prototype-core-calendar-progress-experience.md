# Prototype the Core Calendar and Progress Experience

Type: prototype
Status: resolved
Blocked by: 03, 04, 06

## Question

Which navigation, calendar views, placement dashboard, progress presentation, Preceptor fan-out, attention center, reminder prompts, and sync/backup status surfaces make the settled workflows understandable and fast on phone, tablet, and desktop?

## Comments

- Concept review assets generated for the first HITL pass:
  - [Variant A — Calendar Command Center](../prototype/concepts/Variant%20A%20-%20Calendar%20Command%20Center.png)
  - [Variant B — Progress Navigator](../prototype/concepts/Variant%20B%20-%20Progress%20Navigator.png)
  - [Variant C — Monthly Planning Board](../prototype/concepts/Variant%20C%20-%20Monthly%20Planning%20Board.png)
- First-round direction from the Student:
  - Use a dark theme.
  - Prefer Variant B's overall desktop layout, including the left Clinical Placement dock, bottom total-progress bar, top application bar with menu, Add Schedule, notification, sync, and profile controls, and the right Needs Attention region.
  - Incorporate Variant A's circular Family Medicine hour breakdown, large Interim Review Approaching warning, and phone bottom navigation: Today, Calendar, Placements, Attention, Settings.
  - Variant C's large monthly planning calendar is essential and must be included.
- Revised concept for approval: [Variant D — Dark Composite](../prototype/concepts/Variant%20D%20-%20Dark%20Composite.png).
- Second-round feedback:
  - Variant D's generic dark palette is not coherent enough; explore a deliberately themed color system.
  - Produce multiple Borg-inspired and Star Trek: Picard-inspired directions.
  - The persistent bottom multi-date/template/conflict panel is not yet accepted. Test a clearer staged collapsible tray and an alternative side/drawer interaction while preserving the approved calendar, placement dock, circular progress, review warning, and phone navigation.
- Second-round theme and planning-interaction concepts:
  - [Variant E — Borg Systems Grid](../prototype/concepts/Variant%20E%20-%20Borg%20Systems%20Grid.png)
  - [Variant F — Borg Tactical Console](../prototype/concepts/Variant%20F%20-%20Borg%20Tactical%20Console.png)
  - [Variant G — Picard LCARS Heritage](../prototype/concepts/Variant%20G%20-%20Picard%20LCARS%20Heritage.png)
  - [Variant H — Picard Command Glass](../prototype/concepts/Variant%20H%20-%20Picard%20Command%20Glass.png)
- Accepted working theme: **Variant F — Borg Tactical Console**. The eventual product should remain themeable, but Variant F is the current visual specification.
- Interactive HITL prototype: [Variant F React prototype](../prototype/interactive/README.md).
  - Responsive desktop and phone layouts implemented with fictional, in-memory data only.
  - Calendar date selection, placement selection, template/placement/review staging, conflict resolution, and final Apply Schedule state are interactive.
  - Production build passed on 2026-08-02; browser QA covered 1536 × 1024 and 390 × 844 viewports with no console warnings or errors.
  - Awaiting Student review of the staged planning tray and overall hierarchy before this prototype ticket is resolved.
- Functional-core expansion after the first hands-on review (2026-08-03):
  - The Student correctly identified that a static visual mock plus a terminal Apply action was not enough to judge the program prototype.
  - Added visible in-memory state changes across Work Shift and Clinical Session scheduling, 12-hour military-time templates, all-or-nothing conflict removal, calendar events, Placement and per-Preceptor scheduled/completed hours, Protected Days, session confirmation, Evaluation Plan documentation, Month/Week/Agenda views, attention handling, settings/sync/backup surfaces, and phone navigation.
  - Corrected Billing & Coding Target Hours from the mockup's 60 to the settled 90 hours.
  - Production build passes and the local server responds successfully. Automated rendered revalidation is pending because the Browser-controlled localhost tab entered a blocked error-page state after the development server restart; the Student's live local tab remains the HITL review path.

## Answer

Variant F — Borg Tactical Console is the accepted responsive product and visual prototype. Its React implementation now demonstrates the settled calendar, staged scheduling, Protected Day, Clinical Placement, Preceptor, progress, Evaluation Plan, notification, settings, Help, profile, and responsive interaction decisions with fictional in-memory state. Tickets 09-55 record the subsequent functional repairs and refinements; [`spec.md`](../spec.md) is the production implementation authority.
