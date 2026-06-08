# SwiftUI and Platform Review Loop

## Purpose

Use this focused evaluator workflow to review SwiftUI, macOS, iOS, accessibility, and platform-behavior risks in a diff or completed task.

## Inputs

- Current diff from `git diff`, `git diff --staged`, or the relevant comparison base.
- Touched SwiftUI views, app entry points, shared UI models, Xcode target membership, and relevant previews or check output.
- `ARCHITECTURE.md`, repository instructions, platform target constraints, and user-facing requirements.
- Latest command output from `swift run QuiltwrightChecks`, relevant `script/ci.sh` platform legs, screenshots, previews, or simulator/manual notes when available.

## Loop

1. Read the diff and relevant SwiftUI/platform files before forming findings.
2. Check whether shared UI remains platform-neutral or uses explicit availability/platform guards.
3. Review SwiftUI structure for state ownership, binding flow, view composition, environment usage, update stability, and use of system controls.
4. Assess macOS and iOS platform fit: scene/window behavior, navigation, menus/toolbars where relevant, safe areas, keyboard, pointer, focus, and expected system interactions.
5. Review accessibility: labels, traits, hit targets, VoiceOver flow, Dynamic Type, color/contrast risk, reduced motion, and whether visible text remains clear at supported sizes.
6. Check layout stability across compact and regular sizes, long text, localization-sensitive strings, and platform-specific controls.
7. Prefer concrete file/line findings and request screenshots, previews, or app runs only when visual behavior cannot be judged from code and existing evidence.
8. Separate blocking user-facing defects from follow-up polish.

## Output

- Findings first, ordered by severity, with concrete file and line references where possible.
- Each finding explains the affected platform or assistive technology, user impact, and remediation direction.
- Open questions or assumptions after findings.
- A short change summary only after findings and questions.
- Clear statement when no SwiftUI or platform issues were found, including any residual risk or verification gap.

## Verification

- Review covers SwiftUI/macOS/iOS platform fit, accessibility, Dynamic Type, keyboard/pointer/focus behavior, scene/window behavior, system controls, and layout stability.
- Review considers `swift run QuiltwrightChecks` and platform build evidence when relevant.
- Review does not require custom UI where a system control already fits, and does not request screenshots when code and checks provide enough evidence.
- Review calls out missing visual or runtime evidence when confidence depends on it.

## Agent Surface Notes

- Primary Codex wrapper: `.agents/skills/review-ui-platform/SKILL.md`.
- Primary Claude Code wrapper: `.claude/skills/review-ui-platform/SKILL.md`.
- Primary GitHub Copilot wrapper: `.github/skills/review-ui-platform/SKILL.md`.
- See `docs/agent-workflows/README.md` for the complete accepted companion and rationale-waiver contract.
