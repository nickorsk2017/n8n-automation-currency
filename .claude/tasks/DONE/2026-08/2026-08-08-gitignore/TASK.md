# TASK — 2026-08-08-gitignore
owner: Engineer
immutable: true

## Context
The repository has no `.gitignore`. macOS `.DS_Store` files are already
present at the repo root and inside `.claude/`, and would be committed.
The project will also accumulate local secrets (API keys for
freecurrencyapi and the LLM provider) and screenshot/export scratch files.

## Requirements
- R1: Ignore macOS/editor junk: `.DS_Store`, `Thumbs.db`, `.idea/`,
  `.vscode/`, swap files.
- R2: Ignore local secret material: `.env`, `.env.*`, `*.key`, and any
  credential export from n8n.
- R3: Do NOT ignore harness artifacts (`.claude/tasks/**`) or deliverables
  (`workflows/`, `docs/`, `screenshots/`) — these are the reviewed output.
- R4: Ignore Python cache produced by `.claude/runner.py` and
  `.claude/scripts/ci_check.py` (`__pycache__/`, `*.pyc`).

## Acceptance
- A1: `.gitignore` exists at repo root.
- A2: Every pattern is grouped under a commented section explaining why.
- A3: No pattern matches `workflows/`, `docs/`, `screenshots/`, or
  `.claude/tasks/`.

## Constraints
- English only.
- Single file touched (LOW complexity).
