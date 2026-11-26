---
description: Verify, commit and push the current branch — no PR.
---

Load the `workflow-contract` skill first if it isn't loaded in this session yet: its rules apply to every step below.

1. `cd "$(git rev-parse --show-toplevel)" && bash scripts/agentic/verify.sh`. If it fails, fix the cause and re-run. Do not skip.
2. Review `git status` and `git diff`. Stage only the files that belong to this change; never SESSION.md.
3. Commit following CONTRIBUTING.md: the ticket key from the branch (`aw-tracker from-branch`) and a conventional type.
4. `git push -u origin HEAD`.

A failed step ends the run: report what failed and why. No force, no skipped gates, no `--no-verify`.
