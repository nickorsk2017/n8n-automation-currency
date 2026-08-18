# VALIDATION — 2026-08-18-diagnosable-agent-errors
## v1
result: PASS
validation_version: 1

- R1/R2 — MET. Both loggers serialise the item when no known error field is
  present.
- R3 — MET. `builtInTools` absent from both model nodes.
- R4 — MET. `responsesApiEnabled` was not introduced.
- A1 — MET. `update_workflow` returns `validationWarnings: []`.
- A2 — MET, and consequentially so. Docker row 5 read
  `AI Agent failed; raw item: {"guardrailsInput":"100 USD →EURO","checks":[...],
  "error":"No prompt specified"} [execution 9]`. That serialised item is what
  identified the root cause of the chat failure; the three preceding rows, using
  the old fallback, had said only that something failed. The change paid for
  itself on its first occurrence.

### Note
EXEC v1 withdrew the `builtInTools` hypothesis before implementing, on the
Engineer's own evidence that the guardrail model node carried the same field and
succeeded. That was correct: the cause was unrelated. Removing the field remains
justified on its own terms, and the audit trail does not claim it as the fix.
