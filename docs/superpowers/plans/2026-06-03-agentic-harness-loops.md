# Agentic Harness Loops Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Add a complete multi-agent harness for planning, implementation loops, focused review loops, a code quality guard, and a project style guide across Codex, Claude Code, and GitHub Copilot.

**Architecture:** Keep canonical workflow content in `docs/agent-workflows/`, then expose each workflow through agent-specific surfaces: Codex skills in `.agents/skills/`, Claude Code skills in `.claude/skills/`, and GitHub Copilot skills in `.github/skills/`. Add custom agent profiles for role-specific planning, implementation, and review loops where tool scope or isolated context matters. Keep prompt files as optional manual Copilot entrypoints, and use hooks only for deterministic policy or validation. Extend `scripts/verify-harness.sh` so CI fails when a required workflow is missing from any supported surface or lacks an explicit `docs/agent-tooling/<name>.md` rationale.

**Tech Stack:** Markdown, Bash, SwiftPM/Xcode existing commands, Buildkite existing pipeline, Codex `AGENTS.md`, `.agents/skills`, `.codex/agents`, and optional `.codex` hooks; Claude Code `CLAUDE.md`, `.claude/skills`, `.claude/agents`, and optional `.claude` hooks; GitHub Copilot `.github/copilot-instructions.md`, `.github/skills`, `.github/agents`, `.github/prompts`, `.github/instructions`, and optional `.github/hooks`.

**Status:** Completed on branch `agentic-harness-loops` on 2026-06-03. This file is retained as the implementation record; do not rerun it as an active plan unless a new task explicitly reopens the harness design.

---

## Scope

This plan implements the missing harness structures identified after the foundational harness:

- Planning agent loop
- Implementation loop agents
- Differently focused review loop agents
- Code quality guard
- Project style guide
- Cross-agent equivalents for Codex, Claude Code, and GitHub Copilot

No Swift package dependencies, SwiftLint, SwiftFormat, XCTest migration, or app behavior changes are included.

## Completion State

The branch now contains the planned harness artifacts:

- Canonical workflow docs and manifest in `docs/agent-workflows/`.
- Codex skills in `.agents/skills/` and role agents in `.codex/agents/`.
- Claude Code skills in `.claude/skills/` and role agents in `.claude/agents/`.
- GitHub Copilot skills in `.github/skills/`, role agents in `.github/agents/`, and prompt entrypoints in `.github/prompts/`.
- `STYLEGUIDE.md`, `scripts/quality-guard.sh`, `scripts/test-quality-guard.sh`, and expanded verifier coverage.
- Buildkite quality guard integration after harness verification.

All checklist items below are marked complete because the implementation has been performed and verified. Treat the detailed task text as historical execution notes.

## Research Gate

Before creating any workflow guidance, skills, agents, prompts, hooks, or style guide content, use the source-backed findings in `docs/superpowers/research/2026-06-03-agentic-harness-best-practices.md`.

This gate supersedes the earlier Copilot-only prompt-wrapper assumption in this plan. The implementation must revise the task details before execution so each workflow has:

- Canonical workflow documentation in `docs/agent-workflows/<workflow>.md`.
- Codex skill companion in `.agents/skills/<workflow>/SKILL.md`.
- Claude Code skill companion in `.claude/skills/<workflow>/SKILL.md`.
- GitHub Copilot skill companion in `.github/skills/<workflow>/SKILL.md`.
- Optional GitHub Copilot prompt companion in `.github/prompts/<workflow>.prompt.md` only when a manually invoked slash command is useful.
- Custom agent companions for role-specific planning, implementation, and focused review loops:
  - Codex: `.codex/agents/<role>.toml`
  - Claude Code: `.claude/agents/<role>.md`
  - GitHub Copilot: `.github/agents/<role>.md`
- Optional hooks only when deterministic policy, lifecycle automation, or validation is required:
  - Codex: `.codex/hooks.json` or inline `.codex/config.toml` hooks
  - Claude Code: `.claude/settings.json` or skill/agent frontmatter hooks
  - GitHub Copilot: `.github/hooks/*.json`

Also revise `scripts/verify-harness.sh` so it detects and enforces `.github/skills`, `.github/agents`, `.github/hooks`, `.codex/agents`, and `.claude/agents` where those surfaces are part of a workflow.

## Implementation Notes

As of the final verification pass on 2026-06-03, the working tree contains the Task 1 through Task 5 artifacts: canonical workflow docs and manifest, Codex skills, Claude Code skills, GitHub Copilot skills, optional Copilot prompts, role agents under `.codex/agents`, `.claude/agents`, and `.github/agents`, the style guide, the quality guard, and the updated verifier/test coverage.

Any older task text below that names `.github/prompts/<workflow>.prompt.md` as the required GitHub Copilot equivalent is superseded. The required Copilot workflow surface is `.github/skills/<workflow>/SKILL.md`; `.github/agents/<role>.md` covers role-specific agents; `.github/prompts/<workflow>.prompt.md` remains an optional manual entrypoint.

## File Structure

Create:

- `STYLEGUIDE.md` - Project style guide for Swift, SwiftUI, docs, and agent artifacts.
- `docs/agent-workflows/README.md` - Index of available workflow loops.
- `docs/agent-workflows/manifest.txt` - Required workflow slugs and labels for the verifier.
- `docs/agent-workflows/planning-loop.md` - Canonical planning workflow.
- `docs/agent-workflows/implementation-loop.md` - Canonical implementation loop workflow.
- `docs/agent-workflows/review-architecture.md` - Architecture review workflow.
- `docs/agent-workflows/review-tests.md` - Test review workflow.
- `docs/agent-workflows/review-security-privacy.md` - Security/privacy review workflow.
- `docs/agent-workflows/review-ui-platform.md` - SwiftUI/platform review workflow.
- `docs/agent-workflows/review-performance.md` - Performance review workflow.
- `docs/agent-workflows/code-quality-guard.md` - Code quality guard workflow.
- `.agents/skills/<workflow>/SKILL.md` - Codex skill wrappers for every manifest workflow.
- `.claude/skills/<workflow>/SKILL.md` - Claude Code skill wrappers for every manifest workflow.
- `.github/skills/<workflow>/SKILL.md` - GitHub Copilot skill wrappers for every manifest workflow.
- `.github/prompts/<workflow>.prompt.md` - Optional GitHub Copilot prompt wrappers for manually invoked workflows.
- `.codex/agents/<role>.toml` - Codex custom agents for planning, implementation, and focused review roles.
- `.claude/agents/<role>.md` - Claude Code subagents for planning, implementation, and focused review roles.
- `.github/agents/<role>.md` - GitHub Copilot custom agents for planning, implementation, and focused review roles.
- `scripts/quality-guard.sh` - Local guard command that runs harness verification, targeted workflow verification, SwiftPM checks, and optionally full CI.
- `scripts/test-quality-guard.sh` - Smoke tests for quality guard argument behavior.

Modify:

- `AGENTS.md` - Link workflows, style guide, quality guard, and cross-agent expectations.
- `CLAUDE.md` - Same.
- `.github/copilot-instructions.md` - Same, concise for Copilot.
- `ARCHITECTURE.md` - Add harness workflow directories to the module map.
- `.buildkite/pipeline.yml` - Add a quality guard step after harness verification.
- `scripts/verify-harness.sh` - Check required workflows from `docs/agent-workflows/manifest.txt`, not only discovered workflow artifacts.
- `scripts/test-verify-harness.sh` - Add a fixture proving manifest-required workflows fail when missing.

## Workflow Manifest

Use this exact manifest format so Bash can parse it without YAML dependencies:

```text
planning-loop|Planning loop
implementation-loop|Implementation loop
review-architecture|Architecture review loop
review-tests|Test review loop
review-security-privacy|Security and privacy review loop
review-ui-platform|SwiftUI and platform review loop
review-performance|Performance review loop
code-quality-guard|Code quality guard
```

Do not add `style-guide` to the workflow manifest. `STYLEGUIDE.md` is a standing reference, not an invokable workflow.

## Canonical Workflow Contract

Every `docs/agent-workflows/<workflow>.md` file must include:

```markdown
# <Title>

## Purpose

One paragraph describing when to use this workflow.

## Inputs

- Required repository context.
- Required user request or task artifact.

## Loop

1. Gather context.
2. Produce or update the working artifact.
3. Run the workflow-specific verification command.
4. Report findings, blockers, and next action.

## Output

- Files or report the workflow produces.
- Verification evidence required before handoff.

## Agent Surface Notes

- Codex: exposed through `.agents/skills/<workflow>/SKILL.md`.
- Claude Code: exposed through `.claude/skills/<workflow>/SKILL.md`.
- GitHub Copilot: exposed through `.github/skills/<workflow>/SKILL.md`, with optional `.github/prompts/<workflow>.prompt.md` for manual entrypoints.
```

Each actual workflow should replace the generic text with specific inputs, loop steps, outputs, and verification.

## Research Revision Task

Before Task 1, rewrite the remaining task details in this plan to match the research gate above. In particular, replace the "GitHub Copilot prompt wrappers for every manifest workflow" assumption with "GitHub Copilot skills for every manifest workflow, plus prompt files only where useful", and add custom agent tasks for planning, implementation, and each focused review loop.

## Agent Wrapper Contract

For each workflow in `manifest.txt`, create the primary skill companions below. Add GitHub Copilot prompt companions only when a manually invoked entrypoint is useful.

Codex skill:

```markdown
---
name: <workflow>
description: Use this workflow for <short trigger phrase>.
---

# <Title>

Read `docs/agent-workflows/<workflow>.md` before acting. Follow that workflow exactly, then report the verification evidence it requires.
```

Claude Code skill:

```markdown
---
name: <workflow>
description: Use this workflow for <short trigger phrase>.
---

# <Title>

Read `docs/agent-workflows/<workflow>.md` before acting. Follow that workflow exactly, then report the verification evidence it requires.
```

GitHub Copilot skill:

```markdown
---
name: <workflow>
description: Use this workflow for <short trigger phrase>.
---

# <Title>

Read `docs/agent-workflows/<workflow>.md` before acting. Follow that workflow exactly, then report the verification evidence it requires.
```

Optional GitHub Copilot prompt:

```markdown
# <Title>

Use the repository workflow in `docs/agent-workflows/<workflow>.md`.

Follow the loop, keep changes scoped, and report the verification evidence required by that workflow.
```

## Task 0: Preserve Current Cross-Agent Guard Work

**Files:**
- Modify: `AGENTS.md`
- Modify: `CLAUDE.md`
- Modify: `.github/copilot-instructions.md`
- Modify: `scripts/verify-harness.sh`
- Create: `scripts/test-verify-harness.sh`

- [x] **Step 1: Confirm the current uncommitted verifier tests pass**

Run:

```bash
scripts/test-verify-harness.sh
scripts/verify-harness.sh
```

Expected:

```text
[PASS] unpaired Codex skill fails with companion errors
[PASS] paired skill passes
[PASS] rationale file can intentionally waive missing companions
...
Verification PASSED.
```

- [x] **Step 2: Keep these files in the implementation branch**

Run:

```bash
git status -sb
```

Expected: the five current cross-agent files remain modified/untracked until committed with the first implementation batch.

## Task 1: Add Canonical Workflow Index and Manifest

**Files:**
- Create: `docs/agent-workflows/README.md`
- Create: `docs/agent-workflows/manifest.txt`
- Modify: `scripts/verify-harness.sh`
- Modify: `scripts/test-verify-harness.sh`

- [x] **Step 1: Write failing manifest test**

Add this test function to `scripts/test-verify-harness.sh`:

```bash
expect_failure_for_missing_manifest_workflow() {
  local fixture="$TMP_ROOT/missing-manifest-workflow"
  copy_base_fixture "$fixture"

  mkdir -p "$fixture/docs/agent-workflows"
  cat > "$fixture/docs/agent-workflows/manifest.txt" <<'MANIFEST'
planning-loop|Planning loop
MANIFEST

  if (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/missing-manifest.out" 2>&1); then
    echo "Expected verify-harness to fail for missing manifest workflow companions." >&2
    cat "$TMP_ROOT/missing-manifest.out" >&2
    exit 1
  fi

  if grep -Fq "planning-loop missing Codex companion" "$TMP_ROOT/missing-manifest.out" &&
    grep -Fq "planning-loop missing Claude Code companion" "$TMP_ROOT/missing-manifest.out" &&
    grep -Fq "planning-loop missing GitHub Copilot companion" "$TMP_ROOT/missing-manifest.out"; then
    echo "[PASS] manifest-required workflow fails without companions"
  else
    echo "Expected missing companion messages for manifest-required workflow." >&2
    cat "$TMP_ROOT/missing-manifest.out" >&2
    exit 1
  fi
}
```

Call it before the existing success fixtures:

```bash
expect_failure_for_missing_manifest_workflow
expect_failure_for_unpaired_codex_skill
expect_success_for_paired_skill
expect_success_for_rationale_file
```

- [x] **Step 2: Run the test and verify RED**

Run:

```bash
scripts/test-verify-harness.sh
```

Expected: FAIL because `scripts/verify-harness.sh` does not yet read `docs/agent-workflows/manifest.txt`.

- [x] **Step 3: Create `docs/agent-workflows/manifest.txt`**

```text
planning-loop|Planning loop
implementation-loop|Implementation loop
review-architecture|Architecture review loop
review-tests|Test review loop
review-security-privacy|Security and privacy review loop
review-ui-platform|SwiftUI and platform review loop
review-performance|Performance review loop
code-quality-guard|Code quality guard
```

- [x] **Step 4: Create `docs/agent-workflows/README.md`**

```markdown
# Agent Workflows

This directory contains canonical workflow loops used by Codex, Claude Code, and GitHub Copilot.

Each workflow listed in `manifest.txt` must have equivalent agent surfaces:

- Codex: `.agents/skills/<workflow>/SKILL.md`
- Claude Code: `.claude/skills/<workflow>/SKILL.md`
- GitHub Copilot: `.github/skills/<workflow>/SKILL.md`
- Optional GitHub Copilot prompt: `.github/prompts/<workflow>.prompt.md`

If a workflow intentionally cannot support one of those surfaces, add `docs/agent-tooling/<workflow>.md` explaining why.

## Workflows

- `planning-loop` - Turn requests into scoped specs and implementation plans.
- `implementation-loop` - Execute planned work in small verified batches.
- `review-architecture` - Review module boundaries, dependency direction, and architectural fit.
- `review-tests` - Review test coverage, failure quality, and regression risk.
- `review-security-privacy` - Review secrets, permissions, privacy, and platform security risks.
- `review-ui-platform` - Review SwiftUI, macOS/iOS platform behavior, and accessibility.
- `review-performance` - Review responsiveness, build cost, and runtime performance risks.
- `code-quality-guard` - Run deterministic checks and report completion evidence.
```

- [x] **Step 5: Update `scripts/verify-harness.sh` to read the manifest**

Insert this before checking `workflow_names`:

```bash
if [[ -f docs/agent-workflows/manifest.txt ]]; then
  while IFS='|' read -r workflow_name workflow_label; do
    [[ -n "$workflow_name" ]] || continue
    [[ "$workflow_name" == \#* ]] && continue
    add_workflow_name "$workflow_name"
  done < docs/agent-workflows/manifest.txt
fi
```

- [x] **Step 6: Run the test and verify GREEN**

Run:

```bash
scripts/test-verify-harness.sh
```

Expected: `scripts/test-verify-harness.sh` exits 0 because its fixture expects manifest-required workflows to fail when companions are missing. Running `scripts/verify-harness.sh` on the real repo may fail until Tasks 2 through 5 add all required companions.

## Task 2: Add Planning Loop Artifacts

**Files:**
- Create: `docs/agent-workflows/planning-loop.md`
- Create: `.agents/skills/planning-loop/SKILL.md`
- Create: `.claude/skills/planning-loop/SKILL.md`
- Create: `.github/skills/planning-loop/SKILL.md`
- Optional manual companion: `.github/prompts/planning-loop.prompt.md`

- [x] **Step 1: Create canonical planning workflow**

Use this content for `docs/agent-workflows/planning-loop.md`:

```markdown
# Planning Loop

## Purpose

Use this workflow when a request needs more than a direct edit: new features, multi-file harness work, architecture changes, or work that should be decomposed before implementation.

## Inputs

- The user's goal.
- Current repository state from `git status -sb`.
- Relevant architecture and harness docs.
- Known constraints, including approval boundaries and unavailable tooling.

## Loop

1. Gather context from `AGENTS.md`, `ARCHITECTURE.md`, relevant source files, and existing docs.
2. Restate the goal in one sentence.
3. Identify the smallest useful scope that can be implemented and verified.
4. List files to create or modify with their responsibility.
5. Split work into tasks that each produce a verifiable state.
6. Define exact verification commands and expected outcomes.
7. Call out blockers, open questions, and items intentionally out of scope.

## Output

- A saved implementation plan under `docs/superpowers/plans/`.
- A short chat summary with plan path, scope, risks, and recommended execution mode.

## Verification

- Plan has no placeholder sections.
- Every task has exact files and verification commands.
- Plan respects cross-agent companion rules for any new agent tooling.

## Agent Surface Notes

- Codex: exposed through `.agents/skills/planning-loop/SKILL.md`.
- Claude Code: exposed through `.claude/skills/planning-loop/SKILL.md`.
- GitHub Copilot: exposed through `.github/skills/planning-loop/SKILL.md`, with optional `.github/prompts/planning-loop.prompt.md`.
```

- [x] **Step 2: Create Codex skill**

```markdown
---
name: planning-loop
description: Use when turning a request into a scoped implementation plan before editing code or harness artifacts.
---

# Planning Loop

Read `docs/agent-workflows/planning-loop.md` before acting. Follow that workflow exactly, then report the plan path and verification evidence it requires.
```

- [x] **Step 3: Create Claude Code skill**

Create `.claude/skills/planning-loop/SKILL.md`:

```markdown
---
name: planning-loop
description: Use when turning a request into a scoped implementation plan before editing code or harness artifacts.
---

# Planning Loop

Read `docs/agent-workflows/planning-loop.md` before acting. Follow that workflow exactly, then report the plan path and verification evidence it requires.
```

- [x] **Step 4: Create GitHub Copilot skill and optional prompt**

Create `.github/skills/planning-loop/SKILL.md` using the Agent Wrapper Contract. If a manual prompt entrypoint is useful, also create:

```markdown
# Planning Loop

Use the repository workflow in `docs/agent-workflows/planning-loop.md`.

Turn the request into a scoped implementation plan. Include exact files, tasks, verification commands, and open questions. Do not implement the plan unless explicitly asked.
```

- [x] **Step 5: Verify planning companions**

Run:

```bash
scripts/verify-harness.sh
```

Expected: any remaining failures are for workflows not yet implemented, not `planning-loop`.

## Task 3: Add Implementation Loop Artifacts

**Files:**
- Create: `docs/agent-workflows/implementation-loop.md`
- Create: `.agents/skills/implementation-loop/SKILL.md`
- Create: `.claude/skills/implementation-loop/SKILL.md`
- Create: `.github/skills/implementation-loop/SKILL.md`
- Optional manual companion: `.github/prompts/implementation-loop.prompt.md`

- [x] **Step 1: Create canonical implementation workflow**

```markdown
# Implementation Loop

## Purpose

Use this workflow when executing a saved plan or an approved task list.

## Inputs

- Approved plan path or explicit task list.
- Current `git status -sb`.
- Relevant architecture, style, and harness docs.

## Loop

1. Read the plan and identify the next unchecked task.
2. Confirm current worktree state and avoid overwriting unrelated changes.
3. Make the smallest coherent edit for the current task.
4. Run the task-specific verification command.
5. Update the plan checkbox only after verification passes.
6. Report changed files, verification evidence, and next task.
7. Stop at review checkpoints or blockers.

## Output

- Implemented files for the current task.
- Updated plan checkboxes.
- Verification evidence for the task.

## Verification

- Task-specific command passes.
- `git diff --check` passes.
- `scripts/verify-harness.sh` passes after harness changes.

## Agent Surface Notes

- Codex: exposed through `.agents/skills/implementation-loop/SKILL.md`.
- Claude Code: exposed through `.claude/skills/implementation-loop/SKILL.md`.
- GitHub Copilot: exposed through `.github/skills/implementation-loop/SKILL.md`, with optional `.github/prompts/implementation-loop.prompt.md`.
```

- [x] **Step 2: Create Codex and Claude skills**

Each `SKILL.md`:

```markdown
---
name: implementation-loop
description: Use when executing an approved plan task-by-task with verification after each task.
---

# Implementation Loop

Read `docs/agent-workflows/implementation-loop.md` before acting. Execute only the next approved task, then report changed files and verification evidence.
```

- [x] **Step 3: Create GitHub Copilot skill and optional prompt**

Create `.github/skills/implementation-loop/SKILL.md` using the Agent Wrapper Contract. If a manual prompt entrypoint is useful, also create:

```markdown
# Implementation Loop

Use `docs/agent-workflows/implementation-loop.md`.

Execute the next approved plan task only. Keep edits scoped, run verification, and report changed files plus command output summary.
```

## Task 4: Add Focused Review Loop Artifacts

**Files:**
- Create canonical docs, Codex skills, Claude Code skills, GitHub Copilot skills, and optional Copilot prompts for:
  - `review-architecture`
  - `review-tests`
  - `review-security-privacy`
  - `review-ui-platform`
  - `review-performance`

- [x] **Step 1: Create review workflow docs**

For each review workflow, use this structure and the focus-specific content below:

```markdown
# <Title>

## Purpose

Use this workflow to review changes from the named focus area before merge or handoff.

## Inputs

- Current diff from `git diff` or `git diff origin/main...HEAD`.
- Relevant architecture, style, and harness docs.
- Latest verification command output.

## Loop

1. Read the diff and relevant docs.
2. Identify issues in severity order.
3. Prefer concrete file/line findings over general advice.
4. Separate blocking defects from follow-up recommendations.
5. Recommend exact verification needed after fixes.

## Output

- Findings first, ordered by severity.
- Open questions or assumptions.
- Short change summary only after findings.

## Verification

- Review cites specific files and line references where possible.
- Review does not request unrelated refactors.
- Review does not approve without verification evidence.
```

Focus-specific additions:

```text
review-architecture: module boundaries, dependency direction, target membership, ADR needs.
review-tests: regression coverage, meaningful failures, SwiftPM check coverage, XCTest gaps.
review-security-privacy: secrets, signing material, entitlements, permissions, privacy-sensitive data.
review-ui-platform: SwiftUI structure, macOS/iOS platform differences, accessibility, shared UI neutrality.
review-performance: build cost, SwiftUI update cost, responsiveness, avoid premature optimization.
```

Use these exact titles and skill descriptions:

```text
review-architecture|Architecture Review Loop|Use when performing a focused architecture review of a diff or completed task.
review-tests|Test Review Loop|Use when performing a focused test coverage and regression-risk review of a diff or completed task.
review-security-privacy|Security and Privacy Review Loop|Use when performing a focused security and privacy review of a diff or completed task.
review-ui-platform|SwiftUI and Platform Review Loop|Use when performing a focused SwiftUI, platform behavior, and accessibility review of a diff or completed task.
review-performance|Performance Review Loop|Use when performing a focused build, runtime, and UI responsiveness review of a diff or completed task.
```

- [x] **Step 2: Create Codex and Claude review skills**

For each review workflow, create `SKILL.md` with:

```markdown
---
name: <workflow>
description: Use when performing a focused <focus> review of a diff or completed task.
---

# <Title>

Read `docs/agent-workflows/<workflow>.md` before acting. Produce findings first, ordered by severity, with verification evidence and concrete file references.
```

- [x] **Step 3: Create GitHub Copilot review skills and optional prompts**

For each review workflow, create `.github/skills/<workflow>/SKILL.md` using the Agent Wrapper Contract. If a manual prompt entrypoint is useful, also create:

```markdown
# <Title>

Use `docs/agent-workflows/<workflow>.md`.

Review the current diff from this focus area. Lead with concrete findings ordered by severity, then list open questions and verification gaps.
```

## Task 5: Add Code Quality Guard

**Status update, 2026-06-03:** Implemented in the current working tree. The workflow doc, Codex/Claude Code/GitHub Copilot skills, optional Copilot prompt, `scripts/quality-guard.sh`, `scripts/test-quality-guard.sh`, and Buildkite quality guard wiring already exist. The older red/green creation recipe below is retained as historical planning context only; do not recreate or overwrite the implemented guard with the minimal snippet shown here. Future agents should inspect the existing scripts and update them incrementally.

**Files:**
- Create: `docs/agent-workflows/code-quality-guard.md`
- Create: `.agents/skills/code-quality-guard/SKILL.md`
- Create: `.claude/skills/code-quality-guard/SKILL.md`
- Create: `.github/skills/code-quality-guard/SKILL.md`
- Optional manual companion: `.github/prompts/code-quality-guard.prompt.md`
- Create: `scripts/quality-guard.sh`
- Create: `scripts/test-quality-guard.sh`
- Modify: `.buildkite/pipeline.yml`

- [x] **Step 1: Write failing guard CLI tests**

Create `scripts/test-quality-guard.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

if ! bash -n scripts/quality-guard.sh; then
  echo "quality-guard.sh has invalid Bash syntax" >&2
  exit 1
fi

if ! scripts/quality-guard.sh --help | grep -Fq "Usage: scripts/quality-guard.sh [--fast|--full]"; then
  echo "quality-guard.sh help output is missing expected usage" >&2
  exit 1
fi

echo "[PASS] quality guard CLI smoke tests passed"
```

Run:

```bash
scripts/test-quality-guard.sh
```

Expected: FAIL because `scripts/quality-guard.sh` does not exist yet.

- [x] **Step 2: Create `scripts/quality-guard.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

MODE="${1:---fast}"

usage() {
  echo "Usage: scripts/quality-guard.sh [--fast|--full]"
}

case "$MODE" in
  --fast)
    scripts/verify-harness.sh
    swift run QuiltwrightChecks
    git diff --check
    ;;
  --full)
    scripts/verify-harness.sh
    script/ci.sh all
    git diff --check
    ;;
  --help|-h)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
```

- [x] **Step 3: Make guard scripts executable**

Run:

```bash
chmod +x scripts/quality-guard.sh scripts/test-quality-guard.sh
```

- [x] **Step 4: Create canonical guard workflow and companions**

`docs/agent-workflows/code-quality-guard.md`:

```markdown
# Code Quality Guard

## Purpose

Use this workflow before claiming work is complete, before committing, and before requesting review.

## Inputs

- Current worktree state.
- Scope of changes.
- Latest command outputs.

## Loop

1. Run `scripts/quality-guard.sh --fast` for documentation, harness, or shared UI changes.
2. Run `scripts/quality-guard.sh --full` for build-affecting changes.
3. Read output and fix failures at the source.
4. Report exact commands run and whether they exited 0.

## Output

- Verification summary with command names and outcomes.
- Remaining warnings or intentionally skipped checks.

## Verification

- The selected guard command exits 0.
- No completion claim is made without fresh output.
```

Create the three wrappers using the Agent Wrapper Contract.

- [x] **Step 5: Wire Buildkite quality guard**

Add a Buildkite step after `verify-harness`:

```yaml
  - label: ":shield: Quality guard"
    key: "quality-guard"
    command: "scripts/quality-guard.sh --fast"
    depends_on: "verify-harness"
```

## Task 6: Add Style Guide

**Files:**
- Create: `STYLEGUIDE.md`
- Modify: `AGENTS.md`
- Modify: `CLAUDE.md`
- Modify: `.github/copilot-instructions.md`
- Modify: `ARCHITECTURE.md`

- [x] **Step 1: Create `STYLEGUIDE.md`**

```markdown
# Style Guide

## Swift

- Use Swift file names that match the primary type.
- Prefer small value types for shared presentation state.
- Keep public shared APIs platform-neutral unless explicitly guarded.
- Use 4-space indentation, final newlines, and no trailing whitespace.

## SwiftUI

- Keep app entry points thin.
- Put reusable views and presentation data in `Sources/QuiltwrightUI`.
- Avoid macOS-only or iOS-only APIs in shared UI without platform guards.
- Prefer accessible system symbols and text that works with Dynamic Type.

## Tests and Checks

- Add `QuiltwrightChecks` coverage for shared model or presentation behavior.
- Run `swift run QuiltwrightChecks` after shared UI changes.
- Run `script/ci.sh all` after build, target, project, or CI changes.

## Agent Artifacts

- Keep canonical workflow content in `docs/agent-workflows/`.
- Keep Codex, Claude Code, and GitHub Copilot wrappers equivalent.
- Use `docs/agent-tooling/<name>.md` only when a missing companion is intentionally N/A.
- Run `scripts/verify-harness.sh` after changing any harness artifact.
```

- [x] **Step 2: Link style guide from agent docs**

Add to each agent instruction file near conventions:

```markdown
For detailed project style rules, see [STYLEGUIDE.md](./STYLEGUIDE.md).
```

For `.github/copilot-instructions.md`, use:

```markdown
For detailed project style rules, see `STYLEGUIDE.md`.
```

- [x] **Step 3: Add style guide to `ARCHITECTURE.md` module map**

Add a row:

```markdown
| Style guide | `STYLEGUIDE.md` | Documentation | Swift, SwiftUI, test, and agent artifact style rules. | Existing project conventions | Developers, agents, reviews |
```

## Task 7: Update Harness Documentation

**Files:**
- Modify: `AGENTS.md`
- Modify: `CLAUDE.md`
- Modify: `.github/copilot-instructions.md`
- Modify: `ARCHITECTURE.md`
- Modify: `docs/adr/001-adopt-harness-engineering.md`

- [x] **Step 1: Add commands**

Add:

```text
quality:        scripts/quality-guard.sh --fast
quality:full:   scripts/quality-guard.sh --full
verify:test:    scripts/test-verify-harness.sh
```

- [x] **Step 2: Add workflow overview**

Add a short section:

```markdown
## Agent Workflows

Canonical workflow loops live in `docs/agent-workflows/`.

- Planning: `planning-loop`
- Implementation: `implementation-loop`
- Reviews: `review-architecture`, `review-tests`, `review-security-privacy`, `review-ui-platform`, `review-performance`
- Guard: `code-quality-guard`
```

- [x] **Step 3: Update ADR-001 consequences**

Add:

```markdown
- Multi-agent workflow loops are checked into the repo and verified across Codex, Claude Code, and GitHub Copilot surfaces.
- The quality guard provides a single command for completion evidence.
```

## Task 8: Final Verification

**Files:**
- All changed files.

- [x] **Step 1: Run syntax checks**

Run:

```bash
bash -n scripts/verify-harness.sh
bash -n scripts/test-verify-harness.sh
bash -n scripts/quality-guard.sh
bash -n scripts/test-quality-guard.sh
```

Expected: all exit 0.

- [x] **Step 2: Run harness tests**

Run:

```bash
scripts/test-verify-harness.sh
scripts/test-quality-guard.sh
scripts/verify-harness.sh
```

Expected:

```text
[PASS] unpaired Codex skill fails with companion errors
[PASS] paired skill passes
[PASS] rationale file can intentionally waive missing companions
[PASS] manifest-required workflow fails without companions
[PASS] quality guard CLI smoke tests passed
...
Verification PASSED.
```

- [x] **Step 3: Run project checks**

Run:

```bash
scripts/quality-guard.sh --full
```

Expected:

```text
Verification PASSED.
Build of product 'QuiltwrightChecks' complete!
```

Xcode may emit the existing duplicate macOS destination warning; that is not a failure if the command exits 0.

- [x] **Step 4: Review final diff**

Run:

```bash
git diff --check
git status -sb
git diff --stat
```

Expected: no whitespace errors; status shows only intended harness files.

## Commit Strategy

Use two commits if implementing interactively:

1. `Tighten cross-agent harness verification`
   - Current uncommitted verifier/doc changes.
   - `scripts/test-verify-harness.sh`.

2. `Add agent workflow loops`
   - Workflow docs, skills, prompts, style guide, quality guard, Buildkite update, docs updates.

Do not push until `scripts/quality-guard.sh --full` exits 0 after the final commit.

## References

- Codex AGENTS.md and project guidance: `https://developers.openai.com/codex/guides/agents-md.md`
- Codex skills: `https://developers.openai.com/codex/skills.md`
- Codex project config and hooks: `https://developers.openai.com/codex/config-advanced.md`
- Claude Code skills: `https://docs.claude.com/en/docs/claude-code/skills`
- GitHub Copilot repository custom instructions: `https://docs.github.com/en/copilot/how-tos/custom-instructions/adding-repository-custom-instructions-for-github-copilot`
- GitHub Copilot CLI custom instructions: `https://docs.github.com/en/copilot/how-tos/copilot-cli/add-custom-instructions`
