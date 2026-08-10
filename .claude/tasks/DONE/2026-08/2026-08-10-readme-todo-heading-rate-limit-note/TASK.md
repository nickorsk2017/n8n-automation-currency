# TASK — 2026-08-10-readme-todo-heading-rate-limit-note
owner: Engineer
immutable: true

## Requirements
- R1: Rename the root `README.md` section currently titled
  `## Trade-offs and ToDo` so its heading echoes the submission brief's own
  wording ("Any trade-offs or things you'd improve with more time") instead
  of the generic "ToDo". New heading:
  `## Trade-offs and Things I'd Improve With More Time`.
- R2: Update the existing rate-limiting bullet in that section to record
  that IP/address-based rate limiting was specifically investigated for the
  chat agent on self-hosted n8n Community edition and found not to be a
  workflow-level capability there (no built-in node/trigger option to key a
  limit off request IP or address on Community edition) — this is why it is
  listed as infrastructure-level future work (reverse proxy/CDN) rather than
  something implemented in the workflow itself.

## Acceptance
- A1: `README.md` no longer contains the heading `## Trade-offs and ToDo`;
  it contains `## Trade-offs and Things I'd Improve With More Time` in the
  same position, same list content otherwise unchanged.
- A2: The rate-limiting bullet explicitly states that IP-based rate limiting
  was checked and is not available at the workflow level on self-hosted
  Community edition, distinguishing "not available here" from "not built
  yet".
- A3: No other section, wording, or file is touched.

## Constraints
- One file (`README.md`) -> LOW.
