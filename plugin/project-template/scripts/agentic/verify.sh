#!/usr/bin/env bash
# verify.sh — "CI on your laptop". Runs the steps in .claude/verify-steps in order and stops at
# the first failure. The agent must run the full suite before opening any PR.
#
#   scripts/agentic/verify.sh          all steps (fast + full) — before a PR
#   scripts/agentic/verify.sh --fast   fast steps only — used by the pre-push hook
#   scripts/agentic/verify.sh --list   print the steps without running them
set -uo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
aw_load_config
cd "$AW_ROOT" || exit 1

MODE="full"
case "${1:-}" in
  --fast) MODE="fast" ;;
  --list) MODE="list" ;;
  "") ;;
  *) echo "usage: $0 [--fast|--list]" >&2; exit 2 ;;
esac

STEPS_FILE="$AW_ROOT/.claude/verify-steps"
[ -f "$STEPS_FILE" ] || aw_die "$STEPS_FILE not found"

n=0; total=0; failed=0
labels=(); commands=()
while IFS= read -r line || [ -n "$line" ]; do
  [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
  tier="$(echo "${line%%|*}" | xargs)"
  rest="${line#*|}"
  label="$(echo "${rest%%|*}" | xargs)"
  command="${rest#*|}"; command="${command#"${command%%[![:space:]]*}"}"
  [ "$MODE" = "fast" ] && [ "$tier" != "fast" ] && continue
  labels+=("[$tier] $label"); commands+=("$command")
done < "$STEPS_FILE"
total="${#labels[@]}"

if [ "$total" -eq 0 ]; then
  echo "No verification steps configured in .claude/verify-steps — add your lint/test/build commands."
  exit 1
fi

if [ "$MODE" = "list" ]; then
  for ((i = 0; i < total; i++)); do echo "${labels[$i]}: ${commands[$i]}"; done
  exit 0
fi

start=$(date +%s)
for ((i = 0; i < total; i++)); do
  n=$((i + 1))
  echo ""
  echo "=== [$n/$total] ${labels[$i]} ==="
  echo "\$ ${commands[$i]}"
  if ! bash -c "${commands[$i]}"; then
    failed=1
    echo ""
    echo "FAILED: ${labels[$i]}"
    echo "Fix the problem and re-run. Do not skip or weaken the step."
    break
  fi
done

echo ""
if [ "$failed" -eq 0 ]; then
  echo "=== All $total checks passed ($(( $(date +%s) - start ))s) ==="
else
  exit 1
fi
