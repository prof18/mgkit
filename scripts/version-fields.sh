#!/usr/bin/env bash
# Files and jq paths that must all carry the same mgkit version.
# Sourced by check.sh and bump-version.sh. Format: "file|jq path".
# MGKIT_VERSION_FIELDS (newline-separated) overrides the list, for tests.

VERSION_FIELDS=(
  "package.json|.version"
  ".claude-plugin/plugin.json|.version"
  ".claude-plugin/marketplace.json|.plugins[0].version"
  "plugin.json|.version"
)

if [ -n "${MGKIT_VERSION_FIELDS:-}" ]; then
  VERSION_FIELDS=()
  while IFS= read -r line; do
    if [ -n "$line" ]; then VERSION_FIELDS+=("$line"); fi
  done <<< "$MGKIT_VERSION_FIELDS"
fi
true
