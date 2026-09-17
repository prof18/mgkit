#!/usr/bin/env bash
# mgkit gate. Usage: scripts/check.sh [repo_root]
# Prints ok/skip/FAIL per check and exits 1 if any check failed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${1:-$(git rev-parse --show-toplevel)}"
ROOT="$(cd "$ROOT" && pwd)"

EXPECTED_SKILLS=(review-and-fix explain-commit worktree-task renovate-update-loop renovate-pr-pass roast plan)
REQUIRED_FILES=(
  LICENSE THIRD_PARTY_NOTICES.md CHANGELOG.md README.md AGENTS.md package.json
  .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.json .agents/plugins/marketplace.json
  .opencode/plugins/mgkit.js docs/harnesses.md docs/authoring.md
)
FORBIDDEN_PATTERNS=(
  '/Users/'
  'regesto'
  'gomiero'
  'feed-?flow'
  'reader-?flow'
  'pomo-?stats'
  'difftray'
  'klead'
  'bivio'
  'pcenter'
  'iterative-codebase-review'
  '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[a-z]{2,}'
)

# shellcheck source=version-fields.sh
source "$SCRIPT_DIR/version-fields.sh"

if [ -n "${MGKIT_REQUIRED_FILES:-}" ]; then
  read -r -a REQUIRED_FILES <<< "$MGKIT_REQUIRED_FILES"
fi
if [ -n "${MGKIT_EXPECTED_SKILLS:-}" ]; then
  read -r -a EXPECTED_SKILLS <<< "$MGKIT_EXPECTED_SKILLS"
fi

failed=0
ok() { printf 'ok   %s\n' "$1"; }
skip() { printf 'skip %s\n' "$1"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2"; failed=1; }

# C1 required files
c1=0
for f in "${REQUIRED_FILES[@]}"; do
  if [ ! -e "$ROOT/$f" ]; then fail C1 "missing file $f"; c1=1; fi
done
[ "$c1" -eq 0 ] && ok C1

# C2 JSON parses
c2=0
while IFS= read -r -d '' f; do
  if ! jq empty "$f" >/dev/null 2>&1; then fail C2 "invalid JSON ${f#"$ROOT"/}"; c2=1; fi
done < <(find "$ROOT" -name '*.json' \
  -not -path "$ROOT/node_modules/*" -not -path "$ROOT/plan/*" \
  -not -path "$ROOT/evals/results/*" -not -path "$ROOT/scripts/test/fixtures/*" \
  -not -path "$ROOT/.git/*" -print0)
[ "$c2" -eq 0 ] && ok C2

# C3 versions agree and are 0.0.x
versions=()
for entry in "${VERSION_FIELDS[@]+"${VERSION_FIELDS[@]}"}"; do
  file="${entry%%|*}"; path="${entry#*|}"
  [ -e "$ROOT/$file" ] || continue
  v="$(jq -r "$path // \"<missing>\"" "$ROOT/$file" 2>/dev/null || echo '<unreadable>')"
  versions+=("$file=$v")
done
if [ "${#versions[@]}" -eq 0 ]; then
  skip C3
else
  first="${versions[0]#*=}"; c3=0
  for pair in "${versions[@]}"; do
    [ "${pair#*=}" = "$first" ] || c3=1
  done
  if [ "$c3" -ne 0 ]; then
    fail C3 "version mismatch: ${versions[*]}"
  elif ! [[ "$first" =~ ^0\.0\.[0-9]+$ ]]; then
    fail C3 "version $first is not 0.0.x"
  else
    ok C3
  fi
fi

# C4 skill structure, C6 forbidden patterns, C7 attribution
actual_skills=()
c4=0; c6=0; c7=0
if [ -d "$ROOT/skills" ]; then
  for dir in "$ROOT"/skills/*/; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    actual_skills+=("$name")
    skill="$dir/SKILL.md"
    if [ ! -f "$skill" ]; then fail C4 "skill $name: SKILL.md missing"; c4=1; continue; fi
    if [ "$(head -n 1 "$skill")" != "---" ]; then fail C4 "skill $name: line 1 must be ---"; c4=1; fi
    front="$(awk 'NR==1 && $0=="---" {inside=1; next} inside && $0=="---" {exit} inside {print}' "$skill")"
    fm_name="$(printf '%s\n' "$front" | sed -n 's/^name:[[:space:]]*//p' | head -n 1)"
    if [ "$fm_name" != "$name" ]; then fail C4 "skill $name: frontmatter name '$fm_name' does not match directory"; c4=1; fi
    if ! [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || [ "${#name}" -gt 64 ]; then
      fail C4 "skill $name: name must be kebab-case and at most 64 characters"; c4=1
    fi
    desc="$(printf '%s\n' "$front" | sed -n 's/^description:[[:space:]]*//p' | head -n 1)"
    desc="${desc#\"}"; desc="${desc%\"}"; desc="${desc#\'}"; desc="${desc%\'}"
    desc_next="$(printf '%s\n' "$front" | awk '/^description:/ {getline nxt; print nxt; exit}')"
    if [ -z "$desc" ] || [ "$desc" = ">" ] || [ "$desc" = "|" ] || [[ "$desc" =~ ^[\>\|][-+]?$ ]] || [[ "$desc_next" =~ ^[[:space:]] ]]; then
      fail C4 "skill $name: description must be a non-empty single line"; c4=1
    elif [ "${#desc}" -gt 1024 ]; then
      fail C4 "skill $name: description longer than 1024 characters"; c4=1
    fi
    lines="$(wc -l < "$skill" | tr -d ' ')"
    if [ "$lines" -gt 300 ]; then fail C4 "skill $name: SKILL.md has $lines lines (max 300)"; c4=1; fi

    for p in "${FORBIDDEN_PATTERNS[@]}"; do
      while IFS= read -r hit; do
        [ -n "$hit" ] || continue
        fail C6 "forbidden pattern '$p' in ${hit%%:*}:$(printf '%s' "$hit" | cut -d: -f2)"; c6=1
      done < <(cd "$ROOT" && grep -rniE -- "$p" "skills/$name" 2>/dev/null || true)
    done

    while IFS= read -r url; do
      [ -n "$url" ] || continue
      if ! grep -qF -- "$url" "$ROOT/THIRD_PARTY_NOTICES.md" 2>/dev/null; then
        fail C7 "attribution missing for $url ($name)"; c7=1
      fi
    done < <(grep -oE 'Adapted from https?://[^[:space:](),]+' "$skill" | sed 's/^Adapted from //' | sort -u)
  done
fi
[ "$c4" -eq 0 ] && ok C4

# C5 skill set equals EXPECTED_SKILLS
c5=0
for s in "${actual_skills[@]+"${actual_skills[@]}"}"; do
  found=0
  for e in "${EXPECTED_SKILLS[@]+"${EXPECTED_SKILLS[@]}"}"; do [ "$s" = "$e" ] && found=1; done
  [ "$found" -eq 1 ] || { fail C5 "unexpected skill $s"; c5=1; }
done
for e in "${EXPECTED_SKILLS[@]+"${EXPECTED_SKILLS[@]}"}"; do
  found=0
  for s in "${actual_skills[@]+"${actual_skills[@]}"}"; do [ "$s" = "$e" ] && found=1; done
  [ "$found" -eq 1 ] || { fail C5 "missing skill $e"; c5=1; }
done
[ "$c5" -eq 0 ] && ok C5
[ "$c6" -eq 0 ] && ok C6
[ "$c7" -eq 0 ] && ok C7

# C8 OpenCode plugin syntax
if [ -f "$ROOT/.opencode/plugins/mgkit.js" ]; then
  # node --check misses syntax errors in .js files outside a "type": "module" package, so import the module instead.
  if node --input-type=module -e 'import { pathToFileURL } from "node:url"; await import(pathToFileURL(process.argv[1]).href);' "$ROOT/.opencode/plugins/mgkit.js" >/dev/null 2>&1; then
    ok C8
  else
    fail C8 "OpenCode plugin does not load"
  fi
else
  skip C8
fi

# C9 Claude Code plugin validation
if [ -f "$ROOT/.claude-plugin/plugin.json" ] && [ "${MGKIT_SKIP_CLAUDE_VALIDATE:-}" != "1" ] && command -v claude >/dev/null 2>&1; then
  c9=0
  for target in "$ROOT" "$ROOT/.claude-plugin/plugin.json" "$ROOT/skills"; do
    [ -e "$target" ] || continue
    claude plugin validate "$target" >/dev/null 2>&1 || { fail C9 "claude plugin validate failed for ${target#"$ROOT"/}"; c9=1; }
  done
  [ "$c9" -eq 0 ] && ok C9
else
  skip C9
fi

# C10 nothing under plan/ staged
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  staged="$(git -C "$ROOT" diff --cached --name-only | grep '^plan/' || true)"
  if [ -n "$staged" ]; then fail C10 "plan/ is staged: $(printf '%s' "$staged" | tr '\n' ' ')"; else ok C10; fi
else
  skip C10
fi

# C11 script tests
if [ "${MGKIT_SKIP_TESTS:-}" = "1" ]; then
  skip C11
elif [ -x "$ROOT/scripts/test/run.sh" ]; then
  test_log="$(mktemp)"
  if MGKIT_SKIP_TESTS=1 "$ROOT/scripts/test/run.sh" >"$test_log" 2>&1; then
    ok C11
  else
    cat "$test_log"
    fail C11 "script tests failed"
  fi
  rm -f "$test_log"
else
  skip C11
fi

exit "$failed"
