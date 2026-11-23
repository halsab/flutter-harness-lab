#!/usr/bin/env bash
# Read-only verification of a feature branch's open GitHub PR.
set -euo pipefail
fail() { printf 'BLOCKED PR: %s\n' "$*" >&2; exit 3; }
PROJECT="${1:-.}"
BASE="${2:-}"
[[ -n "$BASE" ]] || fail "Usage: verify-pr.sh PROJECT BASE_BRANCH"
[[ -d "$PROJECT/.git" || -f "$PROJECT/.git" ]] || fail "Not a Git checkout: $PROJECT"
ROOT="$(cd "$PROJECT" && pwd -P)"
branch="$(git -C "$ROOT" symbolic-ref --quiet --short HEAD)" ||
  fail "Detached HEAD: expected a feature branch."
[[ "$branch" != "$BASE" && "$branch" != main && "$branch" != master ]] ||
  fail "Refusing integration/protected branch: $branch"
command -v gh >/dev/null 2>&1 || fail "GitHub CLI not found."
record="$(cd "$ROOT" && gh pr view --json url,baseRefName,state --jq '[.url,.baseRefName,.state] | @tsv' 2>/dev/null)" ||
  fail "No PR found for $branch; push with approval and create the PR."
IFS=$'\t' read -r url actual_base state <<< "$record"
[[ -n "$url" && "$url" == https://github.com/* ]] || fail "Invalid PR URL."
[[ "$actual_base" == "$BASE" ]] || fail "Wrong PR base: $actual_base (expected $BASE)."
[[ "$state" == OPEN ]] || fail "PR is $state, not OPEN."
printf 'PASS PR %s -> %s: %s\n' "$branch" "$BASE" "$url"
