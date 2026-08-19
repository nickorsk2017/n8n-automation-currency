# EXEC — 2026-08-19-recover-deleted-workflows-dir

## v1
1. Recreated `workflows/` and wrote all four tracked entries from `HEAD` via
   `git show`, bypassing the stale `.git/index.lock`. (R1)
2. Re-applied the loader patch from 2026-08-19-loader-base-currency-from-config.
   Verified: no `Set - Loader Config`, no `USD` literal, 13 nodes, no dangling or
   unreachable node in the connection graph. (R2, A1)
3. Restored the agent's `Code - Compute Conversion` `jsCode` and `notes`, and its node
   id `4541ac32-2e0c-46ef-b7b0-c04db3dd5858` per the 2026-08-18 EXEC.md. (R2)
4. Reconstructed `systemMessage` by unwrapping the prompt block in
   `docs/workflows/chat-agent/README.md`. Round-trip check first: unwrapping reproduced
   HEAD byte-for-byte on every line except rule 1, the only line that task changed.
   Result hashes to `c9cf922956ebd9d442906134796103760dad107ca734bb9fae08c7620788a292`
   — the value recorded in that task's EXEC.md. (R3)
5. Agent diff against HEAD is 4 insertions / 4 deletions, the same as the
   `git diff --stat` taken earlier today before the loss. (A2)

`.git/index.lock` (empty, dated 2026-08-18) was left in place — untouched, since no
operation needed it.

### Not recovered
Nothing identified. The two affected files are accounted for by their own tasks'
artifacts; `error-logger.json` was unmodified and came back from HEAD exactly.
