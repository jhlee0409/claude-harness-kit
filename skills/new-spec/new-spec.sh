#!/usr/bin/env bash
# Scaffold a spec triplet: specs/YYYYMMDD-<slug>/{spec,plan,context}.md
# usage: new-spec.sh <name>   (run from the repo root)
set -euo pipefail
name="${1:?usage: new-spec.sh <name>}"
slug="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | sed 's/--*/-/g; s/^-//; s/-$//')"
[ -n "$slug" ] || slug="spec"
root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
dir="specs/$(date +%Y%m%d)-${slug}"
mkdir -p "$dir"
for f in spec plan context; do
  if [ -f "$dir/$f.md" ]; then echo "exists (skipped): $dir/$f.md" >&2; continue; fi
  sed -e "s/{{NAME}}/$name/g" -e "s/{{DATE}}/$(date +%Y-%m-%d)/g" "$root/templates/spec/$f.md" > "$dir/$f.md"
done
echo "$dir"
