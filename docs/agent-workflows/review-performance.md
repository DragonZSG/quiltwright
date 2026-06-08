# Performance Review Loop

## Purpose

Use this focused evaluator workflow to review build, test, runtime responsiveness, SwiftUI update, I/O, and data-structure performance risks in a diff or completed task.

## Inputs

- Current diff from `git diff`, `git diff --staged`, or the relevant comparison base.
- Touched Swift, SwiftUI, scripts, CI, package/project metadata, and check output.
- Existing performance-sensitive context from `ARCHITECTURE.md`, repository instructions, plan notes, Instruments output, Xcode metrics, or user reports when available.
- Latest command output from targeted checks, `swift run QuiltwrightChecks`, `script/ci.sh package`, platform build legs, or full CI when relevant.

## Loop

1. Read the diff and relevant files before forming findings.
2. Check for main-thread work, synchronous I/O in user-facing paths, expensive work in SwiftUI `body`, unnecessary state invalidation, repeated allocations, and unbounded loops.
3. Review data structures, algorithms, caching, and file/network access for costs that scale poorly with realistic input sizes.
4. Assess build/test performance: scripts that duplicate work, project settings that inflate builds, checks that are too broad for fast mode, and CI steps that diverge from local commands.
5. Require measurement before broad performance refactors; prefer a small targeted fix when the risk is obvious and localized.
6. Recommend Instruments, Xcode metrics, or runtime profiling only when the change affects launch, hangs, hitches, memory, energy, storage writes, or responsiveness in a way static review cannot prove.
7. Separate blocking performance regressions from follow-up measurement or optimization suggestions.

## Output

- Findings first, ordered by severity, with concrete file and line references where possible.
- Each finding explains the workload, user or developer impact, expected scale, and suggested measurement or fix.
- Open questions or assumptions after findings.
- A short change summary only after findings and questions.
- Clear statement when no performance issues were found, including any residual risk or verification gap.

## Verification

- Review covers main-thread work, SwiftUI update costs, build/test cost, I/O, data structures, and measurement-before-refactor discipline.
- Review cites command evidence and measurement artifacts considered.
- Review distinguishes measured regressions, likely regressions, and speculative optimization ideas.
- Review calls for Instruments or Xcode metrics only when warranted by the runtime risk.

## Agent Surface Notes

- Primary Codex wrapper: `.agents/skills/review-performance/SKILL.md`.
- Primary Claude Code wrapper: `.claude/skills/review-performance/SKILL.md`.
- Primary GitHub Copilot wrapper: `.github/skills/review-performance/SKILL.md`.
- See `docs/agent-workflows/README.md` for the complete accepted companion and rationale-waiver contract.
