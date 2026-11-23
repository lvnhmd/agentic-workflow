---
description: Set this repository up for the agentic workflow — workflow config, verify steps, git hooks, docs skeleton, PR template, and the settings that enable this plugin for the whole team.
argument-hint: [--update]
---

Set up (or, with `--update`, refresh) the agentic workflow in this repository. **Arguments:** $ARGUMENTS

## 1. Look before asking

- `git rev-parse --show-toplevel` — must be a git repo; stop if not.
- `git status --porcelain` — if there are uncommitted changes, warn that init will add files next to
  them and suggest a fresh branch: `git checkout -b chore/agentic-workflow`.
- Detect what you can: GitHub remote (`git remote get-url origin`), default branch, CI
  (`.github/workflows/` or `.circleci/`), stack (`package.json` → node, `pyproject.toml` /
  `requirements.txt` → python), an existing `CLAUDE.md`, husky (`.husky/`).
- Dry run: `aw-init --dry-run -y <detected flags> .` and read what it would write, keep and merge.

## 2. Ask only what you couldn't detect

Use one AskUserQuestion with at most four questions, each with your detected value as the recommended option:
tracker (GitHub Issues or Jira; if Jira, the project key), CI provider, preset. Skip any you're sure of.

## 3. Run it

```bash
aw-init -y --tracker <jira|github> [--prefix <KEY>] --ci <github|circleci|none> --preset <node|python|generic> .
```

(With `--update`: `aw-init --update .`, no questions needed.)

## 4. Finish the setup

1. Show the summary aw-init printed (written / merged / kept).
2. Fill `.claude/verify-steps` from the real scripts (package.json scripts, Makefile, CI config) so it
   mirrors CI. Run `scripts/agentic/verify.sh --list` to confirm.
3. Draft the project sections of `CLAUDE.md` (overview, repo map, required reading, project rules,
   data boundaries) by reading the code and existing docs. If a `CLAUDE.md` existed before, merge into it
   rather than duplicating what it already says. Show the draft and ask before writing.
4. Run `aw-doctor --offline` and fix what it reports.
5. Tell the user what's left for them: credentials in `.env` (only the ones their tracker/CI needs),
   and committing the setup on its branch. Teammates get a prompt to install the plugin when they trust
   the folder, and run `git config core.hooksPath .githooks` once.
