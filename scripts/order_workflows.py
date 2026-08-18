#!/usr/bin/env python3
"""Compute a dependency-safe activation order for workflows/*.json.

n8n refuses to publish (activate) a workflow that references a sub-workflow
which is not itself published yet (Execute Workflow / Tool Workflow nodes'
`workflowId.value`). `make import-all` used to activate files in whatever
order the shell glob produced (alphabetical), which breaks as soon as a
referencing workflow's filename sorts before the workflow it depends on.

This script builds a dependency graph purely from the JSON files on disk
(no n8n/API calls) and prints a topologically sorted list of filenames, one
per line, dependency-free files first. A workflow's own self-reference (e.g.
a `toolWorkflow` node calling back into the same workflow, used for
sub-workflow "tools") is not a real ordering constraint and is dropped.

A reference to a workflowId that doesn't match any file in workflows/ is not
treated as an error here — it produces no ordering edge, and the real n8n
error (if the reference is genuinely broken) will surface at activation time,
same as it does today for any other activation failure. A cycle among two or
more distinct files IS an error: n8n cannot publish a genuine mutual
dependency either, so it's reported rather than silently worked around.

Usage:
  python3 scripts/order_workflows.py [workflows-dir]

Exit codes:
  0  success, order printed to stdout (one filename per line)
  1  cycle detected; cycle members printed to stderr
"""
import json
import sys
from pathlib import Path

REFERENCING_NODE_TYPES = {
    "n8n-nodes-base.executeWorkflow",
    "@n8n/n8n-nodes-langchain.toolWorkflow",
}


def load_workflows(workflows_dir: Path):
    """Return {filename: (own_id, set_of_referenced_ids)}."""
    result = {}
    for path in sorted(workflows_dir.glob("*.json")):
        if path.name == "n8n-credentials-import.json":
            continue
        data = json.loads(path.read_text())
        own_id = data.get("id")
        refs = set()
        for node in data.get("nodes", []):
            if node.get("type") not in REFERENCING_NODE_TYPES:
                continue
            workflow_id = (node.get("parameters", {}) or {}).get("workflowId", {})
            ref_id = workflow_id.get("value") if isinstance(workflow_id, dict) else None
            if ref_id and ref_id != own_id:
                refs.add(ref_id)
        result[path.name] = (own_id, refs)
    return result


def topo_sort(workflows):
    """workflows: {filename: (own_id, referenced_ids)} -> ordered [filename]."""
    id_to_file = {own_id: fname for fname, (own_id, _) in workflows.items() if own_id}
    # dependency edges expressed in filenames: file depends on dep_file
    deps = {}
    for fname, (_own_id, refs) in workflows.items():
        deps[fname] = {id_to_file[r] for r in refs if r in id_to_file}

    ordered = []
    visited = set()   # fully placed
    visiting = set()   # on current DFS stack

    def visit(fname, stack):
        if fname in visited:
            return
        if fname in visiting:
            cycle = stack[stack.index(fname):] + [fname]
            raise ValueError(" -> ".join(cycle))
        visiting.add(fname)
        for dep in sorted(deps[fname]):
            visit(dep, stack + [fname])
        visiting.discard(fname)
        visited.add(fname)
        ordered.append(fname)

    for fname in sorted(workflows):
        visit(fname, [])

    return ordered


def main():
    workflows_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("workflows")
    workflows = load_workflows(workflows_dir)
    try:
        ordered = topo_sort(workflows)
    except ValueError as exc:
        print(f"Error: cycle detected among workflow files: {exc}", file=sys.stderr)
        return 1
    for fname in ordered:
        print(fname)
    return 0


if __name__ == "__main__":
    sys.exit(main())
