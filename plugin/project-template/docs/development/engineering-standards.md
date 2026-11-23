# Engineering Standards

The rules every change follows. Language- and framework-specific conventions go in their own files in
this folder (e.g. `react-conventions.md`, `api-patterns.md`) and are linked from CLAUDE.md's
"Read First" table.

## Code

- **Readable over clever.** Names say what a thing is or does; no abbreviations a newcomer wouldn't know.
- **Small units.** A function does one thing; a module has one reason to change (SOLID's single responsibility).
- **Strict types** where the language has them. No `any` / untyped escapes; use `unknown` plus a type
  guard, or a schema validator at the boundary.
- **Validate at the boundary**, trust inside it: parse external input (HTTP, queue, file, LLM output)
  into typed values once, at the edge.
- **No hidden global state.** Dependencies are passed in, which also makes them testable.
- **Fail loudly and specifically.** Typed errors with a stable code; never swallow an exception.
- **No dead code, no commented-out code, no TODO without a ticket key.**
- **DRY, but not prematurely.** Duplicate twice; extract on the third time, once the shape is clear.

## Architecture

- Respect the layer boundaries described in `docs/architecture/`: dependencies point inward
  (transport → application → domain), never the other way.
- Integrations with external systems sit behind an interface the rest of the code depends on.
- A new pattern, dependency or integration is a decision: write an ADR.

## Data

- **Migrations** for every schema change, committed with it. Applied migrations are never edited.
- Migrations are backwards-compatible with the running version (expand, migrate, contract).
- Records that are meant to be immutable (audit logs, generated documents) are versioned, never updated in place.

## Configuration and secrets

- Configuration comes from the environment, validated at startup; the app refuses to start with
  missing or invalid config and says which variable is wrong.
- Every runtime variable appears in `.env.example` with a comment. Secrets are never committed.

## Observability

- Structured (JSON) logs with a correlation/trace ID propagated across every boundary.
- No secrets or personal data in logs.
- Health (`/healthz`) and readiness (`/readyz`) endpoints for every service.
- Error tracking on every app; dashboards and alerts for error rate, latency and saturation.

## Dependencies

- Add a dependency only when it does substantial work; prefer the standard library.
- Pin versions through the lockfile; let the dependency bot propose upgrades.
