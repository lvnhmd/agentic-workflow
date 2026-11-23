---
description: Switch to the default branch and pull; delete the previous feature branch only when that's safe.
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git checkout:*), Bash(git switch:*), Bash(git pull:*), Bash(git log:*), Bash(git rev-parse:*), Bash(grep:*)
---

## Context

- Default branch: !`aw-config DEFAULT_BRANCH`
- Current branch: !`git branch --show-current`
- Uncommitted changes: !`git status --porcelain`

Follow this decision tree exactly. `<default>` is the default branch above.

1. **Uncommitted changes** → stop: "`<branch>` has work that isn't committed. Commit, stash or discard
   them before switching." Nothing else.
2. **Already on `<default>`** → `git pull`, report it's up to date. Done.
3. **On a feature branch**, check:
   - `git log <default>..HEAD --oneline --max-count=1` — commits not on the default branch?
   - `git rev-parse --abbrev-ref --symbolic-full-name @{u}` — has an upstream?
   - if so, `git log @{u}..HEAD --oneline --max-count=1` — unpushed commits?

   - **No unique commits** → `git checkout <default> && git pull && git branch -d <branch>`;
     "On <default> and up to date. Removed `<branch>`: everything on it is already merged."
   - **Unique commits, all pushed** → same, "(was pushed to remote)".
   - **Unpushed commits** → ask: "`<branch>` holds commits that exist nowhere else. Remove it and lose them, or keep it?" Delete:
     switch, pull, `git branch -D <branch>`. Keep: switch and pull only.

End with one line: the branch you're on, whether anything was deleted, and whether the pull succeeded.
