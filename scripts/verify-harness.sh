#!/usr/bin/env bash
# verify-harness.sh - Verify that the agent harness is consistent and complete.
set -euo pipefail

PASS=0
FAIL=0
WARN=0

pass() {
  PASS=$((PASS + 1))
  echo "[PASS] $1"
}

fail() {
  FAIL=$((FAIL + 1))
  echo "[FAIL] $1" >&2
}

warn() {
  WARN=$((WARN + 1))
  echo "[WARN] $1"
}

section() {
  echo ""
  echo "== $1 =="
}

agent_files=(
  "CLAUDE.md"
  "AGENTS.md"
  ".github/copilot-instructions.md"
)

required_commands=(
  "script/ci.sh package"
  "script/ci.sh macos"
  "script/ci.sh ios"
  "script/ci.sh all"
  "scripts/verify-harness.sh"
  "scripts/test-verify-harness.sh"
  "scripts/quality-guard.sh --fast"
  "scripts/quality-guard.sh --full"
  "scripts/test-quality-guard.sh"
)

section "Agent files"

for file in "${agent_files[@]}"; do
  if [[ -f "$file" ]]; then
    pass "Found $file"
  else
    fail "Missing $file"
  fi
done

section "Module path existence"

if [[ -f ARCHITECTURE.md ]]; then
  module_paths=()
  while IFS= read -r path; do
    module_paths+=("$path")
  done < <(
    awk '
      /^## Module Map/ { in_map = 1; next }
      /^## / && in_map { exit }
      in_map && /^\|/ && $0 !~ /^\|[-| ]+\|$/ && $0 !~ /^\| Module / {
        split($0, cols, "|")
        path = cols[3]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", path)
        gsub(/`/, "", path)
        if (path != "") print path
      }
    ' ARCHITECTURE.md
  )

  if [[ ${#module_paths[@]} -eq 0 ]]; then
    fail "No module paths found in ARCHITECTURE.md"
  fi

  for path in "${module_paths[@]}"; do
    IFS=',' read -ra parts <<< "$path"
    for part in "${parts[@]}"; do
      trimmed="$(echo "$part" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      if [[ -e "$trimmed" ]]; then
        pass "Path exists: $trimmed"
      else
        fail "Path missing: $trimmed"
      fi
    done
  done
else
  fail "ARCHITECTURE.md not found"
fi

section "Required sections"

required_sections=("Commands" "Architecture" "Harness Evolution")

for file in "${agent_files[@]}"; do
  [[ -f "$file" ]] || continue
  for section_name in "${required_sections[@]}"; do
    if grep -qi "$section_name" "$file"; then
      pass "$file contains $section_name"
    else
      fail "$file missing $section_name"
    fi
  done
done

section "Command consistency"

for file in "${agent_files[@]}"; do
  [[ -f "$file" ]] || continue
  for command in "${required_commands[@]}"; do
    if grep -Fq "$command" "$file"; then
      pass "$file references $command"
    else
      fail "$file missing command reference: $command"
    fi
  done
done

section "Cross-agent tooling policy"

for file in "${agent_files[@]}"; do
  [[ -f "$file" ]] || continue
  for term in "Codex" "Claude Code" "GitHub Copilot" ".codex"; do
    if grep -Fq "$term" "$file"; then
      pass "$file references $term"
    else
      fail "$file missing cross-agent tooling term: $term"
    fi
  done
done

section "Agent workflow companions"

workflow_names=()
manifest_workflow_names=()

add_workflow_name() {
  local name="$1"

  [[ -n "$name" ]] || return
  if [[ ${#workflow_names[@]} -gt 0 ]]; then
    case " ${workflow_names[*]} " in
      *" $name "*) return ;;
    esac
  fi
  workflow_names+=("$name")
}

add_manifest_workflow_name() {
  local name="$1"

  add_workflow_name "$name"
  if [[ ${#manifest_workflow_names[@]} -gt 0 ]]; then
    case " ${manifest_workflow_names[*]} " in
      *" $name "*) return ;;
    esac
  fi
  manifest_workflow_names+=("$name")
}

is_manifest_workflow() {
  local name="$1"

  if [[ ${#manifest_workflow_names[@]} -eq 0 ]]; then
    return 1
  fi
  case " ${manifest_workflow_names[*]} " in
    *" $name "*) return 0 ;;
    *) return 1 ;;
  esac
}

is_valid_workflow_slug() {
  local name="$1"
  [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]
}

trim_manifest_field() {
  local value="$1"

  value="${value%$'\r'}"
  printf '%s\n' "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

collect_skill_dir() {
  local dir="$1"
  local skill_file
  local skill_name

  [[ -d "$dir" ]] || return 0
  for skill_file in "$dir"/*/SKILL.md; do
    [[ -e "$skill_file" ]] || continue
    skill_name="$(basename "$(dirname "$skill_file")")"
    add_workflow_name "$skill_name"
  done
}

collect_named_files() {
  local dir="$1"
  local suffix="$2"
  local file
  local base
  local workflow_name

  [[ -d "$dir" ]] || return 0
  for file in "$dir"/*"$suffix"; do
    [[ -e "$file" ]] || continue
    base="$(basename "$file")"
    workflow_name="${base%$suffix}"
    add_workflow_name "$workflow_name"
  done
}

collect_manifest_workflows() {
  local manifest="docs/agent-workflows/manifest.txt"
  local line
  local line_number=0
  local label
  local trimmed
  local workflow_name

  [[ -f "$manifest" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_number=$((line_number + 1))
    trimmed="$(trim_manifest_field "$line")"

    [[ -z "$trimmed" || "$trimmed" == \#* ]] && continue

    if [[ "$trimmed" != *"|"* ]]; then
      fail "Malformed agent workflow manifest line $line_number: expected slug|Label"
      continue
    fi

    label="${trimmed#*|}"
    if [[ "$label" == *"|"* ]]; then
      fail "Malformed agent workflow manifest line $line_number: expected exactly slug|Label"
      continue
    fi

    workflow_name="$(trim_manifest_field "${trimmed%%|*}")"
    if ! is_valid_workflow_slug "$workflow_name"; then
      fail "Invalid agent workflow slug on line $line_number: $workflow_name"
      continue
    fi

    label="$(trim_manifest_field "$label")"
    if [[ -z "$label" ]]; then
      fail "Malformed agent workflow manifest line $line_number: label must be non-empty"
      continue
    fi

    add_manifest_workflow_name "$workflow_name"
  done < "$manifest"
}

has_codex_workflow() {
  local name="$1"
  [[ -f ".agents/skills/$name/SKILL.md" || -f ".codex/agents/$name.toml" || -f ".codex/skills/$name/SKILL.md" ]]
}

has_claude_workflow() {
  local name="$1"
  [[ -f ".claude/skills/$name/SKILL.md" || -f ".claude/agents/$name.md" || -f ".claude/commands/$name.md" ]]
}

has_copilot_workflow() {
  local name="$1"
  [[ -f ".github/skills/$name/SKILL.md" || -f ".github/agents/$name.md" || -f ".github/instructions/$name.instructions.md" || -f ".github/prompts/$name.prompt.md" ]]
}

has_agent_tooling_rationale() {
  local name="$1"
  [[ -f "docs/agent-tooling/$name.md" ]]
}

has_manifest_workflow_doc() {
  local name="$1"
  [[ -f "docs/agent-workflows/$name.md" ]]
}

validate_canonical_reference() {
  local file="$1"
  local name="$2"
  local canonical="docs/agent-workflows/$name.md"

  [[ -f "$file" ]] || return 0
  if grep -Fq "$canonical" "$file"; then
    pass "$file references $canonical"
  else
    fail "$file does not reference canonical workflow doc: $canonical"
  fi
}

validate_markdown_name_metadata() {
  local file="$1"
  local name="$2"

  [[ -f "$file" ]] || return 0
  if grep -Eq "^name:[[:space:]]*$name[[:space:]]*$" "$file"; then
    pass "$file declares name $name"
  else
    fail "$file missing matching name metadata: $name"
  fi

  if grep -Eq "^description:[[:space:]]*[^[:space:]].*" "$file"; then
    pass "$file declares description metadata"
  else
    fail "$file missing non-empty description metadata"
  fi
}

validate_codex_toml_metadata() {
  local file="$1"
  local name="$2"
  local triple_quote_count

  [[ -f "$file" ]] || return 0
  if grep -Eq "^name[[:space:]]*=[[:space:]]*\"$name\"[[:space:]]*$" "$file"; then
    pass "$file declares name $name"
  else
    fail "$file missing matching TOML name: $name"
  fi

  if grep -Eq "^description[[:space:]]*=[[:space:]]*\"[^\"]+\"[[:space:]]*$" "$file"; then
    pass "$file declares description metadata"
  else
    fail "$file missing non-empty TOML description"
  fi

  if grep -Eq "^developer_instructions[[:space:]]*=[[:space:]]*\"\"\"[[:space:]]*$" "$file"; then
    triple_quote_count="$(grep -o '"""' "$file" | wc -l | tr -d '[:space:]')"
    if [[ "$triple_quote_count" -ge 2 ]]; then
      pass "$file has closed developer_instructions block"
    else
      fail "$file has unclosed developer_instructions block"
    fi
  else
    fail "$file missing developer_instructions block"
  fi
}

validate_workflow_metadata() {
  local name="$1"

  validate_markdown_name_metadata ".agents/skills/$name/SKILL.md" "$name"
  validate_markdown_name_metadata ".codex/skills/$name/SKILL.md" "$name"
  validate_markdown_name_metadata ".claude/skills/$name/SKILL.md" "$name"
  validate_markdown_name_metadata ".github/skills/$name/SKILL.md" "$name"
  validate_markdown_name_metadata ".claude/agents/$name.md" "$name"
  validate_markdown_name_metadata ".github/agents/$name.md" "$name"
  validate_codex_toml_metadata ".codex/agents/$name.toml" "$name"
}

validate_manifest_workflow_references() {
  local name="$1"

  validate_canonical_reference ".agents/skills/$name/SKILL.md" "$name"
  validate_canonical_reference ".codex/skills/$name/SKILL.md" "$name"
  validate_canonical_reference ".claude/skills/$name/SKILL.md" "$name"
  validate_canonical_reference ".github/skills/$name/SKILL.md" "$name"
  validate_canonical_reference ".github/prompts/$name.prompt.md" "$name"
  validate_canonical_reference ".codex/agents/$name.toml" "$name"
  validate_canonical_reference ".claude/agents/$name.md" "$name"
  validate_canonical_reference ".github/agents/$name.md" "$name"
}

collect_manifest_workflows
collect_skill_dir ".agents/skills"
collect_skill_dir ".codex/skills"
collect_skill_dir ".claude/skills"
collect_skill_dir ".github/skills"
collect_named_files ".codex/agents" ".toml"
collect_named_files ".claude/agents" ".md"
collect_named_files ".github/agents" ".md"
collect_named_files ".claude/commands" ".md"
collect_named_files ".github/instructions" ".instructions.md"
collect_named_files ".github/prompts" ".prompt.md"

if [[ ${#workflow_names[@]} -eq 0 ]]; then
  pass "No agent-specific workflow artifacts found"
else
  for workflow_name in "${workflow_names[@]}"; do
    validate_workflow_metadata "$workflow_name"

    if is_manifest_workflow "$workflow_name"; then
      if has_manifest_workflow_doc "$workflow_name"; then
        pass "$workflow_name has canonical workflow doc"
      else
        fail "$workflow_name missing canonical workflow doc: add docs/agent-workflows/$workflow_name.md"
      fi
      validate_manifest_workflow_references "$workflow_name"
    fi

    if has_agent_tooling_rationale "$workflow_name"; then
      pass "$workflow_name has cross-agent rationale"
      continue
    fi

    if has_codex_workflow "$workflow_name"; then
      pass "$workflow_name has Codex companion"
    else
      fail "$workflow_name missing Codex companion: add .agents/skills/$workflow_name/SKILL.md, .codex/agents/$workflow_name.toml, .codex/skills/$workflow_name/SKILL.md, or docs/agent-tooling/$workflow_name.md"
    fi

    if has_claude_workflow "$workflow_name"; then
      pass "$workflow_name has Claude Code companion"
    else
      fail "$workflow_name missing Claude Code companion: add .claude/skills/$workflow_name/SKILL.md, .claude/agents/$workflow_name.md, .claude/commands/$workflow_name.md, or docs/agent-tooling/$workflow_name.md"
    fi

    if has_copilot_workflow "$workflow_name"; then
      pass "$workflow_name has GitHub Copilot companion"
    else
      fail "$workflow_name missing GitHub Copilot companion: add .github/skills/$workflow_name/SKILL.md, .github/agents/$workflow_name.md, .github/instructions/$workflow_name.instructions.md, .github/prompts/$workflow_name.prompt.md, or docs/agent-tooling/$workflow_name.md"
    fi
  done
fi

section "Role agent tool requirements"

if [[ -f .claude/agents/planner.md ]]; then
  if grep -Eq '^tools:.*Bash' .claude/agents/planner.md; then
    pass "Claude planner can run repository status commands"
  else
    fail "Claude planner missing Bash tool required by planning-loop"
  fi
else
  warn "Claude planner agent not found"
fi

if [[ -f .github/agents/planner.md ]]; then
  if grep -Eq '^tools:.*execute' .github/agents/planner.md; then
    pass "GitHub Copilot planner can run repository status commands"
  else
    fail "GitHub Copilot planner missing execute tool required by planning-loop"
  fi
else
  warn "GitHub Copilot planner agent not found"
fi

section "ADR structure"

if [[ -d docs/adr ]]; then
  for adr_file in docs/adr/*.md; do
    [[ -e "$adr_file" ]] || continue
    base="$(basename "$adr_file")"
    if [[ "$base" == "template.md" ]]; then
      pass "ADR template present"
    elif [[ "$base" =~ ^[0-9]{3,}-[a-z0-9]([a-z0-9-]*[a-z0-9])?\.md$ ]]; then
      pass "ADR naming OK: $base"
    else
      fail "ADR naming invalid: $base"
    fi
  done
else
  fail "docs/adr not found"
fi

section "Buildkite integration"

if [[ -f .buildkite/pipeline.yml ]]; then
  quality_guard_block="$(
    awk '
      /^  - label:/ {
        if (in_quality_guard) exit
        if ($0 ~ /Quality guard/) in_quality_guard = 1
      }
      in_quality_guard { print }
    ' .buildkite/pipeline.yml
  )"

  if grep -Fq "scripts/verify-harness.sh" .buildkite/pipeline.yml; then
    pass "Buildkite pipeline runs harness verification"
  else
    fail "Buildkite pipeline does not run harness verification"
  fi

  if [[ -n "$quality_guard_block" ]]; then
    pass "Buildkite pipeline has quality guard step block"
  else
    fail "Buildkite pipeline does not define quality guard step"
  fi

  if grep -Fq 'key: "quality-guard"' <<< "$quality_guard_block"; then
    pass "Buildkite quality guard step has expected key"
  else
    fail "Buildkite quality guard step is missing key: quality-guard"
  fi

  if grep -Fq "scripts/quality-guard.sh --fast" <<< "$quality_guard_block"; then
    pass "Buildkite pipeline runs fast quality guard"
  else
    fail "Buildkite pipeline does not run fast quality guard"
  fi

  if grep -Fq 'depends_on: "verify-harness"' <<< "$quality_guard_block"; then
    pass "Buildkite quality guard depends on harness verification"
  else
    fail "Buildkite quality guard is not ordered after harness verification"
  fi

  if grep -Fq "QUALITY_GUARD_BASE_REF" <<< "$quality_guard_block"; then
    pass "Buildkite pipeline provides quality guard base-ref wiring"
  else
    fail "Buildkite pipeline does not provide quality guard base-ref wiring"
  fi

  if grep -Fq "git fetch --no-tags" <<< "$quality_guard_block"; then
    pass "Buildkite quality guard fetches base ref"
  else
    fail "Buildkite quality guard does not fetch base ref"
  fi
else
  warn "No Buildkite pipeline found"
fi

section "EVOLVE markers"

evolve_count=0
while IFS= read -r marker; do
  evolve_count=$((evolve_count + 1))
  warn "EVOLVE marker: $marker"
done < <(grep -rn '<!-- EVOLVE:' --include='*.md' . 2>/dev/null || true)

if [[ "$evolve_count" -eq 0 ]]; then
  pass "No EVOLVE markers found"
fi

echo ""
echo "Summary"
echo "Passed:   $PASS"
echo "Failed:   $FAIL"
echo "Warnings: $WARN"

if [[ "$FAIL" -gt 0 ]]; then
  echo "Verification FAILED."
  exit 1
fi

echo "Verification PASSED."
