# TASK — 2026-08-08-import-workflow-json-docker-n8n
owner: Engineer
immutable: true

## Requirements
- R1: Provide a repeatable command (script or Make target) that imports a workflow
  JSON file from `workflows/` into a running Docker n8n container, using the n8n
  CLI (`n8n import:workflow`) via `docker exec` / `docker cp`.
- R2: Document the command's usage in the appropriate docs location (or README),
  including required arguments (container name, source file, target workflow file
  path) and any prerequisites (container must be running, n8n CLI available).
- R3: The command must not embed or require any secret value (API keys, credentials)
  as a literal in the script or its output, consistent with the "secrets never live
  in workflow JSON" convention.

## Acceptance
- A1: Running the new command against a local Docker n8n instance with a file from
  `workflows/` successfully imports the workflow (verified via n8n UI or `n8n
  export:workflow` round-trip).
- A2: Usage documentation exists and describes the command, its arguments, and
  prerequisites.
- A3: No secret values appear in the script, its output, or the documentation.

## Constraints
- Follow existing repository conventions in CLAUDE.md (root) for n8n tooling: prefer
  built-in n8n CLI capabilities over custom logic; keep scripts under an appropriate
  existing directory (e.g. `.claude/scripts/` or a project scripts location — Planner
  to decide placement).
- Must integrate with the existing Docker setup already provisioned in prior tasks
  (see DONE tasks: n8n-docker-compose, mount-workflows-volume) rather than
  introducing a new Docker setup.
