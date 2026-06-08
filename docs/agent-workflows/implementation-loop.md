# Implementation Loop

## Purpose

Use this workflow to execute one approved task at a time while preserving unrelated work, validating behavior with the narrowest useful checks, and reporting completion evidence in a repeatable format.

## Inputs

- Approved plan path, issue, or explicit task list with the current task identified.
- Current worktree state from `git status -sb`.
- Relevant instructions from `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, and `ARCHITECTURE.md`.
- Files directly named by the task and nearby implementation, tests, docs, scripts, or project metadata needed to understand the change.
- Task-specific verification commands from the plan, plus repository commands such as `swift run QuiltwrightChecks`, `script/ci.sh package`, `script/ci.sh macos`, `script/ci.sh ios`, `script/ci.sh all`, or `scripts/verify-harness.sh` when relevant.

## Loop

1. Read the task, current `git status -sb`, and all relevant files before editing.
2. Identify unrelated changes and avoid reverting, formatting, or moving them.
3. Choose the smallest coherent edit for the current task; do not start adjacent plan items.
4. Use TDD where feasible: add or update a failing check first when behavior can be expressed in the current test/check structure without introducing new tooling.
5. Make the implementation or documentation change using existing repository patterns.
6. Run targeted checks for the changed surface, then broaden only when the task affects shared behavior, build settings, CI, harness verification, or public APIs.
7. If a check fails, investigate enough to determine whether the failure is caused by the current change, existing worktree state, missing dependencies, or a required user decision.
8. Update the plan checkbox only when the task and its required verification pass.
9. Stop for destructive ambiguity, dependency/tooling changes, unrelated failing checks that need owner input, or scope drift beyond the approved task.

## Output

- Changed files for the single task, with unrelated edits preserved.
- Verification evidence with command names, exit results, and short failure summaries when applicable.
- One status label: `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, or `BLOCKED`.
- A concise handoff noting changed paths, remaining tasks, open questions, and any verification not run.

## Verification

- Relevant files were read before edits.
- Targeted task checks ran and their exit results are reported.
- `git diff --check` passes when source, shell, markdown, or project files were edited.
- `scripts/verify-harness.sh` runs after harness changes, with expected failures explained when another planned task owns the missing pieces.
- The final status matches the evidence: `DONE` only when required checks pass and no known task issue remains; `DONE_WITH_CONCERNS` when the task is complete but an external or future-task concern remains; `NEEDS_CONTEXT` when user input is needed; `BLOCKED` when progress cannot continue without an external change.

## Agent Surface Notes

- Primary Codex wrapper: `.agents/skills/implementation-loop/SKILL.md`.
- Primary Claude Code wrapper: `.claude/skills/implementation-loop/SKILL.md`.
- Primary GitHub Copilot wrapper: `.github/skills/implementation-loop/SKILL.md`.
- See `docs/agent-workflows/README.md` for the complete accepted companion and rationale-waiver contract.
