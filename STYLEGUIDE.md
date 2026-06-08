# Quiltwright Style Guide

This is a standing reference for code, docs, scripts, CI, and harness artifacts in Quiltwright. It is not an agent workflow; use `docs/agent-workflows/` for step-by-step execution loops.

## Swift Naming And API Shape

- Use Swift file names that match the primary type, such as `WelcomeView.swift` and `WelcomeContent.swift`.
- Keep module names aligned with the package and project: `QuiltwrightUI`, `QuiltwrightMac`, `QuiltwrightiOS`, and `QuiltwrightChecks`.
- Keep `@main` app structs thin. Put shared UI and presentation state in `Sources/QuiltwrightUI`.
- Keep shared APIs platform-neutral unless the platform-specific branch is guarded explicitly.
- Prefer small value types for shared presentation models. When values cross checks or UI boundaries, follow the existing `Equatable, Sendable` pattern where it fits.
- Use clear external argument labels for public initializers and methods. Avoid abbreviations unless they are already established in the surrounding code.
- Preserve the current Swift tools and deployment targets unless the task explicitly approves changing them.

## SwiftUI Organization

- Put reusable views in `Sources/QuiltwrightUI`; keep `Sources/QuiltwrightMac` and `Sources/QuiltwrightiOS` focused on platform app entry and lifecycle.
- Keep view composition readable: extract a new `View` only when it names a real UI concept or removes repeated structure.
- Keep default content and simple presentation data close to the shared UI that consumes it.
- Avoid macOS-only or iOS-only APIs in shared views unless they are behind explicit availability or platform checks.
- Prefer system-provided SwiftUI primitives and SF Symbols for the current lightweight app shell.

## Tests And Checks

- Use `Tests/QuiltwrightChecks` for executable package checks while the repo has no dedicated test framework target.
- Run `swift run QuiltwrightChecks` after changes to `Sources/`, `Tests/`, or `Package.swift`.
- Run `script/ci.sh package` after package-level, project metadata, or CI changes that can affect the package check path.
- Run `script/ci.sh all` before handoff when changes can affect macOS or iOS builds.
- Do not make SwiftLint, SwiftFormat, or XCTest a required gate unless the repo explicitly adopts that tooling in a separate approved change.

## Docs And Markdown

- Keep `ARCHITECTURE.md` focused on module boundaries, dependency rules, and command maps.
- Keep ADRs in `docs/adr/` for durable decisions. Use the existing ADR template and date new ADRs with the decision date.
- Keep agent workflows in `docs/agent-workflows/` as executable procedures. Keep this file as reference guidance, not a workflow.
- Use fenced code blocks with language tags when the language is known, especially `sh`, `swift`, `yml`, and `text`.
- Keep markdown fences balanced. The quality guard checks lines beginning with three backticks in changed markdown files.
- Keep generated or harness markdown concrete enough to run. Do not leave unfinished placeholder prose for a later agent to interpret.

## Shell Scripts

- Use Bash for repo scripts, with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Resolve and `cd` to the repo root before reading repo-relative paths.
- Quote variables and paths. Use arrays for file lists when invoking commands over changed paths.
- Print clear sections and the exact command being run before checks that can fail.
- Keep scripts deterministic and local; do not download dependencies or modify global machine state without explicit approval.
- Keep guard script runtime tools to the macOS/Linux baseline already used by the repo, such as `git`, `bash`, `awk`, and `grep`, unless CI availability is documented.
- Mark runnable scripts executable.

## CI And Harness Artifacts

- Buildkite lives in `.buildkite/pipeline.yml` and should call repo scripts instead of duplicating build logic inline.
- Keep `script/ci.sh package`, `script/ci.sh macos`, `script/ci.sh ios`, and `script/ci.sh all` as the canonical CI entry points.
- Keep harness verification in `scripts/verify-harness.sh`; quality gating should call it rather than reimplementing its policy.
- Add CI checks in dependency order. Harness and quality checks should complete before the pipeline wait that precedes platform builds.
- Do not disable, narrow, or remove checks to make a failing task pass. Fix the failing artifact or report the failure clearly.

## Agent Artifact Naming

- Use lowercase kebab-case workflow slugs, such as `code-quality-guard`.
- Name workflow source files `docs/agent-workflows/<slug>.md` and list them in `docs/agent-workflows/manifest.txt` as `slug|Label`.
- Name skill wrappers `.agents/skills/<slug>/SKILL.md`, `.claude/skills/<slug>/SKILL.md`, and `.github/skills/<slug>/SKILL.md`.
- Name GitHub prompt wrappers `.github/prompts/<slug>.prompt.md`.
- Name agent role files by role slug, such as `planner` or `review-tests`, and keep equivalent roles aligned across supported agent surfaces.

## Review Standards

- Style-only review findings must cite one of: this `STYLEGUIDE.md`, a local pattern in nearby code, or deterministic tooling output.
- Treat personal preference without a repo citation or deterministic check as non-blocking review context.
- When guidance depends on external current behavior, cite an official source and include the access date. Verify the source at the time of writing instead of relying on memory for changing tool behavior.
- Prefer local repo commands and files as the source of truth for Quiltwright-specific guidance.
