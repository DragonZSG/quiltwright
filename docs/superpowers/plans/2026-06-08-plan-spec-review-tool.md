# Plan: Plan And Spec Review Tool

## Goal

Add `review-plans-specs`, a focused Quiltwright harness workflow that directs agents to review plans and specs against code quality guidance, established patterns, architecture rules, and repo verification expectations.

## Context

Current branch: `agentic-harness-loops`.

Current worktree state from `git status -sb` includes unrelated existing changes that must be preserved:

- Modified: `.buildkite/pipeline.yml`
- Modified: `.github/copilot-instructions.md`
- Modified: `AGENTS.md`
- Modified: `ARCHITECTURE.md`
- Modified: `CLAUDE.md`
- Modified: `Quiltwright.xcodeproj/project.pbxproj`
- Modified: `docs/adr/001-adopt-harness-engineering.md`
- Modified: `scripts/verify-harness.sh`
- Untracked: `.agents/`
- Untracked: `.claude/`
- Untracked: `.codex/`
- Untracked: `.github/agents/`
- Untracked: `.github/prompts/`
- Untracked: `.github/skills/`
- Untracked: `STYLEGUIDE.md`
- Untracked: `docs/agent-workflows/`
- Untracked: `docs/superpowers/`
- Untracked: `scripts/quality-guard.sh`
- Untracked: `scripts/test-quality-guard.sh`
- Untracked: `scripts/test-verify-harness.sh`

This plan intentionally works with the existing harness changes and does not revert or rewrite unrelated edits.

Source context:

- `docs/superpowers/specs/2026-06-08-plan-spec-review-tool-design.md`
- `docs/agent-workflows/README.md`
- `docs/agent-workflows/manifest.txt`
- `docs/agent-workflows/planning-loop.md`
- `docs/agent-workflows/code-quality-guard.md`
- `STYLEGUIDE.md`
- `AGENTS.md`
- `CLAUDE.md`
- `.github/copilot-instructions.md`
- `scripts/verify-harness.sh`
- `scripts/quality-guard.sh`
- `docs/superpowers/research/2026-06-03-agentic-harness-best-practices.md`

## Scope

In scope:

- Add a canonical `review-plans-specs` workflow.
- Register it in the workflow manifest and README.
- Add Codex, Claude Code, and GitHub Copilot skill wrappers.
- Add reviewer role/manual companions matching existing review workflow patterns.
- Update top-level agent instructions to list the new review workflow.
- Run existing harness verification and fast quality guard.

Out of scope:

- Adding a new shell script or CI step for semantic plan/spec review.
- Changing the deterministic quality guard policy.
- Changing product feature specs, Swift source, Xcode settings, package targets, dependencies, deployment targets, or CI structure.
- Committing, pushing, or opening a PR.

## Task 1: Add Canonical Workflow

Files:

- Create `docs/agent-workflows/review-plans-specs.md`

Responsibilities:

- Define purpose, inputs, loop, output, verification, and agent surface notes.
- Direct reviewers to inspect target plans/specs, repo instructions, `STYLEGUIDE.md`, `ARCHITECTURE.md`, relevant workflow docs, changed paths, and verification evidence.
- Require findings-first output ordered by blocker, major, then minor.
- Require concrete file/line references where possible.
- Require readiness summary, open questions, evidence considered, and missing evidence.
- Make clear that this workflow reviews artifacts and does not edit code unless the user explicitly changes the assignment.

Verification:

- `rg -n "review-plans-specs|Plan And Spec Review" docs/agent-workflows/review-plans-specs.md`
- `rg -n "STYLEGUIDE.md|ARCHITECTURE.md|code-quality-guard|planning-loop" docs/agent-workflows/review-plans-specs.md`

Expected outcome:

- The workflow is concrete, reviewer-scoped, and compatible with existing review-loop style.

## Task 2: Register Workflow

Files:

- Modify `docs/agent-workflows/manifest.txt`
- Modify `docs/agent-workflows/README.md`

Responsibilities:

- Add `review-plans-specs|Plan and spec review loop` to the manifest.
- Add the workflow to the README workflow list.
- Preserve the canonical-docs-first and companion contract language.

Verification:

- `rg -n "review-plans-specs" docs/agent-workflows/manifest.txt docs/agent-workflows/README.md`
- `scripts/verify-harness.sh`

Expected outcome:

- Harness verification discovers the new workflow and reports missing companions until later tasks add them.

Expected failure state:

- After this task alone, `scripts/verify-harness.sh` may fail only because companion artifacts are not yet added. That failure is expected until Task 3 and Task 4 complete.

## Task 3: Add Skill Wrappers

Files:

- Create `.agents/skills/review-plans-specs/SKILL.md`
- Create `.claude/skills/review-plans-specs/SKILL.md`
- Create `.github/skills/review-plans-specs/SKILL.md`

Responsibilities:

- Use metadata name `review-plans-specs`.
- Use a concise description that routes plan/spec review requests.
- Reference `docs/agent-workflows/review-plans-specs.md`.
- Tell the agent to follow the canonical workflow exactly.
- Tell the agent to report findings first and include verification evidence.

Verification:

- `rg -n "name: review-plans-specs|docs/agent-workflows/review-plans-specs.md" .agents/skills/review-plans-specs/SKILL.md .claude/skills/review-plans-specs/SKILL.md .github/skills/review-plans-specs/SKILL.md`
- `scripts/verify-harness.sh`

Expected outcome:

- Primary Codex, Claude Code, and GitHub Copilot skill companions exist and reference the canonical doc.

## Task 4: Add Role And Prompt Companions

Files:

- Create `.codex/agents/review-plans-specs.toml`
- Create `.claude/agents/review-plans-specs.md`
- Create `.github/agents/review-plans-specs.md`
- Create `.github/prompts/review-plans-specs.prompt.md`

Responsibilities:

- Match existing reviewer role conventions.
- Keep reviewer role boundaries explicit: review only unless assignment changes.
- Require findings-first output.
- Reference `docs/agent-workflows/review-plans-specs.md`.
- Include metadata required by `scripts/verify-harness.sh`.

Verification:

- `rg -n "review-plans-specs|docs/agent-workflows/review-plans-specs.md" .codex/agents/review-plans-specs.toml .claude/agents/review-plans-specs.md .github/agents/review-plans-specs.md .github/prompts/review-plans-specs.prompt.md`
- `scripts/verify-harness.sh`

Expected outcome:

- Role/manual companions are aligned with existing review workflows and pass harness metadata/reference checks.

## Task 5: Update Agent Instructions

Files:

- Modify `AGENTS.md`
- Modify `CLAUDE.md`
- Modify `.github/copilot-instructions.md`

Responsibilities:

- Add `review-plans-specs` to the review workflow list.
- Preserve sync comments and existing command guidance.
- Do not alter commands, module boundaries, deployment targets, or unrelated policy.

Verification:

- `rg -n "review-plans-specs" AGENTS.md CLAUDE.md .github/copilot-instructions.md`
- `scripts/verify-harness.sh`

Expected outcome:

- Always-loaded agent guidance exposes the new review workflow across Codex, Claude Code, and GitHub Copilot.

## Task 6: Consider Architecture Documentation

Files:

- Inspect `ARCHITECTURE.md`

Responsibilities:

- Determine whether the existing agent workflow/module map language already covers the new workflow by directory rather than by enumerated slug.
- Only modify `ARCHITECTURE.md` if the current text needs an explicit workflow list update.

Verification:

- If modified: `rg -n "review-plans-specs" ARCHITECTURE.md`
- Always: `scripts/verify-harness.sh`

Expected outcome:

- Architecture docs remain accurate without unnecessary churn.

## Task 7: Run Final Verification

Files:

- No planned edits.

Responsibilities:

- Run the deterministic harness and quality checks.
- Report failures with command, exit result, and failure shape.
- Do not disable or narrow checks to make failures disappear.

Verification:

- `scripts/verify-harness.sh`
- `scripts/quality-guard.sh --fast`

Expected outcome:

- Harness verification passes.
- Fast quality guard passes, or any failure is clearly reported with the blocking reason.

## Review Checkpoints

- Run `review-plans-specs` against this plan before implementation if another agent is available or if the user requests a review pass.
- Run `review-security-privacy` if adding hooks or broad tool access becomes part of scope. It is out of scope in this plan.
- Run `code-quality-guard` before handoff after implementation.

## Stop Conditions

Stop and ask before:

- Adding new scripts or CI steps.
- Changing `scripts/quality-guard.sh` behavior.
- Changing deployment targets, dependencies, package products, schemes, or Xcode settings.
- Editing product feature specs as part of this harness change.
- Reverting or rewriting unrelated worktree changes.

## Handoff

Recommended next task: Task 1, add the canonical workflow document.

Approval needed before implementation: none for the planned files, because the user approved the new review workflow and all planned changes are harness/docs companions. Approval is still required if implementation discovers a need for new scripts, hooks, CI structure, dependencies, or project settings.
