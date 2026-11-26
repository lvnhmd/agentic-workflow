# agentic-workflow

**AI writes the code. Your guardrails decide what ships.**

My agentic development workflow for Claude Code, packaged as a plugin. It takes work from ticket to
merged pull request, with the coding agent working inside checks it can't argue with. People keep the
intent; the agent does the typing; seven independent layers sit between the two. I use it every day and
keep changing it as I learn, so treat it as a working setup rather than a finished framework.

[Install](#install) · [Configure](#configure) · [Extend](#extend-it-for-a-project)

```
Ticket → /refine → /start → test-first code → hooks + gates → /pr → review → /address-review → merge → /qa-feedback
```

## Install in 30 seconds

In Claude Code:

```
/plugin marketplace add lvnhmd/agentic-workflow
/plugin install agentic-workflow@agentic-workflow
```

Then open Claude Code in your repo and run:

```
/init
```

`/init` detects your GitHub repo, default branch, CI and stack, asks only what it can't detect, writes the
project files and finishes with `/doctor`. Commit the result on a branch and you're running. Needs `git`,
`jq`, `perl`, `curl` and a logged-in `gh`; full details are under [Install](#install).

## Seven layers between an agent and your main branch

Each layer catches what the one before it missed. None is trusted alone, and none can be skipped.

| # | Layer | Runs | Catches |
| - | ----- | ---- | ------- |
| 0 | **Contract** | every session | Intent and house rules, read before the agent touches anything. The only layer that guides rather than enforces |
| 1 | **Action guard** | before each command or write | `rm -rf`, force-pushes to protected branches, `--no-verify`, dropped tables. Holds with every permission prompt switched off |
| 2 | **Auto-format** | after each edit | Formatting and lint, so review is about substance |
| 3 | **Docs check** | before the agent stops | Code changed but docs untouched. Asks once, never loops |
| 4 | **Pre-commit** | `git commit` | Commits to protected branches, secrets, scratch files, lint on staged files |
| 5 | **Pre-push** | `git push` | Types, the full offline test suite, project gates |
| 6 | **CI** | every pull request | All of it again on a clean machine, where nobody can skip it |

The approach builds on Ridley's [Augmented Engineering for Grown-Ups](https://ridley.co/articles/2026/02/19/augmented-engineering-for-grown-ups/)
and [Implementing Augmented Engineering](https://ridley.co/articles/2026/02/19/implementing-augmented-engineering/):
deterministic quality gates, layered hooks, Swiss-cheese defence and end-to-end traceability.

## How it fits together

The **plugin** carries everything that's the same in every project and updates in one place. Each
**repo** keeps only what's its own, plus the few scripts that git hooks and CI must run without Claude.

| Lives in the plugin (`plugin/`) | Lives in each repo (written by `/init`) |
| ------------------------------- | --------------------------------------- |
| Workflow contract, loaded at session start | `CLAUDE.md` — project overview, repo map, what to read, project rules |
| 16 commands: `/refine` `/start` `/capture` `/push` `/pr` `/ship-chore` `/review` `/address-review` `/fix-ci` `/qa-feedback` `/nightly-check` `/dependabot-review` `/morning` `/main` `/init` `/doctor` | `.claude/workflow.env` — tracker, ticket prefix, CI, status names, formatters, app URL |
| Agents: `worker` (Haiku), `advisor` (Opus), `adversary` (security), `tdd-critic` | `.claude/verify-steps` — the local mirror of CI (fast tier on push, full before PR) |
| Skills: `review-standards`, `run`, `assign-epic` | `.claude/settings.json` — enables the plugin for the team, permission allow/deny lists |
| Hooks: block destructive commands, format each edit, docs-sync reminder, contract + setup warnings at start | `.githooks/` + `scripts/agentic/` — pre-commit / pre-push gates, `verify.sh`, ADR sync check |
| `aw-tracker` (Jira / GitHub Issues), `aw-ci` (GitHub Actions / CircleCI), `aw-config`, `aw-doctor`, `aw-init` on the agent's PATH | `docs/` skeleton (architecture, ADRs, standards, attack surface), PR template, `.mcp.json` |

## Install

Requirements: `git`, `jq`, `perl`, `curl`, `gh` (logged in). Works with the bash 3.2 that ships with macOS.

**1. Add the marketplace and install the plugin** (once per machine), in Claude Code:

```
/plugin marketplace add lvnhmd/agentic-workflow           # or a local clone's path, to try changes
/plugin install agentic-workflow@agentic-workflow
```

**2. Set up a repo**: open Claude Code in it and run `/init`. It detects the GitHub repo, default
branch, CI and stack, asks only what it can't detect, writes the project files, drafts the `CLAUDE.md`
project sections from the code, and finishes with `/doctor`. From a plain shell instead:

```bash
path/to/agentic-workflow/install.sh .                     # interactive, from a clone
path/to/agentic-workflow/install.sh -y --tracker jira --prefix ABC --ci circleci --preset node .
```

**3. Commit the setup on a branch.** Teammates who open the repo in Claude Code and trust the folder are
offered the plugin automatically (`.claude/settings.json` names the marketplace); they run
`git config core.hooksPath .githooks` once.

Run `/doctor` (or `aw-doctor` in a terminal) whenever something seems off. It checks tools, `gh` login,
git hooks, verify steps, `.env` hygiene, Jira login, **that your `STATUS_*` names exist in the Jira
project**, and CI access.

## Configure

`.claude/workflow.env` (committed, no secrets) — read by every command, hook and script:

| Setting | Purpose |
| ------- | ------- |
| `TRACKER`, `TICKET_PREFIX`, `JIRA_BOARD_ID` | Jira or GitHub Issues; bare numbers become `ABC-42` |
| `STATUS_IN_PROGRESS` / `_REVIEW` / `_QA` / `_DONE` | Your tracker's status names (GitHub: `status:*` labels; Done closes the issue) |
| `CI_PROVIDER` | `github`, `circleci` or `none` |
| `DEFAULT_BRANCH`, `PROTECTED_BRANCHES` | Used by hooks and commands |
| `FORMAT_FILE_CMD`/`_REGEX`, `LINT_FIX_FILE_CMD`/`_REGEX` | Run on each file the agent edits |
| `DEV_CMD`, `APP_URL`, `HEALTH_URL`, `TEST_USER_VAR`… | For the `run` skill |
| `DEPLOY_CONFIG_NOTE` | Where deployed env vars live; the agent is reminded when `.env.example` changes |
| `ATTRIBUTION` | Footer on everything the agent posts (default `_Actioned by Claude Code_`) |

Secrets go in the git-ignored `.env` (template: `.env.workflow.example`): `JIRA_BASE_URL`, `JIRA_EMAIL`,
`JIRA_API_TOKEN`, `JIRA_ACCOUNT_ID`, `QA_ASSIGNEE_QUERY`, `CIRCLECI_TOKEN`.

## Extend it for a project

- **Rules and reading list** → `CLAUDE.md`. **Security focus** → `docs/architecture/attack-surface.md`
  (the `adversary` agent reads it first).
- **More checks** → lines in `.claude/verify-steps`.
- **Project-specific commit/push checks** → executable `.githooks/pre-commit.local` /
  `.githooks/pre-push.local`; the managed hooks call them, and `--update` never touches them.
- **Domain commands and skills** → `.claude/commands/` and `.claude/skills/` in the repo, alongside the
  plugin's. Anything that only makes sense for one codebase belongs there, not in the plugin.
- **Existing husky setup** → `/init` leaves `core.hooksPath` alone and tells you; call
  `.githooks/pre-commit` and `.githooks/pre-push` from your husky hooks.

## Update

- **Plugin** (commands, agents, hooks, adapters): `/plugin marketplace update agentic-workflow`, then
  restart Claude Code. Every repo picks it up.
- **Repo files** (git hooks, `scripts/agentic/`): `/init --update` or `install.sh --update .`. Your
  `CLAUDE.md`, `workflow.env`, `verify-steps`, docs and PR template are never touched.
- **From 0.1** (the copy-in version): `--update` removes the old `@.claude/workflow-contract.md` import
  and lists the copied commands/agents/hooks you can now delete.

## Develop the kit

```bash
bash tests/run.sh      # 119 checks: manifests, installer, update/merge, every hook rule, session start,
                       # git hooks, verify, aw-config, aw-doctor, tracker and CI adapters (stubbed)
claude --plugin-dir ./plugin   # try local changes without reinstalling
```

`plugin/project-template/` mirrors what lands in a repo, except that top-level dotfiles are stored as
`dot-<name>` (`dot-claude/`, `dot-githooks/`...) so the kit never acts as a live config itself;
`aw-init` gives them their real names. Run the tests under macOS's bash 3.2 as well as a modern bash.

---

MIT licensed. © 2026 Elvin Ali.
