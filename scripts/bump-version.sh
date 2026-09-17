#!/usr/bin/env bash
# Sets the mgkit version in every file listed in version-fields.sh, then runs the gate.
# Usage: scripts/bump-version.sh 0.0.N   (run from anywhere inside the repository)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$#" -ne 1 ] || ! [[ "$1" =~ ^0\.0\.[0-9]+$ ]]; then
  echo "usage: bump-version.sh 0.0.N" >&2
  exit 2
fi
version="$1"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# shellcheck source=version-fields.sh
source "$SCRIPT_DIR/version-fields.sh"

for entry in "${VERSION_FIELDS[@]+"${VERSION_FIELDS[@]}"}"; do
  file="${entry%%|*}"; path="${entry#*|}"
  [ -e "$ROOT/$file" ] || continue
  tmp="$(mktemp)"
  jq --arg v "$version" "$path = \$v" "$ROOT/$file" > "$tmp"
  cat "$tmp" > "$ROOT/$file"  # keep the file's permissions
  rm -f "$tmp"
  echo "set $file $path = $version"
done

MGKIT_SKIP_TESTS=1 "$SCRIPT_DIR/check.sh" "$ROOT"
