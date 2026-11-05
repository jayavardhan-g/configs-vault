#!/usr/bin/env bash
# Sync the Obsidian vault clones: a SessionStart hook, and also run by hand after a push.
# Prints one status line per clone; Claude Code adds stdout to the session's context.
# Never blocks the session: offline, auth or conflict problems are reported, not fatal.
#
# Safety: the clones can have uncommitted edits (Obsidian open on /mnt/study). Pulling
# with --autostash over an edited file that also changed upstream leaves conflict markers
# in that file, so in that case it only fetches and reports instead of pulling.

export GIT_TERMINAL_PROMPT=0
# One clone per vault repo, all on the study drive (~/claude/vaults is a symlink to it).
read -ra clones <<< "${VAULT_SYNC_CLONES:-/mnt/study/vaults/configs /mnt/study/vaults/projects /mnt/study/vaults/study /mnt/study/vaults/personal}"
out=()

# NUL-separated paths with uncommitted changes (tracked or untracked; both sides of renames)
dirty_paths() {
  git -C "$1" status --porcelain -z -uall 2>/dev/null | {
    rename=0
    while IFS= read -r -d '' e; do
      if [ "$rename" = 1 ]; then printf '%s\0' "$e"; rename=0; continue; fi
      printf '%s\0' "${e:3}"
      case "${e:0:1}" in R|C) rename=1 ;; esac
    done
  }
}

for repo in "${clones[@]}"; do
  [ -d "$repo/.git" ] || continue
  name="$repo"; [[ "$repo" == "$HOME"/* ]] && name="~${repo#"$HOME"}"

  conflicted=$(git -C "$repo" diff --name-only --diff-filter=U 2>/dev/null)
  if [ -n "$conflicted" ]; then
    out+=("$name: UNRESOLVED CONFLICT in $(echo "$conflicted" | paste -sd, -); not pulled; fix it before editing")
    continue
  fi
  if ! timeout 25 git -C "$repo" fetch -q >/dev/null 2>&1; then
    out+=("$name: fetch failed (offline or GitHub error); working from local copy")
    continue
  fi

  behind=$(git -C "$repo" rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)
  held=""
  if [ "$behind" -gt 0 ]; then
    overlap=$(comm -12 \
      <(dirty_paths "$repo" | tr '\0' '\n' | sort -u) \
      <(git -C "$repo" diff --name-only 'HEAD...@{u}' 2>/dev/null | sort -u))
    if [ -n "$overlap" ]; then
      held="$behind new commit(s) NOT pulled: uncommitted edits in $(echo "$overlap" | paste -sd, -) also changed upstream; commit or finish them, then pull"
    elif ! timeout 25 git -C "$repo" pull --rebase --autostash -q >/dev/null 2>&1; then
      if [ -d "$repo/.git/rebase-merge" ] || [ -d "$repo/.git/rebase-apply" ]; then
        git -C "$repo" rebase --abort >/dev/null 2>&1
        out+=("$name: pull hit a conflict with local commits and was aborted; resolve by hand before editing")
      else
        out+=("$name: pull failed; working from local copy")
      fi
      continue
    fi
  fi

  ahead=$(git -C "$repo" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
  dirty=$(dirty_paths "$repo" | tr '\0' '\n' | grep -v '^\.claude/' | grep -c .)
  if [ -n "$held" ]; then line="$name: $held"
  else line="$name: up to date ($(git -C "$repo" log -1 --format=%h))"; fi
  [ "$ahead" -gt 0 ] && line+=", $ahead unpushed commit(s)"
  [ "$dirty" -gt 0 ] && line+=", $dirty uncommitted change(s)"
  out+=("$line")
done

if [ ${#out[@]} -gt 0 ]; then
  msg="${out[0]}"
  for l in "${out[@]:1}"; do msg+="; $l"; done
  printf 'Vault sync: %s\n' "$msg"
fi
exit 0
