# TASK — 2026-08-08-rename-llm-env-var
owner: Engineer
immutable: true

## Requirements
- R1: Rename the LLM API key variable in `.env.example` from `LLM_API_KEY`
  to `LLM_OPENAI_KEY`, keeping its explanatory comment.

## Acceptance
- A1: `.env.example` no longer contains `LLM_API_KEY`.
- A2: `.env.example` contains `LLM_OPENAI_KEY=your_llm_provider_key_here`
  with its comment intact.
- A3: No other file changed.

## Constraints
- Single file, no new deps -> LOW complexity.
- English only.
