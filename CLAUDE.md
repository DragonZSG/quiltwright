# quiltwright

<!-- Keep in sync with AGENTS.md and .github/copilot-instructions.md -->

This is quiltwright, a SwiftUI app for macOS and iOS written in Swift. The codebase is compact and target-oriented: shared SwiftUI code lives in `QuiltwrightUI`, the macOS and iOS app targets provide thin `@main` entry points, and Buildkite runs the same `script/ci.sh` checks used locally.

## Commands

Run commands from the repository root: `/Users/mgrant/Repos/quiltwright`.

- Build all CI legs: `script/ci.sh all`
- Build macOS app: `script/ci.sh macos`
- Build iOS simulator app: `script/ci.sh ios`
- Test shared UI checks: `swift run QuiltwrightChecks`
- Package check used by CI: `script/ci.sh package`
- Lint: not configured (`lint_cmd: null`)
- Format: not configured (`format_cmd: null`)
- Verify harness: `scripts/verify-harness.sh`
- Test harness verifier: `scripts/test-verify-harness.sh`
- Fast quality guard: `scripts/quality-guard.sh --fast`
- Full quality guard: `scripts/quality-guard.sh --full`
- Test quality guard: `scripts/test-quality-guard.sh`

`script/ci.sh all` is the composite check command. It runs the SwiftPM check target, then the macOS and iOS Xcode builds. No dedicated lint or formatter command exists yet; do not install SwiftLint, SwiftFormat, or another tool without explicit approval.

## Architecture

`QuiltwrightUI` is the shared presentation module. `QuiltwrightMac` and `QuiltwrightiOS` are platform app entry targets that render shared UI. `QuiltwrightChecks` is a lightweight SwiftPM executable test/check target for shared behavior. Build and CI orchestration live in `script/ci.sh` and `.buildkite/pipeline.yml`.

For the full module map, layer diagram, and dependency rules, see [ARCHITECTURE.md](./ARCHITECTURE.md).

## Agent Workflows

Canonical workflow loops live in [docs/agent-workflows](./docs/agent-workflows/). Read the matching workflow before using or changing agent wrappers.

- Planning: `planning-loop`
- Implementation: `implementation-loop`
- Reviews: `review-architecture`, `review-tests`, `review-security-privacy`, `review-ui-platform`, `review-performance`, `review-plans-specs`
- Guard: `code-quality-guard`

### Key Modules

- **QuiltwrightUI** (`Sources/QuiltwrightUI`) - Shared SwiftUI views and simple presentation data types.
- **QuiltwrightMac** (`Sources/QuiltwrightMac`) - macOS SwiftUI app entry point.
- **QuiltwrightiOS** (`Sources/QuiltwrightiOS`) - iOS SwiftUI app entry point.
- **QuiltwrightChecks** (`Tests/QuiltwrightChecks`) - SwiftPM executable checks for shared UI behavior.
- **CI scripts** (`script/ci.sh`, `.buildkite/pipeline.yml`) - Local and Buildkite verification commands.
- **Xcode project** (`Quiltwright.xcodeproj`) - Platform build targets and schemes for macOS and iOS.

## Coding Conventions

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

These rules are non-negotiable. Follow them on every change.

- Work from the repository root unless a command explicitly says otherwise.
- Preserve the Swift tools version `5.10`, iOS deployment target `17`, and macOS deployment target `14` unless the user approves a change.
- Put reusable UI and presentation state in `Sources/QuiltwrightUI`; keep app targets focused on platform entry and lifecycle.
- Run `swift run QuiltwrightChecks` after shared UI or shared model changes.
- Run the relevant `script/ci.sh` build leg after changing app targets, project settings, schemes, or CI.
- Run `script/ci.sh all` before considering a task complete when the change can affect builds.
- Update `ARCHITECTURE.md` and the agent instruction files when modules, commands, or dependency rules change.
- Do not skip pre-commit hooks (`--no-verify`) if hooks are added later.

### Ask

Ask the user before taking these actions.

- Adding, removing, or updating Swift package dependencies.
- Adding new SwiftPM targets, Xcode targets, schemes, package products, or platform modules.
- Changing public APIs in `QuiltwrightUI` that app targets or checks use.
- Changing deployment targets, bundle identifiers, code signing settings, Buildkite queues, or CI structure.
- Introducing persistence, networking, external services, or a new domain/data architecture.
- Replacing `QuiltwrightChecks` with XCTest or adding lint/format tooling such as SwiftLint or SwiftFormat.

### Never

Do not do these under any circumstances.

- Delete or disable tests/checks, CI steps, schemes, or build targets to make a failure disappear.
- Commit secrets, signing certificates, provisioning profiles, API keys, or machine-specific Xcode user data.
- Put macOS-only or iOS-only APIs in shared UI without platform guards.
- Change generated Xcode project settings blindly; verify both `QuiltwrightMac` and `QuiltwrightiOS` schemes afterward.
- Push commits, force-push, or create pull requests without explicit user permission.
- Modify dependencies or business logic as part of harness maintenance unless the user explicitly asked for it.

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
