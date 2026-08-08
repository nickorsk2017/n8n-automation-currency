# PLAN — 2026-08-08-secrets-via-dotenv

## v1

### R1 — CLAUDE.md wording change
Replace, in root `CLAUDE.md` under "n8n conventions", the bullet:

> **Secrets never live in workflow JSON.** The freecurrencyapi key and the
> LLM key are n8n credentials, referenced by credential name only. An
> exported JSON containing a literal key is a blocking issue.

with:

> **Secrets never live in workflow JSON.** The freecurrencyapi key and the
> LLM key are supplied via a local `.env` file (see `.env.example` for the
> required variable names) and loaded into the n8n instance outside of
> workflow export/import. An exported JSON containing a literal key is a
> blocking issue.

Rationale: keeps the invariant that actually matters for review (no literal
key in exported JSON) and only swaps the storage mechanism from "n8n
credential store" to "local `.env`", per Engineer instruction. No other
section of `CLAUDE.md` references the credential-store mechanism, so this is
a single-bullet edit — confirmed by grep before execution.

### R2 — `.env.example`
New file at repo root, two variables (matches the two secrets named in the
brief: freecurrencyapi and the LLM provider):

```
# freecurrencyapi.com API key — used by Workflow 1 (Daily Currency Rate Loader)
# to call the /latest endpoint. Get a free-tier key at https://freecurrencyapi.com
FREECURRENCYAPI_KEY=your_freecurrencyapi_key_here

# LLM provider API key — used by Workflow 2 (AI Chat Agent) for the
# conversation model. Provider is configurable (OpenAI, Anthropic, etc.);
# name the variable for whichever provider is actually wired into the
# workflow's credential/HTTP node.
LLM_API_KEY=your_llm_provider_key_here
```

### R3 — no real `.env`
Executor writes `.env.example` only, never `.env`. This satisfies R3/A3 by
construction (the file simply isn't created).

### R4 — `.gitignore` check
Existing `.gitignore` (task `2026-08-08-gitignore`, DONE) already has:
`.env`, `.env.*` ignored, `!.env.example` negated back in. No edit needed;
Executor verifies with `git check-ignore` and records the check in EXEC.md
rather than modifying the file.

### Files touched
- `CLAUDE.md` (root) — 1 bullet edit
- `.env.example` (new)

No other files change. Confirms MEDIUM classification (2 files, no new
module/schema/infra).

STATE: stage=PLANNED, next_actor=Executor, plan_version=1
