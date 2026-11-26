# agentic-workflow (plugin)

Runs software work from ticket to merged PR in Claude Code, inside deterministic guardrails.

- **Commands** for every stage: `/refine`, `/start`, `/capture`, `/push`, `/pr`, `/ship-chore`, `/review`,
  `/address-review`, `/fix-ci`, `/qa-feedback`, `/nightly-check`, `/dependabot-review`, `/morning`,
  `/main`, plus `/init` to set a repository up and `/doctor` to check the setup.
- **Agents**: `worker` (cheap grunt work), `advisor` (read-only second opinion), `adversary` (security
  adversary that leaves failing tests), `tdd-critic` (pokes holes in tests).
- **Hooks**: load the workflow contract at session start; block destructive commands and edits to
  immutable files; format every edit; remind once per change set to keep docs in sync.
- **Helpers on PATH**: `aw-tracker` (Jira or GitHub Issues), `aw-ci` (GitHub Actions or CircleCI),
  `aw-config`, `aw-doctor`, `aw-init`.

Per-repo settings live in `.claude/workflow.env`, written by `/init`. In repos without it, the hooks
only apply the destructive-command guard and the commands stay out of the way.

Setup, configuration and updates: see the README at the root of this repository.
