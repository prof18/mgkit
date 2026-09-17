#!/usr/bin/env bash
# Shared helpers for mgkit shell tests. Source this file, define test_* functions, then call run_tests.

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$TEST_DIR/.." && pwd)"
FIXTURES_DIR="$TEST_DIR/fixtures"

export MGKIT_SKIP_TESTS=1
export MGKIT_SKIP_CLAUDE_VALIDATE=1
# The fixture repo is minimal: require only the files it ships.
export MGKIT_REQUIRED_FILES="LICENSE THIRD_PARTY_NOTICES.md CHANGELOG.md README.md AGENTS.md package.json"

_tmp_dirs=()
_cleanup() { local d; for d in "${_tmp_dirs[@]}"; do rm -rf "$d"; done; }
trap _cleanup EXIT

# new_fixture [name] -> prints path of a fresh copy of fixtures/<name> (default: valid)
new_fixture() {
  local name="${1:-valid}" dir
  dir="$(mktemp -d)"
  _tmp_dirs+=("$dir")
  cp -R "$FIXTURES_DIR/$name/." "$dir/"
  printf '%s\n' "$dir"
}

# run_capture <cmd...> -> sets OUT and STATUS
run_capture() {
  set +e
  OUT="$("$@" 2>&1)"
  STATUS=$?
  set -e
}

_failures=0
_current=""
# Each test runs in a subshell; a failed assertion exits that subshell.
fail() { printf '  %s: %s\n' "$_current" "$1"; exit 1; }
assert_status() { [ "$STATUS" -eq "$1" ] || fail "expected exit $1, got $STATUS; output: $OUT"; }
assert_contains() { case "$OUT" in *"$1"*) ;; *) fail "expected output to contain '$1'; output: $OUT" ;; esac; }
assert_file_contains() { grep -qF -- "$2" "$1" || fail "expected $1 to contain '$2'"; }

run_tests() {
  local fn
  for fn in $(declare -F | awk '{print $3}' | grep '^test_'); do
    _current="$fn"
    if ( "$fn" ); then
      printf 'PASS %s\n' "$fn"
    else
      printf 'FAIL %s\n' "$fn"
      _failures=$((_failures + 1))
    fi
  done
  [ "$_failures" -eq 0 ]
}
