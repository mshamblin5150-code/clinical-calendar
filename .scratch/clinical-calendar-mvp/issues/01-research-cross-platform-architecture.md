# Research the Cross-Platform Application Architecture

Type: research
Status: resolved
Blocked by: none

## Question

Which currently supported application stack best fits one maintainable codebase targeting Windows, iPhone, and Android tablet, with offline local storage, native-feeling GUI behavior, reliable packaging, and a credible later distribution path? Compare realistic Python options with stronger non-Python alternatives rather than assuming Python is the best fit.

## Comments

## Answer

Use **Flutter/Dart** for the application, with SQLite as the offline on-device source of truth behind a repository interface and synchronization isolated behind a separate adapter. Flutter has first-class current support for Windows, iOS, and Android, documented adaptive UI and offline-first patterns, and credible private-testing and store-release paths. Use **.NET MAUI** as the fallback if C#/.NET expertise becomes decisive.

Python is not the best product runtime for this target set. BeeWare/Toga with Briefcase is the most coherent Python fallback, but mobile binary-wheel availability and less mature publishing/tooling make it riskier; it should only be selected after an all-device packaging proof. Kivy adds more platform-polish and packaging work, while PySide6 lacks a comparably supported iOS Python deployment path.

Full evidence, source links, tradeoffs, architecture boundaries, and the pre-implementation validation gate are recorded in [Cross-Platform Application Architecture](../research/01-cross-platform-architecture.md).
