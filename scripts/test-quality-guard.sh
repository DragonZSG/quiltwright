#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$ROOT_DIR/scripts/quality-guard.sh"
TMP_ROOT="${TMPDIR:-/tmp}"
FIXTURES=()
LAST_FIXTURE=""

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

pass() {
  echo "[PASS] $1"
}

require_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"

  if [[ "$haystack" != *"$needle"* ]]; then
    echo "$haystack" >&2
    fail "$label: expected output to contain '$needle'"
  fi
}

new_fixture() {
  local tmp

  tmp="$(mktemp -d "$TMP_ROOT/quality-guard-test.XXXXXX")"
  LAST_FIXTURE="$tmp"
  FIXTURES+=("$tmp")

  mkdir -p "$tmp/scripts" "$tmp/script" "$tmp/docs" "$tmp/Sources/QuiltwrightUI" "$tmp/.buildkite"
  cp "$GUARD" "$tmp/scripts/quality-guard.sh"
  chmod +x "$tmp/scripts/quality-guard.sh"

  cat > "$tmp/scripts/verify-harness.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo "verify" >> commands.log
SH
  chmod +x "$tmp/scripts/verify-harness.sh"

  cat > "$tmp/script/ci.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo "ci $*" >> commands.log
SH
  chmod +x "$tmp/script/ci.sh"

  cat > "$tmp/Package.swift" <<'SWIFT'
// swift-tools-version: 5.10
import PackageDescription
let package = Package(name: "fixture")
SWIFT

  cat > "$tmp/Sources/QuiltwrightUI/Fixture.swift" <<'SWIFT'
public struct Fixture {}
SWIFT

  cat > "$tmp/docs/guide.md" <<'MD'
# Guide

```sh
echo ok
```
MD

  cat > "$tmp/.buildkite/pipeline.yml" <<'YML'
steps:
  - label: package
    command: script/ci.sh package
YML

  (
    cd "$tmp"
    git init -q
    git add .
    git -c user.name="Quality Guard Test" -c user.email="quality-guard@example.invalid" commit -qm baseline
  )
}

cleanup() {
  local fixture

  if [[ ${#FIXTURES[@]} -eq 0 ]]; then
    return 0
  fi

  for fixture in "${FIXTURES[@]}"; do
    rm -rf "$fixture"
  done
}

trap cleanup EXIT

test_help_and_invalid_args() {
  local fixture
  local output
  local status

  new_fixture
  fixture="$LAST_FIXTURE"

  output="$("$fixture/scripts/quality-guard.sh" --help)"
  require_contains "$output" "Usage: scripts/quality-guard.sh [--fast|--full]" "help output"

  set +e
  output="$("$fixture/scripts/quality-guard.sh" --bogus 2>&1)"
  status=$?
  set -e

  if [[ "$status" -ne 2 ]]; then
    echo "$output" >&2
    fail "invalid flag exited with $status, expected 2"
  fi
  require_contains "$output" "Usage: scripts/quality-guard.sh [--fast|--full]" "invalid flag output"

  pass "help and invalid argument handling"
}

test_default_fast_changed_paths() {
  local fixture
  local output

  new_fixture
  fixture="$LAST_FIXTURE"

  cat > "$fixture/scripts/check-changed.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo changed
SH

  cat > "$fixture/docs/guide.md" <<'MD'
# Guide

```sh
echo changed
```
MD

  (
    cd "$fixture"
    output="$(scripts/quality-guard.sh 2>&1)"
    require_contains "$output" "Mode: --fast" "default mode"
    require_contains "$output" "Source: working tree" "default changed path source"
    require_contains "$output" "scripts/check-changed.sh" "changed shell path"
    require_contains "$output" "docs/guide.md" "changed markdown path"
    require_contains "$output" "+ bash -n scripts/check-changed.sh" "bash syntax command"
    require_contains "$output" "[PASS] docs/guide.md" "markdown fence check"
    require_contains "$output" "[PASS] No placeholder text found" "placeholder scan"
    require_contains "$output" "[SKIP] Swift/package check" "swift skip"
    grep -qx "verify" commands.log || fail "verify-harness stub did not run"
    if grep -q "^ci " commands.log; then
      fail "package CI should not run for only shell and docs changes"
    fi
  )

  pass "default fast mode covers changed shell and markdown files"
}

test_ci_change_runs_package_check() {
  local fixture
  local output

  new_fixture
  fixture="$LAST_FIXTURE"

  cat > "$fixture/.buildkite/pipeline.yml" <<'YML'
steps:
  - label: package
    command: script/ci.sh package
  - label: guard
    command: scripts/quality-guard.sh --fast
YML

  (
    cd "$fixture"
    output="$(scripts/quality-guard.sh --fast 2>&1)"
    require_contains "$output" "Source: working tree" "CI changed path source"
    require_contains "$output" ".buildkite/pipeline.yml" "changed CI path"
    require_contains "$output" "Project metadata or CI changed; running package CI entry point." "package CI explanation"
    require_contains "$output" "+ script/ci.sh package" "package CI command"
    grep -qx "verify" commands.log || fail "verify-harness stub did not run"
    grep -qx "ci package" commands.log || fail "package CI stub did not run"
  )

  pass "CI changes run package check in fast mode"
}

test_placeholder_scan_fails() {
  local fixture
  local output
  local status

  new_fixture
  fixture="$LAST_FIXTURE"

  cat > "$fixture/docs/guide.md" <<'MD'
# Guide

todo
MD

  set +e
  (
    cd "$fixture"
    scripts/quality-guard.sh --fast
  ) >"$fixture/output.log" 2>&1
  status=$?
  set -e

  output="$(cat "$fixture/output.log")"
  if [[ "$status" -eq 0 ]]; then
    echo "$output" >&2
    fail "placeholder scan unexpectedly passed"
  fi
  require_contains "$output" "docs/guide.md" "lowercase todo path"
  require_contains "$output" "Placeholder text found in changed docs or workflow markdown." "placeholder failure"

  pass "placeholder scan fails on lowercase todo placeholders"
}

test_to_be_determined_placeholder_scan_fails() {
  local fixture
  local output
  local status

  new_fixture
  fixture="$LAST_FIXTURE"

  cat > "$fixture/README.md" <<'MD'
# Fixture

to be determined
MD

  set +e
  (
    cd "$fixture"
    scripts/quality-guard.sh --fast
  ) >"$fixture/output.log" 2>&1
  status=$?
  set -e

  output="$(cat "$fixture/output.log")"
  if [[ "$status" -eq 0 ]]; then
    echo "$output" >&2
    fail "to be determined placeholder scan unexpectedly passed"
  fi
  require_contains "$output" "README.md" "to be determined path"
  require_contains "$output" "Placeholder text found in changed docs or workflow markdown." "to be determined placeholder failure"

  pass "placeholder scan fails on to be determined placeholders"
}

test_nested_workflow_placeholder_scan_fails() {
  local fixture
  local output
  local status

  new_fixture
  fixture="$LAST_FIXTURE"

  mkdir -p "$fixture/docs/agent-workflows"
  cat > "$fixture/docs/agent-workflows/planning-loop.md" <<'MD'
# Planning Loop

implement later
MD

  set +e
  (
    cd "$fixture"
    scripts/quality-guard.sh --fast
  ) >"$fixture/output.log" 2>&1
  status=$?
  set -e

  output="$(cat "$fixture/output.log")"
  if [[ "$status" -eq 0 ]]; then
    echo "$output" >&2
    fail "nested workflow placeholder scan unexpectedly passed"
  fi
  require_contains "$output" "docs/agent-workflows/planning-loop.md" "nested workflow scan path"
  require_contains "$output" "Placeholder text found in changed docs or workflow markdown." "nested workflow placeholder failure"

  pass "placeholder scan fails on nested workflow markdown placeholders"
}

test_nested_agent_markdown_is_scanned() {
  local fixture
  local output

  new_fixture
  fixture="$LAST_FIXTURE"

  mkdir -p "$fixture/.claude/agents"
  cat > "$fixture/.claude/agents/review-tests.md" <<'MD'
# Review Tests

Check changed verification coverage against the repository commands.
MD

  (
    cd "$fixture"
    output="$(scripts/quality-guard.sh --fast 2>&1)"
    require_contains "$output" "[SCAN] .claude/agents/review-tests.md" "nested agent placeholder scan path"
    require_contains "$output" "[PASS] No placeholder text found" "nested agent placeholder pass"
    grep -qx "verify" commands.log || fail "verify-harness stub did not run"
  )

  pass "placeholder scan includes passing nested agent markdown"
}

test_buildkite_clean_checkout_uses_head_parent() {
  local fixture
  local output

  new_fixture
  fixture="$LAST_FIXTURE"

  (
    cd "$fixture"
    mkdir -p docs/agent-workflows
    cat > docs/agent-workflows/implementation-loop.md <<'MD'
# Implementation Loop

Run the planned repo checks before handoff.
MD
    git add docs/agent-workflows/implementation-loop.md
    git -c user.name="Quality Guard Test" -c user.email="quality-guard@example.invalid" commit -qm "add workflow doc"

    output="$(BUILDKITE=true scripts/quality-guard.sh --fast 2>&1)"
    require_contains "$output" "Source: HEAD^ fallback" "Buildkite clean checkout source"
    require_contains "$output" "[SCAN] docs/agent-workflows/implementation-loop.md" "Buildkite committed markdown scan"
    require_contains "$output" "[PASS] No placeholder text found" "Buildkite placeholder pass"
    grep -qx "verify" commands.log || fail "verify-harness stub did not run"
  )

  pass "Buildkite clean checkout scans committed HEAD change"
}

test_buildkite_pr_merge_base_scans_multiple_commits() {
  local fixture
  local output
  local output_file
  local status

  new_fixture
  fixture="$LAST_FIXTURE"
  output_file="$fixture.pr-merge-base.out"

  (
    cd "$fixture"
    git checkout -q -b feature/multi-commit
    git branch -f main HEAD

    mkdir -p docs/agent-workflows
    cat > docs/agent-workflows/implementation-loop.md <<'MD'
# Implementation Loop

implement later
MD
    git add docs/agent-workflows/implementation-loop.md
    git -c user.name="Quality Guard Test" -c user.email="quality-guard@example.invalid" commit -qm "add incomplete workflow"

    cat > docs/guide.md <<'MD'
# Guide

Clean final commit.
MD
    git add docs/guide.md
    git -c user.name="Quality Guard Test" -c user.email="quality-guard@example.invalid" commit -qm "add clean final doc"

    set +e
    BUILDKITE=true BUILDKITE_PULL_REQUEST_BASE_BRANCH=main scripts/quality-guard.sh --fast > "$output_file" 2>&1
    status=$?
    set -e

    output="$(cat "$output_file")"
    if [[ "$status" -eq 0 ]]; then
      echo "$output" >&2
      fail "Buildkite PR merge-base scan unexpectedly passed despite first-commit placeholder"
    fi
    require_contains "$output" "Source: Buildkite merge-base (main via merge-base" "Buildkite merge-base changed path source"
    require_contains "$output" "[SCAN] docs/agent-workflows/implementation-loop.md" "Buildkite multi-commit workflow scan"
    require_contains "$output" "Placeholder text found in changed docs or workflow markdown." "Buildkite multi-commit placeholder failure"
  )

  pass "Buildkite PR merge-base scans multiple commits"
}

test_buildkite_pr_missing_base_ref_fails() {
  local fixture
  local output
  local output_file
  local status

  new_fixture
  fixture="$LAST_FIXTURE"
  output_file="$fixture.pr-missing-base.out"

  (
    cd "$fixture"
    mkdir -p docs/agent-workflows
    cat > docs/agent-workflows/implementation-loop.md <<'MD'
# Implementation Loop

Run the planned repo checks before handoff.
MD
    git add docs/agent-workflows/implementation-loop.md
    git -c user.name="Quality Guard Test" -c user.email="quality-guard@example.invalid" commit -qm "add workflow doc"

    set +e
    BUILDKITE=true BUILDKITE_PULL_REQUEST_BASE_BRANCH=missing-base scripts/quality-guard.sh --fast > "$output_file" 2>&1
    status=$?
    set -e

    output="$(cat "$output_file")"
    if [[ "$status" -eq 0 ]]; then
      echo "$output" >&2
      fail "Buildkite PR missing-base scan unexpectedly passed"
    fi
    require_contains "$output" "Buildkite base branch does not resolve locally: missing-base" "Buildkite missing base failure"
    require_contains "$output" "Fetch the base branch or set QUALITY_GUARD_BASE_REF" "Buildkite missing base remediation"
    if grep -q "Source: HEAD^ fallback" <<< "$output"; then
      echo "$output" >&2
      fail "Buildkite missing-base scan fell back to HEAD^"
    fi
  )

  pass "Buildkite PR missing base ref fails instead of one-commit fallback"
}

test_quality_guard_base_ref_diff() {
  local fixture
  local output

  new_fixture
  fixture="$LAST_FIXTURE"

  (
    cd "$fixture"
    cat > docs/guide.md <<'MD'
# Guide

Committed doc change.
MD
    git add docs/guide.md
    git -c user.name="Quality Guard Test" -c user.email="quality-guard@example.invalid" commit -qm "update guide"

    output="$(QUALITY_GUARD_BASE_REF=HEAD^ scripts/quality-guard.sh --fast 2>&1)"
    require_contains "$output" "Source: QUALITY_GUARD_BASE_REF (HEAD^ via merge-base" "base ref changed path source"
    require_contains "$output" "[SCAN] docs/guide.md" "base ref markdown scan"
    require_contains "$output" "[PASS] No placeholder text found" "base ref placeholder pass"
  )

  pass "QUALITY_GUARD_BASE_REF scans committed diff"
}

test_invalid_shell_syntax_fails() {
  local fixture
  local output
  local status

  new_fixture
  fixture="$LAST_FIXTURE"

  cat > "$fixture/scripts/bad.sh" <<'SH'
#!/usr/bin/env bash
if true; then
  echo bad
SH

  set +e
  (
    cd "$fixture"
    scripts/quality-guard.sh --fast
  ) >"$fixture/output.log" 2>&1
  status=$?
  set -e

  output="$(cat "$fixture/output.log")"
  if [[ "$status" -eq 0 ]]; then
    echo "$output" >&2
    fail "invalid shell syntax unexpectedly passed"
  fi
  require_contains "$output" "+ bash -n scripts/bad.sh" "invalid shell syntax command"
  require_contains "$output" "scripts/bad.sh" "invalid shell syntax path"

  pass "invalid changed shell syntax fails"
}

test_unbalanced_markdown_fence_fails() {
  local fixture
  local output
  local status

  new_fixture
  fixture="$LAST_FIXTURE"

  cat > "$fixture/docs/guide.md" <<'MD'
# Guide

```sh
echo missing closing fence
MD

  set +e
  (
    cd "$fixture"
    scripts/quality-guard.sh --fast
  ) >"$fixture/output.log" 2>&1
  status=$?
  set -e

  output="$(cat "$fixture/output.log")"
  if [[ "$status" -eq 0 ]]; then
    echo "$output" >&2
    fail "unbalanced markdown fence unexpectedly passed"
  fi
  require_contains "$output" "docs/guide.md: unbalanced markdown fences" "unbalanced markdown fence failure"

  pass "unbalanced changed markdown fence fails"
}

test_full_runs_all_after_fast_checks() {
  local fixture
  local output

  new_fixture
  fixture="$LAST_FIXTURE"

  cat > "$fixture/docs/guide.md" <<'MD'
# Guide

Updated docs with no placeholders.
MD

  (
    cd "$fixture"
    output="$(scripts/quality-guard.sh --full 2>&1)"
    require_contains "$output" "== Harness verification ==" "full mode fast checks"
    require_contains "$output" "== Full CI ==" "full mode section"
    require_contains "$output" "+ script/ci.sh all" "full mode all command"
    grep -qx "verify" commands.log || fail "verify-harness stub did not run"
    grep -qx "ci all" commands.log || fail "full CI stub did not run"
  )

  pass "full mode invokes script/ci.sh all after fast checks"
}

test_help_and_invalid_args
test_default_fast_changed_paths
test_ci_change_runs_package_check
test_placeholder_scan_fails
test_to_be_determined_placeholder_scan_fails
test_nested_workflow_placeholder_scan_fails
test_nested_agent_markdown_is_scanned
test_buildkite_clean_checkout_uses_head_parent
test_buildkite_pr_merge_base_scans_multiple_commits
test_buildkite_pr_missing_base_ref_fails
test_quality_guard_base_ref_diff
test_invalid_shell_syntax_fails
test_unbalanced_markdown_fence_fails
test_full_runs_all_after_fast_checks

pass "quality guard smoke tests"
