---
description: Review someone else's PR against the project's review standards, post the findings, and submit a formal GitHub verdict.
argument-hint: <pr-number>
---

Load the `workflow-contract` skill first if it isn't loaded in this session yet: its rules apply to every step below.

Review PR **$ARGUMENTS**. Load the `review-standards` skill first and follow it exactly.

1. `gh pr view $ARGUMENTS --json number,title,body,author,baseRefName,headRefName,files,statusCheckRollup`.
   Read the linked ticket (`aw-tracker get <key>`) for the acceptance criteria.
2. **History first.** Fetch review comments, issue comments and reviews (commands in the skill). Map
   every earlier point as pushed back / addressed / open. Pushed-back points are never re-listed.
3. `gh pr diff $ARGUMENTS`, then read every changed file **in full** at the PR's head
   (`gh pr checkout $ARGUMENTS` in a worktree if you need to run anything; never on top of your own work).
4. Check against the ticket: does it do what was asked, and only that?
5. Review through every lens. For each finding note `file:line`, one sentence, and 🔴/🟡/🔵.
   Be concrete: what breaks, for which input. No style opinions that the formatter or linter owns.
6. For anything security-sensitive (auth, permissions, tenant scoping, input handling), consider
   delegating a focused probe to the `agentic-workflow:adversary` agent.
7. Post the comment with `gh pr comment` in the "AI Review" format, then **submit the formal review**
   (`gh pr review --approve` or `--request-changes`) with a one-line verdict and the ATTRIBUTION line.
8. Tell the user the verdict and the 🔴 items, if any.
