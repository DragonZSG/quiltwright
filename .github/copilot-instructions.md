# Copilot Instructions - quiltwright

<!-- Keep in sync with CLAUDE.md and AGENTS.md -->

quiltwright is a SwiftUI app for macOS and iOS written in Swift.

## Commands

- Build all CI legs: `script/ci.sh all`
- Build macOS app: `script/ci.sh macos`
- Build iOS simulator app: `script/ci.sh ios`
- Test shared UI checks: `swift run QuiltwrightChecks`
- Package check used by CI: `script/ci.sh package`
- Lint: not configured (`lint_cmd: null`)
- Format: not configured (`format_cmd: null`)
- Verify harness: `scripts/verify-harness.sh`

## Architecture

`QuiltwrightUI` contains shared SwiftUI views and presentation data. `QuiltwrightMac` and `QuiltwrightiOS` are thin platform app entry targets. `QuiltwrightChecks` is a SwiftPM executable check target. Full details: [ARCHITECTURE.md](../ARCHITECTURE.md).

## Conventions

- Name Swift files after their primary type.
- Keep `@main` app structs thin.
- Put reusable UI and presentation state in `Sources/QuiltwrightUI`.
- Keep shared module APIs platform-neutral unless guarded with explicit availability or platform checks.
- Use 4-space indentation, no trailing whitespace, and a final newline.
- Add checks under `Tests/QuiltwrightChecks` when XCTest is not yet configured.
- Keep `Package.swift`, Xcode target membership, schemes, and CI commands in sync.

## Patterns to Follow

- Run `swift run QuiltwrightChecks` after shared UI or shared model changes.
- Run the relevant `script/ci.sh` build leg after app target, project, scheme, or CI changes.
- Run `script/ci.sh all` before considering a build-affecting task complete.
- Update `ARCHITECTURE.md` and agent instruction files when modules, commands, or dependency rules change.

## Ask Before

- Adding or changing Swift package dependencies.
- Adding targets, schemes, package products, or platform modules.
- Changing public `QuiltwrightUI` APIs.
- Changing deployment targets, bundle identifiers, signing, Buildkite queues, or CI structure.
- Introducing persistence, networking, external services, or domain/data architecture.
- Adding SwiftLint, SwiftFormat, XCTest, or other new tooling.

## Patterns to Avoid

- Do not delete or disable tests/checks, CI steps, schemes, or build targets to make failures disappear.
- Do not commit secrets, signing certificates, provisioning profiles, API keys, or Xcode user data.
- Do not put platform-specific APIs in shared UI without platform guards.
- Do not change Xcode project settings without verifying both app schemes afterward.
- Do not push commits or create pull requests without explicit user permission.

## Harness Evolution

These files are living documents. Update them as the project evolves:

- **After adding a new module**: Update ARCHITECTURE.md module map and dependency rules.
- **After adding a new command**: Update the Commands section in all agent instruction files.
- **After an agent makes a mistake**: Add a rule to the Boundaries section to prevent recurrence.
- **After an architectural decision**: Create a new ADR in docs/adr/.
- **On session start**: Quick-check that commands still work and module list matches reality.
