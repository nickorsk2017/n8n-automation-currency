# PLAN — 2026-08-09-readme-workflow-folder-links

## v1

### Why the directory is the right link target
A link to `docs/workflows/rate-loader/data-table-schema.md` binds the linking
file to the *contents* of that directory. Add a page, rename one, split one in
two, and every file that linked into it needs editing — and the ones that are
missed become the broken links the previous tasks kept having to repair. A link
to `docs/workflows/rate-loader/` binds only to the workflow's existence, which is
the stable fact.

This is the same reasoning that put the Notion link at the section root rather
than at individual pages: link to the thing that will still be there.

### Consequence for the brief, stated rather than glossed
The schema rationale and the system prompt are now two clicks from the README
instead of one. The brief asks for both to be in the README; they have been one
click away since the previous task and are now behind a directory whose main page
lists what is in it. That is a real, if small, cost of the convention, and the
mitigation is that each README link names what the reader will find in that
directory — "schedule, flow, failure behaviour, and the data table it writes" —
so the words a reviewer scans for still appear.

### Uniformity (R3)
Three files link into workflow documentation: `README.md`, `docs/README.md` and
`docs/architecture.md`. All three move to the directory form. Applying the rule
only where it was pointed at would leave two files as counter-examples, and a
convention with visible exceptions is not one.

### CLAUDE.md
Added to the existing README-scope bullet rather than as a new rule, because it
is the same idea continued: the README links to workflow documentation, and it
links to the directory so that the contents can change without touching it.

### Verification
The link checker already resolves directories via `os.path.exists`, so no change
is needed to it. Assert additionally that no file outside a workflow's own
directory links to a `.md` file inside one.

STATE: stage=PLANNED, next_actor=Executor, plan_version=1
