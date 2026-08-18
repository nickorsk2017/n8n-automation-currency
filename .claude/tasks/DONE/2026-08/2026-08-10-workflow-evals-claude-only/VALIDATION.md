# VALIDATION — 2026-08-10-workflow-evals-claude-only
# VALIDATION — 2026-08-10-workflow-evals-claude-only

## v1

- A1: PASS — Claude-only judge-model constraint documented in exactly one
  place (`docs/workflows/chat-agent/README.md#evaluations`), and pointed
  to from `README.md`'s existing trade-off bullet, in English.
- A2: PASS — only `docs/workflows/chat-agent/README.md` and `README.md`
  changed; no workflow JSON touched.
- Language check: no non-English content added (em-dash/arrow characters
  are pre-existing house style, not a violation).
- Docs placement rule: no task/requirement ids introduced into `docs/`.
- Link check: `docs/workflows/chat-agent/` resolves.
- `ci_check.py`: clean.

status: PASS
