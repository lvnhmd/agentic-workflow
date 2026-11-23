#!/usr/bin/env bash
# Decision records and the current-state docs must move together.
#
# docs/adr/ is history; docs/architecture/ is what is true today. When a branch adds or edits a
# decision record but leaves every architecture doc alone, the two drift, and the next reader has to
# replay the whole decision log to learn the present. This script fails that branch.
#
# Some decisions really have nothing to say about current state (a choice of tool, a process
# change). For those, put "[skip-adr-sync: <why>]" in any commit message on the branch. The
# reason then sits in history next to the decision.
set -euo pipefail

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
aw_load_config

base="${BASE_REF:-origin/$DEFAULT_BRANCH}"
say() { printf 'adr-sync: %s\n' "$*"; }

git rev-parse -q --verify "$base" >/dev/null || { say "no $base here, so nothing to compare with (fetch it to check)"; exit 0; }

# CI clones are often shallow. Without a merge base the comparison means nothing, so say so and pass.
if ! mb="$(git merge-base "$base" HEAD 2>/dev/null)"; then
  say "no common ancestor with $base in this clone (shallow fetch?); not checked"
  exit 0
fi

touched="$(git diff --name-only "$mb" HEAD)"
decisions="$(printf '%s\n' "$touched" | grep -E '^docs/adr/[^/]+\.md$' || true)"
current="$(printf '%s\n' "$touched" | grep -E '^docs/architecture/.+\.md$' || true)"

[ -n "$decisions" ] || { say "no decision records touched"; exit 0; }
[ -z "$current" ] || { say "decision records and architecture docs changed together"; exit 0; }

if git log --format=%B "$mb..HEAD" | grep -qiF '[skip-adr-sync'; then
  say "skipped by a [skip-adr-sync] note on this branch"
  exit 0
fi

{
  say "these decision records changed, but no file under docs/architecture/ did:"
  printf '%s\n' "$decisions" | while IFS= read -r f; do printf '    %s\n' "$f"; done
  echo "  Update the architecture doc the decision affects, in this branch."
  echo "  If it affects none, add '[skip-adr-sync: <why>]' to a commit message and run again."
} >&2
exit 1
