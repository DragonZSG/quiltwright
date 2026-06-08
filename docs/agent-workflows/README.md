# Agent Workflows

This directory contains the canonical workflow loops for Quiltwright's agentic harness. Treat these documents as the source of truth: Codex, Claude Code, and GitHub Copilot skills or agents should load the relevant workflow document and act as thin wrappers around it.

`manifest.txt` lists every required workflow as `slug|Label`. `scripts/verify-harness.sh` reads that manifest and requires each slug to have `docs/agent-workflows/<slug>.md` plus cross-agent companions.

## Workflows

- `planning-loop` - Manager-style scope, decomposition, and verification planning.
- `implementation-loop` - One-task implementation loop with targeted verification and evidence.
- `review-architecture` - Focused review of module boundaries, dependency direction, APIs, state/data flow, and architecture decisions.
- `review-tests` - Focused review of test meaning, failure quality, regression risk, command fit, and maintainability.
- `review-security-privacy` - Focused review of secrets, permissions, sandboxing, data privacy, dependency changes, and agent security risks.
- `review-ui-platform` - Focused review of SwiftUI, macOS/iOS platform behavior, accessibility, input, scenes, and layout stability.
- `review-performance` - Focused review of responsiveness, SwiftUI update cost, I/O, build/test cost, and measurement needs.
- `review-plans-specs` - Focused review of plans and specs against repo guidance, established patterns, and verification expectations.
- `code-quality-guard` - Deterministic completion gate for harness, docs, shell, SwiftPM, and CI checks.

## Canonical-Docs-First Architecture

Each workflow starts here, then each agent surface points back to the same document. Skills and agents should be thin wrappers around the canonical workflow docs, not separate sources of behavior.

## Companion Contract

Every workflow listed in `manifest.txt` must have `docs/agent-workflows/<workflow>.md` and companion coverage for Codex, Claude Code, and GitHub Copilot, unless `docs/agent-tooling/<workflow>.md` explains why a surface is intentionally waived.

- Codex primary companion: `.agents/skills/<workflow>/SKILL.md`.
- Codex backward-compatible accepted companion: `.codex/skills/<workflow>/SKILL.md`.
- Codex role/custom agent: `.codex/agents/<role>.toml`; when it is used as the manifest companion, `<role>` should match `<workflow>` or the rationale waiver should explain the mapping.
- Claude Code primary companion: `.claude/skills/<workflow>/SKILL.md`.
- Claude Code accepted legacy/manual command: `.claude/commands/<workflow>.md`.
- Claude Code role/subagent: `.claude/agents/<role>.md`; when it is used as the manifest companion, `<role>` should match `<workflow>` or the rationale waiver should explain the mapping.
- GitHub Copilot primary companion: `.github/skills/<workflow>/SKILL.md`.
- GitHub Copilot accepted instruction companion: `.github/instructions/<workflow>.instructions.md`.
- GitHub Copilot accepted prompt companion: `.github/prompts/<workflow>.prompt.md`.
- GitHub Copilot role/custom agent: `.github/agents/<role>.md`; when it is used as the manifest companion, `<role>` should match `<workflow>` or the rationale waiver should explain the mapping.
- Rationale waiver: `docs/agent-tooling/<workflow>.md`.

The quality guard remains script and CI driven. Hooks may call the guard, but hooks are not the authoritative source of harness correctness.
