# VALIDATION — 2026-08-19-makefile-var-guards-and-activation-echo

## v1
result: PASS
- A1 PASS — all three targets exit 2 naming the missing variable; the directory md5
  taken before and after the three bare runs is identical, so nothing was created,
  copied, moved or deleted.
- A2 PASS — with both variables supplied, `drift` reaches `export_workflow.sh` and
  fails only on the absent container; behaviour past the guard is unchanged.
- A3 PASS (partial) — both echo lines are in place and the script parses; the success
  line itself is confirmable only on a running stand, at the operator's next
  `make import`.
- A4 PASS — `TODO.md` removed; no file in the repository references it.
- PLAN v2 PASS — the `drift` recipe no longer continues past a failed step and no
  longer relocates a repository file into a directory it will delete. This closes the
  standing issue recorded by 2026-08-19-recover-deleted-workflows-dir.
