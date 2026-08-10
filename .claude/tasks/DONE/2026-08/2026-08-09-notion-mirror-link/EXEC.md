# EXEC — 2026-08-09-notion-mirror-link

## v1
Changed files:
- `README.md` — the Documentation section now links the Notion mirror by URL and
  states what it contains and how it is refreshed.

### Notion section created (not a repository artifact, recorded here)
Root page `N8N Workflows`
(https://app.notion.com/p/3b739cf0f2ac81c4892cfaef9fd1f251), carrying the layer
table and a note that it mirrors `docs/`, with eight sub-pages:

| Page | Mirrors |
|---|---|
| Architecture | `docs/architecture.md` |
| Data table schema | `docs/data-table-schema.md` |
| Workflow 1 — Daily Currency Rate Loader | `docs/workflow-1-rate-loader.md` |
| Workflow 2 — AI Chat Currency Agent | `docs/workflow-2-chat-agent.md` |
| Operations | `docs/operations.md` |
| Auditing the workflows | `docs/audit.md` |
| Trade-offs | placeholder |
| Business Requests | placeholder |

The two placeholders each open with an explicit status line saying the loop is
not implemented, then describe what will populate them — audit findings as
drafts, and Slack-originated business requests that require human approval
before becoming harness tasks. Stating "not implemented" at the top is the point:
a page describing an intake flow reads as a description of a working system
unless it says otherwise.

Workspace state before the change was a single teamspace (`Team HQ`) and one
private database (`Notes`); neither was read into or modified. Every page created
sits under the new `N8N Workflows` root, so the "do not touch drafts or other
sections" constraint is satisfied structurally rather than by care.

Note on placement: the Notion API rejects a teamspace id as a page parent, so the
section was created at workspace level. Moving it into `Team HQ` is a drag in the
Notion sidebar and does not change any of the links above.

STATE: stage=EXECUTED, next_actor=Validator, exec_version=1
