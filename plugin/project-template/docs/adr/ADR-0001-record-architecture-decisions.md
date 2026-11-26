# ADR-0001: Keep a log of architecture decisions

**Status:** Accepted
**Date:** {{TODAY}}

## Context

Decisions get made in chats, PR threads and people's heads, then get re-litigated because nobody can
find why they were made. Coding agents make this worse: without a record they rediscover or silently
contradict past decisions.

## Decision

We record significant decisions as ADRs in `docs/adr/`, numbered sequentially, from `TEMPLATE.md`.
Accepted ADRs are immutable; a changed decision gets a new ADR that supersedes the old one, and the old
one's status line is the only edit allowed. The current state lives in `docs/architecture/`, which is
updated in the same PR as any ADR that changes behaviour (checked by `scripts/agentic/check-adr-sync.sh`).

## Consequences

- The "why" behind the system survives team changes and agent sessions.
- Agents read `docs/architecture/` first and only open an ADR when it is cited, which keeps context small.
- Writing an ADR takes a few minutes per significant decision.
