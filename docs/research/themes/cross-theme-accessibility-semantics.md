# Cross-theme accessibility and semantic-color contract

Research date: 2026-08-05

## Decision summary

The six new themes must be independently usable with **Enhanced accessibility off**. Enhanced accessibility is one optional, global presentation layer that can strengthen contrast, add redundant marks, emphasize focus and selection, and quiet decorative chrome; it is not a substitute for baseline accessibility and does not create fourteen themes.

Clinical Calendar should adopt WCAG 2.2 Level AA visual and interaction criteria as its measurable cross-platform acceptance baseline, with first-party Android and Flutter guidance governing native implementation. WCAG is formally a web-content standard, so this document does not claim that every success criterion is legally normative for a native Flutter application. It distinguishes the W3C requirements the project chooses to adopt from platform guidance and project-specific recommendations.

The existing Containment Drone 47-Alpha appearance remains unchanged when Enhanced accessibility is off. The global mode may provide an explicit accessibility overlay when the Student enables it, but no six-theme implementation work may silently restyle the existing default profile.

## Source authority and terminology

- **W3C requirement adopted by the project** means a testable WCAG 2.2 Level A or AA success criterion. WCAG 2.2 is a W3C Recommendation; its success-criterion text is normative, while W3C “Understanding” and technique pages are explanatory guidance. ([WCAG 2.2](https://www.w3.org/TR/WCAG22/), [Understanding WCAG 2.2](https://www.w3.org/WAI/WCAG22/Understanding/))
- **Platform guidance** means a recommendation or API contract published by Android or Flutter. These are first-party implementation sources, not additional WCAG conformance levels.
- **Project recommendation** is a Clinical Calendar decision derived from those sources and its domain. It is binding only if ratified into the theme contract or implementation tickets.

## Adopted baseline requirements

### 1. Text and necessary graphics

W3C requirements adopted by the project:

- Ordinary text and images of text must reach **4.5:1** against their effective background. Large-scale text may use **3:1**. WCAG defines large scale as at least 18 point regular or 14 point bold (approximately 24 CSS px and 18.66 CSS px respectively). Inactive controls, pure decoration, invisible text, and logos have the listed exceptions; placeholder or secondary text is not automatically “inactive.” ([WCAG 2.2 SC 1.4.3](https://www.w3.org/TR/WCAG22/#contrast-minimum))
- Visual information needed to identify a control or understand its state, and graphical objects needed to understand content, must reach **3:1** against adjacent colors. This applies to necessary control boundaries, selected/focused outlines, calendar marks, progress segments, and meaningful icons. ([WCAG 2.2 SC 1.4.11](https://www.w3.org/TR/WCAG22/#non-text-contrast), [W3C non-text contrast explanation](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html))
- Text must remain resizable to **200% without loss of content or functionality**. Content must reflow without two-dimensional scrolling at the WCAG 320 CSS-pixel-wide proxy except where a two-dimensional presentation is essential. ([WCAG 2.2 SC 1.4.4](https://www.w3.org/TR/WCAG22/#resize-text), [WCAG 2.2 SC 1.4.10](https://www.w3.org/TR/WCAG22/#reflow))
- Where supported by the presentation technology, applying 1.5× line height, 2× paragraph spacing, 0.12em letter spacing, and 0.16em word spacing must not clip, overlap, or lose content or functionality. The criterion does **not** require those values as the default. ([WCAG 2.2 SC 1.4.12](https://www.w3.org/TR/WCAG22/#text-spacing), [W3C text-spacing explanation](https://www.w3.org/WAI/WCAG22/Understanding/text-spacing.html))

Platform guidance:

- Android recommends 4.5:1 for text smaller than 18sp (or bold text smaller than 14sp), and 3:1 for larger text. Flutter’s release checklist encourages at least 4.5:1 between controls or text and their backgrounds and asks teams to test colorblind/grayscale modes and very large text/display scales. ([Android: make apps more accessible](https://developer.android.com/guide/topics/ui/accessibility/apps#text-visibility), [Flutter accessibility checklist](https://docs.flutter.dev/ui/accessibility#accessibility-release-checklist))
- Android 14 supports nonlinear font scaling up to 200% and directs teams to test the maximum setting. Flutter’s `MediaQueryData.textScaler` reflects the platform’s preferred scaling strategy; the old scalar `textScaleFactor` is deprecated. Do not clamp or replace the platform scaler merely to preserve theme geometry. ([Android 14 nonlinear font scaling](https://developer.android.com/about/versions/14/features#200-percent-non-linear-font-scaling), [Flutter `textScaler`](https://api.flutter.dev/flutter/widgets/MediaQueryData/textScaler.html))
- Current Flutter `MediaQueryData` also exposes platform/user overrides for bold text, line height, letter spacing, word spacing, and paragraph spacing. Theme typography must allow those overrides to reach live `Text` widgets. ([Flutter `MediaQueryData`](https://api.flutter.dev/flutter/widgets/MediaQueryData-class.html), [Flutter `Text.style`](https://api.flutter.dev/flutter/widgets/Text/style.html))

Project recommendations:

- Store every foreground/background pairing as an opaque semantic token pair and test the **composited result**, not the raw hex values. Gradients, translucency, shadows, photos, textures, and state-layer opacity change effective contrast.
- Use live Flutter text for every heading, label, date, time, status, legend, button, and error. Nine-slice rasters must contain no meaningful text.
- At 200% Android font size, allow cards, rows, dialogs, and calendar details to grow, wrap, reflow, or scroll vertically. Never shrink the Student’s requested text, clip status words, overlap chrome, or hide the only action. Compact-viewport automation remains a regression proxy, not a claim of physical-phone acceptance.

### 2. Color is supportive, never the sole code

W3C requirement adopted by the project:

- Color cannot be the only visual means of conveying information, indicating an action, prompting a response, or distinguishing a visual element. A hue change alone is insufficient even if assistive technology receives the state. ([WCAG 2.2 SC 1.4.1](https://www.w3.org/TR/WCAG22/#use-of-color), [W3C use-of-color explanation](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color))

Platform guidance:

- Android explicitly directs apps to use patterns and position along with color to distinguish categories. Flutter’s checklist requires controls to remain usable and legible in colorblind and grayscale modes. ([Android accessibility principles](https://developer.android.com/guide/topics/ui/accessibility/principles#use-cues-other-than-color), [Flutter accessibility checklist](https://docs.flutter.dev/ui/accessibility#accessibility-release-checklist))

Project recommendations:

| Meaning | Baseline visual redundancy | Accessibility semantics |
| --- | --- | --- |
| Clinical Session | category label plus a theme-stable glyph/mark | Full date, time range, “Clinical Session,” Clinical Placement and Preceptor where shown, and state |
| Work Shift | category label plus a mark distinct in silhouette from Clinical Session | Full date, time range, “Work Shift,” and state |
| Protected Day | visible “Protected Day” wording where space permits plus a ring/shield-style mark; never only a tinted cell | Full date and “Protected Day”; expose conflict prohibition where actionable |
| Scheduled Session | explicit “Scheduled” word or stable schedule glyph | State announced as “Scheduled” |
| Completed Session | explicit “Completed” word or stable completion/check mark | State announced as “Completed” |
| Cancelled Session | explicit “Cancelled” word and strike/cancel mark | State announced as “Cancelled”; do not call it Missed |
| Missed Session | explicit “Missed” word and a distinct absence mark | State announced as “Missed”; do not call it Cancelled |
| Schedule Conflict | error icon plus clear conflict message and resolution action | Error state, conflicting commitments, and available correction |

The theme may alter the drawing style of a mark, but not its semantic meaning. A legend must repeat the visible mark and text, not offer color swatches alone. On dense calendar cells, a Student must be able to open a labeled details surface; truncation cannot erase the only state cue.

### 3. Focus, current date, selection, hover, and press are different states

W3C requirements adopted by the project:

- Every keyboard-operable component must show visible focus, and author-created content must not fully obscure the focused component. Focus must not trigger a context change by itself. ([WCAG 2.2 SC 2.4.7](https://www.w3.org/TR/WCAG22/#focus-visible), [WCAG 2.2 SC 2.4.11](https://www.w3.org/TR/WCAG22/#focus-not-obscured-minimum), [WCAG 2.2 SC 3.2.1](https://www.w3.org/TR/WCAG22/#on-focus))
- The necessary focus indicator is a non-text UI cue and therefore needs 3:1 against adjacent colors when author styled. ([W3C non-text contrast: relationship with focus](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html#relationship-with-focus-visible))
- Name, role, and state/value must be programmatically determinable for controls, including custom controls. When a visible text label exists, the accessible name must contain that visible wording. ([WCAG 2.2 SC 4.1.2](https://www.w3.org/TR/WCAG22/#name-role-value), [WCAG 2.2 SC 2.5.3](https://www.w3.org/TR/WCAG22/#label-in-name))

Platform guidance:

- Flutter `Semantics` exposes `selected`, `focused`, `focusable`, `button`, `label`, `value`, and other state/role properties to assistive technology. Decorative images can be excluded from the semantics tree. ([Flutter `Semantics`](https://api.flutter.dev/flutter/widgets/Semantics-class.html))
- Material 3 says states should use two visual indicators and be applied consistently; focused, hovered, pressed, selected, and disabled are separate states that can combine. This is design guidance, not a WCAG criterion. ([Material 3 states](https://m3.material.io/foundations/interaction/states/overview))

Project recommendations:

- A calendar date may simultaneously be **today**, **selected**, **keyboard focused**, and contain commitments. Give each an independent channel: for example, today marker/text, selected container/shape, focus ring, and event marks. Never reuse one colored fill for all four.
- Keep focus visible across dark, light, textured, and accent surfaces. Prefer a two-tone or theme-resolved outer/inner ring that remains 3:1 against both the control and surrounding surface. Do not encode focus only as a subtle shadow, glow, opacity shift, or hue shift.
- Selection persists after focus moves. Hover and press are transient. Tests must prove moving focus does not clear selection or make it visually indistinguishable.

### 4. Touch targets and control labels

W3C requirement adopted by the project:

- WCAG 2.2 AA requires pointer targets to be at least 24×24 CSS pixels or have enough separation for non-overlapping 24 CSS-pixel circles, subject to its inline, equivalent, user-agent, and essential exceptions. ([WCAG 2.2 SC 2.5.8](https://www.w3.org/TR/WCAG22/#target-size-minimum), [W3C target-size explanation](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html))

Platform guidance and project rule:

- Android recommends at least **48×48dp** focusable/touch area, and Flutter’s Android guideline tests 48×48 logical pixels. Clinical Calendar adopts 48×48 logical pixels as the stricter Android baseline for every tappable action, including icon buttons and calendar affordances; the painted icon may be smaller inside that hit area. ([Android touch targets](https://developer.android.com/guide/topics/ui/accessibility/apps#large-controls), [Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing))
- Every tappable semantics node needs an intelligible accessible label. Icon-only controls must have a purpose label; purely decorative child icons must not generate redundant announcements. ([Android element descriptions](https://developer.android.com/guide/topics/ui/accessibility/apps#describe-ui-element), [Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing))

### 5. Calendar and progress semantics

W3C requirements adopted by the project:

- Visual relationships and states must be programmatically determinable, and status messages must be exposed without requiring focus. ([WCAG 2.2 SC 1.3.1](https://www.w3.org/TR/WCAG22/#info-and-relationships), [WCAG 2.2 SC 4.1.3](https://www.w3.org/TR/WCAG22/#status-messages))

Platform guidance:

- Flutter semantics annotate meaning for assistive technology. Android’s first-party Compose guidance demonstrates the needed native concepts: calendar cells must expose selection and date information, custom progress must expose current value/range, and changing alerts may use polite live-region announcements. Flutter provides corresponding `selected`, `label`, `value`, `liveRegion`, and adjustable-value semantics. ([Android Compose semantics](https://developer.android.com/develop/ui/compose/accessibility/semantics), [Flutter `Semantics`](https://api.flutter.dev/flutter/widgets/Semantics-class.html), [Flutter live regions](https://api.flutter.dev/flutter/semantics/SemanticsProperties/liveRegion.html))

Project recommendations:

- Treat the calendar as a navigable grid/collection in semantics. Each date cell needs a unique full-date label and selected/today state, followed by concise commitment summaries. Decorative frame segments and empty visual spacers must not become focus stops.
- Every progress presentation must provide adjacent readable text and a programmatic value. At minimum expose target, Completed Hours, Scheduled Hours, Remaining Hours, Unscheduled Hours, and Over-Target Hours when present, using the domain terms exactly. Do not make a screen reader infer amounts from arc geometry or color.
- In a segmented progress wheel, each meaningful segment needs a 3:1 boundary against adjacent segments **or** a non-color separation such as spacing/pattern/outline. The adjacent legend repeats text, mark, and value. Completed and Scheduled must never collapse into one “done” category; Unscheduled is not synonymous with Remaining.
- Announce meaningful asynchronous results (save completed, verification failed, synchronization error) politely without moving focus. Do not mark continuously changing timers or routine progress animation as live regions. Error surfaces must state the problem and an actionable correction, not merely turn red.

### 6. Decoration and nine-slice housings

W3C requirements adopted by the project:

- Pure decoration may be ignored for contrast, but meaningful non-text information cannot be reclassified as decoration to avoid the 3:1 requirement. Images of text should be avoided where live text can achieve the presentation. ([WCAG 2.2 SC 1.4.11](https://www.w3.org/TR/WCAG22/#non-text-contrast), [WCAG 2.2 SC 1.4.5](https://www.w3.org/TR/WCAG22/#images-of-text))

Platform guidance and project rule:

- Android directs purely decorative images/icons to use null descriptions or be hidden from accessibility; Flutter provides `ExcludeSemantics` for the same purpose. ([Android decorative elements](https://developer.android.com/guide/topics/ui/accessibility/principles#decorative-elements), [Flutter `Semantics`](https://api.flutter.dev/flutter/widgets/Semantics-class.html))
- Theme motifs belong in nine-slice housing and noninteractive chrome. Content bays remain calm, opaque, and clipped inside the frame. Do not place botanical lines, coastal textures, technical grids, field-note marks, LCARS decoration, grain, noise, or glow behind calendar data or controls.
- Raster assets contain no text, controls, state icons, or information needed to operate the app. They are excluded from semantics, and all live content remains inside tested safe insets.

## Optional Enhanced accessibility mode

Enhanced accessibility is a **single global toggle**, independent of the selected theme. The following are project recommendations, not additional WCAG AA requirements:

| Token/behavior family | Standard-theme floor | Enhanced treatment |
| --- | --- | --- |
| Normal text | WCAG AA 4.5:1 | Target WCAG AAA 7:1 |
| Large text | WCAG AA 3:1 | Target WCAG AAA 4.5:1 |
| Necessary controls/graphics | 3:1 | Target 4.5:1 where palette permits |
| Focus | Visible, 3:1 adjacent contrast, not fully obscured | At least a 2-logical-pixel perimeter-equivalent indicator; fully unobscured target; preferably dual tone |
| Calendar/status categories | Text plus stable mark; never hue alone | Stronger outlines plus patterns/icons and a persistent expanded legend |
| Selection/current date | Independent visible states | Thicker, higher-contrast independent indicators |
| Decoration | No motif behind data; chrome only | Reduce texture, glow, translucency, and visual noise further |
| Typography | Respect system scaling/overrides | May increase weight/spacing, but must still respect system scaler and avoid clipping |

The enhanced focus recommendation deliberately borrows the measurable shape and visibility goals of WCAG 2.2 AAA Focus Appearance and Focus Not Obscured (Enhanced); it does not claim whole-app AAA conformance. ([WCAG 2.2 SC 2.4.12](https://www.w3.org/TR/WCAG22/#focus-not-obscured-enhanced), [WCAG 2.2 SC 2.4.13](https://www.w3.org/TR/WCAG22/#focus-appearance), [WCAG 2.2 SC 1.4.6](https://www.w3.org/TR/WCAG22/#contrast-enhanced))

Implementation constraints:

- Enhanced mode overrides semantic tokens and component emphasis, not layout ownership, information architecture, workflows, or domain labels.
- It must be reversible and must not mutate the chosen theme. Theme preview and Enhanced mode are independent state axes.
- System accessibility preferences remain authoritative whether the toggle is on or off. Flutter exposes text scaling, bold text, accessibility navigation, color inversion, animation reduction, and other media features; do not reset them in a theme wrapper. `highContrast` is currently populated only on supported iOS versions, so it cannot stand in for the app’s cross-platform toggle. ([Flutter `MediaQueryData`](https://api.flutter.dev/flutter/widgets/MediaQueryData-class.html), [Flutter `disableAnimations`](https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html), [Flutter `highContrast`](https://api.flutter.dev/flutter/widgets/MediaQueryData/highContrast.html))

## Implementable acceptance checks

Each of the six new themes must pass with Enhanced accessibility both **off and on** unless a check is specifically an enhanced target.

1. **Static token audit**
   - Calculate sRGB contrast for every declared text/background pair, including selected, focused, pressed, error, warning, disabled, and inverse variants.
   - Calculate composited colors for every opacity/state layer before testing.
   - Check necessary icon, outline, focus, selection, calendar mark, and progress-segment boundaries at 3:1 against every adjacent surface.
   - Keep a machine-readable list of permitted token pairings and an explicit prohibited-pair list in each theme palette brief.
2. **Flutter widget tests**
   - Run `textContrastGuideline`, `androidTapTargetGuideline`, and `labeledTapTargetGuideline` with semantics enabled. ([Flutter guideline API](https://docs.flutter.dev/ui/accessibility/accessibility-testing))
   - Assert category/state labels and `selected`/value semantics for representative date cells, theme-gallery cards, progress displays, icon buttons, errors, and the Enhanced accessibility switch.
   - Assert decorative raster/frame nodes contribute no semantics and do not split one logical control into redundant focus stops.
3. **Scaling and layout matrix**
   - Test default and Android maximum 200% nonlinear text scaling, bold-text override, and the current compact 320-logical-pixel regression viewport.
   - Reject overflow, clipped/overlapped text, hidden actions, lost status words, or content painting over/through frame chrome. Vertical scrolling or responsive stacking is acceptable.
   - Exercise Flutter text-style overrides for line, paragraph, letter, and word spacing where supported.
4. **Visual-state matrix**
   - Capture default, focused, hovered (where applicable), pressed, selected, today, disabled, warning, error, and combined selected+focused states on every surface family.
   - Convert captures to grayscale and simulate common red/green and blue/yellow color-vision deficiencies. Information must remain recoverable from text, shape, mark, pattern, position, or boundary—not inferred from hue names.
   - Inspect content at original resolution to ensure frame texture never crosses live data and small patterns do not become noise.
5. **Android tablet manual acceptance**
   - Use TalkBack to traverse the Calendar, progress, Theme gallery, Preview/Apply flow, dialogs, settings, and signed-out verification surface. Confirm unique, concise labels; correct roles/states; logical traversal; and no decorative stops.
   - Use switch/keyboard navigation where available to confirm visible, unobscured focus and an operable path to every action.
   - Use Accessibility Scanner as a diagnostic for contrast, labels, and targets, but treat scanner silence as insufficient without the semantic and manual checks. Android itself recommends combining manual, service-based, analysis, and automated testing. ([Android accessibility testing](https://developer.android.com/guide/topics/ui/accessibility/testing))
   - Approval is Android-tablet acceptance only. Windows architecture and phone responsive regressions may be preserved, but neither Windows nor physical-phone visual acceptance may be claimed before those targets are available.

## Prohibited patterns

- A theme that becomes compliant only when Enhanced accessibility is enabled.
- Clinical Session, Work Shift, Protected Day, Scheduled, Completed, Cancelled, Missed, warning, error, selection, or focus distinguished only by hue.
- Red/green as the only distinction, differently colored dots with identical silhouettes as the only calendar legend, or progress arcs without text values.
- Focus shown only by a low-contrast glow, shadow, opacity, animation, or the same treatment used for selection.
- A selected date whose state disappears when keyboard focus moves away, or a “today” marker indistinguishable from selection.
- Meaningful labels, dates, controls, or status icons baked into nine-slice raster art.
- Texture, line art, grain, grids, glows, or transparency behind calendar data or interactive controls.
- Contrast measured from uncomposited hex/alpha tokens, from a single point on a gradient, or against an assumed background not actually painted.
- `MediaQuery.withNoTextScaling`, arbitrary `TextScaler.clamp`, fixed-height text containers, forced single lines, or font shrinking used to protect artwork.
- Touch targets smaller than 48×48 logical pixels on Android merely because WCAG’s smaller target-spacing exception could apply.
- Unlabeled icon-only buttons, decorative images announced by TalkBack, duplicated semantic labels, or a visual label that disagrees with the accessible name.
- Live-region announcements for continuous animation/countdowns or focus theft used to announce routine status changes.
- Calling Unscheduled Hours “Remaining Hours,” calling Scheduled Hours “completed,” or merging Cancelled Session and Missed Session for visual convenience.
- Claiming Windows or physical-phone acceptance from Android-tablet screenshots or compact widget tests.

## Handoff to palette and theme contracts

Every new-theme palette brief must supply, at minimum:

- opaque semantic tokens for canvas, content surface, elevated surface, primary/secondary text, disabled text, interactive/control boundary, focus, selection, today, Clinical Session, Work Shift, Protected Day, Scheduled/Completed/Unscheduled progress, warning, error, synchronization/status, and inverse content;
- a table of tested foreground/background and adjacent-graphic ratios for standard and Enhanced modes;
- stable non-color marks for every calendar and progress category;
- enhanced overrides and a prohibited-combination table;
- evidence that decorative housing stays out of content bays and semantics.

No concept should advance to visual approval with attractive swatches alone. The complete semantic mapping and tests are part of the concept.
