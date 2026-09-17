#!/usr/bin/env bash
# Tests for scripts/check.sh.
source "$(dirname "$0")/lib.sh"
CHECK="$SCRIPTS_DIR/check.sh"

export MGKIT_EXPECTED_SKILLS="sample"
export MGKIT_VERSION_FIELDS="package.json|.version"

test_valid_repo_passes() {
  local root; root="$(new_fixture)"
  run_capture "$CHECK" "$root"
  assert_status 0
}

test_missing_required_file() {
  local root; root="$(new_fixture)"
  rm "$root/LICENSE"
  run_capture "$CHECK" "$root"
  assert_status 1
  assert_contains "FAIL C1"
}

test_invalid_json() {
  local root; root="$(new_fixture)"
  printf '{ "name": ' > "$root/package.json"
  run_capture "$CHECK" "$root"
  assert_status 1
  assert_contains "FAIL C2"
}

test_version_mismatch() {
  local root; root="$(new_fixture)"
  mkdir -p "$root/.claude-plugin"
  printf '{\n  "name": "fixture",\n  "version": "0.0.9"\n}\n' > "$root/.claude-plugin/plugin.json"
  MGKIT_VERSION_FIELDS=$'package.json|.version\n.claude-plugin/plugin.json|.version' run_capture "$CHECK" "$root"
  assert_status 1
  assert_contains "FAIL C3"
}

test_skill_name_mismatch() {
  local root; root="$(new_fixture)"
  sed -i '' 's/^name: sample$/name: other/' "$root/skills/sample/SKILL.md"
  run_capture "$CHECK" "$root"
  assert_status 1
  assert_contains "FAIL C4"
}

test_description_too_long() {
  local root long; root="$(new_fixture)"
  long="$(printf 'a%.0s' $(seq 1 1025))"
  sed -i '' "s/^description: .*/description: $long/" "$root/skills/sample/SKILL.md"
  run_capture "$CHECK" "$root"
  assert_status 1
  assert_contains "FAIL C4"
}

test_unexpected_skill() {
  local root; root="$(new_fixture)"
  mkdir -p "$root/skills/extra"
  printf -- '---\nname: extra\ndescription: Extra skill.\n---\n' > "$root/skills/extra/SKILL.md"
  run_capture "$CHECK" "$root"
  assert_status 1
  assert_contains "FAIL C5"
}

test_forbidden_pattern() {
  local root; root="$(new_fixture)"
  printf '\nRead /Users/someone/notes.\n' >> "$root/skills/sample/SKILL.md"
  run_capture "$CHECK" "$root"
  assert_status 1
  assert_contains "FAIL C6"
}

test_missing_attribution() {
  local root; root="$(new_fixture)"
  printf '\n<!-- Adapted from https://github.com/a/b (x, commit y), MIT License. -->\n' >> "$root/skills/sample/SKILL.md"
  run_capture "$CHECK" "$root"
  assert_status 1
  assert_contains "FAIL C7"
}

test_plan_staged() {
  local root; root="$(new_fixture)"
  git -C "$root" init -q
  mkdir -p "$root/plan"
  printf '<p>plan</p>\n' > "$root/plan/x.html"
  git -C "$root" add plan/x.html
  run_capture "$CHECK" "$root"
  assert_status 1
  assert_contains "FAIL C10"
}

test_multiline_description_fails() {
  local root; root="$(new_fixture)"
  sed -i '' 's/^description: .*/description: First line of a folded description/' "$root/skills/sample/SKILL.md"
  sed -i '' '/^description:/a\
  continues on a second line
' "$root/skills/sample/SKILL.md"
  run_capture "$CHECK" "$root"
  assert_status 1
  assert_contains "FAIL C4"
}

test_missing_attribution_non_github() {
  local root; root="$(new_fixture)"
  printf '\n<!-- Adapted from https://gitlab.com/a/b (x, commit y), MIT License. -->\n' >> "$root/skills/sample/SKILL.md"
  run_capture "$CHECK" "$root"
  assert_status 1
  assert_contains "FAIL C7"
}

test_broken_opencode_plugin() {
  local root; root="$(new_fixture)"
  mkdir -p "$root/.opencode/plugins"
  printf 'export const x = ;\n' > "$root/.opencode/plugins/mgkit.js"
  run_capture "$CHECK" "$root"
  assert_status 1
  assert_contains "FAIL C8"
}

test_failing_script_tests() {
  local root; root="$(new_fixture)"
  mkdir -p "$root/scripts/test"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$root/scripts/test/run.sh"
  chmod +x "$root/scripts/test/run.sh"
  MGKIT_SKIP_TESTS=0 run_capture "$CHECK" "$root"
  assert_status 1
  assert_contains "FAIL C11"
}

test_empty_version_fields_override() {
  local root; root="$(new_fixture)"
  MGKIT_VERSION_FIELDS=$'\n' run_capture "$CHECK" "$root"
  assert_status 0
  assert_contains "skip C3"
}

test_broken_relative_skill_path() {
  local root; root="$(new_fixture)"
  printf '\nRead `../missing/SKILL.md` and follow it.\n' >> "$root/skills/sample/SKILL.md"
  run_capture "$CHECK" "$root"
  assert_status 1
  assert_contains "FAIL C12"
}

test_valid_relative_skill_path() {
  local root; root="$(new_fixture)"
  mkdir -p "$root/skills/sample/references"
  printf 'x\n' > "$root/skills/sample/references/x.md"
  printf '\nRead `../sample/references/x.md`.\n' >> "$root/skills/sample/SKILL.md"
  run_capture "$CHECK" "$root"
  assert_status 0
  assert_contains "ok   C12"
}

run_tests
