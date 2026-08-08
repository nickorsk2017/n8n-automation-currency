# TASK — 2026-08-08-setup-prep-docs
owner: Engineer
immutable: true

## Context
Root `CLAUDE.md` requires a `README.md` as the submission entry point
covering setup, but no `README.md` exists yet. The Engineer's own prep
checklist (account registration, local n8n instance, LLM provider key,
git repo, Notion MCP for docs) needs to be captured as documentation so
setup steps are reproducible and are not left only in chat.

## Requirements
- R1: Create `README.md` at repo root with a "Setup" section listing the
  manual prerequisites: freecurrencyapi.com account + free-tier API key,
  a local n8n instance (self-hosted via Docker), an LLM provider account
  + API key (OpenAI), and required env vars (reference `.env.example`,
  do not restate key values).
- R2: README setup section notes that secrets are supplied via `.env`
  per root `CLAUDE.md` and are never committed or placed in workflow JSON.
- R3: README notes that this repo is the submission root and screenshots
  are excluded from the repo (per root `CLAUDE.md`), stored elsewhere.
- R4: Add a short "Documentation" note that project docs may additionally
  be maintained in Notion via an MCP connector, if/when connected — this
  is optional tooling, not a functional requirement of the workflows.
- R5: README stubs (not yet filled) the sections required later by root
  `CLAUDE.md`: Data Table schema rationale, agent system prompt,
  trade-offs — marked as `(pending Workflow 1 / Workflow 2 tasks)`.

## Acceptance
- A1: `README.md` exists at repo root, English only.
- A2: Setup section lists every prerequisite above without embedding any
  actual API key or secret value.
- A3: No workflow JSON, docs/, or screenshots/ content is created by this
  task — scope is limited to `README.md`.

## Constraints
- English only.
- Single file touched (LOW complexity): `README.md`.
- Do not perform the account registration, Docker setup, or MCP OAuth
  connection itself — those are manual actions outside this repo's
  file scope.
