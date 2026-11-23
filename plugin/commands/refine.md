---
description: Refine a ticket — surface clarifying questions, propose ranked approaches, and post the conclusions back to the ticket.
argument-hint: <ticket>
---

Load the `workflow-contract` skill first if it isn't loaded in this session yet: its rules apply to every step below.

Refine a ticket before anyone builds it.

**Ticket:** $ARGUMENTS

## 1. Fetch

```bash
TICKET_KEY=$(aw-tracker key "$ARGUMENTS")
aw-tracker get "$TICKET_KEY"
aw-tracker comments "$TICKET_KEY"
```

Human comments (`by_agent: false`) are decisions already made; they override earlier agent analysis.
Also `get` the parent/epic and every subtask.

## 2. Check status

When someone already owns the ticket or work on it has started, tell the user who has it and its status, and ask
whether to refine it anyway.

## 3. Read the codebase context

Read `CONTRIBUTING.md`, `docs/development/engineering-standards.md`, the relevant `docs/architecture/`
files, and the source in the area the ticket touches. Form opinions from the code, not from the title.

## 4. Analyse

1. **Clarity** — are the acceptance criteria precise and testable? Ambiguous terms, missing edge cases,
   unstated assumptions?
2. **Scope** — right-sized? Should it split? Does it silently require other changes?
3. **Constraints** — architecture, performance, security, accessibility, documented patterns that apply.
4. **Approaches** — genuinely distinct ways to build it, with trade-offs in complexity, testability,
   reversibility and fit with existing patterns.

## 5. Ask

Ask the user the clarifying questions, quoting the line of the ticket each one is about. If
nothing is unclear, say so instead of inventing questions. When approaches differ meaningfully, ask the
user to choose: up to two pros and two cons each, a 1–5 star rating, and your preference marked.
Keep asking until the ticket is clear.

## 6. Write the refinement

```markdown
## Refinement: <key> — <title>

### Clarifications needed
<or "None — the ticket is clear.">

### Proposed approaches
**1. <name> (recommended)**
- What:
- Why preferred:
- Trade-offs:
- Risks:

**2. <name>**
- What:
- Why considered:
- Trade-offs:

### Recommendation
<one paragraph, citing the code and docs you read>

### Open questions before implementation
1. <architectural or risk decisions, distinct from wording ambiguities>

### Clarifications resolved
<every question asked in this session and the user's answer, verbatim — an audit trail, not a summary>
```

## 7. Post it

Write it to a temp file and post it (attribution is appended automatically):

```bash
aw-tracker comment "$TICKET_KEY" /tmp/refinement-$TICKET_KEY.md
```

Confirm it posted, then ask: "Refinement posted — anything to adjust before we plan the implementation?"
