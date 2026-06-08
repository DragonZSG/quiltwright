# Plan And Spec Review Tool Design

## Goal

Add a Quiltwright harness workflow that directs agents to review implementation plans and design specs against repository quality guidance, established patterns, architecture rules, and deterministic verification expectations before implementation or handoff.

## Context

Quiltwright's harness uses a canonical-docs-first model. Each workflow is documented under `docs/agent-workflows/`, listed in `docs/agent-workflows/manifest.txt`, and exposed through thin Codex, Claude Code, and GitHub Copilot companions.

Existing review workflows focus on architecture, tests, security/privacy, UI/platform behavior, and performance. `code-quality-guard` is deterministic and script-driven. Plan and spec review is judgment-heavy, so it should be a focused evaluator workflow rather than a shell-only quality guard.

## Scope

Add a new workflow named `review-plans-specs`.

In scope:

- Canonical workflow document for reviewing plans and specs.
- Manifest and workflow README registration.
- Thin skill wrappers for Codex, Claude Code, and GitHub Copilot.
- Role/custom-agent companions where existing reviewer workflows already use them.
- A GitHub prompt companion matching existing manual prompt coverage.
- Updates to top-level agent instruction files so the review workflow is discoverable.
- Harness verification through the existing manifest companion checks.

Out of scope:

- New deterministic shell script for semantic plan/spec review.
- New CI step beyond existing harness verification and quality guard.
- New lint, format, or test tooling.
- Changes to planning-loop behavior except references to the new review checkpoint if needed.
- Changes to product feature specs or implementation plans outside this harness capability.

## Workflow Behavior

The reviewer should evaluate plans and specs before implementation, before handoff, or when the user explicitly asks whether a plan/spec is ready.

Inputs:

- Target plan or spec files.
- Current worktree state from `git status -sb`.
- Repository guidance from `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, `STYLEGUIDE.md`, and `ARCHITECTURE.md`.
- Canonical workflow requirements from `docs/agent-workflows/planning-loop.md`, `docs/agent-workflows/implementation-loop.md`, and `docs/agent-workflows/code-quality-guard.md`.
- Related plans, specs, ADRs, and research notes when they affect the reviewed artifact.
- Actual repo files and commands named by the plan or spec.

Review checks:

- Scope is concrete and matches user-approved boundaries.
- Required approval checkpoints are explicit instead of assumed.
- Plans name exact files, file responsibilities, verification commands, expected outcomes, risks, and stop conditions.
- Specs avoid placeholders, contradictions, vague requirements, hidden implementation assumptions, and scope creep.
- Artifact guidance matches `STYLEGUIDE.md`, `ARCHITECTURE.md`, and current module/dependency rules.
- Agent tooling plans follow the canonical-docs-first model and include required cross-agent companions or rationale waivers.
- Verification commands match repo commands and are scaled to risk.
- Dirty worktree state is acknowledged and unrelated changes are protected.
- The artifact does not hide source changes inside a plan/spec-only task.

Output shape:

- Findings first, ordered by severity.
- Each finding cites the reviewed file and line when possible.
- Severity buckets: blocker, major, minor.
- Open questions and assumptions after findings.
- Short readiness summary after questions.
- Verification evidence considered and missing evidence that affects confidence.
- Clear statement when no issues were found.

## Relationship To Code Quality Guard

`review-plans-specs` is an evaluator workflow. It directs human-quality review of plans and specs.

`code-quality-guard` remains the deterministic completion gate. It runs shell, markdown, harness, SwiftPM, and CI checks. The new workflow may require a plan to call the quality guard, but it must not duplicate or replace the guard script.

## Companion Coverage

Primary companions:

- `.agents/skills/review-plans-specs/SKILL.md`
- `.claude/skills/review-plans-specs/SKILL.md`
- `.github/skills/review-plans-specs/SKILL.md`

Role/manual companions:

- `.codex/agents/review-plans-specs.toml`
- `.claude/agents/review-plans-specs.md`
- `.github/agents/review-plans-specs.md`
- `.github/prompts/review-plans-specs.prompt.md`

Registration:

- `docs/agent-workflows/manifest.txt`
- `docs/agent-workflows/README.md`
- `AGENTS.md`
- `CLAUDE.md`
- `.github/copilot-instructions.md`
- `ARCHITECTURE.md` only if the module map or harness surface description needs to name the new workflow explicitly.

## Verification

Run:

- `scripts/verify-harness.sh`
- `scripts/quality-guard.sh --fast`

Expected:

- The new workflow is listed in the manifest.
- The canonical workflow document exists.
- Codex, Claude Code, and GitHub Copilot companions exist and reference the canonical workflow.
- Metadata on skills and agents matches `review-plans-specs`.
- Changed markdown has balanced fences and no placeholder language.

## Approval State

The user approved adding a harness tool to direct review of plans and specs against the code quality guide, established patterns, and repo guidance. The approved design is a new focused review workflow named `review-plans-specs`, not a deterministic shell-only guard.
