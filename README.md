**Author:** Nikolai Stepanov
**Contact:** https://www.linkedin.com/in/nickot/

---

# Currency Converter AI Agent (n8n)

An n8n currency conversion assistant built from two workflows:

1. **Daily Currency Rate Loader** — a scheduled workflow that fetches FX rates
   from freecurrencyapi.com and upserts them into an n8n Data Table.
2. **AI Chat Currency Agent** — a chat-triggered LLM agent with a custom
   `convert_currency` tool that answers conversion questions from those stored
   rates.

Exported workflow JSON lives in `workflows/`; it is the source of truth for
review, not the live n8n instance. Full documentation is in
[`docs/`](docs/README.md).

## How this was built

Result: `workflows/currency-rate-loader.json` and
`workflows/ai-chat-currency-agent.json`, documented in `docs/workflows/`.

Built through Claude Desktop connected to the n8n Cloud instance
(`nickdevstartup.app.n8n.cloud`) over MCP, together with the local
`.claude/` harness. Claude audited the live system and surfaced gaps and
bottlenecks — for example, missing AI guardrails on the chat agent — and
those findings became tasks tracked and worked through the harness. The
audited workflows were then synced from Cloud into this repository's
Docker-based `workflows/*.json`. This is a development tool used to build
the system, not a feature added on top of it.

Details in [`docs/architecture.md`](docs/architecture.md).

## AI Harness

Auditing this system on the n8n Cloud dev stand went through the Claude
Harness in this repository (`.claude/` plus the rules in `CLAUDE.md`), not
ad-hoc chat. Claude Desktop was connected to n8n Cloud via MCP, which is what
made the audit and the resulting tasks possible without any command-line
access to that stand. The reviewed workflow JSON was then imported into this
repository to become the local, Docker-based version tracked under
`workflows/`. See [`docs/architecture.md`](docs/architecture.md) for the full
two-stand model and data flow.

The harness itself is carried over from another project, not built for this
submission — wiring it into this repository took about two minutes, so the
`.claude/` task history reflects reused tooling rather than time spent inside
the brief's 4-6 hour budget, and reusing it made changes to this system
auditable and routed consistently, which raised the quality of this
submission and sped up its delivery.

**TODO:** today this audit is run manually, on request, by the AI Automation
Engineer. The recommended next step is an AI Agent that runs the same audit
against the n8n Cloud stand on a regular schedule, rather than relying on
someone remembering to ask for it.

## Setup

Requires Docker, a free [freecurrencyapi.com](https://freecurrencyapi.com) key,
and an OpenAI key (or n8n's own free AI credits). Nothing here needs a paid
plan.

```bash
cp .env.example .env      # fill in FREECURRENCYAPI_KEY and LLM_OPENAI_KEY
make up                   # n8n at http://localhost:5678
```

Once the instance is up, create an n8n API key (Settings → n8n API → Create API
key) and add it to `.env` as `N8N_API_KEY`. Then provision everything the
workflows depend on from `.env` alone — no manual n8n UI steps:

```bash
make setup     # idempotent — creates the currency_rates Data Table and
               # imports both credentials (freecurrencyapi, OpenAI) from .env
```

See [the rate loader docs](docs/workflows/rate-loader/) for the Data Table's
schema and why it's shaped that way. Neither key is ever written into workflow
JSON, on disk, or committed — `make setup` reads `.env` and calls the n8n API
and CLI directly; exported workflows carry credential name/id references only.

Import the workflows into the running stand — one at a time, or all of
`workflows/` at once. Import also activates each workflow (needed for the
loader's schedule to fire and for the chat agent's self-referencing tool call
to work), so nothing needs a manual Active toggle afterward either:

```bash
# for every file in workflows:
make import-all
```

The `Makefile` header carries the full detail — prerequisites, credential setup,
the two n8n stands, and how to read a failed loader run — kept next to the
commands themselves rather than in a separate document that would drift from
them.

### "Permission denied" running a script

`scripts/create_data_table.sh`, `scripts/import_credentials.sh`,
`scripts/import_workflow.sh`, `scripts/export_workflow.sh`, and
`scripts/clean_docker_stand.sh` are tracked in git as executable (mode
`100755`), but a local checkout or copy can still end up without the
executable bit. `setup-data-table`, `import-credentials`, `setup`, `import`,
`import-all`, `export`, `drift`, and `clean` check this before shelling out
and auto-repair it (`chmod +x`) — you'll see a `note: restored exec bit on
...` line and the command proceeds normally.

If the bit can't be restored automatically (script file missing, or a
read-only mount), the target fails with `ERR_SCRIPT_NOT_EXECUTABLE: ...` on
exit code `126` — grep the scripts for that marker, or just run the fix it
names:

```bash
chmod +x scripts/create_data_table.sh scripts/import_credentials.sh scripts/import_workflow.sh scripts/export_workflow.sh scripts/clean_docker_stand.sh
```

## Configuring the base currency

The loader's base currency defaults to USD and is currently a single-field
edit in `Set - Loader Config`. n8n Variables — the usual way to make a value
like this editable without touching the workflow — are gated behind an
Enterprise license on self-hosted Community edition, which is what
`docker-compose.yml` runs here; they're free only on n8n Cloud. Since the
brief rules out paid plans, Variables aren't a reachable option on this
stand, so the node-level literal is the correct choice here, not a shortcut.
See [the rate loader docs](docs/workflows/rate-loader/) for the exact steps
and the Cloud-only alternative.

## Keeping the repo in sync with the instance

`workflows/*.json` is the source of truth for review, not the live n8n
instance. If a workflow is edited in the n8n editor, export it back into the
repo; `drift` checks whether the two have already diverged.

```bash
make export ID=<WORKFLOW_ID> FILE=currency-rate-loader.json
make drift  ID=<WORKFLOW_ID> FILE=currency-rate-loader.json
```

## Trade-offs and ToDo

What I'd improve with more time:

- **An automated audit system for workflows, not just manual checks and n8n's
  own tests.** This becomes a real problem once there are many workflows.
- **Tests** for the cross-rate arithmetic and the validation rules, currently
  verified by running them rather than by a suite.
- **Rate limiting and DDoS protection for the chat agent and any other
  publicly exposed workflow.** Belongs at the infrastructure level (a
  reverse proxy/CDN like Cloudflare in front of n8n), not inside the
  workflow. Not provisioned in this repo today; `docker-compose.yml` runs
  n8n only.
- **Automated evaluation of the chat agent's answer quality**, via n8n's
  built-in Evaluations (Evaluation Trigger/node scoring against a Data
  Table of expected Q&A) instead of manual conversation checks. Left as
  future work because Community edition gates it behind a free,
  per-instance registration step every engineer running `make up` would
  have to repeat themselves.

## Documentation

`docs/` describes how the system works right now — one directory per
workflow, plus cross-cutting material like `docs/architecture.md`. It is
rewritten in place as the system changes rather than kept as a history of
what was tried.

- [Daily rate loader](docs/workflows/rate-loader/) — schedule, flow, error
  handling, and the data table schema: columns, the
  `(base_currency, target_currency)` key, why it upserts rather than appends,
  and why cross rates are derived instead of stored.
- [Chat agent](docs/workflows/chat-agent/) — the full agent
  [system prompt](docs/workflows/chat-agent/README.md#system-prompt), the
  `convert_currency` tool contract, its error codes, and the cross-rate
  arithmetic.

Operational instructions live in the `Makefile`, next to the commands they
describe.
