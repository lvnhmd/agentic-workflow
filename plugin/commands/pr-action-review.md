---
description: Fetch every review comment on a PR and action it — auto-fix the clear ones, discuss the rest, reply and resolve threads, re-request review, and offer to merge.
argument-hint: <pr-number> [--watch]
---

Load the `workflow-contract` skill first if it isn't loaded in this session yet: its rules apply to every step below.

Action the review on PR **$ARGUMENTS**. `--watch` skips the "merge now?" question (never the ticket question).

`{owner}/{repo}` below is `aw-config REPO_SLUG`. Other config values come from `aw-config <KEY>`.

## 1. Ownership and branch

```bash
gh pr view <n> --json number,url,headRefName,baseRefName,author
gh api user --jq .login
```

- PR author ≠ me → STOP: "⚠️ PR #<n> was opened by @<author>, not you. Actioning it will commit, push to
  their branch and post comments on their behalf. Proceed? (yes / no)". Continue only on yes.
- On the PR branch → fine. On the default branch → `git checkout <headRefName>`. Anywhere else → ask first.

## 2. CI state — sync only when it helps

```bash
gh pr view <n> --json mergeable,mergeStateStatus,statusCheckRollup
```

Merging the base in triggers a fresh CI run, so **don't sync a clean, green branch**.

- Mergeable and nothing failing → go to step 3.
- Conflicting (`CONFLICTING` / `DIRTY`) → merge `origin/<base>` and resolve (below).
- Failing checks → diagnose with `aw-ci status` and `aw-ci logs <job>` first:
  - **Unrelated, already fixed on the base** (green there, or in files this PR never touched —
    `gh pr diff <n> --name-only`): merge the base in, push, and re-check after the new run.
  - **Unrelated, broken everywhere or flaky**: don't sync; note it in the summary.
  - **Related to this PR**: it's a review finding — fix it in step 5 or raise it in step 6.

Conflict resolution: auto-resolve only the mechanical ones (formatting, imports, lockfiles). For
semantic conflicts favour the PR branch's intent. If one can't be resolved safely, show it to the user
and wait. Commit as `<KEY>: merge <base> into <head>` and push.

## 3. Fetch everything

```bash
gh api "repos/{owner}/{repo}/pulls/<n>/comments" --paginate   # line comments
gh api "repos/{owner}/{repo}/issues/<n>/comments" --paginate   # general comments
gh api "repos/{owner}/{repo}/pulls/<n>/reviews" --paginate     # review bodies + states
gh api graphql -f query='query { repository(owner:"<owner>", name:"<repo>") { pullRequest(number:<n>) {
  reviewThreads(first:100) { nodes { id isResolved path line comments(first:20) { nodes { author { login } body } } } } } } }'
```

If a `gh` call fails with "GraphQL is not available" (Claude Code on the web and some proxies), use the
REST route the error message names instead (e.g. `GET /repos/{owner}/{repo}/pulls/{n}/ccr/review_threads`
and `.../ccr/comments/{id}/resolve`), and REST equivalents of `gh pr view --json` (`gh api repos/{owner}/{repo}/pulls/{n}`).

Skip resolved threads, CI/infrastructure bots with no code suggestion, and pure praise. **Don't skip
Copilot** — triage it like a human reviewer.

## 4. Triage every comment

- **AUTO-FIX** — clear bug, typo or naming issue; style fix matching our standards; missing test;
  straightforward refactor with no architectural impact; security issue with an obvious fix.
- **NEEDS DISCUSSION** — challenges a design decision; needs a significant change of approach;
  contradicts documented standards; has merit but you disagree or the trade-off isn't obvious; needs
  product input; ambiguous enough to misread.
- **INFORMATIONAL** — already answered by the code or docs; marked nit/optional; out of scope.
  Reply briefly and resolve the thread straight away.

If auto-fixes would touch more than 10 files, summarise the plan and confirm before starting.

## 5. Apply the auto-fixes

1. Read each file before editing; never edit from memory.
2. Make all the fixes, then run `bash scripts/agentic/verify.sh` once and fix anything it finds.
3. One commit: `<KEY>: address PR review comments`. Push.
4. Reply to each thread in one sentence ("Fixed — renamed to `providerKey` for consistency."), ending
   with the ATTRIBUTION line, then resolve it:
   `gh api graphql -f query='mutation { resolveReviewThread(input:{threadId:"<id>"}) { thread { isResolved } } }'`
5. Only resolve threads whose fix is committed **and pushed**.
6. If a comment exposes a docs gap, fix the doc in the same commit.

## 6. Present the discussion items

For each, numbered:

```
**[N] @reviewer — file:line (or "general")**
> exact quote
**My assessment:** agree / disagree / nuanced — and why
**Reply if we push back:** "<draft>"
**Reply if we accept:** "<draft + the change>"
```

Then ask: "For each item: accept / reject / skip — and optionally the reply you want posted."

## 7. Apply the decisions

- **Accept** → change, verify, commit, push, reply, resolve.
- **Reject** → post the push-back reply; leave the thread open for the reviewer.
- **Skip** → nothing.

Run `verify.sh` once more, push, and print:

```
## Review response summary
✅ Auto-fixed (N): ...
✅ Accepted and fixed (N): ...
↩️ Pushed back (N): ...
ℹ️ Informational — replied and resolved (N): ...
⏭️ Skipped (N): ...
```

**Re-request review only from reviewers not already approving.** A reviewer's effective state is their
latest review that isn't `COMMENTED` (a comment after approval doesn't withdraw it). Re-request those
whose effective state isn't `APPROVED`: `gh pr edit <n> --add-reviewer <login>`.

## 8. Merge?

```bash
gh pr view <n> --json mergeable,mergeStateStatus,statusCheckRollup,reviews
```

- **Approved** = at least one human whose effective state is `APPROVED`. Bots (`user.type == "Bot"`, or
  a login containing `bot`/`copilot`) don't count. A human account that approved through AI tooling is a
  human approval: take it at face value.
- **Mergeable** = `MERGEABLE`, `mergeStateStatus` `CLEAN` or `HAS_HOOKS`, and no check failing or pending.

If both: ask **Q1** "All checks passed and the PR is approved — merge now?" (skipped with `--watch`) and
**Q2** "After merging, the ticket should: 1) move to Done, 2) move to QA and be assigned to <QA owner>,
3) stay as it is?". Resolve the QA owner first: `aw-tracker resolve-user "$(aw-config QA_ASSIGNEE_QUERY)"`
and name the person; if it's unset or ambiguous, say so and ask who.

Merge with a merge commit (squash breaks stacked PR chains): `gh pr merge <n> --merge --delete-branch`.
Then, with `KEY=$(aw-tracker from-branch <headRefName>)`:

1. `aw-tracker transition "$KEY" "$(aw-config STATUS_DONE)"`
2. `aw-tracker transition "$KEY" "$(aw-config STATUS_QA)"` then `aw-tracker assign "$KEY" <resolved-id>`
3. nothing

If approved but CI is still running or branch protection isn't satisfied, say so and leave the merge to
the user. If nobody human has approved, say that. Never turn on GitHub auto-merge. A green PR
still waits for a person to merge it.

Every reply posted ends with the ATTRIBUTION line.
