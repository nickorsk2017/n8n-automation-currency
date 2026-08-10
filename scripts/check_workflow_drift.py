#!/usr/bin/env python3
"""Report whether a workflow file in workflows/ still matches the instance.

This is the deterministic, no-LLM member of the audit layer: an editor change
that was never re-exported is a silent divergence between what reviewers read
(workflows/*.json) and what actually runs. Root CLAUDE.md already requires the
two to agree; this makes the requirement checkable by running a command.

Usage:
    scripts/check_workflow_drift.py <repo-file> <instance-file>

Both arguments are workflow JSON. `instance-file` is whatever was just pulled
from the instance — by scripts/export_workflow.sh for the Docker stand, or
written out from the n8n MCP for the Cloud stand. Keeping the fetch out of this
script is what lets one comparison serve both stands.

Exit codes:
    0  in sync
    1  drifted (differences printed)
    2  usage or parse error

Comparison is semantic, not byte-for-byte. n8n rewrites volatile bookkeeping
fields on every save; a hash comparison would report drift on every run and be
ignored within a week, which is the standard way a check like this dies.
"""
import json
import sys

# Rewritten by n8n on save, carry no reviewable meaning.
VOLATILE_TOP_LEVEL = {
    "versionId",
    "activeVersionId",
    "updatedAt",
    "createdAt",
    "triggerCount",
    "shared",
    "tags",
    "meta",
    "pinData",
    "staticData",
    "isArchived",
    "scopes",
}
# Per-node: position is canvas cosmetics, and n8n reassigns node ids on import.
VOLATILE_NODE = {"position", "id"}


def normalise(doc):
    """Reduce a workflow to the parts a reviewer would call its content."""
    if isinstance(doc, list):
        if len(doc) != 1:
            raise ValueError(f"expected exactly one workflow, got {len(doc)}")
        doc = doc[0]

    nodes = {}
    for node in doc.get("nodes", []):
        nodes[node["name"]] = {
            k: v for k, v in sorted(node.items()) if k not in VOLATILE_NODE
        }

    return {
        "name": doc.get("name"),
        "id": doc.get("id"),
        "settings": doc.get("settings", {}),
        "connections": doc.get("connections", {}),
        "nodes": nodes,
    }


def differences(repo, live):
    """Yield human-readable difference lines, most structural first."""
    for field in ("id", "name"):
        if repo[field] != live[field]:
            yield f"{field}: repo={repo[field]!r} instance={live[field]!r}"

    if repo["settings"] != live["settings"]:
        yield f"settings: repo={repo['settings']} instance={live['settings']}"

    repo_nodes, live_nodes = set(repo["nodes"]), set(live["nodes"])
    for name in sorted(repo_nodes - live_nodes):
        yield f"node only in repo file: {name}"
    for name in sorted(live_nodes - repo_nodes):
        yield f"node only on instance: {name}"

    for name in sorted(repo_nodes & live_nodes):
        r, l = repo["nodes"][name], live["nodes"][name]
        for key in sorted(set(r) | set(l)):
            if r.get(key) != l.get(key):
                yield f"node '{name}' differs in {key}"

    if repo["connections"] != live["connections"]:
        yield "connections differ"


def main():
    if len(sys.argv) != 3:
        print(__doc__.strip(), file=sys.stderr)
        return 2

    try:
        with open(sys.argv[1], encoding="utf-8") as fh:
            repo = normalise(json.load(fh))
        with open(sys.argv[2], encoding="utf-8") as fh:
            live = normalise(json.load(fh))
    except (OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    found = list(differences(repo, live))
    if not found:
        print(f"in sync: {sys.argv[1]} matches the instance")
        return 0

    print(f"DRIFT: {sys.argv[1]} does not match the instance")
    for line in found:
        print(f"  - {line}")
    print("\nRe-export the workflow (make export) to bring the repo back in sync.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
