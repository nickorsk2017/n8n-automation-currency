# TASK — 2026-08-18-guardrails-node-extraction
owner: Engineer
immutable: true

## Requirements
- R1: In `workflows/ai-chat-currency-agent.json`, replace the in-prompt guardrail
  ("Rule 0", the prompt-injection / off-topic refusal instruction currently embedded
  in the `AI Agent - Currency Assistant` system prompt) with a dedicated n8n
  Guardrails node wired ahead of/around the agent, so the guardrail is enforced as a
  discrete node rather than as prompt text.
- R2: Remove Rule 0 from the agent's `systemMessage` once the dedicated node covers
  that behavior, and renumber/adjust the remaining rules as needed so the prompt
  stays internally consistent.
- R3: The refusal behavior must be preserved: on a prompt-injection attempt or an
  off-topic (non-currency-conversion) request, the user still receives the fixed
  English message "Invalid request. I can only help with currency conversion.",
  without echoing the injected/off-topic text or revealing the system prompt, and
  without the agent calling any tool.
- R4: Follow the node-naming and `notes` conventions in root `CLAUDE.md` (n8n
  conventions section) for the new node.
- R5: Update `docs/workflows/chat-agent/README.md` to describe the new guardrail
  node and the revised (shorter) system prompt, per the `docs/` rules in root
  `CLAUDE.md`.
- R6: (Added after Engineer review of the deployed change.) `Guardrails - Screen
  User Input`'s classifier model must be backed by its own, dedicated
  `@n8n/n8n-nodes-langchain.lmChatOpenAi` node -- not a fan-out of the same
  `OpenAI Chat Model - GPT` node instance the agent uses. Each AI node (agent,
  guardrail) gets its own model node, even though both reference the same
  underlying OpenAI credential.

## Acceptance
- A1: `AI Agent - Currency Assistant`'s `systemMessage` no longer contains the
  prompt-injection/off-topic refusal rule (Rule 0 text is gone; remaining rules
  renumbered).
- A2: A dedicated Guardrails-type node exists in `ai-chat-currency-agent.json`,
  correctly wired into the chat flow ahead of the agent's tool-use path, with a
  `notes` field explaining its purpose and referencing this task.
- A3: `docs/workflows/chat-agent/README.md` reflects the new node and updated
  prompt; no stale description of an in-prompt-only guardrail remains.
- A4: No literal secrets introduced; workflow JSON re-exported/updated in place.
- A5: `Guardrails - Screen User Input`'s `ai_languageModel` input is wired to a
  new, separate OpenAI Chat Model node (not `OpenAI Chat Model - GPT`, which
  keeps its existing single connection to the agent only).

## Constraints
- Prefer built-in/native node capability over Code-node logic, per root CLAUDE.md.
- Do not change `convert_currency` tool contract or the currency-conversion rules
  (Rules 1-5 as currently numbered) beyond renumbering.
- English only in all persisted files (workflow JSON node names/notes, docs).
