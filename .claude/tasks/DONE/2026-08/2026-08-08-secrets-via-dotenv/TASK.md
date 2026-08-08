# TASK — 2026-08-08-secrets-via-dotenv
owner: Engineer
immutable: true

## Context
Root `CLAUDE.md` (section "n8n conventions") currently mandates:
> Secrets never live in workflow JSON. The freecurrencyapi key and the LLM key
> are n8n credentials, referenced by credential name only. An exported JSON
> containing a literal key is a blocking issue.

Engineer wants to replace this policy: secrets should be supplied via a local
`.env` file (not committed) instead of being mandated as n8n credential-store
entries, and the repo should ship a `.env.example` template documenting the
required variables.

## Requirements
- R1: Amend root `CLAUDE.md` "n8n conventions" section to remove the
  requirement that secrets must be stored as n8n credentials. Replace it with
  a policy that secrets are supplied via a local `.env` file, loaded outside
  of workflow JSON, and that workflow JSON must still never contain a literal
  key value (that constraint stays — only the "must be an n8n credential"
  mechanism is removed).
- R2: Create `.env.example` at repo root listing every required variable
  (freecurrencyapi key, LLM provider key(s)) with placeholder values and a
  one-line comment per variable explaining its purpose.
- R3: Do not create a real `.env` with actual secret values — `.env.example`
  only. A real `.env` is a local, untracked file the Engineer creates
  themselves from the template.
- R4: Confirm `.gitignore` (already present, task `2026-08-08-gitignore`)
  ignores `.env`/`.env.*` but not `.env.example` — do not weaken that rule.

## Acceptance
- A1: Root `CLAUDE.md` no longer states secrets must be n8n credentials;
  new wording reflects the `.env` policy.
- A2: `.env.example` exists at repo root with placeholders for all required
  variables and explanatory comments.
- A3: No real secret value is written to any tracked file.
- A4: `.gitignore` still ignores `.env`/`.env.*` while allowing
  `.env.example` to be tracked.

## Constraints
- English only in all persisted content (per root `CLAUDE.md` language rule).
- Touches: `CLAUDE.md` (root), `.env.example` (new) — 2 files, hence MEDIUM
  complexity (routes through Planner).
