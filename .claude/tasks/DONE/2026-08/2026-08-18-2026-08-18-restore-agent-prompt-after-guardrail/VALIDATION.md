# VALIDATION — 2026-08-18-restore-agent-prompt-after-guardrail
## v1
result: PASS
validation_version: 1

- R1 — MET. The agent receives the message on the chat path; the Engineer's run
  shows it parsing "100 USD -> EURO" and calling `convert_currency` with
  `{amount: 100, from_currency: "USD", to_currency: "EUR"}`. `No prompt
  specified` is gone.
- R2 — MET, and better evidenced than PLAN v1 expected. The plan flagged
  `$json.chatInput` on the evaluation path as an inference from the fact that
  `promptType: "auto"` used to work there. Direct confirmation now exists:
  `chat_agent_eval_dataset` has a column literally named `chatInput`.
- R3 — MET. The guardrail still screens first; the fix is an expression on the
  agent, and no path bypasses the Pass/Fail routing.
- R4 — MET. Cloud first, then export, then Docker.
- A1 — MET.
- A3 — MET.

### Non-blocking observation
- N1 (test-coverage, low): A2 — the evaluation dataset run itself was not
  executed. The column name is confirmed, so the first branch of the expression
  is known to be correct, but the run was not performed. Distinguishing the two
  matters here: this task exists because a structural argument was once accepted
  in place of a run.
