# TASK — 2026-08-09-notion-mirror-link
owner: Engineer
immutable: true

## Requirements
- R1: Record that the Notion `N8N Workflows` section now exists as a mirror of
  `docs/`, and link it from README so a reader can reach it. README currently
  refers to the mirror without saying where it is.
- R2: The link must point at the section root, not at individual pages, so the
  README does not need editing every time a page is added.

## Acceptance
- A1: README contains a working URL to the Notion `N8N Workflows` page.
- A2: The Notion section contains the mirrored documentation pages plus the two
  placeholder sections, and nothing outside that section was created or
  modified.

## Constraints
- One file touched (README.md) -> LOW.
- Notion content itself is not a repository artifact; this task records it and
  adds the reference.
