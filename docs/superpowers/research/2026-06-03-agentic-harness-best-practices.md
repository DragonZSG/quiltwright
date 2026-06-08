# Agentic Harness Best Practices Research

Date: 2026-06-03

## Purpose

This research note records the source-backed design constraints for Quiltwright's next harness layer before creating guidance for planning agents, implementation loop agents, focused review agents, a code quality guard, and a style guide.

The key correction from the earlier draft plan is that GitHub Copilot now has first-class project skills, custom agents, and hooks. Copilot should not be represented only by `.github/prompts/` files.

## Research Method

Sources were limited to primary or vendor-owned documentation where possible: OpenAI/Codex docs, OpenAI Agents SDK docs, Anthropic/Claude Code docs, GitHub Copilot docs, Apple/Swift docs, Google engineering practices, OWASP, NIST, Buildkite, and CMU SEI.

## Executive Findings

1. A documentation-only rule is not enough to force future agents to create equivalent tooling across Codex, Claude Code, and GitHub Copilot. Keep the policy in always-loaded guidance, but enforce it with `scripts/verify-harness.sh` and CI.
2. Use a canonical workflow document for each responsibility area, then expose it through each agent surface with thin wrappers. This prevents three divergent prompt stacks.
3. Use skills for reusable multi-step procedures. Use custom agents/subagents when the workflow needs a role, tool restrictions, isolated context, or delegation. Use prompt files for manually invoked lightweight Copilot tasks. Use hooks for deterministic enforcement, logging, policy gates, or validation commands.
4. The code quality guard should be a normal script and CI step first. Agent-specific hooks may call it, but hooks are not the cross-agent source of truth because hook support, trust, and execution environments differ by surface.
5. Focused review loops should be separate roles. Google's review guidance distinguishes design, functionality, tests, style, documentation, security, privacy, concurrency, accessibility, and other specialist concerns; a single generic reviewer is less reliable than explicit scopes.
6. Agent harness instructions need prompt-engineering discipline: state the goal, scope, inputs, loop, tool expectations, output format, verification evidence, and stop conditions. Avoid vague goals like "review thoroughly" without severity and evidence rules.

## Prompt Construction Best Practices

Effective harness prompts should include these sections:

- Identity: the role the agent is taking for this workflow.
- Trigger: when this workflow should be used and when it should not be used.
- Inputs: exact repository files, diffs, user artifacts, and commands to inspect.
- Boundaries: files or behaviors the agent must not change without permission.
- Loop: ordered steps with a checkpoint and stop condition.
- Tools: allowed or expected commands, and when not to use expensive or dangerous tools.
- Output: required report shape, evidence, unresolved issues, and next action.
- Verification: commands that must run, expected success criteria, and how failures are reported.

OpenAI recommends clear instructions, relevant context, examples where useful, and prompt iteration against the actual task. Anthropic recommends clear upfront task descriptions, XML-style delimiters for boundaries, positive examples for output style, and prompt tuning based on harness behavior. GitHub recommends breaking down complex tasks, being specific, providing examples, validating generated code, and using automated tests and tooling.

For skills specifically, the `description` field is part of the routing surface. It should front-load trigger words, scope, and boundaries. It should not contain a full hidden workflow summary that tempts the model to act from the description instead of loading the skill body.

## Agentic Harness Construction

Use the simplest structure that gives repeatable behavior:

- Always-on repo guidance for stable conventions.
- Skills for repeatable workflows that should load on demand.
- Custom agents/subagents for specialized reviewers, planners, or implementation workers that need their own prompt and tool envelope.
- Scripts for deterministic checks.
- Hooks for lifecycle automation or policy, never as the only source of correctness.
- CI as the shared enforcement point across all agents.

Anthropic's agent guidance emphasizes simple designs, explicit planning visibility, ground truth from the environment, tests as feedback, checkpoints for human judgment, and guardrails for open-ended autonomous work. OpenAI's Agents SDK guidance distinguishes manager-style orchestration, handoffs, evaluator loops, parallel agents, guardrails, and tracing. For Quiltwright, that means:

- Planning loop: manager-style workflow that owns scope, decomposition, and verification plan.
- Implementation loop: worker workflow that executes one small task, runs checks, and reports evidence.
- Review loops: focused evaluator workflows that run independently and report findings by severity.
- Quality guard: deterministic script and CI gate that agents call before completion.

## Surface-Specific Findings

### Codex

Use:

- `AGENTS.md` for durable repository guidance that Codex reads before work.
- `.agents/skills/<name>/SKILL.md` for repo-scoped Codex skills.
- `.codex/config.toml` for project-scoped config in trusted projects.
- `.codex/hooks.json` or inline hooks in `.codex/config.toml` for lifecycle hooks.
- `.codex/agents/<name>.toml` for project-scoped custom Codex agents when role-specific spawned agents are needed.

Important constraints:

- Current Codex docs put repo skills under `.agents/skills`, not `.codex/skills`.
- `.codex/` project layers only load when the project is trusted.
- Custom prompts are deprecated in favor of skills.
- Hooks require review/trust and are command-only today in Codex; prompt and agent hook handlers are parsed but skipped.
- For repo-local hooks, resolve paths from the Git root so Codex can be started from subdirectories.

### Claude Code

Use:

- `CLAUDE.md` for project memory: architecture, commands, style, and common workflows.
- `.claude/skills/<name>/SKILL.md` for project skills.
- `.claude/agents/<name>.md` for project subagents with role prompts, tool restrictions, permissions, hooks, max turns, skills, or worktree isolation.
- `.claude/settings.json` for shared project settings and hooks.
- `.claude/commands/` only for legacy compatibility; current Claude Code docs say commands have been merged into skills.

Important constraints:

- Skills load on demand and support supporting files, dynamic context, tool pre-approval, and subagent execution.
- Project skills are discoverable from parent and nested `.claude/skills` directories.
- Subagents receive their own system prompt, can be restricted to tools, and can be invoked automatically, by mention, or for a whole session.
- Hooks can be in settings, skills, or subagent frontmatter, but security review is required before trusting broad tool access.

### GitHub Copilot

Use:

- `.github/copilot-instructions.md` for repository-wide custom instructions.
- `.github/instructions/*.instructions.md` for path-specific custom instructions.
- `AGENTS.md` for agent instructions when Copilot is acting as an AI agent; GitHub docs also mention `CLAUDE.md` and `GEMINI.md` as alternatives.
- `.github/skills/<name>/SKILL.md` for project skills specific to Copilot. GitHub also recognizes `.claude/skills` and `.agents/skills` as project skill locations, but using `.github/skills` makes the Copilot surface explicit.
- `.github/agents/<name>.md` for Copilot custom agent profiles.
- `.github/prompts/<name>.prompt.md` for lightweight reusable prompt files invoked manually in IDE chat.
- `.github/hooks/*.json` for Copilot CLI and cloud agent hooks where deterministic policy or lifecycle automation is needed.

Important constraints:

- GitHub recommends custom instructions for simple instructions that apply to most tasks and skills for detailed task-specific behavior.
- Copilot project skills are folders with `SKILL.md` and optional scripts/resources, loaded when relevant.
- Prompt files are best for single-task slash commands, not full multi-step harness capabilities.
- Copilot hooks run in different environments for CLI and cloud agent. Cloud hooks run in an ephemeral Linux sandbox with constrained network access, so hook scripts must be portable and must not depend on local state.
- Copilot custom agents define prompts, tools, and MCP servers; use them for persistent roles such as focused reviewers.

## Responsibility-Area Findings

### Planning Loop

Best practice:

- Start with repo facts: current status, architecture, existing commands, modules, constraints, and target files.
- Restate the goal and split work into independently verifiable tasks.
- Include exact files, exact commands, expected outcomes, and rollback or deferral points.
- Use a manager-style workflow, not a reviewer-style workflow.
- Require a research gate before generating new agent guidance when the guidance depends on external tool behavior.

Reasoning:

- Agentic work performs better with upfront task, intent, and constraints.
- Anthropic recommends visible planning steps and ground truth from environment feedback.
- OpenAI orchestration docs distinguish manager agents and evaluator loops; planning should own coordination, not implementation.

### Implementation Loop

Best practice:

- Execute one small task at a time.
- Inspect relevant files before editing.
- Write or update tests before broad implementation where feasible.
- Run targeted verification after each task and the quality guard before completion.
- Stop on ambiguous destructive action, failing dependency setup, or verification failure that needs user choice.

Reasoning:

- Coding agents are especially suitable because code has automated tests and objective feedback.
- Google review guidance treats tests as maintainable code and expects tests in the same change when appropriate.
- GitHub recommends validating Copilot output with tests, linting, code scanning, and other tooling.

### Architecture Review Loop

Best practice:

- Review module boundaries, dependency direction, public API shape, ownership, data flow, state flow, and interaction with existing architecture.
- Evaluate quality attributes explicitly: modifiability, security, performance, reliability, testability, and user impact.
- Report tradeoffs and risks, not just preferences.
- Use architecture review as a focused evaluator loop and mark which parts were reviewed.

Reasoning:

- CMU SEI's ATAM frames architecture evaluation around quality attributes, tradeoffs, and risks.
- Google code review guidance makes design the most important review topic and asks reviewers to consider whether the change integrates with the system.

### Test Review Loop

Best practice:

- Check whether tests fail for the right reason, assert useful behavior, cover edge cases, and avoid false positives.
- Review tests for maintainability, not just existence.
- Prefer the smallest effective test level, but include integration or UI tests when wiring or user behavior is the risk.
- For Swift, use SwiftPM/Xcode test commands already present in the repo; consider sanitizer checks only when concurrency, memory, or release risk warrants it.

Reasoning:

- Google review guidance asks whether tests are correct, sensible, useful, simple, and separated appropriately.
- Apple XCTest docs distinguish unit, performance, and UI testing, while Swift.org recommends `swift test` and sanitizers for production readiness in relevant contexts.

### Security And Privacy Review Loop

Best practice:

- Treat secrets, tokens, credentials, network calls, file access, sandbox escapes, dependency changes, generated code, and agent tools as explicit review surfaces.
- For app privacy, identify collected data, third-party SDK behavior, whether data leaves device, tracking, and whether privacy declarations need updates.
- For AI/agent tooling, treat prompts, retrieved content, and tool output as untrusted input; guard against prompt injection, insecure output handling, excessive agency, and supply-chain risk.
- Report attack path, impact, likelihood, and concrete mitigation.

Reasoning:

- OWASP states manual security code review still has a place even as scanners improve.
- NIST SSDF recommends integrating secure development practices into the SDLC to reduce vulnerabilities and prevent recurrence.
- OWASP GenAI Security documents LLM-specific risks including prompt injection and insecure output handling.
- Apple requires app teams to understand and keep accurate privacy disclosures for first- and third-party data practices.

### UI And Platform Review Loop

Best practice:

- Review SwiftUI code for platform-native patterns, accessibility labels and traits, Dynamic Type, keyboard and pointer behavior where relevant, scene/window behavior, and consistency with macOS/iOS expectations.
- Prefer system controls and platform conventions unless the product reason for custom UI is clear.
- Check visible text, layout stability, focus, hit targets, VoiceOver, reduced motion, and color/contrast risks.
- Validate UI behavior by running the app or targeted previews when feasible.

Reasoning:

- Apple HIG is the primary design source for Apple platform expectations.
- SwiftUI accessibility documentation says SwiftUI has built-in support but teams should try the app with accessibility features and get feedback from users who rely on them.
- Google review guidance says UI changes may require validating behavior or requesting a demo.

### Performance Review Loop

Best practice:

- Review for main-thread blocking, unnecessary SwiftUI body invalidation, expensive work in view updates, large synchronous I/O, unbounded loops, inefficient data structures, and avoidable build cost.
- Use measurements before broad performance refactors.
- For SwiftUI, look for long view body updates and frequent updates that contribute to hangs or hitches.
- Use the existing CI guard for baseline build/test health; use Instruments or Xcode metrics only when the task affects runtime responsiveness.

Reasoning:

- Apple performance docs emphasize measuring app responsiveness, hangs, hitches, launch time, memory, energy, and storage writes.
- Apple's SwiftUI performance docs point to Instruments for detecting hangs, hitches, long view body updates, and frequent SwiftUI updates.
- SEI architecture evaluation treats performance as a quality attribute that trades off against others.

### Code Quality Guard

Best practice:

- Implement as `scripts/quality-guard.sh` with `--fast` and `--full` modes.
- Fast mode should run harness verification, shell syntax, markdown consistency checks, and targeted SwiftPM checks.
- Full mode should call the repo's authoritative CI command: `script/ci.sh all`.
- Buildkite should run the guard as a normal command step.
- Hooks may call fast mode, but CI is authoritative.

Reasoning:

- Buildkite command steps run shell commands or scripts and fail the step if commands fail.
- Swift Package Manager provides standard `swift build` and `swift test` entry points.
- GitHub Copilot and Codex both recommend validating agent output with automated tools.

### Style Guide

Best practice:

- `STYLEGUIDE.md` should be a standing reference, not an invokable workflow.
- It should cover Swift naming and API shape, SwiftUI organization, tests, docs, shell scripts, markdown, agent artifact naming, and source citation standards.
- Keep style rules specific, mechanically checkable where possible, and grounded in existing repo patterns.
- Do not turn preferences into blocking review findings unless they are in the style guide, local pattern, or deterministic tooling.

Reasoning:

- Swift API Design Guidelines emphasize clarity at the point of use, clarity over brevity, documentation comments for public declarations, and Swift naming conventions.
- Google review guidance treats the style guide as the authority for style and treats unlisted style points as preferences.

## Recommended Quiltwright Artifact Model

For each workflow in `docs/agent-workflows/manifest.txt`, create:

- Canonical workflow: `docs/agent-workflows/<workflow>.md`
- Codex skill: `.agents/skills/<workflow>/SKILL.md`
- Claude Code skill: `.claude/skills/<workflow>/SKILL.md`
- GitHub Copilot skill: `.github/skills/<workflow>/SKILL.md`
- GitHub Copilot prompt: `.github/prompts/<workflow>.prompt.md` only when a manually invoked slash command is useful

For role-specific loops, also create custom agents:

- Codex: `.codex/agents/planner.toml`, `.codex/agents/implementation-worker.toml`, and `.codex/agents/review-<focus>.toml`
- Claude Code: `.claude/agents/planner.md`, `.claude/agents/implementation-worker.md`, and `.claude/agents/review-<focus>.md`
- GitHub Copilot: `.github/agents/planner.md`, `.github/agents/implementation-worker.md`, and `.github/agents/review-<focus>.md`

For deterministic enforcement:

- Shared script: `scripts/quality-guard.sh`
- Shared verifier: `scripts/verify-harness.sh`
- Optional Codex hooks: `.codex/hooks.json` or `.codex/config.toml`
- Optional Claude hooks: `.claude/settings.json` or skill/agent frontmatter
- Optional Copilot hooks: `.github/hooks/*.json`

For standing guidance:

- Codex: `AGENTS.md`
- Claude Code: `CLAUDE.md`
- GitHub Copilot: `.github/copilot-instructions.md` and path instructions where useful
- Shared style: `STYLEGUIDE.md`

## Required Plan Changes Before Implementation

1. Revise the existing implementation plan so Copilot companions include `.github/skills/<workflow>/SKILL.md`, not only `.github/prompts/<workflow>.prompt.md`.
2. Add custom agent artifacts for the planning, implementation, and focused review roles across Codex, Claude Code, and Copilot.
3. Extend `scripts/verify-harness.sh` to detect and enforce companions for `.github/skills`, `.github/agents`, `.github/hooks`, `.codex/agents`, and `.claude/agents`, in addition to the currently planned skill and prompt surfaces.
4. Keep hooks optional unless a deterministic policy or lifecycle event is needed. Do not create hooks merely to restate documentation.
5. Keep `STYLEGUIDE.md` out of the workflow manifest. It is a reference used by all workflows.
6. Add source-citation expectations to workflow docs and style guide when guidance depends on external current behavior.

## Sources

- OpenAI prompt engineering: https://platform.openai.com/docs/guides/prompt-engineering
- OpenAI Agents SDK agents: https://openai.github.io/openai-agents-python/agents/
- OpenAI Agents SDK orchestration: https://openai.github.io/openai-agents-python/multi_agent/
- OpenAI Agents SDK guardrails: https://openai.github.io/openai-agents-python/guardrails/
- OpenAI Agents SDK tracing: https://openai.github.io/openai-agents-python/tracing/
- OpenAI practical guide to building agents: https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/
- Codex `AGENTS.md` guidance: https://developers.openai.com/codex/guides/agents-md.md
- Codex skills: https://developers.openai.com/codex/skills.md
- Codex hooks: https://developers.openai.com/codex/hooks.md
- Codex advanced config: https://developers.openai.com/codex/config-advanced.md
- Anthropic building effective agents: https://www.anthropic.com/engineering/building-effective-agents
- Claude prompting best practices: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- Claude Code memory: https://docs.claude.com/en/docs/claude-code/memory
- Claude Code skills: https://docs.claude.com/en/docs/claude-code/skills
- Claude Code subagents: https://docs.claude.com/en/docs/claude-code/sub-agents
- Claude Code hooks: https://docs.claude.com/en/docs/claude-code/hooks
- Claude Code settings: https://docs.claude.com/en/docs/claude-code/settings
- GitHub Copilot best practices: https://docs.github.com/en/copilot/get-started/best-practices
- GitHub Copilot repository custom instructions: https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-repository-instructions
- GitHub Copilot agent skills: https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills
- GitHub Copilot custom agents: https://docs.github.com/en/copilot/concepts/agents/copilot-cli/about-custom-agents
- GitHub Copilot prompt files in VS Code: https://code.visualstudio.com/docs/agent-customization/prompt-files
- GitHub Copilot hooks reference: https://docs.github.com/en/copilot/reference/hooks-reference
- Google code review standard: https://google.github.io/eng-practices/review/reviewer/standard.html
- Google code review topics: https://google.github.io/eng-practices/review/reviewer/looking-for.html
- GitHub pull request reviews: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews
- CMU SEI ATAM: https://www.sei.cmu.edu/library/atam-method-for-architecture-evaluation/
- OWASP Code Review Guide: https://owasp.org/www-project-code-review-guide/
- NIST SSDF SP 800-218: https://csrc.nist.gov/pubs/sp/800/218/final
- OWASP Top 10 for LLM Applications: https://owasp.org/www-project-top-10-for-large-language-model-applications/
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Swift API Design Guidelines: https://www.swift.org/documentation/api-design-guidelines/
- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- SwiftUI Accessibility Fundamentals: https://developer.apple.com/documentation/swiftui/accessibility-fundamentals
- Apple SwiftUI Performance Analysis: https://developer.apple.com/documentation/swiftui/performance-analysis
- Apple Improving App Performance: https://developer.apple.com/documentation/xcode/improving-your-app-s-performance/
- XCTest: https://developer.apple.com/documentation/xctest
- Swift Testing: https://developer.apple.com/xcode/swift-testing/
- Swift.org testing guide: https://www.swift.org/documentation/server/guides/testing.html
- Swift Package Manager docs: https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/
- Buildkite command step: https://buildkite.com/docs/pipelines/configure/step-types/command-step
