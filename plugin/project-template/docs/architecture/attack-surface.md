# Attack Surface

Read by the `adversary` security agent before it probes the code, and by reviewers of security-sensitive
changes. Keep it short and current.

## Tenancy and authorisation

<!-- Who may see what. How the caller's tenant/organisation/owner is resolved on each request, and
     where that check lives (middleware, guard, repository scope). -->

## Authentication paths

<!-- Every way a caller proves who they are: sessions, bearer tokens, API keys, service accounts,
     webhooks. Which endpoints accept which. -->

## Trust boundaries

<!-- External inputs the system trusts too much if it isn't careful: third-party APIs, LLM output,
     uploads, webhooks, queues. Where each is validated. -->

## Secrets

<!-- Where secrets come from at runtime and where they must never appear (logs, errors, client bundles). -->

## Security tests

<!-- Folder for security invariant tests, e.g. tests/security/. -->
