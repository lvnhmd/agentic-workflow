---
name: workflow-contract
description: The shared agentic-workflow contract — ticket lifecycle and its commands, docs-lead-code-follows rule, ADR policy, PROGRESS.md scratchpad, TDD, delegation, absolute rules, must/never lists. Load it before any ticket, code-change, PR, review or QA work in a repository that has .claude/workflow.env. Every lifecycle command loads it first.
---

# Workflow Contract

> The shared half of the agent contract, provided by the agentic-workflow plugin. Project-specific context
> and rules live in the repo's `CLAUDE.md`; project settings live in `.claude/workflow.env`.
>
> Trust comes from the checks, not from reading every line: tests, standards, hooks and CI do the
> line-by-line work, so human review can sample. When a mistake gets through, add a check that would
> have caught it; don't ask people to look harder. The checks are many, cheap and independent
> ("Swiss cheese"), so what slips past one lands on the next.

## Workflow Loop

```
Ticket -> Refine -> Pick up -> Branch -> Test -> Code -> Gates -> PR -> Review -> Merge -> QA -> Trace back
```

| Stage           | Command                                 | What happens                                                                            |
| --------------- | --------------------------------------- | --------------------------------------------------------------------------------------- |
| Shape a ticket  | `/refine <ticket>`                      | Questions, ranked approaches, conclusions posted to the ticket                          |
| Start work      | `/pickup <ticket> [--stay] [--qa]`      | Assign, In Progress, read everything, branch, seed PROGRESS.md                          |
| Log ad-hoc work | `/capture`                              | Turn the current conversation into a ticket (+ commit)                                  |
| Ship            | `/push` or `/pr [--watch]`              | Full verify, commit, push, PR from the template, self-review, ticket to Review          |
| Untracked fix   | `/pr-chore`                             | Small tooling/config PR from a temporary worktree; current branch untouched             |
| Review others   | `/review <pr>`                          | Review against the standards below, then a formal GitHub verdict                        |
| Answer review   | `/pr-action-review <pr> [--watch]`      | Triage comments: auto-fix, discuss, or reply; re-request review; offer merge            |
| Red CI          | `/fix-ci`                               | Read failed job logs; rerun flakes, fix real failures minimally                         |
| QA bounce-back  | `/qa-review-action <ticket>`            | Classify QA points as bug / intended / out of scope; fix or push back with evidence     |
| Maintenance     | `/morning`                              | Default-branch health, `/nightly-check`, `/dependabot-review`                           |
| Housekeeping    | `/main`                                 | Back to the default branch, delete merged local branches safely                         |
| Setup           | `/init`, `/doctor`                      | Set a repo up for the workflow; check that everything it needs works                    |

- Work starts from a ticket. The tracker is the source of truth for acceptance criteria.
- All tracker access goes through `aw-tracker`, all CI access through `aw-ci` (both on PATH via the
  plugin). Never call the Jira, GitHub or CircleCI APIs ad hoc when a subcommand exists. Run either
  with `--help` for the subcommands.
- Verify your own work by running it: tests, then the app itself (the `run` skill + Playwright MCP).

## Configuration

`.claude/workflow.env` (committed, no secrets) holds the tracker, ticket prefix, CI provider, status
names, formatter commands, dev command and app URL. Developer secrets live in the git-ignored `.env`
(see `.env.workflow.example`). Read a value with `aw-config <KEY>`; never print `.env`. `/doctor` checks
the whole setup (tools, credentials, tracker statuses, CI access, hooks) when something seems off.

## ADR Reading Policy

Start with `docs/architecture/`. It describes the system as it is today, and it wins over anything
older. `docs/adr/` is an immutable decision log. Open a specific ADR only when the architecture
docs cite it, or when they are silent on something whose history you need. Don't read the whole ADR
folder as a matter of course; chains of partially superseded ADRs burn tokens that a one-line
current-state fact already answers.

This only works while the architecture docs stay in sync: an ADR that changes current-state behaviour
must update the matching `docs/architecture/*.md` file **in the same PR**. `check-adr-sync.sh` fails a
diff that touches `docs/adr/` without touching `docs/architecture/`. For ADRs with genuinely no
current-state impact (tooling, process), put `[skip-adr-sync: <reason>]` in a commit message on the branch.

## Docs Lead, Code Follows

**When the docs and the code disagree, the docs describe the intent and the code is what changes.**

1. **First**, read the docs for the area you're about to touch, and build to match them.
2. **Matching?** Carry on.
3. **Can't match them?** Stop and lay it out: what the docs say, what you'd change, and why. Ask
   before going further. The usual order is: change the docs, then the code. If the mismatch hints
   that the plan itself is wrong, say that too.
4. **Last**, in the same PR, update every doc the change makes untrue: patterns, endpoints, data
   flows, settings, behaviour.
5. Two docs that contradict each other, or one that's out of date, get raised with the user. Never
   pick a winner silently.

The Stop hook reminds you of this once per new set of changed files.

## PROGRESS.md — Session Scratchpad

> **Primary development agent only.** Secondary sessions opened for quick, unrelated tasks (ticket
> lookups, chores, one-off questions) must not write to PROGRESS.md.

Keep `PROGRESS.md` in the repo root while working a ticket: progress after each milestone, decisions
made, problems hit, open questions, direction changes. It is the progress record, a temporary home for
discoveries, and the recovery point when a session is interrupted.

- `/pickup` seeds it from the ticket. `/pr` reads it back to find docs to update, then deletes it.
- **It stays local.** The pre-commit hook refuses it if staged, and the pre-push hook checks every
  commit being pushed. Don't git-ignore it either: it should stay visible in `git status`.
- Plans end with a short list of unresolved questions.

## TDD Workflow (Red-Green-Refactor)

1. **RED**: write a failing test that states the expected behaviour (start from the acceptance criteria).
2. **GREEN**: write the minimum code to pass it.
3. **REFACTOR**: clean up with the tests green.

**Spike first, when you must**: if you don't yet know whether an approach works at all (a new library,
an undocumented API), get it working first. Then disable that code, write the tests that should fail
without it, and restore it piece by piece until they pass.

## Delegation

| Agent (`subagent_type`)          | Model | Use it for                                                                                    |
| -------------------------------- | ----- | --------------------------------------------------------------------------------------------- |
| `agentic-workflow:worker`        | haiku | Well-specified grunt work: bulk grep, mechanical edits, log trawling, gathering file contents |
| `agentic-workflow:advisor`       | opus  | A second opinion before a consequential call: design choice, risky refactor, being stuck      |
| `agentic-workflow:adversary`      | —     | Adversarial security probing of auth, tenant and data boundaries; leaves failing tests        |
| `agentic-workflow:tdd-critic`    | —     | Adversarial test review before a PR: tests that can't fail, loose assertions, gaps            |

Keep the main loop for decisions. Delegate deliberately, not every turn.

## Absolute Rules

Non-negotiable. No exceptions, no workarounds.

1. **Every feature or fix needs a ticket.** `chore/<short-description>` branches with a `chore:` commit
   prefix are exempt (dependency bumps, test maintenance, config housekeeping).
2. **Every change goes through a branch and a PR.** No commits to protected branches (hook-enforced).
3. **Never bypass hooks or gates.** No `--no-verify`, no skipped or weakened tests, no disabled lint
   rules, without the user's explicit approval for that specific case.
4. **Never ignore pre-existing errors.** Fix them or raise them; don't route around them.
5. **Schema changes travel with a migration.** Applied migrations are immutable.
6. **ADRs are immutable.** Only the status line of an accepted ADR may change
   (`Superseded by ADR-XXXX` plus a one-line pointer). New decision, new ADR.
7. **Check the assignee before updating a ticket.** If it belongs to someone else or nobody, stop and
   ask: "<key> belongs to <name>. Update it anyway?"
8. **Attribute every external write.** Every comment, reply, review or ticket update posted anywhere
   ends with the `ATTRIBUTION` line from `.claude/workflow.env` (`aw-tracker comment` adds it for you).
   Humans must always be able to tell what the agent wrote.
9. **No secrets in code, tests, logs or git.** Read credentials from the environment. If one is missing,
   the app fails with a clear error and tests throw with a clear message; mocks of the secret provider
   are the only place fixture secrets may appear.
10. **Merge = close.** When a PR merges, move its ticket on (Done or QA) immediately.

## What You MUST Always Do

- Read the context first (table above) and the ticket with its comments.
- Write the failing test first; every fix or feature ships with tests. Never reduce coverage.
- One concern per PR, ideally under ~400 changed lines. Refactor in small, behaviour-preserving steps.
- Run `scripts/agentic/verify.sh` (the full suite) before opening any PR.
- Follow the branch and commit conventions in `CONTRIBUTING.md`; include the ticket key.
- Fill the PR template fully: ticket, summary, test evidence, risk, rollback.
- Verify UI changes in the running app, against the design when one exists.
- Keep docs in sync in the same PR.
- Use structured logging with a correlation/trace ID across boundaries (for services).

## What You MUST Never Do

- Drift from the documented architecture, patterns or standards without saying so.
- Commit secrets, credentials or `.env` files, or print `.env` into the conversation.
- Force-push to a protected branch, or rewrite shared history.
- Edit an applied migration or the body of an accepted ADR.
- Start feature work without a ticket, or open a PR without running the full verification.
- Add, remove or change an API endpoint without updating its contract (OpenAPI/schema/examples).
- Read large generated or bulk-data files (seeds, fixtures dumps, lockfiles, build output) unless asked —
  they cost tokens and carry no design information. <!-- PROJECT: list the paths -->

## PR Reviews

Whenever you review a PR — your own (`/pr`, `/pr-chore`) or someone else's (`/review`) — load the
`review-standards` skill first and follow it exactly: history check, lenses, 🔴/🟡/🔵 classification,
verdict rules, comment format and the formal GitHub review.
