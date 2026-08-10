# Architecture

## The layer model

| Layer | Contains | For |
|---|---|---|
| `.claude/tasks/` | Stages, task ids, plans, execution and validation records, decision history | Machine / audit |
| `docs/` | How the system works right now, no history | People |
| Notion → `N8N Workflows` | Mirror of `docs/` | Business readers, reviewers |
| `workflows/*.json` | The implementation, and the artifact under review | n8n |
| Claude + MCP | Sync, audit, documentation — on request | The engineer operating the system |

The last row is the one that surprises people, so it is worth stating plainly:
**the automation around these workflows is not another n8n workflow.** It is
Claude with access to the n8n MCP connector, the Notion MCP connector and this
git repository. That is why the audit, the documentation refresh and the
stand-to-stand sync are things an engineer asks for rather than jobs on a
schedule. Making them scheduled is future work, not a redesign — the operations
themselves already exist: the commands are documented in the `Makefile`, and the
checks an audit performs are listed in the root `README.md`.

## Two n8n stands

The system spans two instances, and they are not interchangeable.

**Dev stand — n8n Cloud.** Where the workflows are built and tested. Reachable
through the n8n MCP connector and the browser, but it has no command-line
access, so no shell script in this repository can talk to it.

**Prod stand — self-hosted Docker.** Defined by `docker-compose.yml`, started
with `make up`. Reachable by the n8n CLI inside the container, which is what
`make import`, `make export` and `make drift` use. This is the stand you would
put behind your own network controls.

Between them sits the git repository, which holds the canonical copy.

```
   n8n Cloud (dev)  ──►  git: workflows/*.json  ──►  Docker (prod)
        ▲                        │
        └──── Claude via MCP ────┘
```

Git to Docker runs in both directions with `make import` and `make export`.
Cloud to git is the direction with no CLI, so Claude performs it through the MCP
connector when asked.

## Why the repository is the source of truth

A workflow edited in the n8n editor and never exported is invisible to review:
the reviewer reads the file, the instance runs something else. The repository
therefore wins by convention, and `make drift` exists to make a violation
detectable rather than merely forbidden. It compares a repository file against
what the instance actually holds, ignoring the bookkeeping fields n8n rewrites
on every save so that it only reports real divergence. See the `drift` target in
the `Makefile`.

This is not hypothetical. The loader's file id and its live id had already
diverged, which would have made an import create a duplicate workflow on the
same daily schedule rather than restoring the original.

## Data flow

1. **06:00 UTC** — the loader's Schedule Trigger fires on the dev stand.
2. It reads `base_currency` (default `USD`) from a config node, calls
   freecurrencyapi's `/latest` endpoint, and validates the response.
3. Valid rates are upserted into the `currency_rates` Data Table, one row per
   currency pair, keyed so that a repeated run updates rather than appends.
4. A user opens the chat interface and asks a question in natural language.
5. The agent extracts the amount and the two currency codes and calls the
   `convert_currency` tool. It is instructed never to compute a rate itself.
6. The tool validates the input, reads `currency_rates`, derives a cross rate
   when neither currency is the base, and returns the converted amount, the rate
   used, and when that rate was fetched.
7. The agent turns that into a sentence, including the freshness timestamp, or
   explains the problem in plain language if the tool returned an error.

Anything that fails between steps 2 and 3 stops before the table is written.
That guarantee is described in
[workflows/rate-loader/](workflows/rate-loader/).
