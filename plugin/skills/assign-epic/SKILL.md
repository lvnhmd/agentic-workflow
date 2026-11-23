---
name: assign-epic
description: Link a ticket to the most relevant open epic (Jira) or milestone (GitHub), asking the user when it's ambiguous. Use right after a ticket is created, when /pickup finds a ticket without one, or when the user says "assign epic" / "where does this ticket go".
---

# Assign a ticket to the right epic

**Ticket:** $ARGUMENTS (or the ticket that was just created)

## 1. Fetch the ticket and the open epics

```bash
TICKET_KEY=$(aw-tracker key "<ticket>")
aw-tracker get "$TICKET_KEY"
aw-tracker epics
```

If the ticket already has a `parent` or `epic`, report it and stop. If there are no open epics, say so
and stop — don't create one unasked.

## 2. Match

Compare the ticket's title, description and labels with each epic's title. Look for the same feature
area, component, user flow or initiative. Rank the candidates.

- **One clear match** → assign it.
- **Two or three plausible** → ask the user, listing each with a one-line reason, plus "none of these".
- **No plausible match** → tell the user and list the open epics so they can choose or skip.

## 3. Assign

Check the assignee first (CLAUDE.md absolute rule 7). Then:

```bash
aw-tracker set-parent "$TICKET_KEY" "<epic key or milestone>"
```

Report: "<ticket> → <epic key>: <epic title>".
