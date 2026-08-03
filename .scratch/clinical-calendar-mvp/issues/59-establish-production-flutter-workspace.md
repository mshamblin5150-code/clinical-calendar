# Establish the Production Flutter Workspace

Type: task
Status: open
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

