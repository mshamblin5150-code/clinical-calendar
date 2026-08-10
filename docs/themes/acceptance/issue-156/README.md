# Issue #156 physical Android-tablet acceptance

Issue: [#156](https://github.com/mshamblin5150-code/clinical-calendar/issues/156)

Physical acceptance passed on 2026-08-10 for commit
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

## Calendar matrix

Every PNG below was paired with a live UI hierarchy. The capture driver failed
closed unless the hierarchy root was `[0,0][2960,1848]`, the menu/scrim was
closed, date controls for Sunday through Saturday were all present, and the
complete `ACCEPTANCE FAMILY MEDICINE` progress heading was present.

| Theme | Mode | PNG SHA-256 |
| --- | --- | --- |
| Containment Drone 47-Alpha | Standard | `ad8306acd5a46c83c2ec3a57e8e641666212ae61781419681319af0990d23589` |
| Containment Drone 47-Alpha | Enhanced | `dba8bd9a6f3cbdf49834f556729a2bd47987a9654e21dad51fe62c017ff43e74` |
| Graphite | Standard | `f4cc54ba05ec33abe5730d6dee4b06a038990d0986fb7e7697370b22d93f40fc` |
| Graphite | Enhanced | `f2534e0fdd8a22e0b5346d872e436646a620b5648f792632c3c913a0b0f372c8` |
| Federation Classic | Standard | `18492f0c902312d6506fceb30ea1f59e03bcd052952e05c1c5f7348f20344e39` |
| Federation Classic | Enhanced | `15bcb1cf7f7bb9d6d22071f3c336d09382ae54b767d963704ea9c95b6d747a66` |
| Federation 2399 | Standard | `6871376de1f25b1341c042556b72ca5fae8a661aa6939565eda97b3bea260529` |
| Federation 2399 | Enhanced | `94db15d9179cb72b6a868314758235e06e26066bbad201bbbd8a6f144dbd892a` |
| Coastal Light | Standard | `94fe65b86987082a3f099232ffd18c10ef4b046cd2a5d7b8ecbbbae7a8d28423` |
| Coastal Light | Enhanced | `532ef84367f6b286284ba05715e44cabcf001d829b5e79636d3062ed2f695bf2` |
| Botanical Study | Standard | `e5fccf9143be99d7656c53020a912f7326fdbc42a58c5ba738458391225278ff` |
| Botanical Study | Enhanced | `558da2159c05398fd4d67e353c29d31c1157da4c6775e34dac42c83fcd3d66d5` |
| Field Archive | Standard | `8761d82f7371a1414fe829266dfe5ddb7136ef9b6ab5044268d3e66d48a2e391` |
| Field Archive | Enhanced | `d7328dcab444a01fbb03da32edf66459fb6db10bbacbde9f053effe90f23178e` |

The identity-clean representative Calendar pair is committed as:

- `calendar-field-archive-standard-2960x1848.png` (SHA-256
  `8761d82f7371a1414fe829266dfe5ddb7136ef9b6ab5044268d3e66d48a2e391`)
- `calendar-field-archive-standard-2960x1848.xml` (SHA-256
  `8a2e9060d6b5bf621bf682b84bb23a4be19b92679914a07658f838307b36e277`)

## Settings and Gallery

The physical Settings capture proves that Close navigation remains complete
and that the selected values `Sunday`, `Military time`, and `Enabled` are
fully visible. The same original-resolution frame shows the production Theme
Gallery thumbnail with a complete Sunday-through-Saturday Calendar shell.

- `settings-gallery-field-archive-standard-2960x1848.png` (SHA-256
  `8f84f6e4cbd645dd72ea6f49c6378da774ed1fc7986f01d18c2b24d894e75448`)
- `settings-gallery-field-archive-standard-2960x1848.xml` (SHA-256
  `220ad0e0ee20d5b76e3c2834658b8f227e0a76f0e6cc8f242c2687c6c1bc6351`)

Both committed PNG/XML pairs were scanned before commit and contain no name,
email-address, credential, or device-serial patterns. The schedule content is
the fictional acceptance fixture already present on the supported tablet.

## Automated corroboration

The physical result is backed by the production Calendar and Settings matrix
in `tablet_200_percent_text_scale_test.dart`: seven catalog themes multiplied
by Standard and Enhanced modes at the SM-X920 logical viewport and 200% text
scale. The presentation package completed 405 tests, and the repository
quality gate and Android release contract passed for the candidate.
