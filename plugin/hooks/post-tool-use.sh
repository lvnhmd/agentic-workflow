#!/usr/bin/env bash
# PostToolUse hook (Write/Edit) — formats and lint-fixes the file Claude just touched, so style
# never shows up in diffs or reviews. Commands and file patterns come from .claude/workflow.env
# (FORMAT_FILE_CMD / LINT_FIX_FILE_CMD). Failures are silent: this hook never blocks the agent.
set -uo pipefail
# shellcheck source=../lib/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/lib.sh"
aw_load_config

FILE="$(jq -r '.tool_input.file_path // ""' 2>/dev/null)" || exit 0
[ -n "$FILE" ] && [ -f "$FILE" ] || exit 0

if [ -n "${FORMAT_FILE_CMD:-}" ] && [[ "$FILE" =~ ${FORMAT_FILE_REGEX:-.^} ]]; then
  bash -c "$FORMAT_FILE_CMD \"\$1\"" _ "$FILE" >/dev/null 2>&1 || true
fi
if [ -n "${LINT_FIX_FILE_CMD:-}" ] && [[ "$FILE" =~ ${LINT_FIX_FILE_REGEX:-.^} ]]; then
  bash -c "$LINT_FIX_FILE_CMD \"\$1\"" _ "$FILE" >/dev/null 2>&1 || true
fi

# .env.example changed: deployed environments probably need the same variable.
RE_ENV_EXAMPLE='\.env(\.[A-Za-z0-9_-]+)*\.example$'
if [[ "$FILE" =~ $RE_ENV_EXAMPLE ]]; then
  default_where="the configuration of each deployed environment (secrets manager, CI settings, config repo)"
  where="${DEPLOY_CONFIG_NOTE:-$default_where}"
  jq -nc --arg msg "ENV_SYNC: $FILE changed. If a runtime variable was added, removed or renamed, update $where in step with it and mention it in the PR's Risk and Rollback section. Developer-only tooling variables don't need this." \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $msg}}'
fi
exit 0
