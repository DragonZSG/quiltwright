# Planning Loop

## Purpose

Use this manager-style workflow when a request needs scoping before implementation: feature planning, multi-file changes, architecture decisions, harness evolution, or work that needs decomposition into independently verifiable tasks.

## Inputs

- User goal, constraints, branch name, target files, and any explicit ownership boundaries.
- Current worktree state from `git status -sb`, including unrelated edits that must be preserved.
- Repository instructions from `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md`.
- Architecture and command context from `ARCHITECTURE.md`, `Package.swift`, `script/ci.sh`, `.buildkite/pipeline.yml`, and relevant source or docs.
- Existing plans under `docs/superpowers/plans/` when continuing or revising planned work.
- Source-backed research, especially `docs/superpowers/research/2026-06-03-agentic-harness-best-practices.md`, whenever the plan creates or changes agent guidance, skills, agents, hooks, prompts, or quality guard behavior.

## Loop

1. Inspect `git status -sb` first and record unrelated changes so the plan protects them.
2. Read always-loaded agent instructions, `ARCHITECTURE.md`, relevant source files, and any existing plan or research note tied to the request.
3. Restate the goal in one concrete sentence and identify the smallest useful scope that can be completed without crossing approval boundaries.
4. Decompose the scope into tasks that each leave the repository in a verifiable state.
5. For every task, name the exact files to create or modify, the responsibility of each file, and the commands that should prove the task is complete.
6. Call out sequencing dependencies, review checkpoints, expected failure states, and items intentionally out of scope.
7. Stop and ask before destructive ambiguity: deleting files, rewriting unrelated work, changing dependencies, changing CI structure, changing deployment settings, or modifying business logic outside the approved scope.
8. Save the plan under `docs/superpowers/plans/` with a date-prefixed, descriptive filename.

## Output

- A saved plan under `docs/superpowers/plans/` containing goal, context, scope, task list, exact files, verification commands, expected outcomes, risks, and stop conditions.
- A short handoff summary with the plan path, recommended next task, unresolved questions, and any approval needed before implementation.
- No source changes beyond the plan unless the user explicitly asked for immediate implementation.

## Verification

- The plan contains no placeholder language and no unresolved section labels.
- Every task names exact files and exact verification commands.
- The plan preserves unrelated work shown by `git status -sb`.
- Any agent tooling work follows the canonical-docs-first model and includes cross-agent companion requirements.
- Destructive or ambiguous actions are represented as explicit approval checkpoints, not assumed implementation steps.

## Agent Surface Notes

- Primary Codex wrapper: `.agents/skills/planning-loop/SKILL.md`.
- Primary Claude Code wrapper: `.claude/skills/planning-loop/SKILL.md`.
- Primary GitHub Copilot wrapper: `.github/skills/planning-loop/SKILL.md`.
- See `docs/agent-workflows/README.md` for the complete accepted companion and rationale-waiver contract.
