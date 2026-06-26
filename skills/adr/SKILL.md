---
name: adr
description: >-
  Record an architecture / cross-cutting decision as the next numbered ADR under
  docs/adr/. Use when a non-obvious or hard-to-reverse decision is made (a module
  boundary, a trade-off, a tech choice), or when the user says "record an ADR",
  "ADR 남겨", "이 결정 기록", "document this decision".
argument-hint: "<title>"
allowed-tools: Bash, Read, Edit
---

# adr

Capture WHY a non-obvious decision was made, so a future reader (or session)
doesn't re-litigate it.

1. **Scaffold:** run
   `bash "${CLAUDE_PLUGIN_ROOT}/skills/adr/new-adr.sh" "<title>"` from the repo
   root. It computes the next number, writes `docs/adr/NNNN-<slug>.md` from the
   template, and prints the path.
2. **Fill:** Context (the forces) → Decision (active voice) → Consequences
   (what's easier / harder) → Alternatives (and why not). Keep it short — an ADR
   records the reasoning, not a manual.
3. Record an ADR for decisions that are non-obvious, cross-cutting, or
   hard to reverse — not for routine changes.
