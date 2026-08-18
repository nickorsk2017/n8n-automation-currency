# PLAN — 2026-08-10-workflow-evals-claude-only
# PLAN — 2026-08-10-workflow-evals-claude-only

## v1

### Scope decision (R2)
Documentation-only. No workflow JSON change, no new eval script/workflow —
the Engineer's note is a status fact about n8n's built-in Evaluations
feature (judge/scoring model choice), not a request to build new tooling.

### Placement (R1)
The fact is workflow-specific (it's about evaluating the chat agent), so
it lives in `docs/workflows/chat-agent/README.md`, not the root README —
per the root CLAUDE.md docs rule that workflow-specific material stays
inside that workflow's directory and the root README only links to it.

### Steps
1. `docs/workflows/chat-agent/README.md`: add a short "## Evaluations"
   section stating that n8n's built-in Evaluations (Evaluation
   Trigger/node) currently supports Claude only as the judge/scoring
   model for this workflow — no other provider is a supported evaluation
   target today.
2. `README.md`: the existing "Automated evaluation..." trade-off bullet
   (Trade-offs and Things I'd Improve section) already covers Community
   edition's registration gate; append the Claude-only judge-model
   constraint to that same bullet in one clause rather than a new bullet,
   keeping it a pointer, not a restatement — no new specifics beyond what
   sends the reader to `docs/workflows/chat-agent/`.
3. No other files touched.

### Risk
Low — additive prose in two existing files, no code/workflow semantics
change.
