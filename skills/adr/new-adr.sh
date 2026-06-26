#!/usr/bin/env bash
# Scaffold the next ADR: docs/adr/NNNN-<slug>.md
# usage: new-adr.sh <title>   (run from the repo root)
set -euo pipefail
title="${1:?usage: new-adr.sh <title>}"
slug="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | sed 's/--*/-/g; s/^-//; s/-$//')"
[ -n "$slug" ] || slug="decision"
root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
mkdir -p docs/adr
# next number = highest existing NNNN + 1, zero-padded to 4.
# `|| true`: an empty docs/adr makes grep exit 1, which would trip set -e/pipefail.
last="$(ls docs/adr 2>/dev/null | grep -oE '^[0-9]{4}' | sort -n | tail -1 || true)"
next="$(printf '%04d' "$(( 10#${last:-0} + 1 ))")"
out="docs/adr/${next}-${slug}.md"
sed -e "s/{{NUMBER}}/$next/g" -e "s/{{TITLE}}/$title/g" -e "s/{{DATE}}/$(date +%Y-%m-%d)/g" "$root/templates/adr.md" > "$out"
echo "$out"
