# EXEC — 2026-08-10-wire-loader-eval-outputs
# EXEC — 2026-08-10-wire-loader-eval-outputs

## v1 (implements PLAN v1)

- Removed the two disconnected, unconfigured draft-only nodes from the
  live "Daily Currency Rate Loader" workflow (`iBdFv2bTfVR7chbE`):
  `When fetching a dataset row` (evaluationTrigger, dataTableId unset)
  and `Evaluation` (setInputs). Confirmed no connections referenced
  either name before removal. Node count: 14 -> 12.
- Published the resulting draft.
- Confirmed `workflows/currency-rate-loader.json` already has 12 nodes
  matching the loader's real pipeline (Schedule Trigger through Stop and
  Error - Fail Loader Run) with no trace of the stub nodes -- they were
  never in the active version or a prior export, so no re-export was
  needed (R4/A3).
- `docs/workflows/rate-loader/README.md`: added an "## Evaluations are
  not wired here" section explaining the decision (deterministic
  transform vs. an LLM-judged free-text answer), linking to the chat
  agent's Evaluations section for contrast.
- No literal credential/key values in any changed file.
- Loader fetch/transform/validate/upsert/error nodes and connections
  unchanged (R5/A5).
