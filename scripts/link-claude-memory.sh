#!/usr/bin/env bash
# One-time switch: make Claude Code's memory dir a symlink into this vault's claude-memory/.
# Run from the main checkout (~/claude/configs) after the vault branch is on main:
#   bash scripts/link-claude-memory.sh
# Safe to re-run: does nothing once the symlink exists.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
target="$repo/claude-memory"
mem="$HOME/.claude/projects/-home-jayavardhan-claude/memory"

if [ -L "$mem" ]; then
    echo "already linked: $mem -> $(readlink "$mem")"
    exit 0
fi
case "$repo" in
    */.claude/worktrees/*) echo "run this from the main checkout, not a worktree ($repo)" >&2; exit 1 ;;
esac
[ -d "$target" ] || { echo "missing $target - is the vault branch merged and pulled?" >&2; exit 1; }
[ -d "$mem" ] || { echo "missing $mem" >&2; exit 1; }

# Memories written since the vault copy was taken win (cp -u: only if newer or missing).
cp -u "$mem"/*.md "$target"/
backup="$mem.bak-$(date +%Y%m%d-%H%M%S)"
mv "$mem" "$backup"
ln -s "$target" "$mem"
python3 "$repo/scripts/build-graph.py"

echo "linked: $mem -> $target"
echo "old dir kept at: $backup (delete it once a session has read memory fine)"
