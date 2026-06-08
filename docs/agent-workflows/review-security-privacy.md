# Security and Privacy Review Loop

## Purpose

Use this focused evaluator workflow to review a diff, completed task, or harness change for security, privacy, sandbox, and agent-risk issues before merge or handoff.

## Inputs

- Current diff from `git diff`, `git diff --staged`, or the relevant comparison base.
- Files touched by the change, package/project metadata, scripts, CI configuration, entitlements, signing-related settings, and agent harness files.
- Repository instructions and boundaries from `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, and `ARCHITECTURE.md`.
- Latest verification output and any user-stated data, network, dependency, or tool-access expectations.

## Loop

1. Read the diff and relevant security/privacy surfaces before forming findings.
2. Check for secrets, credentials, signing material, provisioning assets, tokens, local paths, and machine-specific data.
3. Review permissions, entitlements, sandbox assumptions, file access, network access, subprocess/tool execution, and CI environment behavior.
4. Inspect dependency changes, downloaded tooling, scripts, generated files, and build steps for supply-chain and trust-boundary risks.
5. Assess data privacy: what data is collected or stored, whether it leaves the device, third-party behavior, tracking implications, and whether privacy disclosures would need updates.
6. For agent harness changes, treat prompts, retrieved content, tool output, and generated instructions as untrusted input; review prompt injection, insecure output handling, excessive agency, broad hooks, and policy bypass paths.
7. For each issue, describe attack path, impact, likelihood, and concrete mitigation.
8. Separate blocking defects from non-blocking hardening suggestions.

## Output

- Findings first, ordered by severity, with concrete file and line references where possible.
- Each finding includes attack path, impact, likelihood, and mitigation.
- Open questions or assumptions after findings.
- A short change summary only after findings and questions.
- Clear statement when no security or privacy issues were found, including any residual risk or verification gap.

## Verification

- Review covers secrets, permissions, sandbox/tooling, file/network access, dependency changes, data privacy, prompt injection, agent autonomy, and mitigation paths.
- Review does not request unrelated rewrites or speculative controls without tying them to a concrete risk.
- Review notes command evidence considered, such as harness verification, shell checks, Swift checks, or CI output.
- Review calls out any uninspected security-relevant surface that limits confidence.

## Agent Surface Notes

- Primary Codex wrapper: `.agents/skills/review-security-privacy/SKILL.md`.
- Primary Claude Code wrapper: `.claude/skills/review-security-privacy/SKILL.md`.
- Primary GitHub Copilot wrapper: `.github/skills/review-security-privacy/SKILL.md`.
- See `docs/agent-workflows/README.md` for the complete accepted companion and rationale-waiver contract.
