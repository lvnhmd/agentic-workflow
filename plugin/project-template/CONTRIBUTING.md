# Contributing to {{PROJECT_NAME}}

## Branching

- `{{DEFAULT_BRANCH}}` is always deployable. It is protected and only changes through PRs with passing checks.
- Branch names: `<ticket-key>-<short-description>` for features and fixes, e.g. `{{BRANCH_EXAMPLE}}`.
- `chore/<short-description>` for maintenance that needs no ticket (dependency bumps, test upkeep, config).
- No direct commits to protected branches. The pre-commit hook enforces this.

## Commit messages

`<TICKET-KEY>: <type>: <short description>` where type is `feat`, `fix`, `refactor`, `test`, `docs` or `chore`,
e.g. `{{COMMIT_EXAMPLE}}`. Chore branches use `chore: <description>`.

## Definition of Done

### A PR is ready to merge when

- [ ] `scripts/agentic/verify.sh` passes locally and CI is green
- [ ] Tests were added or updated for the change; coverage did not drop
- [ ] The PR template is complete: ticket, summary, test evidence, risk, rollback
- [ ] Docs are updated if behaviour, a pattern, an endpoint or config changed
- [ ] Required reviewers (CODEOWNERS) approved
- [ ] No secrets, credentials or `.env` files are committed

### A ticket is done when

- [ ] Its PR merged with all of the above
- [ ] The change is deployed to the first shared environment and shows no regressions <!-- adjust -->

## PR size

Aim for under 400 lines of meaningful change. Split bigger work into stacked PRs, and say why in the
description when a PR has to be large.

## Tests

<!-- Where unit, integration and e2e tests live in this repo, and which standards they test against
     (axe-core for WCAG, OWASP checks, contract tests). -->

## Architecture Decision Records

Decision records are kept in `docs/adr/`. Once one is **accepted, its body never changes**.

1. Never edit an accepted ADR's body. The record captures the reasoning at a point in time.
2. The only permitted edit is the status line, plus a pointer:
   `> **Superseded by [ADR-XXXX](ADR-XXXX-<slug>.md)** — <one-line reason>`
3. Every changed decision gets a new ADR that links back to the one it supersedes (`Supersedes:` line).
4. Name files `ADR-NNNN-<short-slug>.md` with the next free number. Start from `docs/adr/TEMPLATE.md`.
5. Status lifecycle: `Proposed` → `Accepted` → `Superseded by ADR-XXXX`.
6. If the ADR changes current behaviour, update `docs/architecture/` in the same PR (CI checks this).

## Running CI locally

```bash
scripts/agentic/verify.sh
```
