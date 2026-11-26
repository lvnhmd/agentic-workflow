---
name: review-standards
description: The project's PR review standard — conversation-history check, review lenses, 🔴/🟡/🔵 classification, verdict rules, comment format and the formal GitHub review. Load it before reviewing any PR, including self-review in /pr and /ship-chore, and when actioning review comments.
---

# PR Review Standards

These apply to **every AI-assisted review** on this repo, whichever command or tool runs it.

## Check the conversation history first

Read every earlier comment, review and reply on the PR before writing your own:

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments --paginate
gh api repos/{owner}/{repo}/issues/{pr}/comments --paginate
gh api repos/{owner}/{repo}/pulls/{pr}/reviews --paginate
```

Map every issue raised before as **pushed back on**, **accepted and addressed**, or **still open**.
**Never re-raise an issue the author pushed back on.** If you think the pushback was wrong, say so once
in the summary, not as a finding.

## Lenses

Correctness · type safety · security (OWASP Top 10) · accessibility (WCAG 2.2 AA, for UI) · test
coverage and assertion quality · conventions · docs sync · performance.

## Severity

- 🔴 **Blocking**: wrong behaviour, a security hole, an accessibility regression, a broken API or data contract
- 🟡 **Worth fixing**: weak tests, missing coverage, code that breaks house conventions
- 🔵 **Optional**: small polish the author may skip

Only 🔴 blocks approval.

## Verdict

| Situation                                                  | Verdict                                              |
| ---------------------------------------------------------- | ---------------------------------------------------- |
| No 🔴 findings                                             | **Approve**                                          |
| 🔴 findings, all previously pushed back on                 | **Approve** — list them in the summary for the human |
| New 🔴 findings that are genuine blockers                  | **Request changes**                                  |

When in doubt, approve and note; don't block. A review submitted from a human account counts as that
human's review, whatever tooling produced it. Only real bot accounts (`user.type == "Bot"`, or a login
containing `bot`/`copilot`) don't count toward approval.

## Comment format

```
