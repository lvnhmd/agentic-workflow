---
description: Review the last week of scheduled (nightly) CI runs, categorise failures, and propose tickets for the real ones.
argument-hint: [days=7]
---

Triage scheduled CI runs for this repository only.

## 1. Fetch

```bash
aw-ci scheduled ${ARGUMENTS:-7}
```

Exit code 3 = no CI adapter: say so and stop. If every run passed: "✅ All scheduled runs passing —
nothing to action." and stop.

## 2. Diagnose each failure

For each failed run, get its failed jobs (`aw-ci status` for the branch, or the run's jobs) and read the
logs with `aw-ci logs <job-id>`. Categorise:

- **Flake**: passes on retry (timeouts, races, a blip in shared infra)
- **Regression**: a recent commit changed the outcome
- **Config** — CI config, env var or secret problem
- **Infra** — runner, disk, memory, service outage
- **Unknown** — can't tell from the logs

## 3. Summarise

```
| Run | Date | Workflow | Job | Category | Root cause (one line) |
```

## 4. Act

- **Regression / Config** → name the affected files or config, propose a concrete fix, and ask:
  "Create a ticket and pick it up for <failure>?" If yes: `/capture`, then `/pickup <key>`.
- **Flake** → more than twice in the window means chronic: propose a fix and offer a ticket. Otherwise
  record it as a known flake.
- **Infra** → flag it for a human with the run and job IDs; it isn't fixable from code.

## 5. Report

Runs reviewed, failures by category, tickets created, recommended next steps.
