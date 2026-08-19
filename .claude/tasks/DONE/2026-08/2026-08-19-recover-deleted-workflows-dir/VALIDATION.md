# VALIDATION — 2026-08-19-recover-deleted-workflows-dir

## v1
result: PASS
- A1 PASS — three files present; loader clean of the removed node and the literal;
  graph re-derived with no dangling or unreachable node.
- A2 PASS — agent diff 4/4 against HEAD, matching the pre-loss measurement;
  `systemMessage` sha256 equals the value recorded on 2026-08-18. The reconstruction
  is verified against a checksum written before the loss, not asserted.
- A3 PASS — `ci_check.py` clean.
- R4 PASS — the recovery wrote only inside `workflows/`.

### Standing issue
The cause is unfixed at the time of this validation: guarded targets are the open task
2026-08-19-makefile-var-guards-and-activation-echo. Until it closes, `make drift` and
`make export` remain able to do this again. The incident also corrects that task's
premise — the earlier claim that `cp` refusing a directory stopped the chain was wrong:
`cp` failed, the recipe continued, and the following `mv` destroyed the directory.
