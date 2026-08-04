# Build Settings, Student Profile, Templates, and Help

Type: task
Status: resolved
Blocked by: 66, 69

## Objective

Implement the configurable supporting surfaces and persist their state locally.

## Acceptance criteria

- Settings persist week start, time display, selected theme, synchronization preferences, and notification preferences through repositories.
- Schedule Templates can be added, edited, and removed with derived duration and optional Clinical Placement/Preceptor defaults.
- Student Profile derives initials from the display name and supports persisted optional avatar selection, replacement, and removal.
- Profile controls appear in desktop and mobile headers and use at least the specified mobile touch target.
- Help covers every primary workflow and production storage/synchronization meaning.
- Help uses shared workflow copy plus theme-specific visual-state guidance with a safe unknown-theme fallback.
- Reload and offline restart preserve settings, templates, profile, and avatar without prototype reset behavior.

## Answer

Implemented persistent Settings, Schedule Templates, Student Profile/avatar, and theme-aware Help over the encrypted local repositories. Production startup now creates a stable secure Student owner, opens the SQLCipher database in application support storage, and composes the same repository-backed state into desktop, Android, and future iOS surfaces. Full analysis, tests, Windows release, and Android release builds pass.
