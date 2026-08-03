# Cross-Platform Application Architecture

Researched: 2026-08-02

## Decision

Build the Clinical Calendar as a **Flutter application written in Dart**, with one shared product codebase targeting Windows, iOS, and Android. Store operational data locally in SQLite behind a repository interface, and treat synchronization as a separate adapter whose provider can be selected later.

Flutter is a better fit than Python for this product. It officially supports all three target platforms, has explicit guidance for adaptive interfaces and offline-first data flow, and documents credible private-test and public-release paths for every target. Python remains suitable for supporting scripts or data migration tools, but should not be the application runtime.

The strongest alternative is **.NET MAUI**. Choose it instead only if sustained C#/.NET expertise or a strongly Windows-centric native-control experience outweighs the advantages of Flutter for a custom, touch-friendly calendar interface.

## Product constraints that drive the decision

- One Student must be able to use the same application on Windows, iPhone, and an Android tablet.
- Calendar interaction must work well with mouse/keyboard and touch, and layouts must adapt from a phone to a tablet or desktop.
- The application must remain usable offline and persist all schedule and Clinical Placement data locally.
- The first release needs practical private installation on the Student's devices; later releases need credible store distribution.
- The architecture should keep one set of domain rules for Schedule Conflicts, Protected Days, Completed Hours, and Review Milestones.

"One codebase" does not mean one source file. Every credible choice should be a structured, multi-file project with shared domain, persistence, presentation, and platform-integration modules.

## Comparison

| Stack | Target coverage | GUI fit | Offline storage | Packaging and distribution | Assessment |
| --- | --- | --- | --- | --- | --- |
| Flutter / Dart | Windows, iOS, and Android are officially supported deployment targets | High-quality custom UI plus documented platform adaptations; well suited to responsive calendar layouts | Official architecture guidance covers offline-first repositories and SQL-backed local data | Documented Android APK/AAB, iOS/TestFlight/App Store, and Windows/MSIX or zip paths | **Recommended** |
| .NET MAUI / C# | Single shared project for Windows, iOS, and Android | Native cross-platform controls and strong Windows integration | Microsoft documents local SQLite use from shared code | Documented Windows MSIX/unpackaged, Android APK/AAB, and provisioned iOS release paths | **Strong runner-up** |
| BeeWare Toga + Briefcase / Python | All three targets are represented | Uses native system widgets, but Windows currently uses WinForms and the component matrix is narrower than mature mobile stacks | Python SQLite is plausible, but mobile binary dependencies require target wheels | MSI, Xcode, and Gradle projects exist; mobile dependency availability and publishing add risk | **Best Python fallback; require a packaging spike** |
| Kivy / Python | Claims write-once support across Windows, iOS, and Android | Custom Kivy widgets give consistency, not a platform-native calendar experience | Local persistence is possible | Separate PyInstaller, Buildozer/python-for-Android, and Xcode/Homebrew workflows create more release work | **Technically viable, not preferred** |
| Qt/PySide6 / Python | Excellent desktop support; Android tooling exists; the Qt C++ framework supports iOS | Strong desktop UI, but the Python mobile path is the problem | Local SQLite is mature in Qt | Official Qt-for-Python guidance says mobile deployment requires advanced processes; Android tooling is host-constrained and there is no comparable documented PySide iOS path | **Reject for the three-target product** |
| React Native / TypeScript | Core mobile plus a separate Microsoft Windows extension | Native-rendered UI and a broad mobile model | Local storage is available through platform/community modules | Windows adds a distinct project/extension and module-compatibility surface | **Viable for an existing React team, but not the simplest fit** |

## Evidence

### Flutter

Flutter's current supported-platform table explicitly lists Android, iOS, and Windows as supported deployment targets. This is first-class framework coverage rather than a community port ([Flutter supported deployment platforms](https://docs.flutter.dev/reference/supported-platforms)).

Flutter provides documented adaptive behavior for navigation, scrolling, typography, icons, haptics, and text editing, while explaining where product-level platform adaptations remain an intentional design choice. It also supplies Material and high-fidelity Cupertino widget libraries ([automatic platform adaptations](https://docs.flutter.dev/ui/adaptive-responsive/platform-adaptations), [Cupertino widgets](https://docs.flutter.dev/ui/widgets/cupertino)). A shared design system can therefore remain consistent while respecting iOS, Android, tablet, and desktop interaction conventions.

The official architecture guidance describes offline-first repositories that coordinate local database and remote services. Its SQL persistence example combines mobile and desktop SQLite implementations behind one database service, including Windows initialization through FFI ([offline-first support](https://docs.flutter.dev/app-architecture/design-patterns/offline-first), [persistent SQL storage architecture](https://docs.flutter.dev/app-architecture/design-patterns/sql)). The exact SQLite package should be confirmed in the implementation spike, but the domain and repository APIs should not depend on it.

Flutter documents release artifacts for all targets: signed APK or AAB files for Android, Xcode/App Store distribution for iOS, and MSIX, Microsoft Store, self-hosted installer, or zip distribution on Windows ([Android deployment](https://docs.flutter.dev/deployment/android), [iOS deployment](https://docs.flutter.dev/deployment/ios), [Windows distribution](https://docs.flutter.dev/platform-integration/windows/building)).

Tradeoffs:

- Dart must be learned and maintained instead of Python.
- Flutter renders its own widget system; native-feeling behavior requires deliberate adaptive design and testing rather than assuming every control is an OEM widget.
- A macOS machine with Xcode is required to build and release iOS. This is an Apple toolchain constraint, not a Flutter-specific defect ([Flutter iOS deployment](https://docs.flutter.dev/deployment/ios)).

### .NET MAUI

Microsoft describes .NET MAUI as a C#/XAML framework for native Android, iOS, macOS, and Windows applications from a single shared codebase and single project ([What is .NET MAUI?](https://learn.microsoft.com/en-us/dotnet/maui/what-is-maui?view=net-maui-10.0), [single-project model](https://learn.microsoft.com/en-us/dotnet/maui/fundamentals/single-project?view=net-maui-10.0)). Microsoft also provides a local SQLite pattern that stores data from shared application code ([.NET MAUI local databases](https://learn.microsoft.com/en-us/dotnet/maui/data-cloud/database-sqlite?view=net-maui-10.0)).

Its deployment story is credible: Windows can be published as MSIX or unpackaged output; Android uses APK for installation and AAB for store release; iOS uses a provisioned IPA ([Windows deployment](https://learn.microsoft.com/en-us/dotnet/maui/windows/deployment/overview?view=net-maui-10.0), [.NET MAUI deployment overview](https://learn.microsoft.com/en-us/dotnet/maui/deployment/?view=net-maui-9.0)). A networked Mac is required for iOS development from Windows ([supported platforms](https://learn.microsoft.com/en-us/dotnet/maui/supported-platforms?view=net-maui-10.0)).

.NET MAUI is a sound choice, particularly for a team already fluent in C# and XAML. For this greenfield, custom calendar application, Flutter's single cross-platform rendering and adaptive layout guidance give it the edge. This conclusion is a product-fit judgment, not a claim that MAUI lacks the required capabilities.

### Python options

#### BeeWare Toga and Briefcase

Toga is the most coherent Python candidate because its supported-platform list includes Windows, Android, and iOS and its design deliberately uses native system widgets rather than visual themes ([Toga supported platforms](https://toga.beeware.org/en/latest/reference/platforms/index.html), [Toga design philosophy](https://toga.beeware.org/en/stable/about/philosophy.html)). Briefcase can produce Windows MSI installers, Android Gradle projects, and iOS Xcode projects ([Briefcase platform support](https://briefcase.beeware.org/en/stable/reference/platforms/index.html), [Briefcase FAQ](https://briefcase.beeware.org/en/stable/about/faq/)).

The risks are material. Toga's Windows backend currently uses WinForms, while WinUI is listed as a future goal ([Toga Windows backend](https://toga.beeware.org/en/stable/reference/platforms/windows.html), [Toga supported platforms](https://toga.beeware.org/en/latest/reference/platforms/index.html)). Briefcase also documents that Android packages containing binary components need Android-specific wheels and that its secondary wheel repository does not contain every package or version ([Briefcase Android Gradle project](https://briefcase.beeware.org/en/stable/reference/platforms/android/gradle/)). That makes dependency selection and packaging more fragile than in Flutter or MAUI.

If Python becomes mandatory, use Toga/Briefcase only after a time-boxed proof builds, installs, and exercises a calendar screen plus SQLite on an actual Windows PC, iPhone, and Android tablet.

#### Kivy

Kivy officially states that one application can run on Windows, iPhone/iPad, and Android tablets/phones ([Kivy introduction](https://kivy.org/doc/stable/gettingstarted/intro.html)). It also documents packaging for each target ([packaging overview](https://kivy.org/doc/stable/guide/packaging.html)).

However, Android packaging uses Buildozer or python-for-Android, Windows packaging uses PyInstaller, and iOS requires macOS, Xcode, Homebrew, and provisioning ([Android packaging](https://kivy.org/doc/stable/guide/packaging-android.html), [Windows packaging](https://kivy.org/doc/stable/guide/packaging-windows.html), [iOS prerequisites](https://kivy.org/doc/stable/guide/packaging-ios-prerequisites.html)). Kivy's custom widget approach is useful for highly bespoke touch interfaces, but it places more responsibility on this project to achieve polished iOS, Android, and Windows calendar behavior. It is not the best default for a productivity application intended for later general distribution.

#### Qt/PySide6

PySide6 is Qt's official Python binding and is excellent for Windows desktop applications ([Qt for Python](https://doc.qt.io/qtforpython-6/)). The issue is the mobile delivery path. Qt for Python's distribution FAQ says Python cannot deploy directly to Android or iOS and requires advanced processes; its main deployment tooling targets Windows, Linux, and macOS ([Qt for Python distribution FAQ](https://doc.qt.io/qtforpython-6/faq/distribution.html), [deployment overview](https://doc.qt.io/qtforpython-6.8/deployment/index.html)). The Android helper currently runs only on Linux or macOS and may require cross-compiling wheels ([PySide6 Android deployment](https://doc.qt.io/qtforpython-6/deployment/deployment-pyside6-android-deploy.html)). Although the underlying C++ Qt framework supports iOS, that does not establish an equally supported PySide6 iOS packaging workflow. PySide6 therefore fails the reliable single-codebase distribution criterion.

### React Native

React Native remains credible for Android and iOS, but Windows support is supplied through Microsoft's separate `react-native-windows` extension and Windows project initialization ([React Native Windows](https://microsoft.github.io/react-native-windows/), [Windows setup](https://microsoft.github.io/react-native-windows/docs/getting-started/)). Microsoft documents remaining New Architecture feature-parity and native-library gaps, so dependency selection must be validated for Windows ([React Native Windows architecture](https://microsoft.github.io/react-native-windows/docs/new-architecture/)). This adds maintenance surface that Flutter and MAUI avoid for the exact three-platform target.

## Recommended architecture boundary

Use one Flutter workspace with these logical layers:

1. **Domain:** platform-independent rules and value objects for Clinical Placements, Preceptors, calendar commitments, Protected Days, hour calculations, and Review Milestones.
2. **Application:** use cases such as scheduling, conflict validation, completing a Clinical Session, and calculating progress.
3. **Local data:** SQLite as the on-device source of truth, with migrations and transactions. The UI must never require network access to read or edit the schedule.
4. **Sync:** an interface over an outbound change log and inbound merge process. Google Drive or a managed backend can be selected without replacing the local data layer.
5. **Presentation:** shared responsive Flutter widgets with narrow-phone, tablet, and desktop layouts plus platform-adaptive interactions.
6. **Platform adapters:** notifications, file export/import, secure credentials, and platform packaging kept outside the domain.

This boundary preserves one implementation of the safety-critical scheduling rules while allowing small, explicit platform differences.

## Installation implications

- **Windows MVP:** signed installer is ideal; a zip build can support early local testing. Public/self-hosted MSIX requires appropriate signing, while Microsoft Store distribution can manage store signing.
- **Android MVP:** a signed APK can be installed privately; an AAB is the normal Google Play artifact.
- **iPhone MVP:** there is no equally frictionless permanent sideload path. Development/ad hoc installation requires device registration and provisioning; TestFlight or the App Store is the practical distribution path for other people. Apple documents registered-device limits for ad hoc distribution ([Apple devices overview](https://developer.apple.com/help/account/devices/devices-overview)).
- **Build infrastructure:** retain Windows development for Windows/Android, but plan access to a Mac/Xcode locally or in CI before promising an iPhone build.

## Validation gate before full implementation

Create a thin vertical slice before building the full product:

- render one responsive week view on Windows, iPhone, and Android tablet;
- create a Clinical Session in military time;
- persist it to local SQLite, restart offline, and verify it remains;
- reject a Schedule Conflict and a Protected Day;
- produce and install a Windows build, Android APK, and provisioned iPhone build.

Proceed with Flutter only after that slice passes on physical target devices. If it fails for a framework-specific reason, reassess .NET MAUI first and BeeWare/Toga only if Python has become a hard requirement.
