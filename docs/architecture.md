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

## Configuration and secrets

`AppEnvironment` accepts only an environment label and public synchronization
base URL through `CLINICAL_CALENDAR_ENVIRONMENT` and
`CLINICAL_CALENDAR_SYNC_BASE_URL`. Service-role keys, signing credentials,
database encryption keys, and recovery secrets are prohibited from source and
application configuration. Platform credential stores and CI secret stores own
them when their implementation tickets begin.
