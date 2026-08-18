# EXEC — 2026-08-17-sync-stop-and-error-to-cloud

## v1
Applied via n8n MCP `update_workflow` on live workflow `bLflLYfGzORWkjJV`:
- addNode: `Stop And Error - Invalid Input` (n8n-nodes-base.stopAndError v1),
  same id/params/notes as repo JSON.
- addConnection: `NoOp - Log Tool Error` -> `Stop And Error - Invalid Input`
  (main, index 0).
- updateNodeParameters: refreshed `NoOp - Log Tool Error` notes to mention
  the handoff, matching repo JSON.
3/3 operations applied (nodeCount 13 -> 14). One pre-existing, unrelated
validation warning surfaced on `OpenAI Chat Model - GPT` (`builtInTools`
field) -- not touched by this task, not introduced by it.

Draft update alone was insufficient: `get_workflow_details` showed the new
content only under the top-level `nodes`/`connections` (draft), while
`activeVersion` (what the running chat trigger and tool sub-workflow calls
actually execute) still had the old graph. Ran `publish_workflow` on
`bLflLYfGzORWkjJV` to promote the draft to active
(new activeVersionId: dadfa764-32a7-4466-bfe0-3c312985904a).
