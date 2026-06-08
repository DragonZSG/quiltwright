# Plan And Spec Review Loop

## Purpose

Use this focused evaluator workflow to review Quiltwright plans, specs, and harness proposals before implementation or handoff. The review checks whether the artifact follows repository guidance, established patterns, architecture rules, quality expectations, and verification discipline.

## Inputs

- Target plan or spec files, plus any user-stated scope, approvals, constraints, and ownership boundaries.
- Current worktree state from `git status -sb`, including unrelated edits that the artifact must preserve.
- Repository guidance from `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, `STYLEGUIDE.md`, and `ARCHITECTURE.md`.
- Canonical workflow context from `docs/agent-workflows/planning-loop.md`, `docs/agent-workflows/implementation-loop.md`, `docs/agent-workflows/code-quality-guard.md`, and any focused review workflows relevant to the artifact.
- Related plans, specs, ADRs, research notes, source files, scripts, package/project metadata, and CI files named by the artifact.
- Verification evidence already produced, such as `scripts/verify-harness.sh`, `scripts/quality-guard.sh --fast`, `swift run QuiltwrightChecks`, or `script/ci.sh all` output.

## Loop

1. Read the target artifact, current `git status -sb`, and relevant repo guidance before forming findings.
2. Check that the artifact restates the goal concretely, stays inside user-approved scope, and names explicit approval checkpoints for destructive or boundary-crossing work.
3. For plans, verify that every task names exact files, file responsibilities, verification commands, expected outcomes, sequencing dependencies, risks, and stop conditions.
4. For specs, verify that requirements are concrete, internally consistent, scoped, testable, and free of hidden implementation assumptions or unresolved placeholders.
5. Check that proposed files, modules, dependencies, public APIs, commands, and agent surfaces match `ARCHITECTURE.md`, `STYLEGUIDE.md`, and established local patterns.
6. For harness or agent-tooling artifacts, verify the canonical-docs-first model, cross-agent companion coverage, role/prompt metadata, and rationale-waiver requirements from `docs/agent-workflows/README.md`.
7. Check that verification commands are exact, risk-scaled, and compatible with repository commands. Plans/specs must not weaken, skip, or replace required checks without explicit approval.
8. Identify whether missing evidence limits confidence, such as absent command output, missing source reads, unstated worktree state, or unreviewed companion surfaces.
9. Separate blockers, major issues, and minor issues from optional improvements. Do not request unrelated refactors, new tooling, dependency changes, or broader scope unless the artifact already requires them.

## Output

- Findings first, ordered by severity: blocker, major, then minor.
- Each finding includes a concrete file and line reference where possible, impact, reasoning, and a specific remediation direction.
- Open questions and assumptions after findings.
- A short readiness summary after questions.
- Verification evidence considered, plus missing evidence that affects confidence.
- A clear statement when no plan/spec issues were found.

## Verification

- Review cites the target plan or spec and the repo guidance considered.
- Review checks scope, approval boundaries, exact file lists, exact commands, expected outcomes, risks, stop conditions, and preservation of unrelated work.
- Review checks `STYLEGUIDE.md`, `ARCHITECTURE.md`, current workflow docs, and established local patterns before making style or pattern findings.
- Review checks cross-agent companion requirements for any harness, skill, agent, hook, prompt, or quality-guard work.
- Review distinguishes deterministic guard failures from judgment findings and does not replace `scripts/quality-guard.sh`.

## Agent Surface Notes

- Primary Codex wrapper: `.agents/skills/review-plans-specs/SKILL.md`.
- Primary Claude Code wrapper: `.claude/skills/review-plans-specs/SKILL.md`.
- Primary GitHub Copilot wrapper: `.github/skills/review-plans-specs/SKILL.md`.
- See `docs/agent-workflows/README.md` for the complete accepted companion and rationale-waiver contract.
