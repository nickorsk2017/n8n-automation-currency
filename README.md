# Currency Converter AI Agent (n8n)

An n8n-based currency conversion assistant, built from two workflows:

1. **Daily Currency Rate Loader** — a scheduled workflow that fetches
   current FX rates from freecurrencyapi.com and upserts them into an
   n8n Data Table.
2. **AI Chat Currency Agent** — a chat-triggered LLM agent with a custom
   `convert_currency` tool that answers conversion questions using the
   rates stored by workflow 1.

Exported workflow JSON lives in `workflows/`, supporting docs in `docs/`.
Screenshots and chat recordings required by the brief are tracked in
`screenshots/` (see `.gitignore` — that directory is intentionally not
ignored).

## Setup

Prerequisites, none of which are automated by this repo:

- **freecurrencyapi.com** — register a free account and generate an API
  key. Used by workflow 1's HTTP Request node to call the `/latest`
  endpoint.
- **n8n instance** — a local, self-hosted n8n instance to build, run, and
  export the workflows. `docker-compose.yml` at repo root defines the
  service; `Makefile` wraps the common commands: `make up` (start in the
  background), `make down` (stop and remove), `make restart`, `make logs`
  (follow n8n logs), `make ps` (container status), and `make help` to list
  all targets. n8n is reachable at http://localhost:5678 once started.
- **LLM provider** — an OpenAI account and API key, used by workflow 2's
  Chat Model node.
- **Environment variables** — copy `.env.example` to `.env` and fill in
  the real values locally. See `.env.example` for the exact variable
  names expected (`FREECURRENCYAPI_KEY`, `LLM_OPENAI_KEY`). Secrets are
  loaded into n8n credentials from this file; they are never written
  into exported workflow JSON or committed to git (`.env` is gitignored).
  On **n8n Cloud** specifically, `$env` expressions are blocked at
  runtime regardless of what the instance's environment holds — workflow
  1's HTTP Request node instead reads the freecurrencyapi key from a
  stored n8n credential (**Generic Credential Type → Query Auth**, param
  name `apikey`), created manually in Credentials → Add Credential. The
  exported workflow JSON only ever holds a credential name/id reference,
  never the key value, on both self-hosted and Cloud.

## Documentation

Project documentation for this submission is tracked in this repo
(`README.md`, `docs/`). It may additionally be mirrored to a Notion
workspace via an MCP connector for easier review, once that connector
is authorized in an interactive session — this is optional tooling and
not a functional requirement of either workflow.

## Data Table schema

`currency_rates` has four columns: `base_currency`, `target_currency`, `rate`,
`fetched_at` (full type detail in `docs/data-table-schema.md`). The logical key
is `(base_currency, target_currency)` — freecurrencyapi's `/latest` response is
keyed by target currency per base, so one loader run naturally produces one row
per target currency, and re-running with a fresh pull must update those same
rows rather than append new ones.

Workflow 1 enforces this with the `Data Table` node's native `upsert` operation
(match on `base_currency` + `target_currency`, update on match / insert
otherwise) rather than a manual lookup-then-branch pattern — fewer nodes, same
idempotency guarantee, and it keeps a repeated daily run from silently growing
the table forever.

**Error handling trade-off:** three distinct failure points — the HTTP call
itself (`HTTP Request` node's error output), an empty/malformed API response
(`IF - Response OK`), and malformed transformed rows (`IF - Rows Valid`) — all
converge on a single `NoOp - Log Loader Error` node rather than three separate
handlers or a persisted errors table. This keeps the failure path isolated from
the Data Table write (no partial/invalid data ever reaches `currency_rates`)
while staying minimal in scope; a dedicated errors table is a reasonable future
enhancement if an audit trail of failures becomes a requirement, but isn't one
today.

## Agent system prompt

_(pending Workflow 2 task)_

## Trade-offs

_(pending — filled once both workflows are implemented)_
