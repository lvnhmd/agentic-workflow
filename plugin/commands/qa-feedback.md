---
description: Review QA feedback on a ticket — classify each point as bug, intended behaviour or out of scope with evidence, fix the bugs, and post the response after approval.
argument-hint: <ticket>
---

Load the `workflow-contract` skill first if it isn't loaded in this session yet: its rules apply to every step below.

Review QA feedback on **$ARGUMENTS**.

## 1. Fetch the ticket, comments and screenshots

```bash
TICKET_KEY=$(aw-tracker key "$ARGUMENTS")
aw-tracker get "$TICKET_KEY"
aw-tracker comments "$TICKET_KEY"
aw-tracker attachments "$TICKET_KEY" "$(mktemp -d)"
```

Discard agent-authored comments (`by_agent: true`). Of the human ones, keep those that read as QA
feedback: observed behaviour in a deployed environment, reproduction steps, screenshots, words like
bug, expected, actual, regression, not working, should be. If there are none: "No QA feedback on
`<key>` — nothing to review." and stop.

Open every downloaded screenshot with the Read tool and note what it shows: page, defect, error text, UI state.

## 2. Number the points

One clearly scoped observation per number. Split comments that raise several problems.

## 3. Classify each point

- **GENUINE BUG** — unintended, the acceptance criteria imply it should work, no documented decision
  justifies it, and it is within the ticket's scope.
- **WORKS AS DESIGNED** — an ADR or doc explains it. **Quote the document and section**; "it probably
  makes sense" is not enough.
- **OUT OF SCOPE** — valid, but never in this ticket's (or a linked ticket's) acceptance criteria. A new
  request, not a defect: propose a follow-up ticket.
- **UNCERTAIN** — only when the evidence genuinely points both ways; say what points each way.

## 4. Locate each genuine bug

Search the code (`grep`/`find`, never guessed paths). Name the file, the function, the change, why it
fixes the root cause, and the test to add or update.

## 5. Report

For each point:

```
### [N] — <one-line summary>
**Source:** <author>, <date>   **Screenshot:** <file — what it shows, or "none">
**Call:** REAL DEFECT | BEHAVES AS SPECIFIED | NOT IN THIS TICKET | NEEDS A HUMAN
**Reasoning:** <with the cited doc/AC>
**Proposed action:** <fix details / draft push-back / follow-up ticket summary / both options + recommendation>
```

If anything is UNCERTAIN, ask: "For each uncertain item reply fix / push-back / skip, e.g. `2: fix, 4: skip`."
and wait.

## 6. Fix

For the genuine bugs plus accepted uncertain items: read each file first, write the failing test, fix,
run `bash scripts/agentic/verify.sh`, then one commit `<KEY>: address QA feedback` and push. Skip this
step if there's nothing to fix.

## 7. Confirm, then post

Show the exact comment and ask: "Ready to post this to `<key>` — yes / edit / cancel?" Post only on yes:

```markdown
**QA Review Response**
- **Fixed** [N] — <what changed>
- **Intended behaviour** [N] — <why> (cites <doc § section>)
- **Out of scope** [N] — <why> — suggested follow-up: <summary>
- **Pushed back** [N] (user decision) — <why>
- **Skipped** [N] (user decision)
```

`aw-tracker comment "$TICKET_KEY" <file>` (attribution added automatically).

## 8. Back to QA?

If no open defects remain, ask whether to move the ticket back to QA; on yes:
`aw-tracker transition "$TICKET_KEY" "$(aw-config STATUS_QA)"`.

Push-backs are always respectful and cite the specific document or acceptance criterion.
