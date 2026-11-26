#!/usr/bin/env bash
# Stop hook: before the agent ends its turn with source changes, ask it (once) whether the docs
# still describe the code.
#
# A dirty working tree is normal mid-ticket, so "files changed" can't be the trigger on its own or
# the agent would never be allowed to stop. We fingerprint the list of changed source files and only
# speak up when that fingerprint is new. Changes under docs/ and to SESSION.md are how the agent
# answers, so they're left out of the fingerprint.

payload="$(cat 2>/dev/null || true)"

# If Claude Code is already continuing because of a Stop hook, let it stop. Without this, two
# reminder hooks can keep waking each other up.
case "$payload" in
  *'"stop_hook_active"'*true*) exit 0 ;;
esac

top="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -f "$top/.claude/workflow.env" ] || exit 0
gitdir="$(git rev-parse --absolute-git-dir 2>/dev/null)" || exit 0

src_ext='ts|tsx|js|jsx|mjs|cjs|py|go|rs|rb|java|kt|cs|php|swift|sh|sql|prisma|json|ya?ml|toml|html|css|scss|vue|svelte'

files="$(
  cd "$top" || exit 0
  { git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null; } \
    | grep -Ev '^(docs/|SESSION\.md$)' \
    | grep -E "\\.($src_ext)\$" \
    | LC_ALL=C sort -u
)"
[ -n "$files" ] || exit 0

stamp="$gitdir/agentic-workflow-docs-sync"   # not shared with any other hook's marker
fingerprint="$(printf '%s\n' "$files" | cksum | tr -d ' ')"
[ "$(cat "$stamp" 2>/dev/null)" = "$fingerprint" ] && exit 0
printf '%s' "$fingerprint" > "$stamp"

cat >&2 <<'MSG'
Docs check before you stop. Source files changed this turn. If the change alters behaviour or adds
a pattern, endpoint, setting or data flow, bring the matching docs/ pages and SESSION.md up to date
now, in the same change. If no doc is affected, say that in one line and finish.
MSG
exit 2
