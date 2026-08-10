# TASK — 2026-08-09-attach-openai-credential-wf2
owner: Engineer
immutable: true

## Requirements
- R1: Engineer confirmed a managed OpenAI credential already exists in the
  n8n project ("n8n free OpenAI API credits", type openAiApi, id
  kpxxTKpEgoMAKTNT, managed/read-only). Attach it to the "OpenAI Chat Model -
  GPT" node in workflow bLflLYfGzORWkjJV (workflows/2-ai-chat-currency-agent.json),
  resolving the A2 gap noted in the prior task's VALIDATION.md (no
  credential reference was attached at build time because no OpenAI
  credential existed then).
- R2: Re-export the updated workflow JSON to
  workflows/2-ai-chat-currency-agent.json per Export discipline (root
  CLAUDE.md) so the credential id/name reference is reflected in the repo
  file, matching the pattern already used for the freecurrencyapi credential
  in workflow 1.
- R3: Now that a working credential exists, run one real end-to-end live
  chat execution (natural language in, agent calling convert_currency,
  reply out) to close the A9/A5 live-chat gap flagged as non-blocking in the
  prior VALIDATION.md, and record the evidence in EXEC.md.

## Acceptance
- A1: workflows/2-ai-chat-currency-agent.json's "OpenAI Chat Model - GPT"
  node has a credentials.openAiApi block referencing id kpxxTKpEgoMAKTNT /
  name "n8n free OpenAI API credits" (id present is fine here since this is
  a managed, non-secret-bearing reference -- consistent with workflow 1's
  freecurrencyapi credential reference, which also includes both id and
  name).
- A2: A real chat execution against the live workflow demonstrates the
  agent calling convert_currency and returning a natural-language answer,
  recorded in EXEC.md.

## Constraints
- Single file touched (workflows/2-ai-chat-currency-agent.json); no schema
  change, no new dependency. Does not reopen or modify the prior task's
  artifacts (VALIDATED/DONE and immutable) -- this is a new, small follow-up
  task per the harness's "no exceptions" rule.
