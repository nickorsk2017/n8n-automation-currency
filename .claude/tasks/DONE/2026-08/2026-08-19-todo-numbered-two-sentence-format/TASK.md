# TASK — 2026-08-19-todo-numbered-two-sentence-format
owner: Engineer
immutable: true

## Requirements
- R1: `TODO.md` is a numbered list. Each item is exactly two sentences: what is
  wrong, and what it costs. English, per the repository language rule.
- R2: The existing entry (unguarded `drift` / `import` variables) is carried over
  into that format; nothing is added or dropped.

## Acceptance
- A1: `TODO.md` contains a numbered list, its item is two sentences, and the
  problem is still identifiable without reading chat history.
- A2: No other repository file changes.

## Constraints
- The file records problems; fixes remain separate tasks.
