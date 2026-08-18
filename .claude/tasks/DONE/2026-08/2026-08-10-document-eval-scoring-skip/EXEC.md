# EXEC — 2026-08-10-document-eval-scoring-skip
# EXEC — 2026-08-10-document-eval-scoring-skip

## v1 (LOW — no PLAN.md)

- Updated `docs/workflows/chat-agent/README.md` "## Evaluations" section:
  scoring is now stated as skipped specifically because no
  Claude/Anthropic credential is provisioned on this instance (no
  `ANTHROPIC_API_KEY` in `.env.example` or an import script step), not
  just "not configured". No other file touched.
