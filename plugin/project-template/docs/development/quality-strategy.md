# Quality Strategy

An agent has to be able to run each layer, read its result and act on it **without a human in the loop**. A check that only a human can
run breaks the feedback loop, so it doesn't count as a gate.

## Defence in depth (Swiss cheese)

No single layer is relied on alone. Each catches different mistakes:

| Layer                  | When                 | What it catches                                                 | Where it's configured                     |
| ---------------------- | -------------------- | --------------------------------------------------------------- | ----------------------------------------- |
| Claude Code hooks      | every tool call      | destructive commands, edits to immutable files, unformatted code | agentic-workflow plugin (`hooks/`)  |
| pre-commit             | `git commit` (~10 s) | protected branches, SESSION.md, `.env`, secrets, staged lint    | `.githooks/pre-commit` (+ `.local`)        |
| pre-push               | `git push` (< 1 min) | fast tier: format, lint, types, unit tests; schema w/o migration | `.githooks/pre-push`, `.claude/verify-steps` |
| verify.sh              | before every PR      | the full suite, same as CI                                      | `.claude/verify-steps`                    |
| CI                     | every push           | everything above on a clean machine, plus scans and e2e         | <!-- your CI config path -->              |
| AI review              | every PR             | intent vs ticket, security, accessibility, docs sync            | `CLAUDE.md` § PR Review Standards         |
| Human review / QA      | before merge / after | product intent, risk, things no test encodes                    | CODEOWNERS, `/qa-feedback`           |
| Production             | always               | observability, alerting, runbooks                               | `docs/runbooks/`                          |

When a defect slips through, add a check to the earliest layer that could have caught it.

## Test conventions — PROJECT

<!-- Where each kind of test lives and how it is named, e.g.
- Unit: co-located `*.test.ts` / `test_*.py`
- Integration: `tests/integration/<feature>/`
- E2E: `e2e/` (Playwright) -->

- **Arrange–Act–Assert** in every test.
- **Assert on outcomes**, not on log lines or implementation details.
- **Factories** for test data, not hand-built inline objects.
- **No real hostnames** in unit tests (staging, production, internal). Use `https://service.example` or `localhost`.
- **Contract tests** pin the shape of every external API we depend on, from recorded fixtures.

## Testing layers

| Test level  | What it covers                                      | When it runs             | Coverage floor <!-- PROJECT --> |
| ----------- | --------------------------------------------------- | ------------------------ | ------------------------------- |
| Unit        | one function/module, collaborators mocked           | pre-push, CI             | 70% (raise for critical code)   |
| Integration | a real boundary (HTTP, DB, queue) with edges mocked | verify.sh, CI            | new endpoints add tests         |
| E2E         | full user flows in a browser                        | CI (and before UI PRs)   | critical journeys               |

## Test effectiveness

- **Mutation testing** (Stryker, mutmut, cargo-mutants...) shows whether tests actually fail when the
  code is wrong. Run it nightly on security-critical paths; a surviving mutant is a missing assertion.
- **The `tdd-critic` agent** reviews tests adversarially before merge: tests written after the fact,
  loose assertions, missing edge cases, production code without a test.

## Standards

- **Accessibility**: WCAG 2.2 AA. Automated axe checks in e2e, plus keyboard and focus checks for new UI.
- **Security**: OWASP Top 10. Static analysis and dependency audit in CI; secret scanning on commit.
- **API contracts**: an OpenAPI (or GraphQL/JSON) schema generated from code and linted in CI; examples
  for every endpoint kept in sync.

## Security invariant tests

Deterministic tests that prove the core boundaries hold. Each newly found kind of vulnerability
(often by the `adversary` agent), it becomes a permanent test here.

- **Tenant isolation**: a user can't read or change another tenant's data → 403/404 with no difference
  between "forbidden" and "missing".
- **Authentication**: unauthenticated → 401; expired or malformed credentials → 401; one auth mechanism
  presented where another is expected → 401.
- **Error sanitisation**: no stack traces, SQL, file paths or framework details in production errors.
- **Input validation**: malformed bodies → 400; unknown fields rejected; oversized payloads → 413;
  queries parameterised.
- **Secrets**: never in logs, never in error responses, never in client bundles.

<!-- PROJECT: list where these tests live and any planned invariants not yet enforced. -->

## Quality checks for AI-generated content

If the product generates text with an LLM: validate output before persisting it (schema, length,
banned content, internal identifiers leaking into prose), log rejected outputs, and keep prompts in
version control with snapshot tests.
