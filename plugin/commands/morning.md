---
description: Morning maintenance — default-branch health, nightly CI triage, then dependency PRs.
---

Run the morning maintenance sequence in order, and keep going if one part has nothing to do.

## 1. Default-branch health

```bash
aw-ci status "$(aw-config DEFAULT_BRANCH)"
```

If the latest run on the default branch failed, that comes first: read the logs (`aw-ci logs <job>`),
say whether it's a flake or a regression and which merge likely caused it, and ask whether to rerun,
open a fix ticket (`/capture`), or continue.

## 2. Nightly runs

Run `/nightly-check`.

## 3. Dependency PRs

Run `/dependabot-review`. If step 1 found the default branch red, don't merge dependency PRs until it's
green again: their checks run against a broken base.

## 4. Summary

```
## Morning report — <date>
- Default branch: <green / red — cause>
- Nightly: <N runs, M failures — categories>
- Dependency PRs: merged X, diagnosed Y, pending Z
- Needs you: <decisions waiting on the user>
```
