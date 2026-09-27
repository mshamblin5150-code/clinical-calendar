# Production architecture

Clinical Calendar uses inward-only dependencies:

```text
domain <- application <- local_data / sync / platform / presentation
                                           \       |       /
                                            composition app
```

The domain package is pure Dart and has no workspace dependency. Application
depends only on domain and owns interfaces for repositories, clocks,
identifiers, synchronization, notifications, secure storage, and files. Outer
packages implement those interfaces. Only `apps/clinical_calendar` constructs
`ApplicationDependencies`; business rules never locate services globally.

Ticket 59 intentionally supplies deferred, fail-closed adapters rather than
mock production storage. Tickets 60-66 replace them with domain types,
invariants, SQLCipher migrations, repositories, and the transactional outbox.

## Tests

| Scope | Location | Command |
| --- | --- | --- |
| Domain/application unit | `packages/*/test` | `dart test` in the package |
| Presentation/platform widget | Flutter package `test` directories | `flutter test` in the package |
| Composition and boundary | `apps/clinical_calendar/test` | `flutter test` |
| Device integration | `apps/clinical_calendar/integration_test` | `flutter test integration_test -d <device>` |
| Native platform | platform runner test targets as adapters arrive | Xcode, Gradle, or Visual Studio platform test command |

Run the complete baseline with `dart run tool/quality.dart`. Device integration
and native platform suites remain explicit because CI may not have target
hardware.

## Synchronized record compatibility

Every synchronization RPC carries the client build number. The server refuses
pushes below `clinical_calendar_sync.sync_configuration.minimum_sync_build`
with `minimum_sync_build_required`, while pull remains available. A refused
push stays in the encrypted native outbox until the Student updates the app.

Any change to the shape of a synchronized record must raise the minimum sync
build in the same migration or configuration change. The application build
number and `CLINICAL_CALENDAR_BUILD_NUMBER` used for web builds must be at
least that new minimum before the migration is deployed.

## Configuration and secrets

`AppEnvironment` accepts only an environment label and public synchronization
base URL through `CLINICAL_CALENDAR_ENVIRONMENT` and
`CLINICAL_CALENDAR_SYNC_BASE_URL`. Service-role keys, signing credentials,
database encryption keys, and recovery secrets are prohibited from source and
application configuration. Platform credential stores and CI secret stores own
them when their implementation tickets begin.
