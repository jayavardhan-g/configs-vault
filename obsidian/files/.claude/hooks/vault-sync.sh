#!/usr/bin/env bash
# SessionStart hook: pull the Obsidian vault clones so a session starts from the latest notes.
# Prints one status line per clone; Claude Code adds stdout to the session's context.
# Never blocks the session: offline, auth or conflict problems are reported, not fatal.

export GIT_TERMINAL_PROMPT=0
read -ra clones <<< "${VAULT_SYNC_CLONES:-$HOME/claude/vaults /mnt/study/vaults}"
out=()

for repo in "${clones[@]}"; do
  [ -d "$repo/.git" ] || continue
  name="$repo"; [[ "$repo" == "$HOME"/* ]] && name="~${repo#"$HOME"}"
  if ! timeout 25 git -C "$repo" pull --rebase --autostash -q >/dev/null 2>&1; then
    if [ -d "$repo/.git/rebase-merge" ] || [ -d "$repo/.git/rebase-apply" ]; then
      git -C "$repo" rebase --abort >/dev/null 2>&1
      out+=("$name: pull hit a conflict and was aborted; resolve by hand before editing")
    else
      out+=("$name: pull failed (offline or GitHub error); working from local copy")
    fi
    continue
  fi
  ahead=$(git -C "$repo" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
  dirty=$(git -C "$repo" status --porcelain 2>/dev/null | grep -vc '^?? \.claude/$')
  line="$name: up to date ($(git -C "$repo" log -1 --format=%h))"
  [ "$ahead" -gt 0 ] && line+=", $ahead unpushed commit(s)"
  [ "$dirty" -gt 0 ] && line+=", $dirty uncommitted change(s)"
  out+=("$line")
done

if [ ${#out[@]} -gt 0 ]; then
  msg="${out[0]}"
  for l in "${out[@]:1}"; do msg+="; $l"; done
  printf 'Vault sync (SessionStart): %s\n' "$msg"
fi
exit 0
