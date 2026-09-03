# NetGuard 🛡️

NetGuard is a high-performance, privacy-focused network firewall, application traffic blocker, and local DNS filtering solution developed with **Flutter** and native **Android (Kotlin)**. 

NetGuard operates entirely **on-device without requiring root permissions**. By utilizing Android's local `VpnService` sinkhole and packet-processing architecture, network traffic is evaluated locally—ensuring that no user data, browsing history, or packet metrics ever leave the device.

---

## 📑 Table of Contents

- [Architectural Principles](#-architectural-principles)
- [Key Features](#-key-features)
  - [1. Application Blocker & Traffic Sinkhole](#1-application-blocker--traffic-sinkhole)
  - [2. Local DNS Interception & Domain Filtering](#2-local-dns-interception--domain-filtering)
  - [3. Custom DNS Resolvers (System Controls)](#3-custom-dns-resolvers-system-controls)
  - [4. Time-Based Scheduling Engine](#4-time-based-scheduling-engine)
  - [5. Application Usage & Network Analytics](#5-application-usage--network-analytics)
  - [6. Master Passcode & Biometric Security](#6-master-passcode--biometric-security)
  - [7. Dark Cyber-Security UI & Access Control Hub](#7-dark-cyber-security-ui--access-control-hub)
- [Android Permissions & Native Integrations](#-android-permissions--native-integrations)
  - [Permissions Breakdown](#permissions-breakdown)
  - [Native Platform Channels](#native-platform-channels)
- [Project Directory Structure](#-project-directory-structure)
- [Design Patterns & Technologies](#-design-patterns--technologies)
  - [Clean Architecture & SOLID](#clean-architecture--solid)
  - [State Management (BLoC)](#state-management-bloc)
  - [Dependency Injection (GetIt)](#dependency-injection-getit)
  - [Functional Error Handling (Dartz)](#functional-error-handling-dartz)
- [Dependencies](#-dependencies)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation & Execution](#installation--execution)
  - [Running Unit & Widget Tests](#running-unit--widget-tests)
- [License](#-license)

---

## 🏛 Architectural Principles

NetGuard strictly adheres to **Clean Architecture** and **SOLID** engineering principles, dividing concerns into distinct layers:

```
┌─────────────────────────────────────────────────────────┐
│                   Presentation Layer                    │
│      (UI Pages, Custom Widgets, BLoC State & Events)    │
└────────────────────────────┬────────────────────────────┘
                             │ calls
                             ▼
┌─────────────────────────────────────────────────────────┐
│                      Domain Layer                       │
│    (Business Entities, Use Cases, Repository Contracts) │
└────────────────────────────▲────────────────────────────┘
                             │ implements
┌────────────────────────────┴────────────────────────────┐
│                       Data Layer                        │
│   (Repository Impls, Local & Native Data Sources, DTOs) │
└────────────────────────────┬────────────────────────────┘
                             │ interacts with
                             ▼
┌─────────────────────────────────────────────────────────┐
│             Hardware & Platform Subsystems              │
│    (VpnService, UsageStats, Keystore, SharedPreferences)│
└─────────────────────────────────────────────────────────┘
```

1. **Domain Layer (Core Business Rules)**:
   - Contains pure Dart Entities and Use Cases.
   - Completely independent of Flutter, UI frameworks, or platform drivers.
   - Defines abstract Repository interfaces (`AppBlockerRepository`, `DomainFilterRepository`, `ScheduleRepository`, `AnalyticsRepository`, `SecurityRepository`, `SystemControlsRepository`).

2. **Data Layer (Data Operations & Adapters)**:
   - Implements domain repository interfaces.
   - Coordinates between local disk caches (`SharedPreferences`, `FlutterSecureStorage`) and native operating system services (`MethodChannel`).
   - Uses gateways (`InstalledAppsGateway`, `NativeAppDataSource`) to abstract third-party and OS interactions.

3. **Presentation Layer (User Interface & Reactive State)**:
   - Utilizes the **BLoC (Business Logic Component)** pattern for predictable, unidirectional data flows.
   - UI widgets consume immutable states and dispatch explicit user events.
   - Highly decoupled, reusable atomic components designed for consistency and unit testability.

4. **Dependency Inversion & Injection**:
   - All layers and dependencies are registered and wired via a centralized Service Locator using `GetIt` (`lib/core/di/injection_container.dart`).

5. **Type-Safe Functional Error Handling**:
   - Operations return `Either<Failure, T>` from the `dartz` package, avoiding uncaught runtime exceptions and forcing explicit error-state management across the presentation layer.

---

## 🚀 Key Features

### 1. Application Blocker & Traffic Sinkhole
- **Zero-Root Local Firewall**: Establishes a local TUN loopback interface using Android `VpnService`.
- **Selective App Routing**: Restricts traffic by allowing or blocking specific package IDs at the OS routing table level.
- **Real-Time App Discovery**: Reads all user and system packages installed on the device with search, filtering, and instant toggle capabilities.
- **Immediate State Synchronization**: Updates the active VPN interface dynamically without dropping existing connection states.

### 2. Local DNS Interception & Domain Filtering
- **In-Memory Packet Inspection**: Listens on local UDP port `53` (`10.120.0.53`) to inspect DNS queries on-the-fly.
- **Instant NXDOMAIN Synthesis**: When a query matches an active blacklisted pattern, NetGuard synthesizes an immediate `NXDOMAIN` (non-existent domain) response, dropping tracking/ad telemetry at zero network cost.
- **Wildcard Pattern Support**: Supports exact (`ads.example.com`) and wildcard domain patterns (`*.tracking.com`).
- **Loopback Protection**: NetGuard itself is excluded from the VPN interface (`addDisallowedApplication`), ensuring that permitted DNS queries are securely forwarded to upstream resolvers without packet loops.

### 3. Custom DNS Resolvers (System Controls)
- **Resolver Presets**: Switch instantly between trusted upstream DNS providers:
  - **Cloudflare DNS** (`1.1.1.1`)
  - **Google Public DNS** (`8.8.8.8`)
  - **AdGuard Default DNS** (`94.140.14.14`)
  - **Quad9 Secure DNS** (`9.9.9.9`)
- **Custom IP Resolvers**: Specify custom IPv4 DNS resolver endpoints.
- **Live Upstream Routing**: Changes upstream resolvers immediately on the native background service.

### 4. Time-Based Scheduling Engine
- **Automated Restrictive Profiles**: Set targeted blocking schedules (e.g., Focus Time, Bedtime, Work Hours).
- **Granular Days & Time Windows**: Configure repeat days of the week (Monday through Sunday) along with start and end times.
- **Targeted Application Lists**: Attach custom subsets of installed apps to individual schedules.
- **Rule Toggles**: Enable or disable schedules independently.

### 5. Application Usage & Network Analytics
- **Screen Time Telemetry**: Gathers foreground screen time using Android's `UsageStatsManager`.
- **Bandwidth Consumption Tracking**: Tracks data transfer metrics broken down by **Wi-Fi** and **Mobile Data (Cellular)** per application via `NetworkStatsManager`.
- **Multi-Period Aggregation**: View usage trends across **Day**, **Week**, and **Month** horizons.
- **Visualized Activity**: Interactive weekly bar charts highlighting usage spikes and top consuming applications.

### 6. Master Passcode & Biometric Security
- **App Lock & Rule Protection**: Lock critical settings and shield controls behind authentication to prevent unauthorized tampering.
- **Hardware-Backed Keystore Storage**: Master PIN/passcode stored securely using AES encryption backed by the Android Keystore (`FlutterSecureStorage`).
- **Biometric Integration**: Instant authentication via fingerprint or facial recognition using `LocalAuthentication`.

### 7. Dark Cyber-Security UI & Access Control Hub
- **Purpose-Built Visual Identity**: Clean, dark cyberpunk aesthetic designed for high contrast and security-first visibility.
- **Real-Time Security Dashboard**: Displays live connection status, active shields, total blocked apps, and filtered domains.
- **Quick Action Trays**: Fast-access bottom sheets for switching rules, blocking all apps, and launching diagnostic tools.

---

## 🔒 Android Permissions & Native Integrations

### Permissions Breakdown

The application requests the following permissions in `android/app/src/main/AndroidManifest.xml`:

| Permission | Category | Purpose |
| :--- | :--- | :--- |
| `android.permission.BIND_VPN_SERVICE` | System / Signature | Required to bind `AppBlockerVpnService` and establish the local virtual network interface (TUN) to intercept and route network traffic. |
| `android.permission.QUERY_ALL_PACKAGES` | System / Special | Required on Android 11+ (API 30+) to discover and list all user and system packages installed on the device for access control. |
| `android.permission.FOREGROUND_SERVICE` | Normal | Allows the VPN background worker to operate persistently without being killed by the Android OS task manager. |
| `android.permission.FOREGROUND_SERVICE_SPECIAL_USE` | Normal (Android 14+) | Declares the specific background service type for Android 14 (API 34+) compatibility for local VPN sinkholing. |
| `android.permission.POST_NOTIFICATIONS` | Runtime (Android 13+) | Displays ongoing, persistent foreground notifications showing the number of actively blocked apps and filtered domains. |
| `android.permission.PACKAGE_USAGE_STATS` | Protected / Special Access | Grants access to `UsageStatsManager` and `NetworkStatsManager` to read per-app screen time and network traffic consumption. Must be granted in Android Settings. |
| `android.permission.READ_PHONE_STATE` | Normal | Allows the app to monitor telephony and mobile connectivity states for mobile data usage calculation. |
| `android.permission.USE_BIOMETRIC` | Normal | Prompts user for biometric authentication (Fingerprint, Face Unlock) to guard security settings. |
| `android.permission.USE_FINGERPRINT` | Normal (Legacy) | Legacy support for fingerprint hardware on older Android versions. |

### Native Platform Channels

Communication between Flutter and the Android native host is established through custom `MethodChannel` bridges:

1. **Traffic Channel (`com.app.net_guard/traffic` & fallback `com.example.blocker/traffic`)**:
   - `startVpnService(blockedPackages)`: Prompts VPN consent dialog and boots `AppBlockerVpnService`.
   - `stopVpnService`: Halts the VPN service and tears down the TUN interface.
   - `updateBlockedList(blockedPackages)`: Updates the list of blocked application packages in real-time.
   - `toggleBlockStatus(packageName, isBlocked)`: Toggles firewall rule for a single application.

2. **DNS Filter Channel (`com.app.net_guard/dns_filter`)**:
   - `updateDnsBlacklist(domains)`: Sends updated domain blacklists to the packet parser.
   - `setCustomDnsResolver(dnsServer)`: Changes the upstream DNS forwarding resolver IP address.

3. **Analytics Channel (`com.app.net_guard/analytics` & fallback `com.example.blocker/analytics`)**:
   - `checkUsagePermission`: Verifies if `PACKAGE_USAGE_STATS` is granted via `AppOpsManager`.
   - `requestUsagePermission`: Launches `Settings.ACTION_USAGE_ACCESS_SETTINGS` intent for user consent.
   - `getAppUsageAnalytics(timeRange)`: Collects screen time, Wi-Fi bytes, and mobile data bytes per UID.

---

## 📂 Project Directory Structure

```text
net_guard/
├── android/                                 # Native Android implementation
│   └── app/src/main/
│       ├── AndroidManifest.xml              # Permissions, VPN service & query configurations
│       └── kotlin/com/app/net_guard/
│           ├── MainActivity.kt              # Flutter activity & MethodChannel handlers
│           └── AppBlockerVpnService.kt      # Local VPN sinkhole, raw TUN processor & DNS engine
├── lib/
│   ├── main.dart                            # Application entrypoint & MultiBlocProvider setup
│   ├── core/                                # Shared infrastructure & utilities
│   │   ├── di/
│   │   │   └── injection_container.dart     # Service locator (GetIt) dependency graph
│   │   ├── error/
│   │   │   └── failure.dart                 # Unified Failure classes (Server, Cache, Platform)
│   │   ├── theme/
│   │   │   ├── app_colors.dart              # Theme palette (Emerald, Cyberpunk Cyan, Carbon Dark)
│   │   │   ├── app_text_styles.dart         # Typography styles
│   │   │   └── app_theme.dart               # Dark ThemeData definitions
│   │   └── usecase/
│   │       └── usecase.dart                 # Base generic UseCase<Type, Params> contract
│   └── features/                            # Modular feature implementations
│       ├── analytics/                       # Screen time & data usage telemetry
│       │   ├── data/
│       │   │   ├── datasources/             # AnalyticsNativeDataSource (MethodChannel)
│       │   │   ├── models/                  # AppUsageAnalyticsModel
│       │   │   └── repositories/            # AnalyticsRepositoryImpl
│       │   ├── domain/
│       │   │   ├── entities/                # AppUsageAnalyticsEntity
│       │   │   ├── repositories/            # AnalyticsRepository contract
│       │   │   └── usecases/                # Check/Request permission & Get analytics
│       │   └── presentation/
│       │       └── bloc/                    # AnalyticsBloc, AnalyticsEvent, AnalyticsState
│       ├── app_blocker/                     # Application-level firewall & discovery
│       │   ├── data/
│       │   │   ├── datasources/             # InstalledAppsDataSource, LocalStorage, Native
│       │   │   ├── models/                  # AppInfoModel
│       │   │   └── repositories/            # AppBlockerRepositoryImpl
│       │   ├── domain/
│       │   │   ├── entities/                # AppInfoEntity
│       │   │   ├── repositories/            # AppBlockerRepository contract
│       │   │   └── usecases/                # GetInstalledApps, ToggleBlockStatus
│       │   └── presentation/
│       │       ├── bloc/                    # AppBlockerBloc, Event, State
│       │       ├── pages/                   # AccessControlPage, AppDiscoveryPage,
│       │       │                            # ShieldSettingsPage, UsageStatisticsPage
│       │       └── widgets/                 # Custom UI cards, stats tiles & headers
│       ├── domain_filter/                   # DNS blacklisting & URL filtering
│       │   ├── data/
│       │   │   ├── datasources/             # DomainLocalDataSource, DomainNativeDataSource
│       │   │   ├── models/                  # BlockedDomainModel
│       │   │   └── repositories/            # DomainFilterRepositoryImpl
│       │   ├── domain/
│       │   │   ├── entities/                # BlockedDomainEntity
│       │   │   ├── repositories/            # DomainFilterRepository contract
│       │   │   └── usecases/                # Add, Remove, Toggle, Get Blocked Domains
│       │   └── presentation/
│       │       ├── bloc/                    # DomainFilterBloc, Event, State
│       │       └── widgets/                 # AddDomainDialog
│       ├── schedule/                        # Automated time-based blocking schedules
│       │   ├── data/
│       │   │   ├── datasources/             # ScheduleLocalDataSource, ScheduleNativeDataSource
│       │   │   ├── models/                  # ScheduleModel
│       │   │   └── repositories/            # ScheduleRepositoryImpl
│       │   ├── domain/
│       │   │   ├── entities/                # ScheduleEntity
│       │   │   ├── repositories/            # ScheduleRepository contract
│       │   │   └── usecases/                # Create, Update, Delete, Toggle, Get Schedules
│       │   └── presentation/
│       │       ├── bloc/                    # ScheduleBloc, Event, State
│       │       └── widgets/                 # CreateScheduleDialog
│       ├── security/                        # PIN protection & biometrics
│       │   ├── data/
│       │   │   ├── datasources/             # SecurityStorageDataSource, BiometricDataSource
│       │   │   ├── models/                  # SecuritySettingsModel
│       │   │   └── repositories/            # SecurityRepositoryImpl
│       │   ├── domain/
│       │   │   ├── entities/                # SecuritySettingsEntity
│       │   │   ├── repositories/            # SecurityRepository contract
│       │   │   └── usecases/                # Authenticate, SetPasscode, ToggleBiometrics
│       │   └── presentation/
│       │       ├── bloc/                    # AuthBloc, Event, State
│       │       └── widgets/                 # SecurityLockDialog
│       └── system_controls/                 # DNS resolvers & network preferences
│           ├── data/
│           │   ├── datasources/             # SystemControlsLocalDataSource, NativeDataSource
│           │   ├── models/                  # DnsSettingsModel
│           │   └── repositories/            # SystemControlsRepositoryImpl
│           ├── domain/
│           │   ├── entities/                # DnsSettingsEntity
│           │   ├── repositories/            # SystemControlsRepository contract
│           │   └── usecases/                # GetDnsSettings, SetDnsResolver
│           └── presentation/
│               ├── bloc/                    # SystemControlsBloc, Event, State
│               └── widgets/                 # DnsSelectionDialog
└── test/                                    # Exhaustive unit and widget test suite
    └── features/                            # Tests mirroring every domain, data & bloc layer
```

---

## 🛠 Design Patterns & Technologies

### Clean Architecture & SOLID
- **Single Responsibility Principle**: Every UseCase encapsulates one discrete action (e.g., `ToggleBlockStatusUseCase`, `SetMasterPasscodeUseCase`).
- **Open/Closed Principle**: Filter rules and DNS adapters can be extended without altering base routing logic.
- **Liskov Substitution Principle**: Abstract repository definitions allow swapping native or mock implementations transparently.
- **Interface Segregation Principle**: Granular datasources (e.g. `BiometricDataSource`, `LocalStorageDataSource`) isolate concerns.
- **Dependency Inversion Principle**: Domain depends on zero data frameworks; Data depends on Domain contracts.

### State Management (BLoC)
Each feature uses a specialized BLoC to preserve predictable states:
- `AppBlockerBloc`: App discovery, search queries, blocklist state, and mass selections.
- `DomainFilterBloc`: Domain blacklist loading, additions, deletions, and active toggles.
- `ScheduleBloc`: Automated schedule lists and validation states.
- `AnalyticsBloc`: Usage telemetry, permission checks, and range filters.
- `AuthBloc`: Security lock, PIN verification, and biometrics enablement.
- `SystemControlsBloc`: DNS provider selection and custom IP configuration.

### Dependency Injection (GetIt)
All singletons, repositories, use cases, and BLoC factories are registered in `lib/core/di/injection_container.dart`, facilitating modularity, mockability, and zero tight-coupling.

### Functional Error Handling (Dartz)
By employing `Either<Failure, T>`, errors are treated as first-class domain values:
```dart
Future<Either<Failure, List<AppInfoEntity>>> call(NoParams params);
```

---

## 📦 Dependencies

| Package | Version | Usage |
| :--- | :--- | :--- |
| [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) | `^9.1.1` | Predictable BLoC state management |
| [`get_it`](https://pub.dev/packages/get_it) | `^9.2.1` | Inversion of Control & dependency injection |
| [`dartz`](https://pub.dev/packages/dartz) | `^0.10.1` | Functional data types (`Either`, `Left`, `Right`) |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | `^2.5.5` | Key-value persistent storage for rules & settings |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | `^11.0.0` | Android Keystore-backed master passcode storage |
| [`local_auth`](https://pub.dev/packages/local_auth) | `^3.0.2` | Biometric authentication (Fingerprint / Face ID) |
| [`installed_apps`](https://pub.dev/packages/installed_apps) | `^2.1.1` | Device installed package querying |
| [`cupertino_icons`](https://pub.dev/packages/cupertino_icons) | `^1.0.9` | iOS & material design glyphs |

---

## 🏁 Getting Started

### Prerequisites
- **Flutter SDK**: `>=3.13.0`
- **Dart SDK**: `^3.13.0`
- **Android SDK**: API 21+ (Android 5.0 Lollipop or newer)
- **Target Device**: An Android phone or emulator with Google Play Services.

### Installation & Execution

1. **Clone the repository**:
   ```bash
   git clone https://github.com/imdheeraj2799/NetGuard.git
   cd NetGuard
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run on an attached Android device**:
   ```bash
   flutter run
   ```

4. **Grant Special Permissions**:
   - **VPN Permission**: When activating the firewall, accept Android's native VPN confirmation prompt.
   - **Usage Access**: In order to view screen time and network usage statistics, navigate to **Settings > Apps > Special App Access > Usage Access** and grant access to **NetGuard** (or tap the prompt in the Analytics screen).

### Running Unit & Widget Tests

Execute the comprehensive test suite:
```bash
flutter test
```

---

## 📄 License

This project is licensed under the terms described in the project repository. Unauthorized copying or redistribution is strictly regulated.
