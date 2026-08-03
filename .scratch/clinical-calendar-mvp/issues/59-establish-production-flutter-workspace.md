# Establish the Production Flutter Workspace

Type: task
Status: resolved
Blocked by: 58

## Objective

Turn the successful vertical slice into the production workspace with enforceable domain, application, local-data, synchronization, presentation, and platform-adapter boundaries from [`spec.md`](../spec.md#81-application-stack-and-boundaries).

## Acceptance criteria

- The workspace builds for Windows, iOS, and Android without prototype data or React dependencies.
- Package boundaries prevent presentation and platform code from becoming dependencies of domain code.
- Dependency injection exposes repositories, clocks, identifiers, synchronization, notifications, secure storage, and file services through interfaces.
- Unit, widget, integration, and platform-test locations and commands are documented.
- Static analysis, formatting, and the baseline test suite run through one repeatable local command and CI job.
- Environment-specific configuration contains no privileged server credential in source or application artifacts.

## Comments

- Claimed on 2026-08-03 after ticket 58 approved Flutter for continued MVP
  implementation with the physical iPhone leg explicitly deferred to tickets
  87 and 88 pending hardware.

## Answer

Created a native Dart workspace with a Flutter composition root at
`apps/clinical_calendar` and six separately resolved packages for domain,
application, local data, synchronization, presentation, and platform adapters.
Pubspec dependencies and an architecture test enforce inward-only direction:
domain is dependency-free, application depends only on domain, and the app is
the sole production composition root.

`ApplicationDependencies` requires interface implementations for repositories,
clock, identifier generation, synchronization, notifications, secure storage,
and file services. Deferred outer adapters are explicit and fail closed where
use would be unsafe; later implementation tickets replace them without service
location or business rules in widgets.

The root `dart run tool/quality.dart` command enforces production-source policy,
stable formatting, fatal-info analysis for all seven members, and the complete
unit/widget/boundary baseline. It passes with nine tests. GitHub Actions runs
the same command. Test locations, device/native commands, configuration, and
credential rules are documented in `README.md` and `docs/architecture.md`.

Windows release and Android ARM64 release builds pass. The production Android
app installed and cold-launched on the physical Samsung SM-X920 in 225 ms with
an empty crash buffer. The generated iOS workspace, schemes, bundle targets,
and shared package graph are present, but compilation remains explicitly
unverified under the owner-approved Mac/iPhone hardware deferment. Ticket 87
must perform the missing Xcode/signing/device evidence; this answer does not
claim an iOS pass. Production scans found no React/Node dependency or privileged
credential pattern, and Android application backup is disabled.
