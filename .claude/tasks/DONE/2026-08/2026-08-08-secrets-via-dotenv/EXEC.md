# EXEC — 2026-08-08-secrets-via-dotenv

## v1
Changed files:
- `CLAUDE.md` (root) — replaced the "Secrets never live in workflow JSON"
  bullet under "n8n conventions". New wording: keys supplied via a local
  `.env` file (pointing to `.env.example`), loaded outside workflow
  export/import; the "no literal key in exported JSON" invariant is kept
  verbatim.
- `.env.example` (new, repo root) — two variables with explanatory comments:
  `FREECURRENCYAPI_KEY`, `LLM_API_KEY`. No real secret values.

Not changed (per PLAN R4): `.gitignore` — already ignores `.env`/`.env.*`
and negates `.env.example` back in; verified by inspection (`git
check-ignore` unavailable in this sandbox — no `.git` present — so verified
by reading pattern list directly against `.env`, `.env.local`, `.env.example`
names).

Observation for Validator: `.gitignore` line 12 comment still reads "live in
n8n credentials, never in this repo" — now stale relative to the new
`.env`-based policy. Patterns themselves are still correct and unaffected;
flagging as a possible non-blocking follow-up rather than editing, since
`.gitignore` was out of this task's file scope per PLAN.

STATE: stage=EXECUTED, next_actor=Validator, exec_version=1
