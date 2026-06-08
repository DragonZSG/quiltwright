# Test Review Loop

## Purpose

Use this focused evaluator workflow to review whether a change has meaningful, maintainable verification and whether the chosen SwiftPM, Xcode, or script checks fit the risk.

## Inputs

- Current diff from `git diff`, `git diff --staged`, or the relevant comparison base.
- Existing checks under `Tests/QuiltwrightChecks`, package/project configuration, `script/ci.sh`, Buildkite configuration, and any test-related plan notes.
- Latest command output from targeted checks, `swift run QuiltwrightChecks`, `script/ci.sh package`, or broader CI legs when available.
- User-stated risk areas, expected behavior, and any reason tests were intentionally deferred.

## Loop

1. Read the diff, test/check files, and command output before forming findings.
2. Verify that tests or executable checks assert meaningful behavior rather than implementation details or trivial existence.
3. Check whether failures would point to the real defect with useful messages and a stable reproduction path.
4. Assess regression risk: changed public APIs, shared UI behavior, platform-specific paths, CI scripts, manifest parsing, and edge cases.
5. Confirm the chosen command fits the change: `swift run QuiltwrightChecks` for shared UI/check behavior, `script/ci.sh package` for SwiftPM packaging, app build legs for platform target changes, and harness verification for agent artifacts.
6. Review test maintainability: clear setup, low duplication, deterministic data, no brittle timing or local-machine assumptions, and no disabled checks.
7. Separate blocking test gaps from follow-up recommendations.

## Output

- Findings first, ordered by severity, with concrete file and line references where possible.
- Each finding explains the missed behavior, the likely regression, and the smallest useful check to add or adjust.
- Open questions or assumptions after findings.
- A short change summary only after findings and questions.
- Clear statement when no test issues were found, including any residual risk or verification gap.

## Verification

- Review considers meaningful assertions, failure quality, regression risk, SwiftPM/Xcode command fit, and maintainability.
- Review does not require new tooling such as XCTest, SwiftLint, or SwiftFormat without explicit approval and architectural justification.
- Review cites command evidence considered and identifies missing command output when confidence depends on it.
- Review does not approve a build-affecting change based only on unchecked reasoning.

## Agent Surface Notes

- Primary Codex wrapper: `.agents/skills/review-tests/SKILL.md`.
- Primary Claude Code wrapper: `.claude/skills/review-tests/SKILL.md`.
- Primary GitHub Copilot wrapper: `.github/skills/review-tests/SKILL.md`.
- See `docs/agent-workflows/README.md` for the complete accepted companion and rationale-waiver contract.
