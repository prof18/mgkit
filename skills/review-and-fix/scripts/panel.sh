#!/usr/bin/env bash
# Review panel seat runner. See ../references/panel.md for the protocol.
# Usage:
#   panel.sh seats --driver NAME
#   panel.sh run --driver NAME --prompt-file FILE --out-dir DIR [--repo DIR]
# Runs every configured seat except the driver's own CLI, read-only and in parallel, on one prompt.
# Exit codes: 0 at least one seat returned a review, 2 usage error, 3 no seat returned a review.
set -euo pipefail

# A seat still running after this many seconds is stopped. The slowest real review seen took about 40 minutes;
# a stalled model never ends on its own.
DEFAULT_TIMEOUT=3600
KNOWN_KEYS="MGKIT_PANEL_SEATS MGKIT_PANEL_CLAUDE_MODEL MGKIT_PANEL_CODEX_MODEL MGKIT_PANEL_PI_MODEL MGKIT_PANEL_PI_FALLBACK_MODEL MGKIT_PANEL_PI_EXTENSIONS MGKIT_PANEL_TIMEOUT"

usage() {
  echo "usage: panel.sh seats --driver NAME | panel.sh run --driver NAME --prompt-file FILE --out-dir DIR [--repo DIR]" >&2
  exit 2
}

# load_config: reads KEY=value lines for the known keys; an exported variable wins. Never sourced.
load_config() {
  local file="${MGKIT_PANEL_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/mgkit/panel.conf}" line key value isset
  [ -f "$file" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in '' | '#'*) continue ;; esac
    key="${line%%=*}"
    value="${line#*=}"
    case " $KNOWN_KEYS " in *" $key "*) ;; *) continue ;; esac
    eval "isset=\${$key+x}"
    if [ -z "$isset" ]; then export "$key=$value"; fi
  done <"$file"
}

seat_model() {
  local v=""
  case "$1" in
    claude) v="${MGKIT_PANEL_CLAUDE_MODEL:-}" ;;
    codex) v="${MGKIT_PANEL_CODEX_MODEL:-}" ;;
    pi) v="${MGKIT_PANEL_PI_MODEL:-}" ;;
  esac
  printf '%s\n' "${v:-default}"
}

# list_seats DRIVER: one line per configured seat, "seat<TAB>available|skipped<TAB>model or reason".
list_seats() {
  local driver="$1" seat
  for seat in ${MGKIT_PANEL_SEATS:-claude codex pi}; do
    case "$seat" in
      claude | codex | pi) ;;
      *) printf '%s\tskipped\tunknown seat\n' "$seat"; continue ;;
    esac
    if [ "$seat" = "$driver" ]; then
      printf '%s\tskipped\tdriver\n' "$seat"
    elif command -v "$seat" >/dev/null 2>&1; then
      printf '%s\tavailable\t%s\n' "$seat" "$(seat_model "$seat")"
    else
      printf '%s\tskipped\tnot installed\n' "$seat"
    fi
  done
}

# exec_seat SEAT PROMPT OUT: replaces the current (sub)shell with the seat's CLI, so a kill reaches it.
exec_seat() {
  local seat="$1" prompt="$2" out="$3"
  local args=()
  case "$seat" in
    claude)
      # --tools limits only built-in tools; --strict-mcp-config with no --mcp-config drops every MCP server.
      args=(-p --permission-mode plan --tools Read,Grep,Glob --strict-mcp-config --no-session-persistence)
      if [ -n "${MGKIT_PANEL_CLAUDE_MODEL:-}" ]; then args+=(--model "$MGKIT_PANEL_CLAUDE_MODEL"); fi
      exec claude "${args[@]}" <"$prompt" >"$out/$seat.md" 2>"$out/$seat.log"
      ;;
    codex)
      # -s read-only does not cover MCP tools: skip config.toml (its MCP servers and plugins; auth stays) and apps.
      # --skip-git-repo-check: a plan is often reviewed before its folder is a git repository; the seat writes nothing.
      args=(exec -s read-only --ephemeral --ignore-user-config --disable apps --skip-git-repo-check -o "$out/$seat.md")
      if [ -n "${MGKIT_PANEL_CODEX_MODEL:-}" ]; then args+=(-m "$MGKIT_PANEL_CODEX_MODEL"); fi
      exec codex "${args[@]}" - <"$prompt" >"$out/$seat.log" 2>&1
      ;;
    pi)
      args=(-p --tools read,grep,find,ls --no-extensions --no-skills --no-session --no-approve --offline)
      if [ -n "${MGKIT_PANEL_PI_MODEL:-}" ]; then args+=(--model "$MGKIT_PANEL_PI_MODEL"); fi
      # Only the extensions the user names load (e.g. one that provides a model provider); --tools still
      # keeps any tool they add out of the seat's reach.
      if [ -n "${MGKIT_PANEL_PI_EXTENSIONS:-}" ]; then
        local exts=() ext
        read -r -a exts <<<"$MGKIT_PANEL_PI_EXTENSIONS"
        for ext in "${exts[@]}"; do
          case "$ext" in '~/'*) ext="$HOME/${ext#'~/'}" ;; esac
          args+=(-e "$ext")
        done
      fi
      exec pi "${args[@]}" <"$prompt" >"$out/$seat.md" 2>"$out/$seat.log"
      ;;
  esac
}

# run_attempt SEAT PROMPT OUT TIMEOUT: runs the CLI once as a child; with a TIMEOUT (seconds) a watcher stops it
# and leaves OUT/SEAT.timeout behind. Sets the caller's $child so a TERM can be passed on.
run_attempt() {
  local seat="$1" prompt="$2" out="$3" timeout="$4" rc=0 watcher=""
  rm -f "$out/$seat.timeout"
  (exec_seat "$seat" "$prompt" "$out") &
  child=$!
  if [ -n "$timeout" ]; then
    # Detached from our stdout/stderr, so a sleep that outlives a fast seat never holds a caller's pipe open.
    (sleep "$timeout" && : >"$out/$seat.timeout" && kill -TERM "$child") </dev/null >/dev/null 2>&1 &
    watcher=$!
  fi
  wait "$child" || rc=$?
  if [ -n "$watcher" ]; then kill "$watcher" 2>/dev/null || true; fi
  return "$rc"
}

# seat_job SEAT PROMPT OUT TIMEOUT: runs one seat. When pi fails for any reason (a rate limit, quota or auth error,
# or a model that stalls until the timeout), it runs once more with MGKIT_PANEL_PI_FALLBACK_MODEL, under its own
# timeout. A TERM is passed on to the running CLI.
seat_job() {
  local seat="$1" prompt="$2" out="$3" timeout="$4" child="" rc=0 reason
  trap '[ -z "$child" ] || kill -TERM "$child" 2>/dev/null; exit 143' TERM
  run_attempt "$seat" "$prompt" "$out" "$timeout" || rc=$?
  if [ "$seat" != pi ] || [ -z "${MGKIT_PANEL_PI_FALLBACK_MODEL:-}" ]; then return "$rc"; fi
  if [ "$rc" -eq 0 ] && grep -q '[^[:space:]]' "$out/$seat.md" 2>/dev/null; then return 0; fi
  mv "$out/$seat.log" "$out/$seat.primary.log"
  if [ -e "$out/$seat.timeout" ]; then
    reason="timed out after ${timeout}s"
  else
    reason="exit $rc: $(tr '\n' ' ' <"$out/$seat.primary.log" | cut -c1-200)"
  fi
  printf '%s\t%s\n' "$MGKIT_PANEL_PI_FALLBACK_MODEL" "$reason" >"$out/$seat.fallback"
  rc=0
  MGKIT_PANEL_PI_MODEL="$MGKIT_PANEL_PI_FALLBACK_MODEL" run_attempt "$seat" "$prompt" "$out" "$timeout" || rc=$?
  return "$rc"
}

run_panel() {
  local driver="$1" prompt="$2" out="$3" repo="$4" timeout="${MGKIT_PANEL_TIMEOUT:-$DEFAULT_TIMEOUT}"
  local seats=() pids=() seat status detail i rc ok=0 line fb_model fb_reason model timeout_label
  case "$timeout" in '' | *[!0-9]*) usage ;; esac
  timeout=$((10#$timeout))
  timeout_label="${timeout}s"
  if [ "$timeout" -eq 0 ]; then timeout=""; timeout_label=none; fi
  mkdir -p "$out"
  : >"$out/status.tsv"
  while IFS= read -r line; do
    seat="${line%%$'\t'*}"
    case "$line" in
      *$'\t'available$'\t'*) seats+=("$seat") ;;
      *) printf '%s\n' "$line" >>"$out/status.tsv" ;;
    esac
  done < <(list_seats "$driver")
  if [ "${#seats[@]}" -eq 0 ]; then
    cat "$out/status.tsv"
    return 3
  fi
  for seat in "${seats[@]}"; do
    rm -f "$out/$seat.md" "$out/$seat.log" "$out/$seat.timeout" "$out/$seat.fallback" "$out/$seat.primary.log"
    (cd "$repo" && seat_job "$seat" "$prompt" "$out" "$timeout") &
    pids+=("$!")
    model="$(seat_model "$seat")"
    if [ "$seat" = pi ] && [ -n "${MGKIT_PANEL_PI_FALLBACK_MODEL:-}" ]; then model="$model, fallback: $MGKIT_PANEL_PI_FALLBACK_MODEL"; fi
    printf 'started %s (model: %s, timeout: %s, log: %s)\n' "$seat" "$model" "$timeout_label" "$out/$seat.log"
  done
  for i in "${!seats[@]}"; do
    seat="${seats[$i]}"
    rc=0
    wait "${pids[$i]}" || rc=$?
    # Exit status first: a seat that finished cleanly is never reported as timed out.
    if [ "$rc" -eq 0 ] && grep -q '[^[:space:]]' "$out/$seat.md" 2>/dev/null; then
      status=ok; detail="$out/$seat.md"; ok=1
    elif [ -e "$out/$seat.timeout" ]; then
      status=failed; detail="timed out after ${timeout}s"
    elif [ "$rc" -ne 0 ]; then
      status=failed; detail="exit $rc, see $out/$seat.log"
    else
      status=failed; detail="empty review, see $out/$seat.log"
    fi
    if [ -e "$out/$seat.fallback" ]; then
      IFS=$'\t' read -r fb_model fb_reason <"$out/$seat.fallback" || true
      detail="$detail (fallback $fb_model after $fb_reason)"
    fi
    printf '%s\t%s\t%s\n' "$seat" "$status" "$detail" >>"$out/status.tsv"
  done
  cat "$out/status.tsv"
  [ "$ok" -eq 1 ] || return 3
}

main() {
  local cmd="${1:-}" driver="" prompt="" out="" repo="$PWD"
  [ -n "$cmd" ] || usage
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --driver) driver="${2:-}"; shift 2 || usage ;;
      --prompt-file) prompt="${2:-}"; shift 2 || usage ;;
      --out-dir) out="${2:-}"; shift 2 || usage ;;
      --repo) repo="${2:-}"; shift 2 || usage ;;
      *) usage ;;
    esac
  done
  case "$driver" in claude | codex | pi | opencode | other) ;; *) usage ;; esac
  load_config
  case "$cmd" in
    seats) list_seats "$driver" ;;
    run)
      [ -n "$prompt" ] && [ -f "$prompt" ] && [ -n "$out" ] && [ -d "$repo" ] || usage
      prompt="$(cd "$(dirname "$prompt")" && pwd)/$(basename "$prompt")"
      mkdir -p "$out"
      out="$(cd "$out" && pwd)"
      run_panel "$driver" "$prompt" "$out" "$repo"
      ;;
    *) usage ;;
  esac
}

main "$@"
