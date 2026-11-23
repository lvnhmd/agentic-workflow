---
description: Check that this repo's agentic-workflow setup works — config, tools, git hooks, credentials, tracker statuses, CI access — and fix what's broken.
argument-hint: [--offline]
allowed-tools: Bash(aw-doctor:*)
---

Run `aw-doctor $ARGUMENTS` and report the result.

- If everything passes, say so in one line.
- For each ✗ failure and ! warning, say what it means and how to fix it, most important first.
- Offer to fix the ones you can fix safely yourself: enabling git hooks (`git config core.hooksPath .githooks`),
  adding `.env` to `.gitignore`, correcting `STATUS_*` names in `.claude/workflow.env` to the ones Jira
  reported, filling empty `verify-steps` from the project's package scripts or Makefile, drafting the
  `CLAUDE.md` project sections from the code. Ask before each.
- Never ask the user to paste a token into the conversation. Tell them which variable to add to `.env`
  and where to create the token (`.env.workflow.example` has the links).
