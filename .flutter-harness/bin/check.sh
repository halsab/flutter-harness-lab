#!/usr/bin/env bash
# Deterministic verification runner.
set -u
set -o pipefail
usage() { echo "Usage: bash scripts/check.sh PROJECT [quick|standard|full] [mobile|mobile-web]" >&2; exit 2; }
PROJECT="${1:-}"
LEVEL="${2:-standard}"
PROFILE="${3:-}"
[[ -n "$PROJECT" && -f "$PROJECT/pubspec.yaml" ]] || usage
[[ "$LEVEL" == "quick" || "$LEVEL" == "standard" || "$LEVEL" == "full" ]] || usage
[[ "$PROFILE" == "mobile" || "$PROFILE" == "mobile-web" ]] || usage
command -v flutter >/dev/null 2>&1 || { echo "BLOCKED: flutter missing from PATH" >&2; exit 3; }
command -v dart >/dev/null 2>&1 || { echo "BLOCKED: dart missing from PATH" >&2; exit 3; }
PROJECT="$(cd "$PROJECT" && pwd -P)"
PROJECT_KEY="$(python3 -c 'import hashlib,sys; print(hashlib.sha256(sys.argv[1].encode()).hexdigest()[:12])' "$PROJECT")"
LOG_DIR="${HARNESS_ARTIFACTS_DIR:-${HOME}/.cache/flutter-harness/$(basename "$PROJECT")-$PROJECT_KEY}"
mkdir -p "$LOG_DIR"
ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
LOG="$LOG_DIR/check-$ID.log"
RESULT="$LOG_DIR/check-$ID.tsv"
printf 'check\tstatus\texit_code\n' > "$RESULT"
failed=0
printf 'Profile: %s; level: %s\n' "$PROFILE" "$LEVEL"

check() {
  local label="$1"
  shift
  printf 'RUN  %s\n' "$label"
  if (cd "$PROJECT" && python3 -c 'import subprocess,sys; sys.exit(subprocess.run(sys.argv[1:], timeout=600).returncode)' "$@") >>"$LOG" 2>&1; then
    printf '%s\tPASS\t0\n' "$label" >>"$RESULT"
    printf 'PASS %s\n' "$label"
  else
    local code="$?"
    printf '%s\tFAIL\t%s\n' "$label" "$code" >>"$RESULT"
    printf 'FAIL %s (exit %s)\n' "$label" "$code"
    failed=1
  fi
}
check format dart format --output=none --set-exit-if-changed lib test
if [[ "$failed" -ne 0 ]]; then
  echo 'Fix formatting first: dart format lib test'
  printf 'Log: %s\nResults: %s\n' "$LOG" "$RESULT"
  exit 1
fi
if [[ -f "$PROJECT/.flutter-harness/product.json" ]]; then
  check product python3 .flutter-harness/bin/check-product.py .
  if [[ "$failed" -ne 0 ]]; then
    printf 'Log: %s\nResults: %s\n' "$LOG" "$RESULT"
    exit 1
  fi
fi
check analyze flutter analyze
if [[ "$LEVEL" != "quick" ]]; then
  check flutter-tests flutter test
fi
if [[ "$LEVEL" == "full" ]]; then
  check android-build flutter build apk --debug
  if [[ "$(uname -s)" == "Darwin" ]]; then
    check ios-simulator-build flutter build ios --simulator --no-codesign
  else
    printf 'ios-simulator-build\tBLOCKED\t3\n' >>"$RESULT"
    printf 'BLOCKED ios-simulator-build (macOS/Xcode required)\n'
    failed=1
  fi
  if [[ "$PROFILE" == "mobile-web" ]]; then
    check web-build flutter build web
  fi
fi
printf 'Log: %s\nResults: %s\n' "$LOG" "$RESULT"
[[ "$failed" -eq 0 ]] || { echo "Verification incomplete/failed."; exit 1; }
echo "All requested checks passed. Device E2E and MCP runtime are NOT covered by this bootstrap script."
