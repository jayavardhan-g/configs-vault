# SSH TERM mismatch fix (kitty terminfo not on remote)

**Date:** 2026-08-28
**Category:** system
**Files touched:** `~/.ssh/config`

<!-- graph:begin -->
**Graph:** [[kitty]] · [[SSH]]
<!-- graph:end -->

## What
Added a `Host` entry in `~/.ssh/config` for the lab GPU server that forces
`TERM=xterm-256color` for that connection via `SetEnv`.

## Why
Local terminal is kitty, which sets `TERM=xterm-kitty`. The lab server doesn't have
kitty's terminfo entry installed, so `clear` failed with "unknown terminal type" and `vim`
dumped a full terminfo list before falling back to a default terminal. Overriding `TERM`
to a universally-available value sidesteps needing anything installed on the remote.

## Change
```
Host lab
    HostName <lab-server-ip>
    User <username>
    SetEnv TERM=xterm-256color
```
`chmod 600 ~/.ssh/config` after creating.

## Notes
- **[`files/.ssh/config`](files/.ssh/config)** is a real copy of the live file, but with
  `HostName`/`User` replaced by placeholders — those are this specific lab host's private
  IP and account, not part of the fix being documented (that's the `SetEnv` line).
- Requires OpenSSH client ≥8.7 for `SetEnv` (confirmed available here: `OpenSSH_10.5p1`).
- Trade-off: this flattens kitty-specific terminal features (undercurl, some
  keyboard-protocol niceties) — irrelevant for plain vim/tmux/shell use, so not a real
  downside for this use case.
- Alternative not taken, kept here in case kitty-specific features are ever needed: copy
  kitty's terminfo entry onto the remote instead of overriding `TERM`, which keeps full
  kitty features and needs no local config change:
  ```
  infocmp -x | ssh lab -- 'tic -x -o ~/.terminfo /dev/stdin'
  ```
  Run once per remote host from the local machine (needs write access to the remote home
  dir, not root). If done, the `SetEnv` line above can be removed.
