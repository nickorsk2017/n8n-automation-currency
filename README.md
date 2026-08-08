# Currency Converter AI Agent (n8n)

An n8n-based currency conversion assistant, built from two workflows:

1. **Daily Currency Rate Loader** — a scheduled workflow that fetches
   current FX rates from freecurrencyapi.com and upserts them into an
   n8n Data Table.
2. **AI Chat Currency Agent** — a chat-triggered LLM agent with a custom
   `convert_currency` tool that answers conversion questions using the
   rates stored by workflow 1.

Exported workflow JSON lives in `workflows/`, supporting docs in `docs/`.
Screenshots and chat recordings required by the brief are **not** stored
in this repository — see `screenshots/` handling below.

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

## Documentation

Project documentation for this submission is tracked in this repo
(`README.md`, `docs/`). It may additionally be mirrored to a Notion
workspace via an MCP connector for easier review, once that connector
is authorized in an interactive session — this is optional tooling and
not a functional requirement of either workflow.

## Data Table schema

_(pending Workflow 1 task)_

## Agent system prompt

_(pending Workflow 2 task)_

## Trade-offs

_(pending — filled once both workflows are implemented)_
