# Claude sessions pull the vaults at start and push when done

**Date:** 2026-10-30
**Category:** obsidian
**Files touched:** `~/claude/.claude/settings.json` (new; copy in `obsidian/files/claude/.claude/settings.json`), `~/.claude/hooks/vault-sync.sh` (new; copy in `obsidian/files/.claude/hooks/vault-sync.sh`), `~/claude/CLAUDE.md`, `configs/CLAUDE.md`, `personal/CLAUDE.md`, repo root `README.md`

<!-- graph:begin -->
**Graph:** [[Obsidian]] · [[Claude Code]]
<!-- graph:end -->

## What
`~/claude/vaults` keeps all four vaults checked out (`configs`, `personal`, `mtp`,
`projects`) so every Claude Code session started in `~/claude` can read and edit them. A
SessionStart hook pulls that clone and `/mnt/study/vaults` at the start of each session,
and `~/claude/CLAUDE.md` tells Claude to commit and push any vault change before the
conversation ends, then pull `/mnt/study/vaults` so Obsidian sees it.

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
`~/.claude/hooks/vault-sync.sh` (full copy in `obsidian/files/.claude/hooks/`): for each of
`~/claude/vaults` and `/mnt/study/vaults` that exists, run
`timeout 25 git pull --rebase --autostash`; on a conflict run `git rebase --abort`; print
one "Vault sync" line (commit, unpushed commits, uncommitted changes, or the failure),
which Claude Code adds to the session context. Always exits 0. `chmod +x` it.

Push rule (in `~/claude/CLAUDE.md`, "Vaults: pull first, push when done"):
```bash
cd ~/claude/vaults/<vault> && git add . && git commit -m "<vault>: <what changed>"
git pull --rebase --autostash && git push
git -C /mnt/study/vaults pull --rebase --autostash   # if mounted
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
- Claude edits `personal` in `~/claude/vaults/personal`, not `/mnt/study`, so there is one
  working copy for Claude; Obsidian's copy on the Study drive catches up by `git pull`.
- This replaces the `configs`-only sparse checkout described in
  [[vaults-repo-migration]]. `~/claude/configs.old` (the pre-merge clone) was moved to the
  trash the same day after checking its history is inside `vaults`.
- GitHub returned "Internal Server Error" on pushes twice that day; a retry went through.
