# Clinical Calendar

Offline-first clinical scheduling and training-progress software for Windows,
Android tablet, and iPhone from one Flutter/Dart codebase. Product behavior is
governed by [the MVP specification](.scratch/clinical-calendar-mvp/spec.md).

## Production workspace

- `apps/clinical_calendar`: Flutter composition root and platform runners.
- `packages/clinical_calendar_domain`: dependency-free business rules.
- `packages/clinical_calendar_application`: use cases and side-effect ports.
- `packages/clinical_calendar_local_data`: encrypted local-data adapters.
- `packages/clinical_calendar_sync`: replaceable synchronization adapters.
- `packages/clinical_calendar_presentation`: responsive Variant F widgets.
- `packages/clinical_calendar_platform`: native capability adapters.

The interactive React prototype remains under `.scratch` as a product/design
reference; it is not a production dependency.

## Bootstrap and quality

```text
flutter pub get
dart run tool/quality.dart
```

The shared quality command formats production Dart, analyzes every package, and
runs all unit and widget tests. CI invokes the same command.

Build the composition app from `apps/clinical_calendar`:

```text
flutter build windows --release
flutter build apk --release --split-per-abi
flutter build ios --no-codesign
```

The iOS command requires macOS and Xcode. No privileged server credential may
be supplied through Dart defines, source files, or application artifacts.

See [the architecture guide](docs/architecture.md) for dependency direction,
test locations, configuration, and platform-test commands.
