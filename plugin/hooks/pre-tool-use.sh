#!/usr/bin/env bash
# PreToolUse hook — deterministic pattern matching that stops catastrophic actions before they run.
# No LLM judgement: plain regexes against the command or file path, so it behaves the same every time.
#
# Input: Claude Code hook JSON on stdin ({tool_name, tool_input, ...}).
# Output: nothing (allow), or a permissionDecision of "deny" (blocked, reason shown to Claude)
#         or "ask" (the user gets a confirmation prompt).
# Test it: echo '{"tool_name":"Bash","tool_input":{"command":"git push -f origin main"}}' | bash this-file
set -uo pipefail
# shellcheck source=../lib/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/lib.sh"
aw_load_config

INPUT="$(cat)"
TOOL="$(jq -r '.tool_name // ""' <<<"$INPUT" 2>/dev/null)" || exit 0
PROTECTED_WORDS="$(printf '%s' "$PROTECTED_BRANCHES" | sed -E 's/^\^\(?//; s/\)?\$$//')"

decide() {
  jq -nc --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
  exit 0
}

# Regexes live in variables: bash 3.2 (macOS) mis-parses some of them written inline after =~.
RE_RM='rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*|-r[[:space:]]+-f|-f[[:space:]]+-r|--recursive[[:space:]]+--force|--force[[:space:]]+--recursive)[[:space:]]+((/|~/?|\./?|\.\./?|\$HOME/?)\*?|\*)([[:space:]]|$)'
RE_PUSH='git[[:space:]]+push'
RE_FORCE='(--force|--force-with-lease|[[:space:]]-f([[:space:]]|$)|[[:space:]]\+[A-Za-z0-9_])'
RE_PROTECTED_REF="(^|[[:space:]:/+])(${PROTECTED_WORDS})([[:space:]]|$)"
RE_DIRECT_PUSH="git[[:space:]]+push[[:space:]]+[^[:space:]-][^[:space:]]*[[:space:]]+(HEAD:)?(${PROTECTED_WORDS})([[:space:]]|$)"
# -n only counts in the leading flag cluster (git commit -n / -an / -nm), not inside a -m message.
RE_NO_VERIFY='(--no-verify|git[[:space:]]+commit([[:space:]]+-[^[:space:]n]*)*[[:space:]]+-[a-zA-Z]*n[a-zA-Z]*([[:space:]]|$))'
RE_RESET='git[[:space:]]+reset[[:space:]]+(.*[[:space:]])?--hard'
RE_DISCARD='git[[:space:]]+(clean[[:space:]]+-[a-zA-Z]*f|checkout[[:space:]]+(--[[:space:]]+)?\.([[:space:]]|$)|restore[[:space:]]+(.*[[:space:]])?\.([[:space:]]|$))'
RE_BRANCH_D='git[[:space:]]+branch[[:space:]]+(.*[[:space:]])?(-D|--delete[[:space:]]+--force|--force[[:space:]]+--delete)'
RE_SCHEMA_PUSH='(prisma[[:space:]]+db[[:space:]]+push|db:push|drizzle-kit[[:space:]]+push|schema:sync)'
RE_DROP='([Dd][Rr][Oo][Pp][[:space:]]+([Tt][Aa][Bb][Ll][Ee]|[Dd][Aa][Tt][Aa][Bb][Aa][Ss][Ee]|[Ss][Cc][Hh][Ee][Mm][Aa])|[Tt][Rr][Uu][Nn][Cc][Aa][Tt][Ee][[:space:]]+([Tt][Aa][Bb][Ll][Ee][[:space:]]+)?[A-Za-z_"`])'
RE_SUDO='(^|[;&|[:space:]])sudo[[:space:]]'
RE_CURL_SH='(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z)?sh([[:space:]]|$)'
RE_CAT_ENV='(cat|less|more|head|tail|bat|nl)[[:space:]]+([^|;&]*[[:space:]/])?\.env([[:space:]]|$)'

check_bash() {
  local c="$1"

  # Recursive delete of root, home, the repo root, the parent, or a bare glob.
  if [[ "$c" =~ $RE_RM ]]; then
    decide deny "BLOCKED: recursive delete on a sensitive path. Delete specific paths instead, or ask the user to do it."
  fi

  # Force push: hard block on protected branches, confirm elsewhere.
  if [[ "$c" =~ $RE_PUSH ]] && [[ "$c" =~ $RE_FORCE ]]; then
    if [[ "$c" =~ $RE_PROTECTED_REF ]]; then
      decide deny "BLOCKED: force push to a protected branch."
    fi
    decide ask "Force push detected. Confirm this is intentional."
  fi

  # Plain push straight to a protected branch (work should land through a PR).
  if [[ "$c" =~ $RE_DIRECT_PUSH ]]; then
    decide ask "Pushing directly to a protected branch. Work should land through a PR — confirm this is intentional."
  fi

  if [[ "$c" =~ $RE_NO_VERIFY ]]; then
    decide ask "--no-verify bypasses the quality gates. Only proceed with the user's explicit approval."
  fi

  if [[ "$c" =~ $RE_RESET ]]; then
    decide ask "git reset --hard discards uncommitted work. Confirm this is intentional."
  fi

  if [[ "$c" =~ $RE_DISCARD ]]; then
    decide ask "This discards changes across the whole working tree, which may include other agents' work. Restore specific files instead, or confirm."
  fi

  if [[ "$c" =~ $RE_BRANCH_D ]]; then
    decide ask "Force-deleting a branch. Confirm this is intentional."
  fi

  # Schema changes must travel with a migration.
  if [[ "$c" =~ $RE_SCHEMA_PUSH ]]; then
    decide deny "BLOCKED: schema push without a migration. Generate and commit a migration instead."
  fi

  if [[ "$c" =~ $RE_DROP ]]; then
    decide deny "BLOCKED: DROP/TRUNCATE is destructive and irreversible. Ask the user to run it themselves."
  fi

  if [[ "$c" =~ $RE_SUDO ]]; then
    decide deny "BLOCKED: never run commands with sudo from the agent."
  fi

  # Piping a remote script straight into a shell.
  if [[ "$c" =~ $RE_CURL_SH ]]; then
    decide ask "Piping a downloaded script into a shell. Confirm the source is trusted."
  fi

  # Printing secrets into the transcript.
  if [[ "$c" =~ $RE_CAT_ENV ]]; then
    decide ask "This prints .env (secrets) into the conversation. Check for the one variable you need instead, e.g. grep -c '^KEY=' .env."
  fi
}

RE_ENV_FILE='(^|/)\.env(\.[A-Za-z0-9_-]+)?$'
RE_CI_FILE='(^|/)(\.github/workflows/|\.circleci/|\.gitlab-ci\.ya?ml$|Jenkinsfile$|azure-pipelines\.ya?ml$|bitbucket-pipelines\.ya?ml$)'
RE_MIGRATION='(^|/)migrations?/'
RE_ADR='(^|/)docs/adr/ADR-[0-9]+'

check_file() {
  local f="$1"
  if [[ "$f" =~ $RE_ENV_FILE ]] && [[ "$f" != *.example ]]; then
    decide ask "Writing to an env file ($f). Confirm it won't commit secrets."
  fi
  if [[ "$f" =~ $RE_CI_FILE ]]; then
    decide ask "Modifying the CI/CD pipeline ($f). Confirm this is intentional."
  fi
  if [[ "$f" =~ $RE_MIGRATION ]] && [ -f "$f" ]; then
    decide ask "Editing an existing migration ($f). Applied migrations are immutable — create a new one unless this migration has never run anywhere."
  fi
  if [[ "$f" =~ $RE_ADR ]] && [ -f "$f" ]; then
    decide ask "Editing an existing ADR ($f). Accepted ADRs are immutable: only the status line may change (Superseded by ...). Write a new ADR for a new decision."
  fi
}

case "$TOOL" in
  Bash) check_bash "$(jq -r '.tool_input.command // ""' <<<"$INPUT")" ;;
  Write|Edit|MultiEdit|NotebookEdit) check_file "$(jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' <<<"$INPUT")" ;;
esac
exit 0
