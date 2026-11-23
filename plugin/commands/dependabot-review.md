---
description: Review open Dependabot/Renovate PRs — merge the green minor/patch bumps, diagnose the failing ones.
---

Review open dependency-bot PRs.

## 1. List

```bash
gh pr list --author "app/dependabot" --state open --json number,title,url,headRefName,createdAt --limit 50
gh pr list --author "app/renovate" --state open --json number,title,url,headRefName,createdAt --limit 50
```

None: "✅ No open dependency PRs." and stop.

## 2. Check each

`gh pr checks <n> --json name,state,bucket,link` → **Green** (all pass), **Failing**, **Pending**, or
**No checks** (treat as failing; never merge unchecked).

## 3. Green PRs

1. Read the title: package, old → new version, major / minor / patch.
2. **Major** → warn and ask "PR #<n> is a major bump (<pkg> <old> → <new>). Approve and merge anyway?"
   and wait. Minor or patch → continue.
3. Approve: `gh pr review <n> --approve --body $'Dependency bot: all checks green, <patch|minor> bump.\n\n<ATTRIBUTION>'`
4. Merge: `gh pr merge <n> --squash --delete-branch` and confirm it merged.

## 4. Failing PRs

1. Find the failed checks and read the logs (`aw-ci logs <job-id>`, job IDs from `aw-ci status <headRefName>`).
2. Categorise: dependency conflict · type error · test failure · lint failure · flake · unknown.
3. **Flake** → `gh pr comment <n> --body $'@dependabot rebase\n\n<ATTRIBUTION>'` (Renovate: tick its rebase box).
4. **Fixable** → describe the fix in 1–3 sentences, say whether it's a one-liner or risky, and ask
   "Check out PR #<n> and fix it, or close it and let the bot re-raise later?"
   - Default to **fix** for minor/patch bumps with a one-line, low-risk change.
   - Default to **close** for major bumps with ecosystem-wide breakage, big code changes, or no compatible
     upstream release yet: `gh pr close <n> --comment "<reason>. The bot will re-raise when <condition>.\n\n<ATTRIBUTION>"`
5. **Unknown** → leave a diagnostic comment and flag it to the user.

## 5. Pending PRs

Note and skip; the next run picks them up.

## 6. Report

```
| PR | Package | Bump | Status | Action |
```

"X merged, Y diagnosed, Z left (checks still running)."
