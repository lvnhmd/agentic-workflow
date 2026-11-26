---
description: Start a ticket: take ownership, set it In Progress, read all of it, create the branch, and seed SESSION.md before any code is written.
argument-hint: <ticket> [--stay] [--qa]
---

Load the `workflow-contract` skill first if it isn't loaded in this session yet: its rules apply to every step below.

Start work on a ticket: take ownership, set its status to In Progress, then read the whole of it, including subtasks and linked
context, create the branch, then prepare to implement.

**Arguments:** $ARGUMENTS

- `--stay` — don't create a branch; work on the current one (stacking several tickets on one branch).
- `--qa` — QA-rework mode: the work is already merged and the ticket came back from QA with comments.
  Run the normal front door (assign, In Progress, branch), then hand off to `/qa-feedback`.
  With `--stay` too, merge the latest default branch into the current branch first.

All tracker calls go through `aw-tracker` (it reads `.claude/workflow.env` and `.env`).
If it reports missing credentials, stop and tell the user which variables to add.

## 1. Parse arguments

Remove `--stay` / `--qa` from `$ARGUMENTS`, then normalise what's left:

```bash
TICKET_KEY=$(aw-tracker key "<remaining argument>")
```

## 2. Read the ticket, comments included

```bash
aw-tracker get "$TICKET_KEY"
aw-tracker comments "$TICKET_KEY"
```

Comments with `by_agent: true` were written by an agent. Human comments are decisions already made and
take precedence over earlier agent analysis.

## 3. Ensure an epic / milestone

If the ticket has neither `parent` nor `epic`, invoke the `assign-epic` skill for `$TICKET_KEY` and wait
for it before continuing.

## 4. Assignee safety check

- `assignee` is null, or `assignee.id` equals `aw-tracker me` → continue.
- Assigned to someone else → STOP: "$TICKET_KEY already belongs to <name>. Take it over anyway? (pick
  this up?" Continue only after a clear yes.

## 5. Assign, move to In Progress, put it on the board

```bash
aw-tracker assign "$TICKET_KEY" me
aw-tracker transition "$TICKET_KEY" "$(aw-config STATUS_IN_PROGRESS)"
aw-tracker board-add "$TICKET_KEY"
```

If the transition isn't available from the current status, show the user the options the script
lists and ask which to use.

## 6. Read the surrounding context

- `get` each subtask and summarise its title, description and status.
- `get` the parent / epic to understand the broader story.
- `get` each linked issue that blocks or relates to this one.
- Read the docs the CLAUDE.md "Read First" table names for this area of the code.

## 7. Output a brief

```
## Ticket: <key> — <title>

**Type:** <type>   **Priority:** <priority>   **Status:** now In Progress
**Parent:** <key — title, if any>
**Branch (stay mode):** <current branch>
**🔁 QA rework:** <only with --qa — "Work is already merged. Handing off to /qa-feedback after branch setup.">

### Description
<description>

### Subtasks
- [ ] <key>: <title> (<status>)

### Linked issues
- <type>: <key> — <title>

### Decisions already made in comments
- <author, date>: <decision>

### Implementation notes
<what needs building, which files/modules, which docs apply, the first failing test to write>

### Open questions
<anything unclear that must be resolved before coding>
```

## 8. Branch

**Stay mode:** if the current branch is protected (matches `PROTECTED_BRANCHES`), STOP: "You're on
`<branch>`. `--stay` continues an existing feature branch — rerun without it, or switch branch first."
Otherwise stay put. With `--qa` as well: `git fetch origin "$(aw-config DEFAULT_BRANCH)" && git merge "origin/$(aw-config DEFAULT_BRANCH)"`;
on conflicts, stop and ask. Commits for this ticket must still use `$TICKET_KEY`.

**Otherwise:**

```bash
git checkout "$(aw-config DEFAULT_BRANCH)" && git pull && git checkout -b "<ticket-key-lowercase>-<2-4-word-kebab-summary>"
```

If there are uncommitted changes, stop and ask before switching.

## 9. Seed SESSION.md

Create `SESSION.md` in the repo root (never committed):

```markdown
# SESSION.md — <key>: <title>

**Branch:** <branch>
**Started:** <today>

## Plan
<approach from the brief, including the first failing test>

## Progress
_Nothing yet._

## Decisions
_Nothing yet._

## Open Questions
<from the brief>
```

- Not stay mode: if a SESSION.md exists, read it (it may hold unfinished notes worth mentioning), then
  replace it.
- Stay mode with an existing SESSION.md: append a new `---` section for this ticket instead of
  overwriting.

## 10. Hand off or pause

- `--qa`: say "Ticket set up for QA rework on `<branch>` — handing off to `/qa-feedback`." and run
  `/qa-feedback $TICKET_KEY`. It has its own confirmation gates.
- Otherwise ask: "That's the plan. Anything to change before I write the first test?" and wait for the go-ahead before writing code.
