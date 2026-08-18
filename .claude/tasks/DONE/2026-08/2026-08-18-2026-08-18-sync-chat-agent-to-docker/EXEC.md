# EXEC — 2026-08-18-sync-chat-agent-to-docker
owner: Executor

## v1 — HALTED, prerequisites unreachable
exec_version: 1

The TASK constraint requires halting rather than reporting a partial result when
Docker or the local n8n API is unreachable. Both are. Checked, not assumed:

- `command -v docker` -> not installed in this execution environment. Every
  target this task needs (`make up`, `make import-all` via
  `scripts/import_workflow.sh`, which runs `docker compose exec n8n ...`) is
  therefore unrunnable here.
- `curl http://localhost:5678/healthz` -> HTTP 000, unreachable. `localhost` in
  this sandbox is the sandbox, not the Engineer's machine, so no port-forward
  interpretation makes this reachable either.
- `.env` does contain `N8N_API_URL` and `N8N_API_KEY`. That does not help: the
  values point at an instance this environment cannot route to, and the CLI
  import step needs the Docker daemon regardless of API reachability.

No operation was attempted against any instance. Nothing was changed.

## Preconditions verified from the repository (the part that could be done here)
These are read-only checks of whether the tooling can satisfy the task once run
on a machine that has Docker, so the Engineer is not debugging them mid-run:

- R3 (`error_log` must exist first): `scripts/create_data_table.sh` creates both
  `currency_rates` and `error_log` if missing, and is idempotent. Reached via
  `make setup-data-table`, itself part of `make setup`. Satisfied by running
  `make setup` before `make import-all`.
- Credentials: `scripts/import_credentials.sh` provisions
  `fcaHttpQueryAuth` and `llmOpenAiApiCred` from `.env`. `llmOpenAiApiCred` is
  exactly the id both OpenAI model nodes reference in
  `workflows/ai-chat-currency-agent.json`, so the credential wiring will resolve
  on import — provided `LLM_OPENAI_KEY` in `.env` is a real OpenAI key. It must
  be: the Cloud instance runs on n8n's built-in AI credits and carries no
  credential at all, so nothing about Cloud working is evidence that this key is
  valid.
- A1 (dependency-ordered activation): `python3 scripts/order_workflows.py`
  against the current `workflows/` emits `error-logger.json` before
  `ai-chat-currency-agent.json`, so the activation order this task depends on is
  correct on the current file set.

## Runbook for the Engineer
```
make up                  # start the stand
make setup               # data tables (incl. error_log) + credentials from .env
make import-all          # import all three, then activate in dependency order
make drift ID=bLflLYfGzORWkjJV FILE=ai-chat-currency-agent.json
```
`ID` is the workflow's own id, which is stable across instances because the
repository file pins it and `n8n import:workflow` upserts by it — the Docker
instance will hold the same id as Cloud, not a freshly generated one.

Then open the Docker instance's chat and send one message (A3). Expected, given
a working `LLM_OPENAI_KEY`: a normal conversion answer. Given a missing or
exhausted key: one `error_log` row with `context = "Guardrails - Screen User
Input"` and the fixed refusal text in chat — the same behaviour verified on
Cloud in execution 171.

What to report back for the Validator: the output of `make import-all` and
`make drift`, and either the chat answer or the new `error_log` row.

## Open issue
- id: EXEC-1
  type: requirement
  severity: blocking
  ref: "Task cannot proceed without a Docker daemon and a routable local n8n
    instance, neither of which exists in any actor's execution environment. Only
    the Engineer can run the four commands above. This is an access blocker, not
    a design or implementation gap — no amount of iteration inside the harness
    resolves it."
