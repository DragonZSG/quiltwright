# Code Quality Guard

## Purpose

Use this deterministic completion gate before handoff whenever a task changes source, tests, scripts, CI, docs, project metadata, or agent harness artifacts.

## Inputs

- Current worktree state from `git status -sb`.
- Changed paths from `git diff --name-only` and, when needed, `git diff --staged --name-only`.
- Repository commands from `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, `script/ci.sh`, and `scripts/verify-harness.sh`.
- The task plan or workflow output that states required fast or full verification.

## Loop

1. Inspect changed paths and choose fast or full mode based on risk and task requirements.
2. In fast mode, always run `scripts/verify-harness.sh`.
3. For each changed `.sh` file, run `bash -n <changed-shell-script>`.
4. For changed `.md` files, run a fence balance check that counts lines beginning with three backticks per file and fails when any file has an odd count. One portable command shape is:

   ```sh
   awk 'FNR == 1 { if (NR > 1 && fence_count % 2) { print previous_file ": unbalanced fences"; bad = 1 } previous_file = FILENAME; fence_count = 0 } /^```/ { fence_count++ } END { if (fence_count % 2) { print previous_file ": unbalanced fences"; bad = 1 } exit bad }' <changed-markdown-paths>
   ```

5. For changed workflow or docs files, run a placeholder scan with `grep -E -n -i -H` and the repository placeholder pattern. To keep this workflow document from matching its own guard text, write the pattern as concatenated shell literals that evaluate to the required scan pattern:

   ```sh
   placeholder_pattern='(^|[^[:alnum:]_])(t''bd|to''do|to[[:space:]-]+be[[:space:]-]+determined|fill[[:space:]-]+in|implement[[:space:]-]+later)([^[:alnum:]_]|$)'
   grep -E -n -i -H "$placeholder_pattern" <changed-doc-paths>
   ```

6. For Swift or package changes, run `swift run QuiltwrightChecks` for targeted shared checks or `script/ci.sh package` when package-level behavior is affected.
7. In full mode, run all fast-mode checks, then run `script/ci.sh all`.
8. Use `scripts/quality-guard.sh --fast` for fast mode and `scripts/quality-guard.sh --full` for full mode instead of manually assembling the command list.
9. Treat CI as authoritative. Local checks provide early evidence, but Buildkite remains the shared enforcement point.
10. Hooks may call this guard, but hooks may not replace it, bypass it, or define a different source of quality policy.
11. If a command fails, capture the failing command, exit result, short failure shape, and whether the failure is expected because a later task owns the missing artifact.
12. Stop rather than hiding failures by disabling tests, removing checks, narrowing CI, or editing unrelated files.

## Output

- A guard report listing commands, exit results, changed paths covered, and any skipped checks with reason.
- Final status of `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, or `BLOCKED` when used as an implementation completion gate.
- For expected harness failures, enough output to prove the failure is limited to known missing companion artifacts or another explicitly planned future task.

## Verification

- `scripts/verify-harness.sh` ran for harness changes.
- `bash -n <changed-shell-script>` ran for each changed `.sh` file.
- Markdown fence balance checks ran for changed `.md` files.
- `grep -E -n -i -H "$placeholder_pattern" <changed-doc-paths>` ran for changed workflow/docs files, with `placeholder_pattern` evaluating to the repository placeholder scan pattern.
- `swift run QuiltwrightChecks` or `script/ci.sh package` ran for Swift or package-level changes in fast mode.
- `script/ci.sh all` ran in full mode, or the report explains why full mode was not required or could not run.
- CI remains the authoritative guard, and any hook integration delegates to this workflow or `scripts/quality-guard.sh`.

## Agent Surface Notes

- Primary Codex wrapper: `.agents/skills/code-quality-guard/SKILL.md`.
- Primary Claude Code wrapper: `.claude/skills/code-quality-guard/SKILL.md`.
- Primary GitHub Copilot wrapper: `.github/skills/code-quality-guard/SKILL.md`.
- See `docs/agent-workflows/README.md` for the complete accepted companion and rationale-waiver contract.
