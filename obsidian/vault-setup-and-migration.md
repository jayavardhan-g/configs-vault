# Setting up Obsidian on CachyOS, migrating the existing vault

**Date:** 2026-09-20
**Category:** obsidian
**Files touched:** none tracked here — the vault itself lives in a separate git repo, `~/notes` (see Notes)

<!-- graph:begin -->
**Graph:** [[Obsidian]] · [[BitLocker]] · [[Windows]]
<!-- graph:end -->

## What
Installed Obsidian on CachyOS via the official `extra` repo package (not the AppImage
sitting in `~/Downloads`), and got the real, existing vault — previously only on a
BitLocker-encrypted Windows drive — onto the Linux side without duplicating it or losing
any in-flight work.

## Why
Wanted the same vault (notes, not just app config) usable from both OSes on this
dual-boot machine, the same way [[../zen-browser/windows-profile-migration]] did for the
browser. Unlike Zen's profiles, an Obsidian vault turned out to already have its own git
remote (`obsidian-git` community plugin auto-backs it up), which changes the right
approach — clone the repo rather than copy files across a BitLocker mount every session.

## Change

### 1. Install
```bash
sudo pacman -S obsidian   # extra/obsidian 1.13.7-2, official repo
```
Chosen over the AppImage in `~/Downloads` because: proper desktop integration, updates
via normal `pacman -Syu`, no FUSE dependency, and — unlike Zen's Flatpak — a native
unsandboxed package needs no permission grant to read files off mounted drives.

### 2. Find the real vault
There were *two* `.obsidian` folders reachable from mounted Windows drives:
`/mnt/desktop-c/Users/jayav/Documents/Obsidian Vault` (essentially empty — just the
auto-generated `Welcome.md`, no plugins, no `hotkeys.json` — clearly unused) and the real
one at `/mnt/nani-newvolume/Jay/` (real content: `BugBounty/`, `Code/`, `Dev/`, `IITB/`,
`Interviews/`, `Seminar/`, `Tools/`, real notes, an `attachments/` folder, and critically
a `.git` directory). Don't assume the first `.obsidian` folder found is the right one —
check for actual note content and a git remote before treating it as canonical.

### 3. Capture pending Windows-side work before cloning
The real vault's working tree had uncommitted changes when found. Diffing confirmed most
of the diff (`~/.obsidian.vimrc`, a plugin `manifest.json`, two CSS snippets) was pure
CRLF/LF line-ending noise (`git diff -w --stat` came back empty for those files) — not
real changes. The genuine content was 2 new notes (`IITB/MTP/ELLSA.md`, `To-do.md`) and 6
new attachment images, all untracked. Committed and pushed those from the Windows-mounted
copy *before* cloning on Linux, so nothing new got left behind:
```bash
cd "/mnt/nani-newvolume/Jay"
git add "IITB/MTP/ELLSA.md" "IITB/MTP/To-do.md" attachments/
git commit -m "IITB/MTP: add ELLSA and To-do notes with attachments"
git push
```
`workspace.json` (pure UI/session state — open tabs, pane layout) was deliberately left
uncommitted, same reasoning as never committing Zen's `prefs.js`.

### 4. Clone on Linux
```bash
git clone https://github.com/jayavardhan-g/Obsidian-Vault-Jay.git ~/notes
```
`~/notes` was chosen specifically to avoid the BitLocker-unlock dependency every
session — the vault is now on ext4/btrfs, not tied to `bit-unlock nani` at all. The
`obsidian-git` plugin (already installed in the vault's `community-plugins.json`) keeps
both OSes in sync via its own auto-commit/push going forward — no manual sync step needed
after this point, same self-syncing property `~/dotfiles` has for Zen's shortcuts file.

### 5. First-launch checklist (real GUI steps, can't be scripted)
- "Open folder as vault" → `~/notes`
- Obsidian shows a restricted-mode prompt on a fresh install — click "Turn on community
  plugins" so `obsidian-git`, `obsidian-vimrc-support`, `omnisearch`, `image-converter`,
  `obsidian-style-settings` (already listed as enabled in the vault's own config) actually
  activate
- Vim mode needed no manual toggle — `"vimMode": true` was already tracked in
  `.obsidian/app.json`, carried over automatically with the clone

## Notes
- **Vault files are not duplicated into this repo's `files/` tree.** Same reasoning as
  `~/dotfiles` for Zen's shortcuts file ([[../zen-browser/vim-style-keyboard-shortcuts]]) —
  the vault has its own dedicated repo
  (`https://github.com/jayavardhan-g/Obsidian-Vault-Jay`) that's the actual live source of
  truth, self-syncing via `obsidian-git`. Duplicating any of it here would just drift.
  This entry documents the *setup decisions*, not the vault content.
- The abandoned empty vault on `desktop-c` was left alone — not deleted, just not used.
- See [[vimrc-keybindings]] for everything done to `.obsidian/.obsidian.vimrc` after this
  point.
- **Superseded 2026-10-14:** the vault no longer lives in `~/notes` or syncs through
  `Obsidian-Vault-Jay`. It is now `personal/` in the shared `vaults` repo, sparse-cloned at
  `/mnt/study/vaults` for both OSes. See [[vaults-repo-migration]]. Steps 1, 2 and 5 above still apply.
