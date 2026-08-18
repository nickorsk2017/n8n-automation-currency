# PLAN — 2026-08-10-wire-loader-eval-outputs
# PLAN — 2026-08-10-wire-loader-eval-outputs

## v1

### Decision (R1, R2, A1): evaluation wiring is not a good fit here

n8n's Evaluations feature is built around one shape: a dataset row goes
in, the workflow produces some output (typically natural-language, from
an LLM step), and either a human-authored `expected_answer` or an LLM
judge scores how close the actual output came. Every part of that shape
assumes the thing being graded is non-deterministic and worth judging by
similarity/quality — which is exactly why it fit the chat agent (task
2026-08-10-wire-eval-outputs-to-dataset).

The rate loader has none of that shape. Given a fixed sample API
response, the transform (`Code - Rates To Rows`), validation
(`IF - Rows Valid`, `IF - Row Fields Valid`), and upsert are pure
functions of their input — the "correct" output is a single exact value,
not a range of acceptable answers. That is what unit/integration tests
check (already named as a documented gap in the root README's trade-offs
list), and testing it through n8n's Evaluations UI would mean hand-coding
one dataset row's `expected_answer` as a full serialized row-array or
error-record and asking Claude (the only available judge model, per task
2026-08-10-workflow-evals-claude-only) to eyeball whether two JSON blobs
"match" — strictly worse than an assertion. There is also no meaningful
`setInputs` moment: the loader's real input is an external API response,
not something a human usefully hand-authors as a dataset row.

Conclusion: don't wire it. The two stub nodes found in the draft
(`When fetching a dataset row` with an unset `dataTableId`, and the
disconnected `Evaluation`/`setInputs` node) are UI-generated clutter from
opening the Evaluations tab, not a deliberate design — remove them (R3).

### Steps
1. Remove `When fetching a dataset row` (evaluationTrigger) and
   `Evaluation` (setInputs) nodes from the live "Daily Currency Rate
   Loader" workflow. Neither has any connection to remove alongside them
   (confirmed via `get_workflow_details`: absent from `connections`).
2. Publish the resulting draft so the active version has no trace of
   them either (they were never in the active version to begin with, but
   publishing keeps draft/active in sync going forward).
3. Re-export `workflows/currency-rate-loader.json` — no diff expected
   versus the currently exported file, since these nodes were draft-only
   and never appeared in the active version or a prior export; confirm
   this by comparing node counts before closing out.
4. Add a short note to `docs/workflows/rate-loader/README.md` recording
   the decision *why* Evaluations isn't wired here — one paragraph,
   pointing at the "deterministic vs. judged" distinction — so a future
   reader doesn't reopen this question without the reasoning, and so it
   doesn't read as an oversight next to the chat agent's Evaluations
   section.

### Risk
Very low — removing two disconnected, unconfigured nodes and adding one
documentation paragraph. No change to loader logic (R5).
