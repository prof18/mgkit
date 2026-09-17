#!/usr/bin/env bash
# Installs mgkit into each harness in isolation and checks every expected skill is visible.
# Usage: scripts/install-check.sh [claude|codex|opencode|pi|all]
# Never touches global harness configuration: each check uses a temp home/config dir or project.
# Not part of check.sh (slow). A harness whose CLI is missing is skipped.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="${1:-all}"
failed=0
tmp_dirs=()
cleanup() { local d; for d in "${tmp_dirs[@]+"${tmp_dirs[@]}"}"; do rm -rf "$d"; done; }
trap cleanup EXIT
new_tmp() { local d; d="$(mktemp -d)"; tmp_dirs+=("$d"); printf '%s\n' "$d"; }

expected_skills() { sed -n 's/^EXPECTED_SKILLS=(\(.*\))$/\1/p' "$ROOT/scripts/check.sh" | tr ' ' '\n' | grep -v '^$'; }

# report <harness> <text containing the discovered skill names>
report() {
  local harness="$1" found="$2" missing=()
  while IFS= read -r skill; do
    printf '%s\n' "$found" | grep -qx -- "$skill" || missing+=("$skill")
  done < <(expected_skills)
  if [ "${#missing[@]}" -eq 0 ]; then
    printf 'ok   %s\n' "$harness"
  else
    printf 'FAIL %s: missing skills: %s\n' "$harness" "${missing[*]}"
    failed=1
  fi
}

have() { command -v "$1" >/dev/null 2>&1 || { printf 'skip %s (CLI not found)\n' "$1"; return 1; }; }

check_claude() {
  have claude || return 0
  local dir out
  dir="$(new_tmp)"
  out="$(cd "$dir" && claude --plugin-dir "$ROOT" plugin details mgkit 2>&1 || true)"
  report claude "$(printf '%s\n' "$out" | sed -n 's/^ *Skills ([0-9]*) *//p' | tr ',' '\n' | sed 's/^ *//; s/ *$//')"
}

check_codex() {
  have codex || return 0
  local home found version
  home="$(new_tmp)"
  CODEX_HOME="$home" codex plugin marketplace add "$ROOT" >/dev/null 2>&1 || { printf 'FAIL codex: marketplace add failed\n'; failed=1; return 0; }
  CODEX_HOME="$home" codex plugin add mgkit@mgkit >/dev/null 2>&1 || { printf 'FAIL codex: plugin add failed\n'; failed=1; return 0; }
  version="$(jq -r .version "$ROOT/plugin.json")"
  found="$(ls "$home/plugins/cache/mgkit/mgkit/$version/skills" 2>/dev/null || true)"
  report codex "$found"
}

check_opencode() {
  have opencode || return 0
  local config project found
  config="$(new_tmp)"; project="$(new_tmp)"
  printf '{"plugin": ["file://%s/.opencode/plugins/mgkit.js"]}\n' "$ROOT" > "$config/opencode.json"
  found="$(cd "$project" && OPENCODE_CONFIG_DIR="$config" OPENCODE_DISABLE_EXTERNAL_SKILLS=1 opencode debug skill 2>/dev/null | jq -r '.[].name' 2>/dev/null || true)"
  report opencode "$found"
}

check_pi() {
  have pi || return 0
  local project listing found
  project="$(new_tmp)"
  (cd "$project" && pi install -l "$ROOT" >/dev/null 2>&1) || { printf 'FAIL pi: install failed\n'; failed=1; return 0; }
  listing="$(cd "$project" && pi list -a 2>&1 || true)"
  if ! printf '%s\n' "$listing" | grep -qF -- "$ROOT"; then
    printf 'FAIL pi: package not listed\n'; failed=1; return 0
  fi
  # Pi reads skills from the "pi.skills" folders of the package; live discovery needs a model call (see docs/harnesses.md).
  found="$(jq -r '.pi.skills[]' "$ROOT/package.json" | while IFS= read -r rel; do ls "$ROOT/$rel"; done)"
  report pi "$found"
}

case "$target" in
  claude) check_claude ;;
  codex) check_codex ;;
  opencode) check_opencode ;;
  pi) check_pi ;;
  all) check_claude; check_codex; check_opencode; check_pi ;;
  *) echo "usage: install-check.sh [claude|codex|opencode|pi|all]" >&2; exit 2 ;;
esac
exit "$failed"
