# TASK — 2026-08-10-workflow-evals-claude-only
owner: Engineer
immutable: true

## Requirements
- R1: Document that workflow evaluations for the AI chat currency agent
  (`ai-chat-currency-agent.json`) are currently only supported against a
  Claude-backed model — no other LLM provider is a supported evaluation
  target yet. Determine the right place for this to live (docs vs.
  README) per the `docs/` rules in the root CLAUDE.md, and record the
  constraint there.
- R2: Confirm whether this is purely a documentation note or whether it
  also implies a concrete follow-up (e.g. an eval script/workflow that
  should exist and currently only runs against Claude). Scope the
  Planner step accordingly.

## Acceptance
- A1: The Claude-only evaluation constraint is documented in exactly one
  place, linked from elsewhere per the linking rules, in English.
- A2: No other repository content (workflow JSON, other docs) is changed
  beyond what R1/R2 require.

## Constraints
- English only in all persisted files (root CLAUDE.md language rule).
- Follow the `docs/` placement rules — no task/requirement ids in docs/.
