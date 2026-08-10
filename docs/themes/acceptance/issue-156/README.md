# Issue #156 physical Android-tablet acceptance

Issue: [#156](https://github.com/mshamblin5150-code/clinical-calendar/issues/156)

Physical recapture passed on 2026-08-10 for commit
`29ce956cfd1da12c572b77658704102cb715ff7c`.

## Capture configuration

- Samsung SM-X920 running Android 16 / API 36.
- Native 2960 x 1848 landscape viewport.
- Android `font_scale=2.0`.
- Locally packaged `0.1.0+43` acceptance APK, installed in place without
  clearing app data.
- APK SHA-256:
  `ced0dcc5b9d1e25e441bc561ce0dd2e2a250957f0a49c82d1a7ed5cc9001ed93`.
- Approved signer SHA-256:
  `9903aca5242daa0f926270940b4174687f65144b698d28a7c4dbd00bedb817f0`.
- The build used the documented non-distributable `LOCAL` acceptance mode. It
  preserved the production signer but contained no protected synchronization
  configuration.

The app was returned to its authoritative Field Archive theme and Standard
mode after capture. Android text scale and rotation settings were restored to
their pre-capture values (`font_scale=1.0`, automatic rotation, user rotation
0). Temporary device-side capture files were removed.

## Calendar physical recapture

The identity-clean Calendar PNG was paired with its live UI hierarchy. The
hierarchy root is `[0,0][2960,1848]`, date controls for Sunday through Saturday
are present, and the complete `ACCEPTANCE FAMILY MEDICINE` progress heading is
present.

- `calendar-field-archive-standard-2960x1848.png` (SHA-256
  `8761d82f7371a1414fe829266dfe5ddb7136ef9b6ab5044268d3e66d48a2e391`)
- `calendar-field-archive-standard-2960x1848.xml` (SHA-256
  `8a2e9060d6b5bf621bf682b84bb23a4be19b92679914a07658f838307b36e277`)

## Settings and Gallery

The physical Settings capture enters Settings from the application menu and
proves that the affected Back navigation remains complete
and that the selected values `Sunday`, `Military time`, and `Enabled` are
fully visible. The same original-resolution frame shows the production Theme
Gallery thumbnail with a complete Sunday-through-Saturday Calendar shell.

- `settings-gallery-field-archive-standard-2960x1848.png` (SHA-256
  `35bc626733f0c04651741dccdfdf2d09da254a9f0d40e917a9f0c567159adda5`)
- `settings-gallery-field-archive-standard-2960x1848.xml` (SHA-256
  `20ea76f04e01c5e07c8faf26acbcaaffdb9bbb50a7d6641b73d5c61c4a7c4324`)

Both committed PNG/XML pairs were scanned before commit and contain no name,
email-address, credential, or device-serial patterns. The schedule content is
the fictional acceptance fixture already present on the supported tablet.

## Automated fourteen-state matrix

The all-theme requirement is covered by production widget tests at the SM-X920
logical viewport and 200% text scale: seven catalog themes multiplied by
Standard and Enhanced modes. Calendar coverage lives in
`issue_156_tablet_accessibility_golden_test.dart`; Settings navigation and
complete values live in `support_surfaces_test.dart`; and the seven-day product
Gallery shell lives in `theme_gallery_test.dart`.

The physical captures above are the retained representative device evidence;
they do not claim to replace the reproducible fourteen-state widget matrix.
The presentation package completed 405 tests, and the repository quality gate
and Android release contract passed for the candidate.
