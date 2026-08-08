# EXEC — 2026-08-08-gitignore

## v1
Changed files:
- .gitignore (new)

Four commented sections mapping 1:1 to R1/R2/R4, plus an explicit
"deliverables NOT ignored" comment block documenting R3 so a future edit
does not blanket-ignore `workflows/` or `.claude/tasks/`.
`!.env.example` negation kept so a committed template stays possible.

STATE: stage=EXECUTED, next_actor=Validator, exec_version=1
