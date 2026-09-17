#!/usr/bin/env bash
# Tests for scripts/bump-version.sh.
source "$(dirname "$0")/lib.sh"
BUMP="$SCRIPTS_DIR/bump-version.sh"

export MGKIT_EXPECTED_SKILLS="sample"

test_bump_rejects_bad_version() {
  local root; root="$(new_fixture)"
  (cd "$root" && MGKIT_VERSION_FIELDS="package.json|.version" run_capture "$BUMP" 1.0.0
   assert_status 2
   assert_contains "usage: bump-version.sh 0.0.N") || exit 1
  assert_file_contains "$root/package.json" '"version": "0.0.1"'
}

test_bump_updates_all_fields() {
  local root; root="$(new_fixture)"
  mkdir -p "$root/.claude-plugin"
  printf '{\n  "plugins": [\n    {\n      "name": "fixture",\n      "version": "0.0.1"\n    }\n  ]\n}\n' > "$root/.claude-plugin/marketplace.json"
  (cd "$root" && MGKIT_VERSION_FIELDS=$'package.json|.version\n.claude-plugin/marketplace.json|.plugins[0].version' run_capture "$BUMP" 0.0.2
   assert_status 0) || exit 1
  assert_file_contains "$root/package.json" '"version": "0.0.2"'
  assert_file_contains "$root/.claude-plugin/marketplace.json" '"version": "0.0.2"'
}

test_bump_skips_missing_files() {
  local root; root="$(new_fixture)"
  (cd "$root" && MGKIT_VERSION_FIELDS=$'package.json|.version\nplugin.json|.version' run_capture "$BUMP" 0.0.3
   assert_status 0) || exit 1
  assert_file_contains "$root/package.json" '"version": "0.0.3"'
  [ ! -e "$root/plugin.json" ] || fail "bump created plugin.json"
}

run_tests
