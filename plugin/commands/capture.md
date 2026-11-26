---
description: Record what this session just did as a ticket (assigned to me, In Progress) and commit any related changes under it.
---

Load the `workflow-contract` skill first if it isn't loaded in this session yet: its rules apply to every step below.

Capture what this conversation did as a ticket, so no work goes untracked.

## 1. Decide the type

- Fixing broken or incorrect behaviour → **Bug**
- Adding new functionality → **Story**
- Anything else → **Task**

## 2. Create the ticket

Write a description to a temp file: the problem, what was done, and any context a reviewer or QA needs.

```bash
TICKET_KEY=$(aw-tracker create "<Bug|Story|Task>" "<concise summary>" /tmp/capture.md)
aw-tracker board-add "$TICKET_KEY"
aw-tracker transition "$TICKET_KEY" "$(aw-config STATUS_IN_PROGRESS)"
```

Then invoke the `assign-epic` skill for `$TICKET_KEY`.

## 3. Commit related changes

Check `git status`. If files changed for what was discussed:

- If on a protected branch, create `<ticket-key-lowercase>-<short-summary>` first.
- Stage only the relevant files (never `git add .`, never SESSION.md).
- Commit as `<TICKET_KEY>: <fix|feat|refactor|chore>: <short description>` per CONTRIBUTING.md.

If nothing changed, skip the commit.

## 4. Report

The ticket key, title and link (`aw-tracker url "$TICKET_KEY"`), and the commit message if one was made.
