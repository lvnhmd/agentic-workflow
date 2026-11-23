# ADR-0002: Agentic development workflow

**Status:** Accepted
**Date:** {{TODAY}}

## Context

Most code in this repository is written by coding agents working from tickets. Agents are fast but
inconsistent from session to session, and a human reviewing every line becomes the bottleneck.

## Decision

We adopt the agentic-workflow Claude Code plugin, enabled for the repo in `.claude/settings.json`:

- The plugin loads a shared workflow contract into every session; `CLAUDE.md` adds what is specific to
  this project (what to read, project rules).
- Each stage of the ticket lifecycle is a plugin slash command, so every session follows the same path.
- Deterministic guardrails sit around the agent: plugin hooks on every tool call, git hooks on commit
  and push, `scripts/agentic/verify.sh` before every PR, and CI.
- Tracker and CI access go through the plugin's `aw-tracker` and `aw-ci`, configured in
  `.claude/workflow.env`.
- Review is spot-checking backed by those gates. Every external write by an agent is attributed.

## Consequences

- Process lives in versioned files: the plugin is versioned in its own repo, project settings change
  through PRs like code.
- New guardrails are added where a mistake slipped through, not as more manual review.
- Changing the tracker or CI provider is a config change, not a rewrite of the commands.
