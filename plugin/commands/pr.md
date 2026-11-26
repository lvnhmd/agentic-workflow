---
description: Ship the branch — clean up, full verify, commit, push, open a PR from the template, self-review it, and move the ticket to Review.
argument-hint: [--watch]
---

Load the `workflow-contract` skill first if it isn't loaded in this session yet: its rules apply to every step below.

Run the full ship workflow. **Arguments:** $ARGUMENTS

Config values come from `aw-config <KEY>` (e.g. `aw-config DEFAULT_BRANCH`); `aw-config` alone lists them all.

## 1. Clean up session artefacts

- If `SESSION.md` exists: read it back, list the docs it says need updating and update them now, then
  delete it (`git rm --cached SESSION.md 2>/dev/null; rm SESSION.md`). The pre-push hook blocks while it is in history.
- Delete untracked screenshots in the repo root left over from verification:
  `git ls-files --others --exclude-standard -- '*.png' '*.jpg' '*.jpeg' '*.gif' '*.webp' | grep -v / | while read -r f; do rm -f "$f"; done`

## 2. Verify

`cd "$(git rev-parse --show-toplevel)" && bash scripts/agentic/verify.sh` — the full suite. Fix and re-run until it passes.

## 3. Commit and push

- Review `git status` and `git diff`; stage only files that belong to the change.
- Commit per CONTRIBUTING.md with the ticket key (`aw-tracker from-branch`).
- `git push -u origin HEAD`.

## 4. Open the PR

`gh pr create` using `.github/pull_request_template.md`, every section filled:

- Title under 70 characters, starting with the ticket key.
- Ticket link (`aw-tracker url <key>`; for GitHub issues write `Closes #<n>`).
- Summary, test evidence (which tests, what you ran, screenshots for UI), risk and rollback.
- **Stacked PR** (base is not the default branch): put this at the very top of the body:

  ```
  ⚠️ Built on top of #<parent> (<KEY>: <title>). The diff shows only this PR's changes, so it can be reviewed now. **Do not merge** until #<parent> merges; then retarget this PR to <default branch>.

  ---
  ```

- Never open stacked PRs as drafts; open them ready for review so review can run in parallel.

Print the PR URL. (If `gh pr create` fails because GraphQL is unavailable, as in Claude Code on the web, create
it with `gh api repos/$(aw-config REPO_SLUG)/pulls -f title=... -f head=<branch> -f base=<default branch> -f body=...`.)

## 5. Self-review

- `gh pr diff` and read every changed file in full before judging anything.
- Load the `review-standards` skill and review through its lenses (correctness, type safety, OWASP, WCAG,
  tests, conventions, docs sync, performance) and classify findings 🔴 / 🟡 / 🔵.
- **Fix every 🔴 before posting**, in a follow-up commit, and list it as "Fixed prior to this comment".
- Post with `gh pr comment`:

  ```
  ## AI Pre-Review

  Self-review: checked the diff through every lens in the review-standards skill.

  ### Findings
  <emoji> `file:line` — one sentence
  _or_ ✅ Nothing found.

  ### Summary
  <1–2 sentences: ready for human review, or what blocks it>

  <ATTRIBUTION>
  ```

## 6. Ticket to Review

```bash
KEY=$(aw-tracker from-branch)
aw-tracker transition "$KEY" "$(aw-config STATUS_REVIEW)"
```

Skip with a warning on `chore/` branches or when tracker credentials are missing.

## 7. Comment on the ticket when it helps QA

Post one (`aw-tracker comment "$KEY" <file>`) for bug fixes, UI changes and behaviour
changes: the symptom, the root cause if not obvious, the fix, what QA should check, and the PR link.
Skip it for pure refactors, chores, or when the PR says everything already.

## 8. Offer to watch for reviews

With `--watch`, don't ask; otherwise ask: "Shall I watch for reviews and run `/address-review <n>`
once one arrives? I'll check every 2 minutes."

If yes, poll (ScheduleWakeup or /loop, 120 s) with a self-contained prompt that counts:

```bash
# formal reviews from humans or Copilot
gh api "repos/$(aw-config REPO_SLUG)/pulls/<n>/reviews" --paginate --jq 'length'
# human comments that aren't the agent's own
gh api "repos/$(aw-config REPO_SLUG)/issues/<n>/comments" --paginate | jq -s --arg a "Actioned by Claude Code" \
  '[.[][] | select(.user.type != "Bot") | select(.body | contains($a) | not)] | length'
```

When either is non-zero, run `/address-review <n>` and **stop watching** — that command re-requests
review, and watching on would loop forever. Otherwise check again in 120 s.

A failed step ends the run: report what failed and why. Gates are never forced or skipped.
