# AGENTS.md

This repository is developed with an agentic workflow. The full contract for any coding agent
(Claude Code, Codex, Copilot, Cursor, OpenCode...) starts with [`CLAUDE.md`](CLAUDE.md). Claude Code
also loads the shared workflow contract and slash commands from the agentic-workflow plugin; other
agents follow the summary below.

The short version:

- Work from a ticket; branch per ticket (`CONTRIBUTING.md`); never commit to protected branches.
- Read `docs/architecture/` before designing; docs lead and code follows.
- Test first. Run `scripts/agentic/verify.sh` before opening a PR. Never bypass git hooks.
- `PROGRESS.md` is a local scratchpad: never commit it.
- End every comment you post to GitHub or the tracker with the `ATTRIBUTION` line in `.claude/workflow.env`.
