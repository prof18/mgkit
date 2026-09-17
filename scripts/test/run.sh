#!/usr/bin/env bash
# Runs every scripts/test/*.test.sh and exits non-zero if any fails.
set -euo pipefail
dir="$(cd "$(dirname "$0")" && pwd)"
status=0
for t in "$dir"/*.test.sh; do
  [ -e "$t" ] || continue
  bash "$t" || status=1
done
exit "$status"
