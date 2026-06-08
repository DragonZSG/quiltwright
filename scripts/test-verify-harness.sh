#!/usr/bin/env bash
# test-verify-harness.sh - Smoke tests for harness verification rules.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/quiltwright-harness-test.XXXXXX")"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

copy_base_fixture() {
  local fixture="$1"

  mkdir -p \
    "$fixture/.agents/skills" \
    "$fixture/.buildkite" \
    "$fixture/.codex/agents" \
    "$fixture/.claude/agents" \
    "$fixture/.claude/skills" \
    "$fixture/.github/agents" \
    "$fixture/.github/prompts" \
    "$fixture/.github/skills" \
    "$fixture/docs/adr" \
    "$fixture/docs/agent-workflows" \
    "$fixture/Quiltwright.xcodeproj" \
    "$fixture/script" \
    "$fixture/scripts" \
    "$fixture/Sources/QuiltwrightUI" \
    "$fixture/Sources/QuiltwrightMac" \
    "$fixture/Sources/QuiltwrightiOS" \
    "$fixture/Tests/QuiltwrightChecks"

  cp "$ROOT_DIR/CLAUDE.md" "$fixture/CLAUDE.md"
  cp "$ROOT_DIR/AGENTS.md" "$fixture/AGENTS.md"
  cp "$ROOT_DIR/ARCHITECTURE.md" "$fixture/ARCHITECTURE.md"
  cp "$ROOT_DIR/STYLEGUIDE.md" "$fixture/STYLEGUIDE.md"
  cp "$ROOT_DIR/.github/copilot-instructions.md" "$fixture/.github/copilot-instructions.md"
  cp "$ROOT_DIR/.buildkite/pipeline.yml" "$fixture/.buildkite/pipeline.yml"
  cp "$ROOT_DIR/docs/adr/template.md" "$fixture/docs/adr/template.md"
  cp "$ROOT_DIR/docs/adr/001-adopt-harness-engineering.md" "$fixture/docs/adr/001-adopt-harness-engineering.md"
  cp "$ROOT_DIR/scripts/verify-harness.sh" "$fixture/scripts/verify-harness.sh"
  cp "$ROOT_DIR/scripts/quality-guard.sh" "$fixture/scripts/quality-guard.sh"
  cp "$ROOT_DIR/scripts/test-verify-harness.sh" "$fixture/scripts/test-verify-harness.sh"
  cp "$ROOT_DIR/scripts/test-quality-guard.sh" "$fixture/scripts/test-quality-guard.sh"
  touch "$fixture/script/ci.sh"
}

assert_contains() {
  local file="$1"
  local expected="$2"

  if ! grep -Fq "$expected" "$file"; then
    echo "Expected output to contain: $expected" >&2
    cat "$file" >&2
    exit 1
  fi
}

expect_failure_for_unpaired_codex_skill() {
  local fixture="$TMP_ROOT/unpaired-codex-skill"
  copy_base_fixture "$fixture"

  mkdir -p "$fixture/.agents/skills/planning-agent"
  cat > "$fixture/.agents/skills/planning-agent/SKILL.md" <<'SKILL'
---
name: planning-agent
description: Plan implementation work.
---

Plan implementation work.
SKILL

  if (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/unpaired.out" 2>&1); then
    echo "Expected verify-harness to fail for an unpaired Codex skill." >&2
    cat "$TMP_ROOT/unpaired.out" >&2
    exit 1
  fi

  if grep -Fq "missing Claude Code companion" "$TMP_ROOT/unpaired.out" &&
    grep -Fq "missing GitHub Copilot companion" "$TMP_ROOT/unpaired.out"; then
    echo "[PASS] unpaired Codex skill fails with companion errors"
  else
    echo "Expected companion error messages for unpaired Codex skill." >&2
    cat "$TMP_ROOT/unpaired.out" >&2
    exit 1
  fi
}

expect_failure_for_manifest_required_workflow_without_companions() {
  local fixture="$TMP_ROOT/manifest-required-workflow"
  copy_base_fixture "$fixture"

  cat > "$fixture/docs/agent-workflows/manifest.txt" <<'MANIFEST'
# slug|Label
planning-agent|Planning Agent
MANIFEST
  cat > "$fixture/docs/agent-workflows/planning-agent.md" <<'WORKFLOW'
# Planning Agent

Plan implementation work.
WORKFLOW

  if (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/manifest.out" 2>&1); then
    echo "Expected verify-harness to fail for a manifest workflow without companions." >&2
    cat "$TMP_ROOT/manifest.out" >&2
    exit 1
  fi

  assert_contains "$TMP_ROOT/manifest.out" "planning-agent missing Codex companion"
  assert_contains "$TMP_ROOT/manifest.out" "planning-agent missing Claude Code companion"
  assert_contains "$TMP_ROOT/manifest.out" "planning-agent missing GitHub Copilot companion"
  echo "[PASS] manifest-required workflow fails without companions"
}

expect_failure_for_manifest_workflow_missing_doc() {
  local fixture="$TMP_ROOT/manifest-missing-doc"
  copy_base_fixture "$fixture"

  mkdir -p \
    "$fixture/.agents/skills/planning-agent" \
    "$fixture/.claude/skills/planning-agent" \
    "$fixture/.github/skills/planning-agent"

  cat > "$fixture/docs/agent-workflows/manifest.txt" <<'MANIFEST'
# slug|Label
planning-agent|Planning Agent
MANIFEST

  cat > "$fixture/.agents/skills/planning-agent/SKILL.md" <<'SKILL'
---
name: planning-agent
description: Plan implementation work.
---

Plan implementation work.
SKILL

  cat > "$fixture/.claude/skills/planning-agent/SKILL.md" <<'SKILL'
---
name: planning-agent
description: Plan implementation work.
---

Plan implementation work.
SKILL

  cat > "$fixture/.github/skills/planning-agent/SKILL.md" <<'SKILL'
---
name: planning-agent
description: Plan implementation work.
---

Plan implementation work.
SKILL

  if (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/manifest-missing-doc.out" 2>&1); then
    echo "Expected verify-harness to fail for a manifest workflow missing its canonical doc." >&2
    cat "$TMP_ROOT/manifest-missing-doc.out" >&2
    exit 1
  fi

  assert_contains "$TMP_ROOT/manifest-missing-doc.out" "planning-agent missing canonical workflow doc: add docs/agent-workflows/planning-agent.md"
  echo "[PASS] manifest workflow fails without canonical doc"
}

expect_failure_for_malformed_manifest_record() {
  local fixture="$TMP_ROOT/malformed-manifest"
  copy_base_fixture "$fixture"

  cat > "$fixture/docs/agent-workflows/manifest.txt" <<'MANIFEST'
# slug|Label
planning-agent Planning Agent
MANIFEST

  if (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/malformed-manifest.out" 2>&1); then
    echo "Expected verify-harness to fail for a malformed manifest record." >&2
    cat "$TMP_ROOT/malformed-manifest.out" >&2
    exit 1
  fi

  assert_contains "$TMP_ROOT/malformed-manifest.out" "Malformed agent workflow manifest line 2: expected slug|Label"
  echo "[PASS] malformed manifest record fails"
}

expect_failure_for_invalid_manifest_slug() {
  local fixture="$TMP_ROOT/invalid-manifest-slug"
  copy_base_fixture "$fixture"

  cat > "$fixture/docs/agent-workflows/manifest.txt" <<'MANIFEST'
# slug|Label
Bad Slug|Bad
MANIFEST

  if (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/invalid-manifest-slug.out" 2>&1); then
    echo "Expected verify-harness to fail for an invalid manifest slug." >&2
    cat "$TMP_ROOT/invalid-manifest-slug.out" >&2
    exit 1
  fi

  assert_contains "$TMP_ROOT/invalid-manifest-slug.out" "Invalid agent workflow slug on line 2: Bad Slug"
  echo "[PASS] invalid manifest slug fails"
}

expect_failure_for_manifest_empty_label() {
  local fixture="$TMP_ROOT/manifest-empty-label"
  copy_base_fixture "$fixture"

  cat > "$fixture/docs/agent-workflows/manifest.txt" <<'MANIFEST'
# slug|Label
planning-agent|
MANIFEST

  if (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/manifest-empty-label.out" 2>&1); then
    echo "Expected verify-harness to fail for a manifest record with an empty label." >&2
    cat "$TMP_ROOT/manifest-empty-label.out" >&2
    exit 1
  fi

  assert_contains "$TMP_ROOT/manifest-empty-label.out" "Malformed agent workflow manifest line 2: label must be non-empty"
  echo "[PASS] manifest record with empty label fails"
}

expect_failure_for_manifest_empty_slug() {
  local fixture="$TMP_ROOT/manifest-empty-slug"
  copy_base_fixture "$fixture"

  cat > "$fixture/docs/agent-workflows/manifest.txt" <<'MANIFEST'
# slug|Label
|Planning Agent
MANIFEST

  if (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/manifest-empty-slug.out" 2>&1); then
    echo "Expected verify-harness to fail for a manifest record with an empty slug." >&2
    cat "$TMP_ROOT/manifest-empty-slug.out" >&2
    exit 1
  fi

  assert_contains "$TMP_ROOT/manifest-empty-slug.out" "Invalid agent workflow slug on line 2:"
  echo "[PASS] manifest record with empty slug fails"
}

expect_failure_for_manifest_extra_field() {
  local fixture="$TMP_ROOT/manifest-extra-field"
  copy_base_fixture "$fixture"

  cat > "$fixture/docs/agent-workflows/manifest.txt" <<'MANIFEST'
# slug|Label
planning-agent|Planning Agent|extra
MANIFEST

  if (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/manifest-extra-field.out" 2>&1); then
    echo "Expected verify-harness to fail for a manifest record with an extra field." >&2
    cat "$TMP_ROOT/manifest-extra-field.out" >&2
    exit 1
  fi

  assert_contains "$TMP_ROOT/manifest-extra-field.out" "Malformed agent workflow manifest line 2: expected exactly slug|Label"
  echo "[PASS] manifest record with extra field fails"
}

expect_success_for_paired_workflow_skill() {
  local fixture="$TMP_ROOT/paired-skill"
  copy_base_fixture "$fixture"

  mkdir -p \
    "$fixture/.agents/skills/planning-agent" \
    "$fixture/.claude/skills/planning-agent" \
    "$fixture/.github/skills/planning-agent"

  cat > "$fixture/docs/agent-workflows/manifest.txt" <<'MANIFEST'
# slug|Label
planning-agent|Planning Agent
MANIFEST
  cat > "$fixture/docs/agent-workflows/planning-agent.md" <<'WORKFLOW'
# Planning Agent

Plan implementation work.
WORKFLOW

  cat > "$fixture/.agents/skills/planning-agent/SKILL.md" <<'SKILL'
---
name: planning-agent
description: Plan implementation work.
---

Read `docs/agent-workflows/planning-agent.md` before acting.
Plan implementation work.
SKILL

  cat > "$fixture/.claude/skills/planning-agent/SKILL.md" <<'SKILL'
---
name: planning-agent
description: Plan implementation work.
---

Read `docs/agent-workflows/planning-agent.md` before acting.
Plan implementation work.
SKILL

  cat > "$fixture/.github/skills/planning-agent/SKILL.md" <<'SKILL'
---
name: planning-agent
description: Plan implementation work.
---

Read `docs/agent-workflows/planning-agent.md` before acting.
Plan implementation work.
SKILL

  (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/paired.out" 2>&1)
  assert_contains "$TMP_ROOT/paired.out" "planning-agent has canonical workflow doc"
  assert_contains "$TMP_ROOT/paired.out" ".agents/skills/planning-agent/SKILL.md references docs/agent-workflows/planning-agent.md"
  assert_contains "$TMP_ROOT/paired.out" "planning-agent has Codex companion"
  assert_contains "$TMP_ROOT/paired.out" "planning-agent has Claude Code companion"
  assert_contains "$TMP_ROOT/paired.out" "planning-agent has GitHub Copilot companion"
  echo "[PASS] paired workflow skill passes"
}

expect_success_for_paired_role_agent() {
  local fixture="$TMP_ROOT/paired-role-agent"
  copy_base_fixture "$fixture"

  mkdir -p \
    "$fixture/.codex/agents" \
    "$fixture/.claude/agents" \
    "$fixture/.github/agents"

  cat > "$fixture/.codex/agents/release-manager.toml" <<'TOML'
name = "release-manager"
description = "Coordinate release readiness."
developer_instructions = """
Coordinate release readiness.
"""
TOML

  cat > "$fixture/.claude/agents/release-manager.md" <<'AGENT'
---
name: release-manager
description: Coordinate release readiness.
tools: Read, Glob, Grep
---

Coordinate release readiness.
AGENT

  cat > "$fixture/.github/agents/release-manager.md" <<'AGENT'
---
name: release-manager
description: Coordinate release readiness.
tools: [read, search]
---

Coordinate release readiness.
AGENT

  (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/paired-role.out" 2>&1)
  assert_contains "$TMP_ROOT/paired-role.out" "release-manager has Codex companion"
  assert_contains "$TMP_ROOT/paired-role.out" "release-manager has Claude Code companion"
  assert_contains "$TMP_ROOT/paired-role.out" "release-manager has GitHub Copilot companion"
  echo "[PASS] paired role agent passes"
}

expect_failure_for_manifest_companion_missing_canonical_reference() {
  local fixture="$TMP_ROOT/manifest-missing-reference"
  copy_base_fixture "$fixture"

  mkdir -p \
    "$fixture/.agents/skills/planning-agent" \
    "$fixture/.claude/skills/planning-agent" \
    "$fixture/.github/skills/planning-agent"

  cat > "$fixture/docs/agent-workflows/manifest.txt" <<'MANIFEST'
# slug|Label
planning-agent|Planning Agent
MANIFEST
  cat > "$fixture/docs/agent-workflows/planning-agent.md" <<'WORKFLOW'
# Planning Agent

Plan implementation work.
WORKFLOW

  for skill_file in \
    "$fixture/.agents/skills/planning-agent/SKILL.md" \
    "$fixture/.claude/skills/planning-agent/SKILL.md" \
    "$fixture/.github/skills/planning-agent/SKILL.md"; do
    cat > "$skill_file" <<'SKILL'
---
name: planning-agent
description: Plan implementation work.
---

Plan implementation work without a canonical doc reference.
SKILL
  done

  if (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/manifest-missing-reference.out" 2>&1); then
    echo "Expected verify-harness to fail for manifest companions without canonical references." >&2
    cat "$TMP_ROOT/manifest-missing-reference.out" >&2
    exit 1
  fi

  assert_contains "$TMP_ROOT/manifest-missing-reference.out" ".agents/skills/planning-agent/SKILL.md does not reference canonical workflow doc: docs/agent-workflows/planning-agent.md"
  echo "[PASS] manifest companion without canonical reference fails"
}

expect_failure_for_codex_agent_name_mismatch() {
  local fixture="$TMP_ROOT/codex-agent-name-mismatch"
  copy_base_fixture "$fixture"

  mkdir -p \
    "$fixture/.codex/agents" \
    "$fixture/.claude/agents" \
    "$fixture/.github/agents"

  cat > "$fixture/.codex/agents/release-manager.toml" <<'TOML'
name = "wrong-release-manager"
description = "Coordinate release readiness."
developer_instructions = """
Coordinate release readiness.
"""
TOML

  cat > "$fixture/.claude/agents/release-manager.md" <<'AGENT'
---
name: release-manager
description: Coordinate release readiness.
tools: Read, Glob, Grep
---

Coordinate release readiness.
AGENT

  cat > "$fixture/.github/agents/release-manager.md" <<'AGENT'
---
name: release-manager
description: Coordinate release readiness.
tools: [read, search]
---

Coordinate release readiness.
AGENT

  if (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/codex-agent-name-mismatch.out" 2>&1); then
    echo "Expected verify-harness to fail for a Codex agent TOML name mismatch." >&2
    cat "$TMP_ROOT/codex-agent-name-mismatch.out" >&2
    exit 1
  fi

  assert_contains "$TMP_ROOT/codex-agent-name-mismatch.out" ".codex/agents/release-manager.toml missing matching TOML name: release-manager"
  echo "[PASS] Codex agent name mismatch fails"
}

expect_failure_for_buildkite_missing_quality_guard() {
  local fixture="$TMP_ROOT/buildkite-missing-quality-guard"
  copy_base_fixture "$fixture"

  cat > "$fixture/.buildkite/pipeline.yml" <<'YML'
steps:
  - label: package
    key: "package"
    command: "script/ci.sh package"
  - label: verify
    key: "verify-harness"
    command: "scripts/verify-harness.sh"
    depends_on: "package"
YML

  if (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/buildkite-missing-quality-guard.out" 2>&1); then
    echo "Expected verify-harness to fail when Buildkite omits the quality guard step." >&2
    cat "$TMP_ROOT/buildkite-missing-quality-guard.out" >&2
    exit 1
  fi

  assert_contains "$TMP_ROOT/buildkite-missing-quality-guard.out" "Buildkite pipeline does not define quality guard step"
  assert_contains "$TMP_ROOT/buildkite-missing-quality-guard.out" "Buildkite pipeline does not run fast quality guard"
  echo "[PASS] Buildkite missing quality guard fails"
}

expect_failure_for_buildkite_quality_guard_missing_base_fetch() {
  local fixture="$TMP_ROOT/buildkite-missing-base-fetch"
  copy_base_fixture "$fixture"

  cat > "$fixture/.buildkite/pipeline.yml" <<'YML'
steps:
  - label: package
    key: "package"
    command: "script/ci.sh package"
  - label: verify
    key: "verify-harness"
    command: "scripts/verify-harness.sh"
    depends_on: "package"
  - label: ":shield: Quality guard"
    key: "quality-guard"
    command: |
      export QUALITY_GUARD_BASE_REF="origin/main"
      scripts/quality-guard.sh --fast
    depends_on: "verify-harness"
YML

  if (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/buildkite-missing-base-fetch.out" 2>&1); then
    echo "Expected verify-harness to fail when Buildkite omits the quality guard base fetch." >&2
    cat "$TMP_ROOT/buildkite-missing-base-fetch.out" >&2
    exit 1
  fi

  assert_contains "$TMP_ROOT/buildkite-missing-base-fetch.out" "Buildkite quality guard does not fetch base ref"
  echo "[PASS] Buildkite quality guard missing base fetch fails"
}

expect_failure_for_planner_agents_missing_status_tools() {
  local fixture="$TMP_ROOT/planner-missing-status-tools"
  copy_base_fixture "$fixture"

  mkdir -p \
    "$fixture/.codex/agents" \
    "$fixture/.claude/agents" \
    "$fixture/.github/agents"

  cat > "$fixture/.codex/agents/planner.toml" <<'TOML'
name = "planner"
description = "Plans Quiltwright work before implementation."
developer_instructions = """
Read docs/agent-workflows/planning-loop.md before acting.
"""
TOML

  cat > "$fixture/.claude/agents/planner.md" <<'AGENT'
---
name: planner
description: Use when planning Quiltwright work before implementation.
tools: Read, Glob, Grep, Edit, Write
---

Plan Quiltwright work.
AGENT

  cat > "$fixture/.github/agents/planner.md" <<'AGENT'
---
name: planner
description: Plans Quiltwright work before implementation.
tools: [read, search, edit]
---

Plan Quiltwright work.
AGENT

  if (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/planner-missing-status-tools.out" 2>&1); then
    echo "Expected verify-harness to fail when planner agents cannot run status commands." >&2
    cat "$TMP_ROOT/planner-missing-status-tools.out" >&2
    exit 1
  fi

  assert_contains "$TMP_ROOT/planner-missing-status-tools.out" "Claude planner missing Bash tool required by planning-loop"
  assert_contains "$TMP_ROOT/planner-missing-status-tools.out" "GitHub Copilot planner missing execute tool required by planning-loop"
  echo "[PASS] planner agents missing status tools fail"
}

expect_failure_for_unpaired_copilot_skill() {
  local fixture="$TMP_ROOT/unpaired-copilot-skill"
  copy_base_fixture "$fixture"

  mkdir -p "$fixture/.github/skills/planning-agent"

  cat > "$fixture/.github/skills/planning-agent/SKILL.md" <<'SKILL'
---
name: planning-agent
description: Plan implementation work.
---

Plan implementation work.
SKILL

  if (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/unpaired-copilot.out" 2>&1); then
    echo "Expected verify-harness to fail for an unpaired Copilot skill." >&2
    cat "$TMP_ROOT/unpaired-copilot.out" >&2
    exit 1
  fi

  assert_contains "$TMP_ROOT/unpaired-copilot.out" "planning-agent missing Codex companion"
  assert_contains "$TMP_ROOT/unpaired-copilot.out" "planning-agent missing Claude Code companion"
  echo "[PASS] unpaired Copilot skill fails with companion errors"
}

expect_failure_for_unpaired_claude_skill() {
  local fixture="$TMP_ROOT/unpaired-claude-skill"
  copy_base_fixture "$fixture"

  mkdir -p "$fixture/.claude/skills/planning-agent"

  cat > "$fixture/.claude/skills/planning-agent/SKILL.md" <<'SKILL'
---
name: planning-agent
description: Plan implementation work.
---

Plan implementation work.
SKILL

  if (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/unpaired-claude.out" 2>&1); then
    echo "Expected verify-harness to fail for an unpaired Claude Code skill." >&2
    cat "$TMP_ROOT/unpaired-claude.out" >&2
    exit 1
  fi

  assert_contains "$TMP_ROOT/unpaired-claude.out" "planning-agent missing Codex companion"
  assert_contains "$TMP_ROOT/unpaired-claude.out" "planning-agent missing GitHub Copilot companion"
  echo "[PASS] unpaired Claude Code skill fails with companion errors"
}

expect_success_for_rationale_file() {
  local fixture="$TMP_ROOT/rationale-skill"
  copy_base_fixture "$fixture"

  mkdir -p \
    "$fixture/.agents/skills/planning-agent" \
    "$fixture/docs/agent-tooling"

  cat > "$fixture/.agents/skills/planning-agent/SKILL.md" <<'SKILL'
---
name: planning-agent
description: Plan implementation work.
---

Plan implementation work.
SKILL

  cat > "$fixture/docs/agent-tooling/planning-agent.md" <<'RATIONALE'
# planning-agent

Codex has a skill for this workflow. Claude Code and GitHub Copilot do not have
separate companions because this repository is documenting a Codex-only
experiment; this rationale must be revisited before the workflow graduates.
RATIONALE

  (cd "$fixture" && scripts/verify-harness.sh > "$TMP_ROOT/rationale.out" 2>&1)
  assert_contains "$TMP_ROOT/rationale.out" "planning-agent has cross-agent rationale"
  echo "[PASS] rationale file can intentionally waive missing companions"
}

expect_failure_for_unpaired_codex_skill
expect_failure_for_manifest_required_workflow_without_companions
expect_failure_for_manifest_workflow_missing_doc
expect_failure_for_malformed_manifest_record
expect_failure_for_invalid_manifest_slug
expect_failure_for_manifest_empty_label
expect_failure_for_manifest_empty_slug
expect_failure_for_manifest_extra_field
expect_success_for_paired_workflow_skill
expect_success_for_paired_role_agent
expect_failure_for_manifest_companion_missing_canonical_reference
expect_failure_for_codex_agent_name_mismatch
expect_failure_for_buildkite_missing_quality_guard
expect_failure_for_buildkite_quality_guard_missing_base_fetch
expect_failure_for_planner_agents_missing_status_tools
expect_failure_for_unpaired_copilot_skill
expect_failure_for_unpaired_claude_skill
expect_success_for_rationale_file
