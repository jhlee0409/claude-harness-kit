#!/usr/bin/env bash
# Tests for the new-adr scaffolder (numbering + template fill).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/skills/adr/new-adr.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "[1] first ADR is 0001, template filled"
a="$(cd "$TMP" && CLAUDE_PLUGIN_ROOT="$ROOT" bash "$SCRIPT" "Use Postgres")"
echo "$a" | grep -q 'docs/adr/0001-use-postgres.md' && ok "0001 + slug" || no "bad path ($a)"
grep -q "ADR 0001: Use Postgres" "$TMP/$a" && ok "number + title interpolated" || no "template not filled"

echo "[2] second ADR increments to 0002"
b="$(cd "$TMP" && CLAUDE_PLUGIN_ROOT="$ROOT" bash "$SCRIPT" "Adopt Vitest")"
echo "$b" | grep -q 'docs/adr/0002-adopt-vitest.md' && ok "increments to 0002" || no "no increment ($b)"

echo "[3] numbering follows the highest existing (gap-tolerant)"
( cd "$TMP" && : > docs/adr/0007-manual.md )
c="$(cd "$TMP" && CLAUDE_PLUGIN_ROOT="$ROOT" bash "$SCRIPT" "Next One")"
echo "$c" | grep -q 'docs/adr/0008-next-one.md' && ok "follows highest → 0008" || no "ignored existing ($c)"

echo ""
echo "RESULT: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
