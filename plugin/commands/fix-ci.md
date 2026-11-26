---
description: Diagnose failing CI on the current branch — rerun flakes, fix real failures with the smallest change.
---

Load the `workflow-contract` skill first if it isn't loaded in this session yet: its rules apply to every step below.

Fix failing CI on the current branch. Scoped to this repository only (`REPO_SLUG`): never read or
trigger another project's pipelines.

## 1. Find the failure

```bash
aw-ci status            # latest run(s) for this branch's head commit
```

Exit code 3 means `CI_PROVIDER=none`: say so and stop. If there are no runs: "No CI run found for this
branch." If nothing failed: "✅ No failing jobs on `<branch>`." Skip jobs still running.

## 2. Read the logs

For every failed job (in parallel): `aw-ci logs <job-id>`. Read each to the end; the
first real error usually sits just above the last one printed.

## 3. Flake or real?

Before touching code:

- Run the same check locally (the matching step from `scripts/agentic/verify.sh --list`).
- Compare the failing job with what this branch changed:
  `git diff "origin/$(aw-config DEFAULT_BRANCH)...HEAD" --name-only`.

It's a **flake** when it passes locally **and** the job covers code this branch didn't touch, or the log
shows a known transient signature (network timeout, registry 5xx, install blip, runner lost). Then
don't change code: `aw-ci rerun <run-or-workflow-id>`, report "Flake — re-ran failed
jobs, no code changes", and stop. If the rerun call fails, show the error and stop.

## 4. Fix a real failure

Open just the files the failing log points to. Make the minimal fix; don't refactor nearby code. Run the
failing check locally until it passes, then the fast tier (`verify.sh --fast`).

Commit `<KEY>: fix: <what broke>` (key from `aw-tracker from-branch`) and push. Report
the root cause in one sentence.
