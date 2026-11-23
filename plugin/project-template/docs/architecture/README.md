# Architecture — current state

This folder answers "what is true now". Agents read it before designing anything, and open an ADR only
when a document here cites it. Keep it accurate: any PR that changes a data flow, schema, integration or
pattern updates the matching file here.

Suggested files (C4-style):

- `context.md` — the system, its users, and the external systems it talks to
- `containers.md` — deployable units, their responsibilities, how they communicate
- `data.md` — data model, ownership, retention, PII boundaries
- `deployment.md` — environments, infrastructure, CI/CD path
