# TASK — 2026-08-10-document-eval-scoring-skip
owner: Engineer
immutable: true

## Requirements
- R1: The editor's Evaluations step 3 ("Set up a quality score",
  optional, `setMetrics` Evaluation node) is being skipped by decision:
  `list_credentials` confirms no Anthropic/Claude credential exists on
  this n8n instance, and neither `.env.example` nor `scripts/` provision
  one (unlike `FREECURRENCYAPI_KEY`/`LLM_OPENAI_KEY`). Update
  `docs/workflows/chat-agent/README.md`'s "## Evaluations" section to
  state plainly that scoring is skipped for this concrete reason, not
  just "not configured".
- R2: No workflow JSON or live n8n workflow changes — documentation only.

## Acceptance
- A1: `docs/workflows/chat-agent/README.md` "## Evaluations" clearly
  states scoring is skipped because no Claude/Anthropic credential is
  provisioned on this instance.
- A2: No other file changed.

## Constraints
- English only.
