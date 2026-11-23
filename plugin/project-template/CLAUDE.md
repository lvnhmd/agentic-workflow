# CLAUDE.md — {{PROJECT_NAME}}

This is the project half of the agent contract: what's specific to {{PROJECT_NAME}}. The shared half
(ticket lifecycle, docs-sync rule, TDD, absolute rules) is loaded into every session by the
**agentic-workflow** Claude Code plugin, enabled for this repo in `.claude/settings.json`. Project
settings (tracker, CI, formatters, app URL) are in `.claude/workflow.env`.

## Project Overview

<!-- What the product is, who uses it, the main flows, and the stack. Five to ten lines. -->

## Repo Map

```
<!-- top-level directories and what lives in each, e.g.
src/            — application code
tests/          — integration and e2e tests
docs/           — architecture, ADRs, development standards, runbooks
scripts/agentic — verify.sh, check-adr-sync.sh (used by git hooks and CI) — managed by the kit
-->
```

## Read First

Open the files for every area a task touches before changing anything. Don't rely on what you think the code does.

| Area                         | Files to read                                                          |
| ---------------------------- | ---------------------------------------------------------------------- |
| Always                       | `CLAUDE.md`, `CONTRIBUTING.md`                                         |
| Architecture / design        | `docs/architecture/` (current state) — see ADR reading policy          |
| Security-sensitive changes   | `docs/architecture/attack-surface.md`                                  |
| Engineering patterns         | `docs/development/engineering-standards.md`                            |
| Quality / testing            | `docs/development/quality-strategy.md`                                 |
| Feature work                 | The ticket (`aw-tracker get <key>`) and its comments                   |
| <!-- add rows: frontend conventions, API patterns, i18n, infra... --> |                                                     |

A task that crosses areas means reading each area's files. Unsure whether a file matters? Read it.

## Project Rules

Additions to the absolute rules in the workflow contract. Same weight: non-negotiable.

<!-- PROJECT: add your own, e.g. "No `any` in TypeScript", "All UI strings go through i18n",
     "Never hand-edit generated content". -->

## Commands for Validation

```bash
scripts/agentic/verify.sh          # full suite, same as CI — before every PR
scripts/agentic/verify.sh --fast   # what pre-push runs
scripts/agentic/verify.sh --list   # show the configured steps
# <!-- add your individual commands: dev server, unit tests, e2e, a11y, security scans -->
```

## Quality Standards

<!-- Coverage floor (e.g. >70%), WCAG level, OWASP scanning, API contract validation, mutation testing,
     design checks against Figma. Keep it to what CI actually enforces. -->

## Data Boundaries

<!-- Who may see what (tenancy, roles), where PII lives, what must never leave its boundary. -->
