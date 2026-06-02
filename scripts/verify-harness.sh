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
  if grep -Fq "scripts/verify-harness.sh" .buildkite/pipeline.yml; then
    pass "Buildkite pipeline runs harness verification"
  else
    fail "Buildkite pipeline does not run harness verification"
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
