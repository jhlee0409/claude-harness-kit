# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-06-26

Hybrid renderer — shrink the probabilistic (LLM) surface of `introspect` to just the
spine's judgment prose.

### Added
- **`render.sh` — a deterministic renderer for the three generated agent files** (the
  `<stack>-architect` and the conditional `db-verify` / `ui-verify` critics). Those
  files have only pure-data / table-lookup slots, so a script fills them instead of the
  LLM. This makes the whole class of slot-fill defects the dogfood pass found
  (wrong store idiom, empty `()` / backticks, dir-name project_name, a leaked
  `{{SLOT}}`) **deterministically impossible** — `render.sh` exits non-zero if any slot
  would leak — and **fully testable** (`tests/render_test.sh`, 21 cases across the
  stack matrix). The store-verify idiom table now lives in `render.sh` as the single
  source of truth.
- +23 tests (→ 146).

### Changed
- **`introspect` (SKILL §4)** now runs `render.sh` for the agent files instead of
  hand-filling templates; the **only** LLM-filled, probabilistic part left is the
  spine's judgment slots (`{{ARCHITECTURE_NOTE}}` / `{{STACK_LINES}}` /
  `{{TEST_DISCIPLINE}}` / `{{AGENT_ROUTING}}`) — the irreducible residue, which the
  README/dogfood-log now scope precisely.
- `generation_contract_test` slot-contract split: spine slots are checked against the
  SKILL (LLM fills them), agent slots against `render.sh` (the renderer fills them).

## [0.3.4] - 2026-06-26

Test-hardening — deterministic guards for the contract around the (probabilistic)
generation step. No product behavior change beyond one generation-guidance fix.

### Added
- **Generation-contract tests** (`tests/generation_contract_test.sh`): **referential
  integrity** — every critic / `tdd-runner` / `/harness-kit:<skill>` the spine routes
  to must resolve to a real file (catches rename/delete drift, which this kit's
  deletion-bias invites); **slot contract** — every `{{SLOT}}` in the generated
  templates must be documented as fillable in the SKILL (catches a slot that would
  render literally, incl. digit slots like `{{E2E_NOTE}}`).
- **Store idiom coverage** — `conditional_critics_test` now asserts each store row
  carries its signature verify idiom (`$exists` / `information_schema` / the MySQL
  no-`FILTER` warning / `PRAGMA table_info` / `HEXISTS`), so a row can't silently
  degrade to a wrong/empty howto.
- +40 tests (→ 123).

### Changed
- **`verify_command` join (C2 dogfood fix)** — `SKILL.md §4.4` now says to join with
  `&&` only the non-empty checks (no dangling `tsc --noEmit && `) and notes the hook
  runs inside the repo so a workspace-local bin resolves.

## [0.3.3] - 2026-06-26

Maturation from a dogfood pass — `introspect` was run against real public repos
across the unvalidated matrix (Go/Rust/monorepo/Python+DB/frontend); the kit's
judgment held everywhere and the plumbing defects it surfaced are fixed. See
[`docs/dogfood-log.md`](docs/dogfood-log.md).

### Fixed
- **Go / Rust / Python verify commands** — these branches set a test *runner* but no
  runnable command, so the verify-loop hook silently no-op'd on those ecosystems. Now
  `go test ./...` / `cargo test` / `pytest` (+ build/typecheck/lint defaults) are
  emitted, lighting up the verify loop. (D1)
- **`project_name` for Go/Rust** — now read from the Go module path / Cargo
  `[package].name`, not the clone-dir basename (`# CLAUDE.md — go` → `cobra`). (D6)
- **Prisma datasource** — was hardcoded to Postgres, so a MySQL/SQLite repo got a
  `db-verify` with Postgres-only `FILTER(WHERE)` queries that *error*. `detect.sh` now
  reads `schema.prisma` `provider`; the SKILL store table gained MySQL + SQLite rows. (D4)
- **Monorepo member detection (REL-5)** — `requirements.txt` / `setup.py` / `setup.cfg`
  are now member markers, so Python sub-packages are no longer invisible. (D3)
- **Duplicate members** — a dir with two manifests is now listed once. (D7)
- **Python package manager** — `uv.lock` / `poetry.lock` / `Pipfile.lock` detected. (C3)

### Changed
- **Empty-slot rendering** — `SKILL.md §4.2` now instructs the generator to omit empty
  slots (no empty `()` / inline-code / dangling `Build:` lines) and gives a
  no-test-runner fallback, so a frameworkless Go/Rust harness renders cleanly. (D2)
- README Status narrowed to the dogfood evidence; +12 tests (→ 83).

### Known limitations (0.x)
- Cargo `[workspace]` `members`/`exclude` not parsed (find-based member scan can
  include an excluded crate or miss a no-manifest binary crate) — tracked. (D5)

## [0.3.2] - 2026-06-26

### Changed
- **IP / attribution hygiene** (from an adversarial copyright audit — verdict was
  CLEAN, these are norm nits, no obligation existed): added a "not affiliated with
  Anthropic" disclaimer to the README ("Claude" / "Claude Code" used descriptively);
  renamed the `karpathy-guidelines` skill → `coding-guidelines` to drop a person's
  name from the public slug (content unchanged); fixed the `marketplace.json`
  `$schema` to the resolvable community URL (`json.schemastore.org/claude-code-marketplace.json`)
  — the previous `anthropic.com` URL 404'd and implied false provenance. The audit
  confirmed: no third-party code is vendored, no copied license headers, and no
  internal/proprietary content leaked (the engine is original bash; references like
  github-linguist / package-manager-detector are credited ideas, not copied code).

## [0.3.1] - 2026-06-26

A security + honesty patch from an adversarial OSS-readiness audit.

### Security
- **Critical RCE in `detect.sh` fixed.** The `add()` helper used `eval` to build its
  comma-lists; the `members` list is fed attacker-controlled directory names from a
  scanned (untrusted) target repo, so a crafted dir name like
  `a$(…)b/package.json` executed arbitrary shell when `introspect` scanned the repo —
  a drive-by RCE in a tool whose whole job is scanning untrusted repos. Replaced
  `eval` with a `printf -v` / `${!var}` form that stores values as inert data (no
  re-evaluation), portable to bash 3.2. Added a regression test (`detect_test.sh` [8])
  that feeds a `$(touch MARKER)`-named member dir and asserts nothing executes.

### Changed
- **Honest status / caveats** (the audit flagged overclaim): README now states that
  harness *generation* is LLM-driven and probabilistic (only *detection* is e2e-
  validated), that only TS + Python are generation-validated end-to-end, and adds a
  Requirements section (bash + python3; Windows via WSL; hooks fail open without
  python3). Test count corrected to 71.

## [0.3.0] - 2026-06-26

The introspect-first thesis extended to verification + build discipline, plus a
full cross-file coherence audit (identity / version / detection-gap fixes).

### Added
- **Stack-conditional critics** — `introspect` now generates a `db-verify` critic
  **only when a data layer is detected** (tailored to the real store: MongoDB
  `$exists` counts / Postgres `information_schema` / Redis) and a `ui-verify` critic
  **only when a frontend framework is detected** (tailored to the real dev command).
  Generated like the architect (not shipped static) because their commands are
  stack-specific — the introspect-first thesis applied to verification. The kit does
  **not** bundle the DB client or browser driver these need; introspect surfaces the
  one command to add them as guidance (§5 "External setup you may need") and never
  copies an external tool into the repo. New spine slot `{{CONDITIONAL_CRITICS}}`;
  replaces the old dead references to non-existent UI skills. +20 tests (→ 69).
- **Build-discipline layer** — `/harness-kit:tdd` + the `tdd-runner` agent
  (red → green → refactor, test-first), `/harness-kit:diagnose` (reproduce →
  minimize → hypothesize → fix the cause → regression-test),
  `/harness-kit:karpathy-guidelines` (surgical changes, no overcomplication,
  verifiable success), and the `architecture-reviewer` critic (layers / smells /
  invariants — the review pair of the generated `<stack>-architect`). Closes the
  build-discipline gap: the kit had verification + artifacts but not the
  test-first / debug discipline. The spine `## Workflow` gains a Build bullet and
  `## Critics` gains `architecture-reviewer` (eight critics).

### Fixed
- **Coherence audit remediation** (a full cross-file / per-stack-generation sweep):
  - **Identity** — `plugin.json` author, `marketplace.json` owner, and `LICENSE`
    copyright now use the publishing identity (`Jack Lee` / `github.com/jhlee0409`);
    the prior placeholder leaked an unrelated account onto the distribution surface.
  - **Python data layer detected** — `detect.sh` now recognizes a Python DB client
    (`pymongo` / `motor` / `sqlalchemy` / `psycopg` / `redis`), so a FastAPI + Mongo
    backend correctly gets a `db-verify` critic (previously DB detection was
    Node-only — the canonical backend stack silently shipped no `db-verify`).
  - **Measurement vapor removed** — `introspect` no longer mentions a Tier-3
    measurement subsystem or an `--enable-measurement` flag (neither exists); this
    matches the "no measurement system" thesis the README/CHANGELOG state.
  - **No dash sentinel** — an absent `dev`/`build`/`test` script now yields an empty
    field, not a literal `-` that could leak into a generated `{{DEV_COMMAND}}`.
  - **Monorepo** — `introspect` re-runs `detect.sh` per member (the root scan only
    names members); doc/comment honesty fixed to match.
  - Doc/template fixes: README hook paths (`hooks/scripts/…`), the five-key config
    schema noted, the resume-block fields moved inside the `resume:*` markers, the
    guard's default branches de-personalized, and a CI identity/version guard added.

## [0.2.0] - 2026-06-26

The workflow + verification layer: structured artifact management, a seven-critic
verification spine, the introspect routing block, a validated resume loop, and
brand assets. Reliability comes from discipline + independent checks — no
measurement system (deliberately cut as too heavy).

### Added
- **Agent routing** — introspect generates an explicit `## Agents` block in the
  spine so the main agent delegates to the right `<stack>-architect` without being
  named (auto-orchestration by explicit guidance, not description-matching luck).
- **Artifact-management skills** — `/harness-kit:new-spec` (spec / plan / context
  triplet), `/harness-kit:adr` (auto-numbered ADR), plus a spine `## Workflow`
  section (spec discipline / ADR / scratch).
- **Worktree workflow (ask-gated)** — introspect ASKS whether to enable a
  worktree-per-task workflow; `/harness-kit:worktree <slug>` isolates a task.
  Opinionated choices are asked, not assumed.
- **Resume loop** — `/harness-kit:handoff` writes a resume block;
  `/harness-kit:pickup` continues in a fresh session. Shipped only after a
  discriminating validation: a fresh session respected a non-obvious decision a
  no-handoff control missed 3/3.
- **Verification spine — seven read-only critics** routed on demand at each
  boundary: `instruction-critic` (is this the right ask?),
  `requirement-fidelity-critic` (spec drift from the original ask?),
  `change-verifier` (is the change complete?), `claim-checker` (overclaim? — with
  spine `§0.6 No overclaim`), `spec-reviewer` (PR vs its spec), `readability-critic`
  (can a human decide from this output?), `pr-shepherd` (is the PR mergeable?).
  Independent verification is the reliability lever; effect is marginal-but-real,
  not a guarantee — the only proven 100% check is a human.
- **`pr-shepherd` discovers the PR workflow** instead of assuming one — host / CI /
  bots are read at runtime, intent is pinned via a `pr_workflow` config
  (host / ci / merge_gate), it degrades gracefully when CI or a host CLI is absent,
  and never fabricates a MERGEABLE verdict without a defined gate.
- **Brand** — SVG logo, 1280×640 social-preview card, README hero, and an honest
  demo GIF (the real `/harness-kit:introspect` trigger, not a fabricated CLI).
- Tests: +spec (4) +adr (4) +worktree (4) → **49** across all suites.

### Changed
- The spine grew `§0.6 No overclaim` and `## Workflow` / `## Critics` sections;
  introspect seeds `worktree_workflow` and `pr_workflow` in `.claude/harness-kit.json`.

## [0.1.0] - 2026-06-26

First public release.

### Added
- `introspect` skill: scans a target repo's stack and generates a tailored harness
  (root `CLAUDE.md` spine + stack `*-architect` agent + `.claude/harness-kit.json`
  verify config + specs / ADR scaffolding).
- `detect.sh` detection engine (23-case suite) — layered-precedence detection of
  language / framework / test-runner / package-manager / monorepo / data-layer,
  plus typecheck/lint commands and polyglot per-subtree detection. Reads configs
  statically.
- `verify-loop` Stop hook — the feedback half of plan→work→verify→feedback, wired
  to the repo's real verify command. Non-blocking by default.
- `change-verifier` read-only critic agent.
- `protected-branch-guard` PreToolUse hook — configurable protected branches
  (env override > repo config > built-in default).
- `update-block.sh` — idempotent marked-block updater for safe introspect re-runs.
- `.claude/harness-kit.json` per-repo config; plugin + marketplace manifests, MIT
  license, community-profile files, CI. 37 tests.

[0.4.0]: https://github.com/jhlee0409/claude-harness-kit/releases/tag/v0.4.0
[0.3.4]: https://github.com/jhlee0409/claude-harness-kit/releases/tag/v0.3.4
[0.3.3]: https://github.com/jhlee0409/claude-harness-kit/releases/tag/v0.3.3
[0.3.2]: https://github.com/jhlee0409/claude-harness-kit/releases/tag/v0.3.2
[0.3.1]: https://github.com/jhlee0409/claude-harness-kit/releases/tag/v0.3.1
[0.3.0]: https://github.com/jhlee0409/claude-harness-kit/releases/tag/v0.3.0
[0.2.0]: https://github.com/jhlee0409/claude-harness-kit/releases/tag/v0.2.0
[0.1.0]: https://github.com/jhlee0409/claude-harness-kit/releases/tag/v0.1.0
