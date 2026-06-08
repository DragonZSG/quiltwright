# 001. Adopt Harness Engineering

**Date:** 2026-06-02

**Status:** Accepted

## Context

quiltwright is early in its lifecycle and has a compact SwiftUI architecture. AI agents can work effectively in a codebase this small if they have clear commands, module boundaries, and risk tiers before the project grows more complex.

## Decision

Adopt a repository harness made of root agent instruction files, an architecture map, ADR scaffolding, an editor configuration, a harness verification script, and a Buildkite harness verification step.

The harness defines:

- Deterministic verification commands for package checks and app builds.
- Three-tier agent boundaries: Always, Ask, and Never.
- A concise module map for shared UI, platform app targets, checks, CI, and Xcode project metadata.
- ADR conventions for future architectural and toolchain decisions.

## Consequences

### Easier

- Agents can find the correct build and test commands quickly.
- Shared UI and platform target boundaries are explicit.
- Future module and command additions have a documented update path.
- CI can detect missing or stale harness files.
- Multi-agent workflow loops are checked into the repo and verified across Codex, Claude Code, and GitHub Copilot surfaces.
- The quality guard provides a single command family for completion evidence.
- Canonical workflow docs prevent drift between agent-specific surfaces.
- `STYLEGUIDE.md` is the standing style authority for code, docs, scripts, CI, and agent artifacts.

### Harder

- Harness files must be kept in sync as modules, commands, and tools evolve.
- New architecture or tooling decisions should be captured in ADRs instead of living only in chat or commit history.

## Notes

This ADR records the initial harness adoption only. Future decisions, such as adding XCTest, SwiftLint, SwiftFormat, persistence, or networking, should receive separate ADRs.
