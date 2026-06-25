#!/usr/bin/env bash
# Renders docs/demo.gif with VHS. Sets up a realistic sample repo and a thin
# `harness-kit` demo wrapper that drives the REAL detection engine + block updater
# (the deterministic, API-free core of the introspect skill), then records it.
# Requires: vhs (brew install vhs). Run from anywhere: bash docs/demo/build-demo.sh
set -euo pipefail
KIT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

# --- a realistic Next.js + TS + Postgres sample repo (no harness yet) ---
app="$WORK/acme-shop"; mkdir -p "$app/src"
cat > "$app/package.json" <<'J'
{
  "name": "acme-shop",
  "scripts": { "dev": "next dev", "build": "next build", "test": "vitest run",
               "lint": "next lint", "typecheck": "tsc --noEmit" },
  "dependencies": { "next": "^15", "react": "^19", "pg": "^8" },
  "devDependencies": { "vitest": "^2", "typescript": "^5", "eslint": "^9" }
}
J
: > "$app/tsconfig.json"; : > "$app/pnpm-lock.yaml"; : > "$app/src/index.ts"

# --- the demo wrapper: real detect.sh + real update-block.sh ---
cat > "$WORK/harness-kit" <<WRAP
#!/usr/bin/env bash
set -e
dir="\${2:-.}"
json="\$(bash "$KIT/skills/introspect/detect.sh" "\$dir" 2>/dev/null)"
mkdir -p "\$dir/.claude"
eval "\$(printf '%s' "\$json" | python3 -c 'import json,sys;d=json.load(sys.stdin);vc=" && ".join(x for x in [d["typecheck_cmd"],d["test_cmd"]] if x and x!="-");print("FW=\""+", ".join(d["frameworks"])+"\"");print("VERIFY=\""+vc+"\"");print("PM=\""+d["package_manager"]+"\"")')"
cat > "\$dir/.claude/harness-kit.json" <<CFG
{ "verify_command": "\$VERIFY", "blocking": false,
  "protected_branches": ["main", "master", "develop", "release"] }
CFG
BLOCK="<!-- harness-kit:start -->
## Engineering harness (harness-kit)
**Stack** \$FW · TypeScript (strict) · \$PM
**Verify** \\\`\$VERIFY\\\` before \"done\"  ·  **Agent** .claude/agents/typescript-architect.md
### 0. Rules  0.0 establish→execute · 0.2 verify before claiming · 0.3 no premature \"done\"
<!-- harness-kit:end -->"
printf '%s' "\$BLOCK" | bash "$KIT/skills/introspect/update-block.sh" "\$dir/CLAUDE.md" '<!-- harness-kit:start' '<!-- harness-kit:end -->'
printf '\033[32m✓ detected:\033[0m %s  ·  \033[32mverify:\033[0m %s\n' "\$FW" "\$VERIFY"
printf '\033[32m✓ generated:\033[0m %s/CLAUDE.md + .claude/harness-kit.json\n' "\$dir"
WRAP
chmod +x "$WORK/harness-kit"

# --- record ---
( cd "$WORK" && PATH="$WORK:$PATH" vhs "$KIT/docs/demo/demo.tape" )
mv "$WORK/demo.gif" "$KIT/docs/demo.gif"
echo "wrote $KIT/docs/demo.gif ($(du -h "$KIT/docs/demo.gif" | cut -f1))"
