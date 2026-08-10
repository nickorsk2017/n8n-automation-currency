# PLAN — 2026-08-09-readme-scope

## v1

### The rule being applied
Material specific to one workflow lives in that workflow's directory. The
previous task established this for `docs/`; the README had been left carrying
two sections that violate it in the same way, because they were written before
`docs/workflows/` existed and were never revisited when it did.

Both sections are also duplicates in the strict sense: everything the README
says about the schema and the prompt is said more fully in the linked pages.
Duplication in documentation is not redundancy that costs nothing — it is two
places to update, one of which will be forgotten, and the reader has no way to
tell which one is current.

### The constraint pulling the other way
The test brief asks the README to contain the schema design rationale and the
agent system prompt. Deleting both sections outright would satisfy the structural
rule and fail the brief.

Resolution: the README keeps a pointer that names what the reader will find and
where, rather than a section that restates it. A reviewer following the brief's
checklist can still start at the README and reach both in one click, and there is
still exactly one authoritative copy of each. This is what R3 is for — the
sections are replaced, not removed.

### Where the pointers go
Not scattered. The README already has a `## Documentation` section at the end,
which is where a reader looks for "where is the detail". Both pointers go there,
named explicitly — "the data table schema and why it is shaped that way", "the
full agent system prompt" — so the words a reviewer is scanning for still appear
in the README even though the content does not.

### What survives in README
What the system is, the layer model, setup, trade-offs, documentation pointers.
Every one of those is either about the system as a whole or about the submission
itself; none is specific to a single workflow. That is the line the rule draws.

### CLAUDE.md (R4)
One rule added to the `docs/` section: the README is the entry point and states
what the system is, how to set it up and its trade-offs; anything specific to one
workflow lives under `docs/workflows/<name>/` and the README links to it. Placed
with the other documentation rules rather than in Repository layout, because it
is a constraint on writing rather than a description of the tree.

### Verification
Assert both headings are gone, both links present and resolving, and re-run the
recursive link check across README, CLAUDE.md and `docs/**`. Confirm before
deleting that the schema page carries the key rationale and the agent page
carries the full prompt, so A3 is checked rather than assumed.

STATE: stage=PLANNED, next_actor=Executor, plan_version=1
