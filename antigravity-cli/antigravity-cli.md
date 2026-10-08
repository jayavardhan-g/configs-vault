# Antigravity CLI (`agy`)

**Date:** 2026-09-30
**Category:** antigravity-cli
**Files touched:** `~/.local/bin/agy` (binary); installer appended a PATH line to `~/.bashrc`, `~/.zshrc`, `~/.bash_profile`, `~/.config/fish/config.fish` (fish one removed, see Notes). Login/settings live in `~/.gemini/antigravity-cli/` — never copy it here.
Stored copies of the three changed shell profiles: `antigravity-cli/files/.bashrc`, `files/.zshrc`, `files/.bash_profile` (`config.fish` ended up unchanged).

## What
Installed Google's Antigravity CLI (`agy`) for quick terminal Q&A and small one-off
tasks. Claude Code stays the tool for real work.

## Why
Wanted a lightweight assistant for simple questions. Gemini CLI was the first pick, but
Google retired it on 2026-06-18 — it no longer serves free/AI Pro/Ultra personal
accounts. Antigravity CLI is its official successor (closed-source Go binary).

## Change
```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
```
Official installer: downloads the binary, SHA512-verifies it, puts it at
`~/.local/bin/agy`, then runs `agy install` to add PATH lines to shell profiles. No sudo.
Self-updates in the background (or `agy update`).

First run: `agy` → opens the browser for Google login; token is kept in the OS keyring
(Secret Service).

Usage:
```bash
agy                        # interactive session
agy -p "your question"     # one-shot answer, prints and exits
agy -c                     # continue the last conversation
```

## Notes
- **Gemini CLI is dead for personal accounts** — don't install `gemini-cli` from the
  repos (it's still packaged in `extra`, but can't log in anymore). It was briefly
  installed this same day and then removed with `sudo pacman -Rns gemini-cli`.
- **Chose the official script over AUR `antigravity-cli`**: the AUR package is the same
  Google binary repackaged into `/usr/bin`, which means manual `makepkg` rebuilds for
  every update (no AUR helper here) and breaks self-update.
- The installer appends `# Added by Antigravity CLI installer` + a PATH export to every
  shell profile. In fish that's redundant (`fish_user_paths` already holds
  `~/.local/bin`, so it ended up in `$PATH` twice) — removed from `config.fish`. The
  bash/zsh lines were left in place (harmless).
- Needs a CPU with AES-NI (this one has it) — x86_64 builds exit with an error without it.
- `~/.gemini/` also still holds the old Gemini CLI login files (`oauth_creds.json` etc.);
  harmless leftovers, safe to delete, but don't delete `~/.gemini/antigravity-cli/`.
- Uninstall: `rm ~/.local/bin/agy`, remove the installer's lines from shell profiles.
