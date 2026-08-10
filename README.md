# Currency Converter AI Agent (n8n)

An n8n currency conversion assistant built from two workflows, plus the system
around them that keeps documentation, sync and review honest.

1. **Daily Currency Rate Loader** — a scheduled workflow that fetches FX rates
   from freecurrencyapi.com and upserts them into an n8n Data Table.
2. **AI Chat Currency Agent** — a chat-triggered LLM agent with a custom
   `convert_currency` tool that answers conversion questions from those stored
   rates.

Exported workflow JSON lives in `workflows/`; it is the source of truth for
review, not the live n8n instance. Full documentation is in
[`docs/`](docs/README.md).

## Why a system, not just two workflows

Two working workflows are the deliverable the brief asks for. The rest of this
repository exists because shipping only the workflow files would leave three
problems unsolved the moment someone other than the person who built them
needs to touch this:

1. **Only the person who built it knows how it works.** Without a documented,
   current description of each workflow's behaviour, a schema's rationale or a
   tool's error contract, operating or changing the system requires opening
   the workflow in the editor and reverse-engineering intent from nodes.
2. **"Read the repository" does not scale past one repository.** A CTO, an
   end user, or another engineer can currently only learn how this works from
   the files in this repo. That is fine for one submission. It stops being
   fine once an organization has dozens of repositories like this one and a
   team larger than the person who wrote them — nobody is going to clone
   every repo to find out what it does.
3. **There is no automated audit.** Reviewing workflow JSON by hand for drift,
   duplicated ids, or a stale export is slow with one repository and close to
   infeasible with hundreds. Automated tests help with behaviour but do not
   check the things that go wrong in low-code — a node exported with a live
   secret, a schedule trigger id that would collide with another workflow, a
   file that no longer matches what the instance runs.

The `.claude/` harness, `docs/`, the Notion mirror and the on-request audit
described below are a minimal environment addressing exactly these three
problems, not scope beyond the brief: a documentation layer a non-engineer can
read without opening the repository, and a review layer that catches the
classes of mistake manual review and tests both miss. See `Layers` for the
mechanism and [`docs/architecture.md`](docs/architecture.md) for how it
operates end to end.

**Provenance, for the time budget:** the `.claude/` harness itself is reused
from another project — adapted here by copy-paste, not written from scratch
for this task. Describing this project's own rules on top of it, in root
`CLAUDE.md`, took about 2 minutes. It is an existing tool applied here, not
time spent inventing process instead of building the two workflows.

## Layers

| Layer | Contains | For |
|---|---|---|
| `.claude/tasks/` (harness) | Stages, task ids, plans, execution and validation records, decision history | Machine / audit |
| `docs/` | How the system works **now** — no task ids, no history | People |
| Notion → `N8N Workflows` | Mirror of `docs/` | Business readers, reviewers |
| `workflows/*.json` | The implementation, and the artifact under review | n8n |
| Claude + MCP | Sync, audit, documentation — on request | The AI Automation Engineer |

The last row is the design decision worth calling out: **the automation around
these workflows is not another n8n workflow**. It is Claude with access to the
n8n MCP connector, the Notion MCP connector and this repository. That is why
syncing stands, refreshing documentation and auditing the workflows are
operations an engineer requests today rather than jobs on a schedule — and why
putting them on a schedule is an extension of what exists rather than a rewrite.
See [`docs/architecture.md`](docs/architecture.md).

## Setup

Requires Docker, a free [freecurrencyapi.com](https://freecurrencyapi.com) key,
and an OpenAI key (or n8n's own free AI credits). Nothing here needs a paid
plan.

```bash
cp .env.example .env      # fill in FREECURRENCYAPI_KEY and LLM_OPENAI_KEY
make up                   # n8n at http://localhost:5678
make help                 # every available target
```

Then create the two n8n credentials and attach them — freecurrencyapi as
*Generic Credential Type → Query Auth* with parameter name `apikey`, and OpenAI
as `openAiApi`. Neither key is ever written into workflow JSON; exported
workflows carry credential name/id references only.

Import a workflow into the running stand, export one back out, or check whether
the two have diverged:

```bash
make import FILE=1-currency-rate-loader.json
make export ID=iBdFv2bTfVR7chbE FILE=1-currency-rate-loader.json
make drift  ID=iBdFv2bTfVR7chbE FILE=1-currency-rate-loader.json
```

The `Makefile` header carries the full detail — prerequisites, credential setup,
the two n8n stands, and how to read a failed loader run — kept next to the
commands themselves rather than in a separate document that would drift from
them.

## Trade-offs

Things deliberately not built:

- **One error convergence point, not a persisted errors table.** All three
  loader failure modes — the HTTP call, an unusable response, invalid
  transformed rows — converge on a single node that emits a structured record
  and fails the run. That gives diagnosis and visibility without a schema
  change. What it does not give is an audit trail across runs; you can see that
  yesterday failed, but not query a month of failures.
- **Cross rates derived, not stored.** Keeps the loader unchanged and the table
  proportional to the number of currencies, at the cost of float division per
  request and results rounded to six decimals. Fine for conversation, not for
  settlement.
- **The tool lives in the same workflow file as the agent.** A sandboxed code
  tool cannot query a Data Table, so the tool is a second entry point in the
  same workflow, called by id. One file instead of two, at the cost of a canvas
  with two unconnected chains on it.
- **The audit and documentation loops are requested, not scheduled.** They work
  today by asking Claude; nothing runs on its own.

What would come next, in the order I would build it:

1. **Scheduled and change-triggered audit.** Daily plus on-change, rather than
   on request. The deterministic checks are the ones to automate first — they
   are cheap and have already caught real problems, including a workflow id that
   would have created a duplicate loader on the same schedule.
2. **Findings with state, reported as deltas.** Each finding fingerprinted and
   tracked as new / acknowledged / fixed, so a report contains what changed
   rather than the same list every morning. A daily report that repeats itself
   gets muted within a week, which is the usual way this kind of check dies.
3. **Findings written to Notion as drafts** under `N8N Workflows → Trade-offs`,
   keeping generated content and human rationale in separate blocks so a refresh
   never overwrites the reasoning.
4. **Slack intake.** Business requests arrive in Slack, Claude drafts a
   structured task under `N8N Workflows → Business Requests`, and a human
   approves before it becomes real work. Never auto-created — a passing remark
   in a channel should not become a task.
5. **A `loader_errors` table**, once failure history is worth querying.
6. **Staleness warning.** If the loader silently stops, the agent keeps
   answering confidently from old rates. It should warn when `fetched_at` is
   older than a threshold.
7. **Tests** for the cross-rate arithmetic and the validation rules, which are
   currently verified by running them rather than by a suite.

## Documentation

Anything specific to one workflow is documented with that workflow rather than
here:

- [Daily rate loader](docs/workflows/rate-loader/) — schedule, flow, what happens
  when the API fails, and the data table schema it writes: the columns, the
  `(base_currency, target_currency)` key, why it upserts rather than appends, and
  why cross rates are derived instead of stored.
- [Chat agent](docs/workflows/chat-agent/) — the full agent system prompt, the
  `convert_currency` tool contract, its error codes, and the cross-rate
  arithmetic.
- [Architecture](docs/architecture.md) — main details about arechitecture of workflows

Operational instructions live in the `Makefile`, next to the commands they
describe.

Mirrored to Notion under
[N8N Workflows](https://app.notion.com/p/3b739cf0f2ac81c4892cfaef9fd1f251) for
readers who do not open the repository. The mirror carries the same pages plus
two placeholder sections — *Trade-offs* and *Business Requests* — which describe
the audit-findings and Slack-intake loops that are not automated yet. It is
regenerated from `docs/` on request; nothing outside that section is touched.

`.claude/` holds the execution harness: every change here was made as a tracked
task with a plan, an execution record and a validation record. That history is
deliberately kept out of `docs/`, which describes only the current state.
