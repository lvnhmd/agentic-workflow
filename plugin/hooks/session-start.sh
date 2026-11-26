#!/usr/bin/env bash
# SessionStart hook — loads the workflow contract into the session and flags setup problems early.
#
# In a repo initialised for the workflow (.claude/workflow.env exists), a compact brief (config,
# warnings, the absolute rules, helper names) becomes additionalContext. In any other git repo, a single
# line saying the workflow is available. Fast and offline: no network calls (that's aw-doctor's job).
set -uo pipefail
PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/lib.sh
source "$PLUGIN_ROOT/lib/lib.sh"

emit() { jq -nc --arg c "$1" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'; exit 0; }

git rev-parse --git-dir >/dev/null 2>&1 || exit 0
if [ ! -f "$AW_ROOT/.claude/workflow.env" ]; then
  emit "The agentic-workflow plugin is enabled, but this repository is not set up for it (no .claude/workflow.env). If the user wants the ticket-to-PR workflow here, suggest /init. Until then, ignore the workflow's commands."
fi

aw_load_config
warnings=()
grep -q '{{[A-Z_]*}}' "$AW_ROOT/.claude/workflow.env" && warnings+=("workflow.env still has unfilled {{PLACEHOLDERS}}")
hooks_path="$(git config --get core.hooksPath || true)"
if [ -d "$AW_ROOT/.husky" ]; then
  [ "$hooks_path" = ".husky" ] || [ "$hooks_path" = ".githooks" ] ||
    warnings+=("husky git hooks are not active in this clone — run npm install (its prepare script enables them)")
elif [ -d "$AW_ROOT/.githooks" ] && [ "$hooks_path" != ".githooks" ]; then
  warnings+=("git hooks are not enabled in this clone — run: git config core.hooksPath .githooks")
fi
[ -x "$AW_ROOT/scripts/agentic/verify.sh" ] || warnings+=("scripts/agentic/verify.sh is missing — run aw-init --update")
if [ "$TRACKER" = jira ] && { [ -z "${JIRA_BASE_URL:-}" ] || [ -z "${JIRA_API_TOKEN:-}" ] || [ -z "${JIRA_EMAIL:-}" ]; }; then
  warnings+=("Jira credentials are missing from .env, so tracker commands will fail until they are added")
fi
[ "$CI_PROVIDER" = circleci ] && [ -z "${CIRCLECI_TOKEN:-}" ] && warnings+=("CIRCLECI_TOKEN is missing from .env")
if [ -f "$AW_ROOT/CLAUDE.md" ] && grep -q '<!-- What the product is' "$AW_ROOT/CLAUDE.md"; then
  warnings+=("CLAUDE.md project sections are still the template's placeholders — offer to draft them")
fi

# Claude Code shows only the first ~2 KB of a SessionStart hook's context, so this stays a compact
# brief; the full contract is the workflow-contract skill, which every lifecycle command loads.
brief="This repo uses the agentic-workflow plugin (config: .claude/workflow.env — tracker=$TRACKER${TICKET_PREFIX:+ prefix=$TICKET_PREFIX}, ci=$CI_PROVIDER, default branch=$DEFAULT_BRANCH)."
if [ "${#warnings[@]}" -gt 0 ]; then
  brief="$brief"$'\n'"Setup warnings — mention once, briefly; /doctor checks everything:"
  for w in "${warnings[@]}"; do brief="$brief"$'\n'"- $w"; done
fi
brief="$brief"$'\n'"Before any ticket, code, PR or review work, load the workflow-contract skill (full rules). Non-negotiable even before that:
- No feature/fix work without a ticket; branch per ticket; never commit to protected branches or bypass hooks (--no-verify).
- Docs lead, code follows: read CLAUDE.md's required context first; flag any deviation; update docs in the same PR.
- Test first. Run scripts/agentic/verify.sh before every PR.
- SESSION.md is a local scratchpad: never commit it.
- Schema changes ship with a migration; applied migrations and accepted ADRs are immutable.
- Check a ticket's assignee before updating it; end everything you post externally with: $ATTRIBUTION
- No secrets in code, logs or git; never print .env.
Helpers on PATH: aw-tracker (tickets), aw-ci (CI runs/logs), aw-config <KEY>, aw-doctor. Commands: /refine /start /capture /pr /review /address-review /fix-ci /qa-feedback /morning (also as /agentic-workflow:<name>). Agents: agentic-workflow:worker, :advisor, :adversary, :tdd-critic."

emit "$brief"
