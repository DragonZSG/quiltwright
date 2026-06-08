#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  echo "Usage: scripts/quality-guard.sh [--fast|--full]"
}

section() {
  echo ""
  echo "== $1 =="
}

run_command() {
  echo "+ $*"
  "$@"
}

skip() {
  echo "[SKIP] $1: $2"
}

changed_paths=()
changed_paths_source="none"

add_changed_path() {
  local path="$1"
  local existing

  [[ -n "$path" ]] || return 0

  if [[ ${#changed_paths[@]} -gt 0 ]]; then
    for existing in "${changed_paths[@]}"; do
      if [[ "$existing" == "$path" ]]; then
        return 0
      fi
    done
  fi

  changed_paths+=("$path")
}

collect_paths_from_base_ref() {
  local base_ref="$1"
  local source_label="$2"
  local strict="${3:-false}"
  local before_count="${#changed_paths[@]}"
  local merge_base
  local path

  if ! git rev-parse --verify -q "${base_ref}^{commit}" >/dev/null; then
    if [[ "$strict" == "true" ]]; then
      echo "Base ref does not resolve to a commit: $base_ref" >&2
      return 2
    fi
    return 1
  fi

  merge_base="$(git merge-base "$base_ref" HEAD 2>/dev/null || true)"
  if [[ -z "$merge_base" ]]; then
    if [[ "$strict" == "true" ]]; then
      echo "Base ref has no merge-base with HEAD: $base_ref" >&2
      return 2
    fi
    return 1
  fi

  while IFS= read -r path; do
    add_changed_path "$path"
  done < <(git diff --name-only "$merge_base..HEAD" --)

  if [[ ${#changed_paths[@]} -gt "$before_count" ]]; then
    changed_paths_source="$source_label ($base_ref via merge-base ${merge_base:0:12})"
    return 0
  fi

  return 1
}

collect_changed_paths() {
  local base_ref="${QUALITY_GUARD_BASE_REF:-}"
  local base_branch="${BUILDKITE_PULL_REQUEST_BASE_BRANCH:-}"
  local default_branch="${BUILDKITE_PIPELINE_DEFAULT_BRANCH:-}"
  local build_branch="${BUILDKITE_BRANCH:-}"
  local buildkite_base_branch=""
  local path
  local status

  while IFS= read -r path; do
    add_changed_path "$path"
  done < <(git diff --name-only HEAD --)

  while IFS= read -r path; do
    add_changed_path "$path"
  done < <(git ls-files --others --exclude-standard)

  if [[ ${#changed_paths[@]} -gt 0 ]]; then
    changed_paths_source="working tree"
    return 0
  fi

  if [[ -n "$base_ref" ]]; then
    if collect_paths_from_base_ref "$base_ref" "QUALITY_GUARD_BASE_REF" true; then
      return 0
    fi
    status=$?
    if [[ "$status" -eq 2 ]]; then
      return 2
    fi
  fi

  if [[ -n "${BUILDKITE:-}" ]]; then
    if [[ -n "$base_branch" && "$base_branch" != "false" ]]; then
      buildkite_base_branch="$base_branch"
    elif [[ -n "$default_branch" && "$build_branch" != "$default_branch" ]]; then
      buildkite_base_branch="$default_branch"
    fi

    if [[ -n "$buildkite_base_branch" ]]; then
      if collect_paths_from_base_ref "origin/$buildkite_base_branch" "Buildkite merge-base"; then
        return 0
      fi
      if collect_paths_from_base_ref "$buildkite_base_branch" "Buildkite merge-base"; then
        return 0
      fi
      echo "Buildkite base branch does not resolve locally: $buildkite_base_branch" >&2
      echo "Fetch the base branch or set QUALITY_GUARD_BASE_REF before running the quality guard." >&2
      return 2
    fi

    if git rev-parse --verify -q "HEAD^" >/dev/null; then
      while IFS= read -r path; do
        add_changed_path "$path"
      done < <(git diff --name-only "HEAD^..HEAD" --)

      if [[ ${#changed_paths[@]} -gt 0 ]]; then
        changed_paths_source="HEAD^ fallback"
        return 0
      fi
    else
      echo "[INFO] HEAD^ is unavailable; no Buildkite fallback diff was run."
    fi
  fi

  changed_paths_source="none"
}

is_markdown_file() {
  [[ "$1" == *.md ]]
}

is_shell_file() {
  [[ "$1" == *.sh ]]
}

is_docs_or_workflow_markdown() {
  local path="$1"

  is_markdown_file "$path" || return 1

  case "$path" in
    docs/*|.agents/*|.claude/*|.github/*|AGENTS.md|CLAUDE.md|ARCHITECTURE.md|README.md|STYLEGUIDE.md)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_swift_or_package_relevant() {
  case "$1" in
    Package.swift|Sources/*|Tests/*|Quiltwright.xcodeproj/*|script/ci.sh|.buildkite/pipeline.yml)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

needs_package_ci() {
  case "$1" in
    Quiltwright.xcodeproj/*|script/ci.sh|.buildkite/pipeline.yml)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

print_changed_paths() {
  local path

  section "Changed paths"
  echo "Source: $changed_paths_source"
  if [[ ${#changed_paths[@]} -eq 0 ]]; then
    echo "No changed paths found."
    return 0
  fi

  for path in "${changed_paths[@]}"; do
    echo "- $path"
  done
}

run_shell_syntax_checks() {
  local shell_files=()
  local path

  section "Shell syntax"
  if [[ ${#changed_paths[@]} -gt 0 ]]; then
    for path in "${changed_paths[@]}"; do
      if is_shell_file "$path" && [[ -f "$path" ]]; then
        shell_files+=("$path")
      fi
    done
  fi

  if [[ ${#shell_files[@]} -eq 0 ]]; then
    skip "Shell syntax" "no changed .sh files"
    return 0
  fi

  for path in "${shell_files[@]}"; do
    run_command bash -n "$path"
  done
}

run_markdown_fence_checks() {
  local markdown_files=()
  local path
  local fence_count
  local bad=0

  section "Markdown fence balance"
  if [[ ${#changed_paths[@]} -gt 0 ]]; then
    for path in "${changed_paths[@]}"; do
      if is_markdown_file "$path" && [[ -f "$path" ]]; then
        markdown_files+=("$path")
      fi
    done
  fi

  if [[ ${#markdown_files[@]} -eq 0 ]]; then
    skip "Markdown fence balance" "no changed .md files"
    return 0
  fi

  echo "+ awk <changed-markdown-fence-check>"
  for path in "${markdown_files[@]}"; do
    fence_count="$(awk '/^```/ { count++ } END { print count + 0 }' "$path")"
    if (( fence_count % 2 != 0 )); then
      echo "$path: unbalanced markdown fences" >&2
      bad=1
    else
      echo "[PASS] $path"
    fi
  done

  if (( bad != 0 )); then
    return 1
  fi
}

run_placeholder_scan() {
  local docs_files=()
  local path
  local grep_status
  local placeholder_pattern

  section "Placeholder scan"
  if [[ ${#changed_paths[@]} -gt 0 ]]; then
    for path in "${changed_paths[@]}"; do
      if is_docs_or_workflow_markdown "$path" && [[ -f "$path" ]]; then
        docs_files+=("$path")
      fi
    done
  fi

  if [[ ${#docs_files[@]} -eq 0 ]]; then
    skip "Placeholder scan" "no changed docs or workflow markdown files"
    return 0
  fi

  placeholder_pattern='(^|[^[:alnum:]_])(tbd|todo|to[[:space:]-]+be[[:space:]-]+determined|fill[[:space:]-]+in|implement[[:space:]-]+later)([^[:alnum:]_]|$)'
  echo "+ grep -E -n -i -H \"\$PLACEHOLDER_PATTERN\" <changed-docs-and-workflow-markdown>"
  for path in "${docs_files[@]}"; do
    echo "[SCAN] $path"
  done
  set +e
  grep -E -n -i -H "$placeholder_pattern" "${docs_files[@]}"
  grep_status=$?
  set -e

  case "$grep_status" in
    0)
      echo "Placeholder text found in changed docs or workflow markdown." >&2
      return 1
      ;;
    1)
      echo "[PASS] No placeholder text found"
      ;;
    *)
      echo "grep failed while scanning for placeholder text." >&2
      return "$grep_status"
      ;;
  esac
}

run_swift_or_package_check() {
  local path
  local relevant=0
  local package_ci=0

  section "Swift/package check"
  if [[ ${#changed_paths[@]} -gt 0 ]]; then
    for path in "${changed_paths[@]}"; do
      if is_swift_or_package_relevant "$path"; then
        relevant=1
      fi
      if needs_package_ci "$path"; then
        package_ci=1
      fi
    done
  fi

  if [[ "$relevant" -eq 0 ]]; then
    skip "Swift/package check" "no Package.swift, Sources, Tests, project, CI, or package-script changes"
    return 0
  fi

  if [[ "$package_ci" -eq 1 ]]; then
    echo "Project metadata or CI changed; running package CI entry point."
    run_command script/ci.sh package
  else
    echo "Swift package sources changed; running targeted package checks."
    run_command swift run QuiltwrightChecks
  fi
}

run_fast_checks() {
  section "Harness verification"
  run_command scripts/verify-harness.sh

  run_shell_syntax_checks
  run_markdown_fence_checks
  run_placeholder_scan
  run_swift_or_package_check
}

mode="${1:---fast}"

case "$mode" in
  --fast|--full)
    ;;
  --help|-h)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 2
fi

echo "Quality guard"
echo "Mode: $mode"

collect_changed_paths
print_changed_paths
run_fast_checks

if [[ "$mode" == "--full" ]]; then
  section "Full CI"
  run_command script/ci.sh all
fi
