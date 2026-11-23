#!/usr/bin/env bash
# Shared helpers for the agentic workflow scripts. Source it, don't run it.
#   source "$(git rev-parse --show-toplevel)/scripts/agentic/lib.sh"

AW_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
export AW_ROOT

aw_die() { echo "error: $*" >&2; exit 1; }
aw_warn() { echo "warning: $*" >&2; }

# Parse a KEY=VALUE file without executing it. Lines that are blank or comments are skipped,
# surrounding quotes are stripped, and a variable that is already set in the environment wins.
aw_load_env_file() {
  local file="$1" line key value
  [ -f "$file" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
    [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]] || continue
    key="${BASH_REMATCH[2]}"
    value="${BASH_REMATCH[3]}"
    if [[ "$value" =~ ^\"(.*)\"[[:space:]]*(#.*)?$ ]]; then
      value="${BASH_REMATCH[1]}"
    elif [[ "$value" =~ ^\'(.*)\'[[:space:]]*(#.*)?$ ]]; then
      value="${BASH_REMATCH[1]}"
    else
      value="${value%%[[:space:]]#*}"
      value="${value%"${value##*[![:space:]]}"}"
    fi
    if [ -z "${!key+x}" ]; then
      printf -v "$key" '%s' "$value"
      export "${key?}"
    fi
  done < "$file"
}

aw_load_config() {
  aw_load_env_file "$AW_ROOT/.claude/workflow.env"
  aw_load_env_file "$AW_ROOT/.env"
  : "${DEFAULT_BRANCH:=main}"
  : "${PROTECTED_BRANCHES:=^(main|master|staging|production)$}"
  : "${TRACKER:=github}"
  : "${CI_PROVIDER:=github}"
  : "${ATTRIBUTION:=_Actioned by Claude Code_}"
  : "${STATUS_IN_PROGRESS:=In Progress}"
  : "${STATUS_REVIEW:=Review}"
  : "${STATUS_QA:=Ready for Testing}"
  : "${STATUS_DONE:=Done}"
}

aw_require() {
  local missing=() var
  for var in "$@"; do
    [ -n "${!var:-}" ] || missing+=("$var")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    aw_die "missing ${missing[*]} — set them in .env (see .env.workflow.example)"
  fi
}

aw_need_cmd() {
  local c
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || aw_die "'$c' is required but not installed"
  done
}

aw_current_branch() { git rev-parse --abbrev-ref HEAD 2>/dev/null; }

# Lower-case, hyphenated slug: "Ready for Testing" -> "ready-for-testing"
aw_slug() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'; }
