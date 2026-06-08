# Architecture Review Loop

## Purpose

Use this focused evaluator workflow to review a diff, completed task, or proposed plan for architectural fit before merge or handoff.

## Inputs

- Current diff from `git diff`, `git diff --staged`, or the relevant comparison base.
- `ARCHITECTURE.md`, `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, and any ADRs under `docs/adr/`.
- Files touched by the change, nearby modules, public APIs, package/project metadata, and verification output.
- User-stated scope, constraints, and any planned future tasks so review findings stay within the approved change.

## Loop

1. Read the diff and architecture docs before forming findings.
2. Check module boundaries, dependency direction, target membership, and whether shared code remains platform-neutral.
3. Review public API shape, ownership, state flow, data flow, entry points, and interactions with existing abstractions.
4. Evaluate quality attributes explicitly: modifiability, testability, reliability, security, performance, platform fit, and user impact.
5. Identify whether the change needs a new or updated ADR because it introduces a new layer, dependency, persistence/networking model, toolchain decision, or durable tradeoff.
6. Separate blocking defects from non-blocking recommendations and avoid broad refactors outside the change.
7. Recommend exact follow-up verification when an architectural fix is needed.

## Output

- Findings first, ordered by severity, with concrete file and line references where possible.
- Each finding includes impact, reasoning, and a specific remediation direction.
- Open questions or assumptions after findings.
- A short change summary only after findings and questions.
- Clear statement when no architecture issues were found, including any residual risk or verification gap.

## Verification

- Findings cite specific files, symbols, modules, or ADRs where possible.
- Review covers module boundaries, dependency direction, public API shape, state/data flow, quality attributes, and ADR needs.
- Review does not request unrelated refactors or style-only changes unless they affect architecture.
- Review notes the verification evidence considered and any missing evidence that affects confidence.

## Agent Surface Notes

- Primary Codex wrapper: `.agents/skills/review-architecture/SKILL.md`.
- Primary Claude Code wrapper: `.claude/skills/review-architecture/SKILL.md`.
- Primary GitHub Copilot wrapper: `.github/skills/review-architecture/SKILL.md`.
- See `docs/agent-workflows/README.md` for the complete accepted companion and rationale-waiver contract.
