# Personal vault moved into the shared `vaults` repo (sparse clone on the Study drive)

**Date:** 2026-10-14
**Category:** obsidian
**Files touched:** `~/.config/obsidian/obsidian.json` (vault path; copy in `obsidian/files/.config/obsidian/obsidian.json`); new clone `/mnt/study/vaults/`; old clones `~/notes` and `/mnt/study/Jay` removed

<!-- graph:begin -->
**Graph:** [[Obsidian]]
<!-- graph:end -->

## What
The personal vault no longer syncs through its own repo (`Obsidian-Vault-Jay`). It is now
the `personal/` folder of the shared `jayavardhan-g/vaults` repo (one folder per vault,
alongside `mtp/` and `projects/` from the GPU server), sparse-cloned at
`/mnt/study/vaults` so only `personal/` is checked out on this laptop.

## Why
One repo for every vault, synced with the same daily commands everywhere (the repo's
README). The clone sits on the NTFS Study partition, not `~/`, so Linux and Windows on
this dual-boot laptop open the *same* folder: one copy, nothing to conflict. Before this
there were two clones of the old repo here: `~/notes` (current) and `/mnt/study/Jay` (13
commits behind, only CRLF noise uncommitted).

## Change
```bash
cd /mnt/study
git clone --filter=blob:none --sparse https://github.com/jayavardhan-g/vaults.git vaults
cd vaults
git config core.autocrlf false     # shared with Windows: don't rewrite line endings
git config core.filemode false     # NTFS has no exec bit
git config user.name "Jayavardhan"; git config user.email "<email>"
git sparse-checkout set personal
mkdir personal && cp -a ~/notes/. personal/ && rm -rf personal/.git
git add . && git commit -m "personal: import vault from Obsidian-Vault-Jay (laptop)"
git pull --rebase --autostash && git push
```
Auth is HTTPS through `gh` (already logged in, credential helper set globally), not
the SSH key the repo README describes. Same reasoning as [[vault-setup-and-migration]].

Then retired the old clones and repointed Obsidian (it was closed while editing the JSON):
```bash
mv ~/notes ~/notes.old; mv /mnt/study/Jay /mnt/study/Jay.old
# ~/.config/obsidian/obsidian.json: the old ~/notes vault entry's "path" → "/mnt/study/vaults/personal"
```

Daily sync from now on (never `git add -A` / `commit -a`):
```bash
cd /mnt/study/vaults/personal
git add . && git commit -m "personal: update"
git pull --rebase --autostash && git push
```

## Notes
- Windows side: open `<Study drive>\vaults\personal` as the vault there (the old `Jay`
  folder is now `Jay.old`). Windows git will want
  `git config --global --add safe.directory <path>` once, since the folder is owned by
  the Linux uid.
- The repo's `.gitignore` drops `.obsidian/workspace*.json`, which ended the
  workspace.json churn the old repo had.
- `obsidian-git` is still in the vault. Inside a sparse clone it can only see `personal/`,
  so its commits stay scoped to this vault.
- The `~/notes.old` / `/mnt/study/Jay.old` backups were deleted the same day after checking `personal/` matched them. `Obsidian-Vault-Jay`
  on GitHub is untouched and no longer used.
- Stored vault-file copies moved from `obsidian/files/notes/` to
  `obsidian/files/mnt/study/vaults/personal/`.
