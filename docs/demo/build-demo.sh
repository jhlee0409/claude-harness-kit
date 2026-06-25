#!/usr/bin/env bash
# Renders docs/demo.gif with VHS. The GIF is a faithful representation of running
# /harness-kit:introspect IN CLAUDE CODE (the real trigger — a slash skill, not a
# shell command). Detection + file generation are REAL (detect.sh, update-block.sh,
# the architect template); only the Claude Code chrome around them is drawn.
# Requires: vhs (brew install vhs). Run: bash docs/demo/build-demo.sh
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

# --- the session renderer: draws a Claude Code session; generation is REAL ---
cat > "$WORK/session" <<SESS
#!/usr/bin/env bash
set -e
KIT="$KIT"; dir="acme-shop"
sl(){ sleep "\${1:-0.6}"; }
printf '\033[2J\033[3J\033[H'   # clear the (hidden) launch prompt
printf '\033[1;35m●\033[0m \033[2mClaude Code\033[0m\n\n'; sl 0.4
printf '\033[35m>\033[0m /harness-kit:introspect\n\n'; sl 1.1

json="\$(bash "\$KIT/skills/introspect/detect.sh" "\$dir" 2>/dev/null)"
eval "\$(printf '%s' "\$json" | python3 -c 'import json,sys;d=json.load(sys.stdin);vc=" && ".join(x for x in [d["typecheck_cmd"],d["test_cmd"]] if x and x!="-");print("FW=\""+", ".join(d["frameworks"])+"\"");print("VERIFY=\""+vc+"\"");print("PM=\""+d["package_manager"]+"\"")')"
mkdir -p "\$dir/.claude/agents"
cat > "\$dir/.claude/harness-kit.json" <<CFG
{ "verify_command": "\$VERIFY", "blocking": false,
  "protected_branches": ["main", "master", "develop", "release"] }
CFG
sed -e "s/{{STACK}}/typescript/g" -e "s/{{PROJECT_NAME}}/acme-shop/g" \
    -e "s/{{FRAMEWORKS}}/\$FW/g" -e "s#{{LANGUAGE}}#TypeScript (strict, ESM)#g" \
    -e "s/{{TEST_RUNNER}}/vitest/g" -e "s#{{TEST_COMMAND}}#vitest run#g" \
    -e "s#{{BUILD_COMMAND}}#next build#g" -e "s/{{TEST_MANDATE}}/Write the failing test first./g" \
    "\$KIT/templates/agents/stack-architect.md" > "\$dir/.claude/agents/typescript-architect.md"
BLOCK="<!-- harness-kit:start -->
## Engineering harness (harness-kit)
**Stack** \$FW · TypeScript (strict) · \$PM
**Verify** \\\`\$VERIFY\\\` before \"done\"  ·  **Agent** .claude/agents/typescript-architect.md
### 0. Rules  0.0 establish→execute · 0.2 verify before claiming · 0.3 no premature \"done\"
<!-- harness-kit:end -->"
printf '%s' "\$BLOCK" | bash "\$KIT/skills/introspect/update-block.sh" "\$dir/CLAUDE.md" '<!-- harness-kit:start' '<!-- harness-kit:end -->'

printf '\033[36m●\033[0m Detected \033[1m%s\033[0m · %s · vitest\n' "\$FW" "\$PM"; sl 0.7
printf '\033[36m●\033[0m Generated a harness tailored to this repo:\n'; sl 0.5
printf '    \033[32m+\033[0m CLAUDE.md                              \033[2mspine + §0 rules\033[0m\n'; sl 0.35
printf '    \033[32m+\033[0m .claude/agents/typescript-architect.md \033[2mdesign-first agent\033[0m\n'; sl 0.35
printf '    \033[32m+\033[0m .claude/harness-kit.json               \033[2mverify: %s\033[0m\n\n' "\$VERIFY"; sl 1.0
printf '\033[2m── CLAUDE.md ──────────────────────────────────────\033[0m\n'
sed -n '/harness-kit:start/,/harness-kit:end/p' "\$dir/CLAUDE.md"
sl 2.2
SESS
chmod +x "$WORK/session"

( cd "$WORK" && PATH="$WORK:$PATH" vhs "$KIT/docs/demo/demo.tape" )
mv "$WORK/demo.gif" "$KIT/docs/demo.gif"
echo "wrote $KIT/docs/demo.gif ($(du -h "$KIT/docs/demo.gif" | cut -f1))"
