# Agent Instructions for quiltwright

<!-- Keep in sync with CLAUDE.md and .github/copilot-instructions.md -->

## Identity

You are a coding agent operating within the quiltwright repository. quiltwright is a SwiftUI app for macOS and iOS written in Swift. Your goal is to make correct, minimal, convention-respecting changes and verify them with the repo's own commands.

## Commands

Working directory: `/Users/mgrant/Repos/quiltwright`

```text
build:          script/ci.sh all
build:macos:    script/ci.sh macos
build:ios:      script/ci.sh ios
test:           swift run QuiltwrightChecks
test:package:   script/ci.sh package
lint:           null
format:         null
check:          script/ci.sh all
verify:         scripts/verify-harness.sh
verify:test:    scripts/test-verify-harness.sh
quality:        scripts/quality-guard.sh --fast
quality:full:   scripts/quality-guard.sh --full
quality:test:   scripts/test-quality-guard.sh
```

`lint` and `format` are intentionally `null` because no Swift lint or format tool is configured. Do not add one without explicit approval.

## Architecture

`QuiltwrightUI` is the shared SwiftUI presentation module. `QuiltwrightMac` and `QuiltwrightiOS` are thin platform app entry targets. `QuiltwrightChecks` verifies shared UI behavior as a SwiftPM executable target. Buildkite uses `.buildkite/pipeline.yml`, which calls `script/ci.sh`.

See [ARCHITECTURE.md](./ARCHITECTURE.md) for the full module map and dependency rules.

## Agent Workflows

Canonical workflow loops live in [docs/agent-workflows](./docs/agent-workflows/). Read the matching workflow before using or changing agent wrappers.

- Planning: `planning-loop`
- Implementation: `implementation-loop`
- Reviews: `review-architecture`, `review-tests`, `review-security-privacy`, `review-ui-platform`, `review-performance`, `review-plans-specs`
- Guard: `code-quality-guard`

## Modules

- **QuiltwrightUI** (`Sources/QuiltwrightUI`) - Shared SwiftUI views and simple presentation data types.
- **QuiltwrightMac** (`Sources/QuiltwrightMac`) - macOS SwiftUI app entry point.
- **QuiltwrightiOS** (`Sources/QuiltwrightiOS`) - iOS SwiftUI app entry point.
- **QuiltwrightChecks** (`Tests/QuiltwrightChecks`) - SwiftPM executable checks for shared UI behavior.
- **CI scripts** (`script/ci.sh`, `.buildkite/pipeline.yml`) - Local and Buildkite verification commands.
- **Xcode project** (`Quiltwright.xcodeproj`) - Platform build targets and schemes for macOS and iOS.

## Conventions

- Use Swift file names that match the primary type, such as `WelcomeView.swift` and `WelcomeContent.swift`.
- Keep `@main` app structs thin; place shared UI and reusable presentation state in `Sources/QuiltwrightUI`.
- Use SwiftUI `View` structs for UI composition and simple `Sendable` value types for shared content models.
- Keep shared module APIs platform-neutral unless guarded with explicit availability or platform checks.
- Use 4-space indentation, trim trailing whitespace, and keep a final newline.
- Add executable checks under `Tests/QuiltwrightChecks` when XCTest is not yet configured.
- Keep `Package.swift`, Xcode target membership, schemes, and CI commands in sync when adding targets or source files.

For detailed project style rules, see [STYLEGUIDE.md](./STYLEGUIDE.md).

## Boundaries

### Always

- ALWAYS: Work from the repository root unless a command explicitly says otherwise.
- ALWAYS: Preserve the Swift tools version `5.10`, iOS deployment target `17`, and macOS deployment target `14` unless the user approves a change.
- ALWAYS: Put reusable UI and presentation state in `Sources/QuiltwrightUI`; keep app targets focused on platform entry and lifecycle.
- ALWAYS: Run `swift run QuiltwrightChecks` after shared UI or shared model changes.
- ALWAYS: Run the relevant `script/ci.sh` build leg after changing app targets, project settings, schemes, or CI.
- ALWAYS: Run `script/ci.sh all` before considering a task complete when the change can affect builds.
- ALWAYS: Update `ARCHITECTURE.md` and the agent instruction files when modules, commands, or dependency rules change.
- ALWAYS: Do not skip pre-commit hooks (`--no-verify`) if hooks are added later.

### Ask First

- ASK: Adding, removing, or updating Swift package dependencies.
- ASK: Adding new SwiftPM targets, Xcode targets, schemes, package products, or platform modules.
- ASK: Changing public APIs in `QuiltwrightUI` that app targets or checks use.
- ASK: Changing deployment targets, bundle identifiers, code signing settings, Buildkite queues, or CI structure.
- ASK: Introducing persistence, networking, external services, or a new domain/data architecture.
- ASK: Replacing `QuiltwrightChecks` with XCTest or adding lint/format tooling such as SwiftLint or SwiftFormat.

### Never

- NEVER: Delete or disable tests/checks, CI steps, schemes, or build targets to make a failure disappear.
- NEVER: Commit secrets, signing certificates, provisioning profiles, API keys, or machine-specific Xcode user data.
- NEVER: Put macOS-only or iOS-only APIs in shared UI without platform guards.
- NEVER: Change generated Xcode project settings blindly; verify both `QuiltwrightMac` and `QuiltwrightiOS` schemes afterward.
- NEVER: Push commits, force-push, or create pull requests without explicit user permission.
- NEVER: Modify dependencies or business logic as part of harness maintenance unless the user explicitly asked for it.

## Harness Evolution

These files are living documents. Update them as the project evolves:

- **After adding a new module**: Update ARCHITECTURE.md module map and dependency rules.
- **After adding a new command**: Update the Commands section in all agent instruction files.
- **After adding agent tooling or workflows**: Create or update equivalent guidance for every supported agent surface, not only the agent currently making the change. Codex uses `AGENTS.md`, `.agents/skills/<name>/SKILL.md`, `.codex/agents/<role>.toml`, and project `.codex/` config/hooks when deterministic policy requires it. Claude Code uses `CLAUDE.md`, `.claude/skills/<name>/SKILL.md`, `.claude/agents/<role>.md`, `.claude/commands/<name>.md` as legacy/manual compatibility, and hooks/settings only when deterministic policy requires it. GitHub Copilot uses `.github/copilot-instructions.md`, `.github/skills/<name>/SKILL.md`, `.github/agents/<role>.md`, optional `.github/prompts/<name>.prompt.md`, optional `.github/instructions/<name>.instructions.md`, and `.github/hooks/*.json` only when deterministic policy requires it. If no equivalent exists, add `docs/agent-tooling/<name>.md` explaining the coverage and why the missing companion is intentionally N/A.
- **After an agent makes a mistake**: Add a rule to the Boundaries section to prevent recurrence.
- **After an architectural decision**: Create a new ADR in docs/adr/.
- **On session start**: Quick-check that commands still work and module list matches reality.

<!-- EVOLVE: Add XCTest guidance once the project adopts XCTest targets. -->
<!-- EVOLVE: Add lint and format commands after the project chooses Swift lint tooling. -->
