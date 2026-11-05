# Claude sessions pull the vaults at start and push when done

**Date:** 2026-10-30
**Category:** obsidian
**Files touched:** `~/claude/.claude/settings.json` (new; copy in `obsidian/files/claude/.claude/settings.json`), `~/.claude/hooks/vault-sync.sh` (new; copy in `obsidian/files/.claude/hooks/vault-sync.sh`), `~/claude/CLAUDE.md`, `configs/CLAUDE.md`, `personal/CLAUDE.md`, repo root `README.md`

<!-- graph:begin -->
**Graph:** [[Obsidian]] · [[Claude Code]]
<!-- graph:end -->

## What
Every vault is its own repo, cloned once on the study drive: `/mnt/study/vaults/{configs,
study,projects,personal}` (`~/claude/vaults` is a symlink to it), and Obsidian opens the
same clones. A SessionStart hook pulls each clone at the start of every session started in
`~/claude`, and `~/claude/CLAUDE.md` tells Claude to commit and push any vault change before
the conversation ends.

## Why
Jayavardhan wanted Claude to always have access to the vaults, and to pull before starting
something new and push work when finished, so the copies (this laptop's two clones, the
GPU server's, GitHub) don't drift or conflict. The pull is a hook, so it doesn't depend on
Claude remembering; the push stays an instruction, because only Claude knows when a change
is finished and what the commit message should say.

## Change
`~/claude/.claude/settings.json`:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/vault-sync.sh",
            "timeout": 60,
            "statusMessage": "Pulling Obsidian vaults..."
          }
        ]
      }
    ]
  }
}
```
`~/.claude/hooks/vault-sync.sh` (full copy in `obsidian/files/.claude/hooks/`), for each of
`/mnt/study/vaults/configs`, `/mnt/study/vaults/projects`, `/mnt/study/vaults/study` and
`/mnt/study/vaults/personal` that exists (the default of `VAULT_SYNC_CLONES`):
1. If it has an unresolved conflict, report it and don't touch it.
2. `timeout 25 git fetch`; on failure report "offline".
3. If behind: compare the files with uncommitted edits (tracked and untracked) with the
   files changed upstream. If any overlap, **don't pull**: report the held notes. Otherwise
   `git pull --rebase --autostash`; if that rebase conflicts with local commits,
   `git rebase --abort` and report.
4. Print one "Vault sync" line per clone (commit, held notes, unpushed commits,
   uncommitted changes); Claude Code adds it to the session context. Always exits 0.
`chmod +x` it.

Push rule (in `~/claude/CLAUDE.md`, "Vaults: pull first, push when done"):
```bash
cd ~/claude/vaults/<clone>
git add <the files you changed>    # never . / -A / -a: Obsidian edits share this clone
git commit -m "<vault>: <what changed>"
~/.claude/hooks/vault-sync.sh      # pulls safely; reports a held note instead of forcing
git push
```

## Notes
- The hook was tested on throwaway repos: a conflicting pull is aborted cleanly (branch
  left diverged, no rebase in progress), an unreachable remote is reported, and
  uncommitted changes are counted. `VAULT_SYNC_CLONES="<dir> <dir>"` overrides the clone
  list for such tests.
- `compact` is left out of the matcher: compaction continues the same session.
- `configs/.gitignore` ignores every `.claude/` path, so the two stored copies under
  `obsidian/files/…/.claude/` were added with `git add -f`. Once tracked, re-copies are
  picked up by a normal `git add .`.
- `~/claude` is not a git repo, so `settings.json` there is plain project settings.
- Superseded 2026-11-05: Claude used to edit in `~/claude/vaults` (one clone of the shared
  `jayavardhan-g/vaults` repo, all four vaults) while Obsidian opened a second clone at
  `/mnt/study/vaults`, and the push rule used `git add .`. The vaults are now separate
  repos with one clone each that Claude and Obsidian share (see [[vaults-repo-migration]]),
  so Claude stages only its own files.
- This replaces the `configs`-only sparse checkout described in
  [[vaults-repo-migration]]. `~/claude/configs.old` (the pre-merge clone) was moved to the
  trash the same day after checking its history is inside `vaults`.
- GitHub returned "Internal Server Error" on pushes twice that day; a retry went through.
- 2026-10-31: the first version pulled every clone with `--autostash`. Jayavardhan had an
  uncommitted edit to `KMP.md` open in Obsidian while a session pushed a change to the
  same note; the pull in `/mnt/study/vaults` left conflict markers in his file (his edit
  was safe in the autostash). Fixed by merging both versions by hand, and the script now
  holds back a pull whose incoming changes touch an edited file. Tested: same-file edit
  (held, file untouched, no stash), different-file edit (pulled, edit kept), leftover
  conflict, offline, conflicting local commit.
