#!/usr/bin/env bash
# Tests for skills/review-and-fix/scripts/panel.sh, with stub seat CLIs on PATH.
source "$(dirname "$0")/lib.sh"
PANEL="$SCRIPTS_DIR/../skills/review-and-fix/scripts/panel.sh"

unset MGKIT_PANEL_SEATS MGKIT_PANEL_CLAUDE_MODEL MGKIT_PANEL_CODEX_MODEL MGKIT_PANEL_PI_MODEL MGKIT_PANEL_TIMEOUT
export MGKIT_PANEL_CONFIG=/nonexistent/panel.conf

# One root for every stub dir, registered here: new_stubs runs in $(...), where _tmp_dirs+= would be lost.
STUBS_ROOT="$(mktemp -d)"
_tmp_dirs+=("$STUBS_ROOT")

# new_stubs SEAT... -> prints a temp dir; sets up a bin/ with one stub CLI per seat.
# A stub logs its argv to <dir>/<seat>.args and prints "review from <seat>" (codex writes it to its -o file).
# STUB_EXIT_<seat>, STUB_SLEEP_<seat> and STUB_EMPTY_<seat>=1 change its behaviour.
new_stubs() {
  local dir seat
  dir="$(mktemp -d "$STUBS_ROOT/stubs.XXXXXX")"
  mkdir -p "$dir/bin"
  for seat in "$@"; do
    cat >"$dir/bin/$seat" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >"$dir/$seat.args"
cat >/dev/null
eval "sleep_for=\\\${STUB_SLEEP_$seat:-0}; exit_with=\\\${STUB_EXIT_$seat:-0}; empty=\\\${STUB_EMPTY_$seat:-}; fail_model=\\\${STUB_FAIL_MODEL_$seat:-}"
for a in "\$@"; do
  if [ -n "\$fail_model" ] && [ "\$a" = "\$fail_model" ]; then echo "429 rate limit reached for \$a" >&2; exit 1; fi
done
sleep "\$sleep_for"
text="review from $seat"
[ -z "\$empty" ] || text=""
if [ "$seat" = codex ]; then
  out=""; prev=""
  for a in "\$@"; do [ "\$prev" = "-o" ] && out="\$a"; prev="\$a"; done
  printf '%s\n' "\$text" >"\$out"
else
  printf '%s\n' "\$text"
fi
exit "\$exit_with"
EOF
    chmod +x "$dir/bin/$seat"
  done
  printf 'prompt\n' >"$dir/prompt.md"
  printf '%s\n' "$dir"
}

# panel DIR ARGS... -> runs panel.sh with only the stubs and system tools on PATH.
panel() {
  local dir="$1"; shift
  run_capture env PATH="$dir/bin:/usr/bin:/bin" bash "$PANEL" "$@"
}

test_usage_without_arguments() {
  local d; d="$(new_stubs)"
  panel "$d"
  assert_status 2
  assert_contains "usage: panel.sh"
}

test_seats_skip_driver_and_missing_cli() {
  local d; d="$(new_stubs claude codex)"
  panel "$d" seats --driver claude
  assert_status 0
  assert_contains $'claude\tskipped\tdriver'
  assert_contains $'codex\tavailable\tdefault'
  assert_contains $'pi\tskipped\tnot installed'
}

test_run_writes_one_review_per_seat() {
  local d; d="$(new_stubs claude codex pi)"
  panel "$d" run --driver claude --prompt-file "$d/prompt.md" --out-dir "$d/out" --repo "$d"
  assert_status 0
  assert_file_contains "$d/out/codex.md" "review from codex"
  assert_file_contains "$d/out/pi.md" "review from pi"
  [ ! -e "$d/out/claude.md" ] || fail "driver seat ran"
  assert_file_contains "$d/out/status.tsv" $'codex\tok'
  assert_file_contains "$d/out/status.tsv" $'pi\tok'
}

test_run_uses_read_only_flags() {
  local d; d="$(new_stubs claude codex pi)"
  panel "$d" run --driver codex --prompt-file "$d/prompt.md" --out-dir "$d/out" --repo "$d"
  assert_status 0
  assert_file_contains "$d/claude.args" "--permission-mode"
  assert_file_contains "$d/claude.args" "Read,Grep,Glob"
  assert_file_contains "$d/claude.args" "--strict-mcp-config"
  panel "$d" run --driver claude --prompt-file "$d/prompt.md" --out-dir "$d/out2" --repo "$d"
  assert_file_contains "$d/codex.args" "read-only"
  assert_file_contains "$d/codex.args" "--ignore-user-config"
  assert_file_contains "$d/codex.args" "--skip-git-repo-check"
  assert_file_contains "$d/codex.args" "apps"
  assert_file_contains "$d/pi.args" "read,grep,find,ls"
}

test_config_file_sets_model_and_env_wins() {
  local d; d="$(new_stubs pi)"
  printf '# panel\nMGKIT_PANEL_PI_MODEL=zai/from-file\n' >"$d/panel.conf"
  MGKIT_PANEL_CONFIG="$d/panel.conf" panel "$d" run --driver claude --prompt-file "$d/prompt.md" --out-dir "$d/out" --repo "$d"
  assert_status 0
  assert_file_contains "$d/pi.args" "zai/from-file"
  MGKIT_PANEL_CONFIG="$d/panel.conf" MGKIT_PANEL_PI_MODEL=zai/from-env panel "$d" run --driver claude --prompt-file "$d/prompt.md" --out-dir "$d/out2" --repo "$d"
  assert_file_contains "$d/pi.args" "zai/from-env"
}

test_config_file_is_never_executed() {
  local d; d="$(new_stubs pi)"
  printf 'MGKIT_PANEL_PI_MODEL=$(touch %s/pwned)\nrm -rf %s/bin\n' "$d" "$d" >"$d/panel.conf"
  MGKIT_PANEL_CONFIG="$d/panel.conf" panel "$d" seats --driver claude
  assert_status 0
  [ ! -e "$d/pwned" ] || fail "config value was executed"
  [ -d "$d/bin" ] || fail "config line was executed"
}

test_failed_and_empty_seats_are_reported() {
  local d; d="$(new_stubs codex pi)"
  STUB_EXIT_pi=1 panel "$d" run --driver claude --prompt-file "$d/prompt.md" --out-dir "$d/out" --repo "$d"
  assert_status 0
  assert_contains $'pi\tfailed\texit 1'
  STUB_EXIT_pi=1 STUB_EMPTY_codex=1 panel "$d" run --driver claude --prompt-file "$d/prompt.md" --out-dir "$d/out2" --repo "$d"
  assert_status 3
  assert_contains $'codex\tfailed\tempty review'
}

test_timeout_stops_a_slow_seat() {
  local d start; d="$(new_stubs pi)"
  start="$(date +%s)"
  STUB_SLEEP_pi=20 MGKIT_PANEL_TIMEOUT=1 panel "$d" run --driver claude --prompt-file "$d/prompt.md" --out-dir "$d/out" --repo "$d"
  assert_status 3
  assert_contains "timed out after 1s"
  [ $(( $(date +%s) - start )) -lt 10 ] || fail "timeout did not stop the seat"
}

test_timeout_keeps_a_fast_seat_that_finished() {
  local d; d="$(new_stubs codex pi)"
  STUB_SLEEP_codex=30 STUB_SLEEP_pi=0 MGKIT_PANEL_TIMEOUT=5 panel "$d" run --driver claude --prompt-file "$d/prompt.md" --out-dir "$d/out" --repo "$d"
  assert_status 0
  assert_contains $'codex\tfailed\ttimed out after 5s'
  assert_contains $'pi\tok'
}

test_timeout_does_not_delay_fast_seats() {
  local d start; d="$(new_stubs pi)"
  start="$(date +%s)"
  MGKIT_PANEL_TIMEOUT=30 panel "$d" run --driver claude --prompt-file "$d/prompt.md" --out-dir "$d/out" --repo "$d"
  assert_status 0
  [ $(( $(date +%s) - start )) -lt 10 ] || fail "a pending timeout watcher held the output open"
}

test_pi_falls_back_when_its_model_fails() {
  local d; d="$(new_stubs pi)"
  MGKIT_PANEL_PI_MODEL=zai/glm-5.3 MGKIT_PANEL_PI_FALLBACK_MODEL=xai/grok-4.7 STUB_FAIL_MODEL_pi=zai/glm-5.3 \
    panel "$d" run --driver claude --prompt-file "$d/prompt.md" --out-dir "$d/out" --repo "$d"
  assert_status 0
  assert_contains $'pi\tok'
  assert_contains "fallback xai/grok-4.7 after exit 1: 429 rate limit"
  assert_file_contains "$d/pi.args" "xai/grok-4.7"
  assert_file_contains "$d/out/pi.primary.log" "429 rate limit"
  assert_file_contains "$d/out/pi.md" "review from pi"
}

test_pi_loads_only_the_named_extensions() {
  local d; d="$(new_stubs pi)"
  HOME="$d" MGKIT_PANEL_PI_EXTENSIONS="~/ext/provider /opt/other.ts" \
    panel "$d" run --driver claude --prompt-file "$d/prompt.md" --out-dir "$d/out" --repo "$d"
  assert_status 0
  assert_file_contains "$d/pi.args" "--no-extensions"
  assert_file_contains "$d/pi.args" "$d/ext/provider"
  assert_file_contains "$d/pi.args" "/opt/other.ts"
  [ "$(grep -c '^-e$' "$d/pi.args")" -eq 2 ] || fail "expected two -e flags"
}

test_pi_reports_a_failed_fallback() {
  local d; d="$(new_stubs pi)"
  MGKIT_PANEL_PI_FALLBACK_MODEL=xai/grok-4.7 STUB_EXIT_pi=1 \
    panel "$d" run --driver claude --prompt-file "$d/prompt.md" --out-dir "$d/out" --repo "$d"
  assert_status 3
  assert_contains $'pi\tfailed\texit 1'
  assert_contains "fallback xai/grok-4.7"
}

test_pi_does_not_fall_back_after_a_timeout() {
  local d start; d="$(new_stubs pi)"
  start="$(date +%s)"
  MGKIT_PANEL_PI_FALLBACK_MODEL=xai/grok-4.7 STUB_SLEEP_pi=30 MGKIT_PANEL_TIMEOUT=2 \
    panel "$d" run --driver claude --prompt-file "$d/prompt.md" --out-dir "$d/out" --repo "$d"
  assert_status 3
  assert_contains "timed out after 2s"
  [ ! -e "$d/out/pi.fallback" ] || fail "fell back after a timeout"
  [ $(( $(date +%s) - start )) -lt 15 ] || fail "the timeout did not stop the seat"
}

test_no_timeout_by_default() {
  local d; d="$(new_stubs pi)"
  STUB_SLEEP_pi=2 panel "$d" run --driver claude --prompt-file "$d/prompt.md" --out-dir "$d/out" --repo "$d"
  assert_status 0
  assert_contains $'pi\tok'
}

run_tests
