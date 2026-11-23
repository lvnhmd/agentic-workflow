#!/usr/bin/env bash
# Set a repository up for the agentic-workflow plugin from a shell (same as /init inside Claude Code).
#   ./install.sh [options] <target-repo>      — see: ./install.sh --help
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/plugin/bin/aw-init" "$@"
