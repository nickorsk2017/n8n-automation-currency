# TASK — 2026-08-19-recover-deleted-workflows-dir
owner: Engineer
immutable: true

## Context
`make drift` run without `ID` / `FILE` expanded `mv workflows/$(FILE) $tmp/instance.json`
to `mv workflows/ $tmp/instance.json`, moving the whole directory into the recipe's
temporary directory, which the recipe then deleted with `rm -rf`. `workflows/` and all
three workflow files were gone, including uncommitted work from two closed tasks.

## Requirements
- R1: `workflows/` is restored with all three workflow files.
- R2: The uncommitted state at the moment of deletion is restored, not merely the last
  commit: the loader's config-table rewiring (2026-08-19) and the agent's derived base
  currency (2026-08-18) must be present.
- R3: Every restored value is evidenced — from git, from a recorded artifact, or from a
  checksum recorded before the loss — not from recollection.
- R4: Nothing outside `workflows/` is changed by the recovery.

## Acceptance
- A1: The three files exist; the loader has no `Set - Loader Config` and no `USD`
  literal; its graph has no dangling or unreachable node.
- A2: The agent's diff against HEAD is the same size it was immediately before the
  deletion (4 insertions, 4 deletions), and its `systemMessage` matches the sha256
  recorded in the 2026-08-18 task's EXEC.md.
- A3: `ci_check.py` clean.

## Constraints
- Complexity set to MEDIUM, not HIGH: no design decision is being made. The target
  state is already specified by two closed tasks; this restores it.
- Recovery was performed immediately on discovery, ahead of writing these artifacts.
  Recorded here rather than presented as normal routing.
