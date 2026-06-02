# quiltwright - Architecture Map

quiltwright is a SwiftUI app for macOS and iOS. The current architecture is intentionally small: shared UI and presentation data live in `QuiltwrightUI`, platform app targets provide entry points, and `QuiltwrightChecks` verifies shared behavior through public APIs.

## System Overview

The repository has both SwiftPM and Xcode project metadata. `Package.swift` defines the shared UI library, the macOS executable, and the check executable. `Quiltwright.xcodeproj` defines the macOS and iOS app targets and shared schemes. Buildkite runs `.buildkite/pipeline.yml`, which delegates to `script/ci.sh`.

## Module Map

| Module | Path | Layer | Purpose | Depends on | Depended on by |
|-|-|-|-|-|-|
| QuiltwrightUI | `Sources/QuiltwrightUI` | UI / shared presentation | Shared SwiftUI views and simple presentation data types. | SwiftUI | QuiltwrightMac, QuiltwrightiOS, QuiltwrightChecks |
| QuiltwrightMac | `Sources/QuiltwrightMac` | Runtime / app entry | macOS SwiftUI `@main` application entry point. | SwiftUI, QuiltwrightUI | Xcode scheme, SwiftPM product |
| QuiltwrightiOS | `Sources/QuiltwrightiOS` | Runtime / app entry | iOS SwiftUI `@main` application entry point. | SwiftUI, QuiltwrightUI through Xcode target membership | Xcode scheme |
| QuiltwrightChecks | `Tests/QuiltwrightChecks` | Verification | Lightweight SwiftPM executable checks for shared behavior. | QuiltwrightUI | `script/ci.sh package` |
| CI scripts | `script/ci.sh`, `.buildkite/pipeline.yml` | Tooling | Local and Buildkite build/check orchestration. | SwiftPM, xcodebuild | Developers, Buildkite |
| Xcode project | `Quiltwright.xcodeproj` | Tooling | macOS and iOS app target definitions, build settings, and schemes. | Xcode | `script/ci.sh macos`, `script/ci.sh ios` |

## Layer Diagram

Dependency direction:

```text
Buildkite / local shell
        |
        v
script/ci.sh
        |
        +--> SwiftPM: Package.swift -> QuiltwrightChecks -> QuiltwrightUI
        |
        +--> Xcode: Quiltwright.xcodeproj -> QuiltwrightMac -> QuiltwrightUI
        |
        +--> Xcode: Quiltwright.xcodeproj -> QuiltwrightiOS -> QuiltwrightUI

SwiftUI framework sits below the app and shared UI targets.
```

There is no persistence, networking, service, or domain layer yet.

## Dependency Rules

- `Sources/QuiltwrightUI` must not import `QuiltwrightMac` or `QuiltwrightiOS`.
- App targets may depend on shared UI, but shared UI must remain platform-neutral unless code is guarded by availability or platform checks.
- `Tests/QuiltwrightChecks` should verify shared behavior through public `QuiltwrightUI` APIs.
- `Package.swift`, `Quiltwright.xcodeproj`, shared schemes, and `script/ci.sh` must stay aligned when targets, products, or source files change.
- CI should call repository scripts instead of duplicating long `xcodebuild` commands in pipeline YAML.
- New persistence, networking, domain, or service layers require an ADR before implementation.

## Key Decisions

- ADRs live in [docs/adr](./docs/adr/).
- The first ADR is [001-adopt-harness-engineering.md](./docs/adr/001-adopt-harness-engineering.md).

## What Doesn't Belong

- `Sources/QuiltwrightUI` - no platform app lifecycle, signing, Buildkite, or Xcode-only configuration logic.
- `Sources/QuiltwrightMac` - no reusable shared UI or iOS-specific behavior.
- `Sources/QuiltwrightiOS` - no reusable shared UI or macOS-specific behavior.
- `Tests/QuiltwrightChecks` - no production app entry points or platform build settings.
- `script/ci.sh` and `.buildkite/pipeline.yml` - no business logic or UI code.
- `Quiltwright.xcodeproj` - no hand edits without verifying both app schemes afterward.

## Harness Maintenance

- Update this file when modules, targets, dependency rules, commands, or architectural decisions change.
- Keep `CLAUDE.md`, `AGENTS.md`, and `.github/copilot-instructions.md` consistent with command and boundary changes.
- Add an ADR for new architectural layers or toolchain decisions.

<!-- EVOLVE: Add sequence diagrams once the app has user workflows. -->
<!-- EVOLVE: Add data-flow documentation when persistence or networking is introduced. -->
