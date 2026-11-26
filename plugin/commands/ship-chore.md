---
description: Raise a small chore PR (tooling, config, agent files) from a temporary worktree, without touching the current branch. No ticket needed.
argument-hint: <short-description>
---

Load the `workflow-contract` skill first if it isn't loaded in this session yet: its rules apply to every step below.

Open a chore PR containing only the files named in this conversation. **The current branch must not be
touched** beyond removing those exact files: other agents may be working on it. No SESSION.md.

Config values come from `aw-config <KEY>`.

## 1. Pin down the change

Name every file the conversation agreed to change. Don't infer extras; confirm with the user if unsure.

## 2. Create a worktree from the default branch

```bash
git fetch origin "$(aw-config DEFAULT_BRANCH)"
CHORE_BRANCH="chore/<short-description>"
WT="$(mktemp -d)/chore-pr"
git worktree add -b "$CHORE_BRANCH" "$WT" "origin/$(aw-config DEFAULT_BRANCH)"
```

## 3. Copy the files and confirm

`mkdir -p` the parent directories, `cp` each file to the same relative path under `$WT`, then check each
one explicitly (`git status` alone misses files identical to the default branch):

```bash
for f in <files>; do test -f "$WT/$f" && echo "ok      $f" || echo "absent  $f"; done
```

Don't continue until every file is present.

## 4. Restore the current branch — only those files

From the original working tree (not `$WT`):

- Modified tracked files: `git restore --staged --worktree <files>`
- New untracked files: `rm -f <files>`
- Already committed on this branch: leave them and tell the user. Never rewrite history.

Don't discard anything wholesale (`git restore .`, `git checkout .`, a hard reset). Confirm with `git status --short` that
only unrelated pre-existing changes remain.

## 5. Verify (only if code changed)

Skip when every file is docs or config (`.md`, `.json`, `.yml`, agent commands/skills). Otherwise:
`cd "$WT"`, install dependencies, `bash scripts/agentic/verify.sh`, fixing issues inside the worktree.

## 6. Commit, push, PR

```bash
cd "$WT"
git add <files>
git commit -m "chore: <description>"
git push -u origin "$CHORE_BRANCH"
gh pr create --base "$(aw-config DEFAULT_BRANCH)" --head "$CHORE_BRANCH" --title "chore: <description>" --body-file <file>
```

The body covers what changed, why, and risk/rollback, ending with the ATTRIBUTION line.

## 7. Self-review

`gh pr diff <n>`, review with the `review-standards` skill, classify findings 🔴/🟡/🔵, fix any 🔴 in the worktree first, then post the
"AI Pre-Review" comment in the format from `/pr` step 5.

## 8. Clean up

```bash
cd "$(git rev-parse --show-toplevel)"   # the original tree
git worktree remove --force "$WT"
```
