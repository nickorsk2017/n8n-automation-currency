# PLAN — 2026-08-19-recover-deleted-workflows-dir

## v1

### Recovery sources, in order of authority
1. `git show HEAD:workflows/<file>` — restores the committed baseline of all three
   files without touching the index (a stale `.git/index.lock` from 2026-08-18 made
   `git checkout` unusable; writing files directly avoids needing the lock at all).
2. The loader's post-2026-08-19 state is reproduced by re-running the same
   transformation that produced it: the change was a deterministic patch over the
   committed file, so re-applying it yields the same result rather than a
   reconstruction.
3. The agent's lost diff is enumerated by its own task's `EXEC.md`
   (2026-08-18-agent-base-currency-not-hardcoded): `jsCode`, `notes`, the node id
   `4541ac32-...`, and `systemMessage`. That artifact is why the loss is recoverable —
   the harness recorded what changed, including the node id and a sha256 of each field.
4. `systemMessage` is not quoted verbatim anywhere in the repository, but
   `docs/workflows/chat-agent/README.md` carries it wrapped for the page. Unwrapping is
   validated before it is trusted: unwrap the whole block and diff it against HEAD's
   value — rules 2-5 (unchanged by that task) must come back byte-identical. They do,
   so the same unwrap of rule 1 is sound, and the result is confirmed against the
   sha256 in EXEC.md.

### Not used
The live Cloud workflows hold the same content, but exporting from them would
reintroduce instance bookkeeping (ids, positions, cached names) that the repository
files deliberately do not carry. Every value here has a repository-side source.

### Residual risk
Anything changed in the working tree that neither git, a task artifact, nor a checksum
records cannot be recovered and would be invisible. The agent file's diff size before
the loss (4/4) and after recovery (4/4) is the check that nothing of that kind is
outstanding for that file; the loader's is covered by re-running its own patch.
