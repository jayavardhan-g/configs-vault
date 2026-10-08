# Noctalia theme-template application: gotchas found while trialing Wezterm

**Date:** 2026-09-20
**Category:** appearance
**Files touched:** none persisted (Wezterm was trialed as a Kitty replacement, then

<!-- graph:begin -->
**Graph:** [[Noctalia]] · [[kitty]]
<!-- graph:end -->

uninstalled — Kitty stays the default terminal; keeping this note only for the reusable
Noctalia lesson).

## What
Trialed adding a new app (Wezterm) to Noctalia's `[theme.templates] builtin_ids` in
`~/.config/noctalia/config.toml`. Decided against Wezterm and reverted everything (removed
the `builtin_ids` entry, uninstalled the package, deleted its config) — Kitty's GUI/cursor
polish (notably `cursor_trail`, which Wezterm has no equivalent for) won out. Keeping this
entry only because enabling a new template surfaced three real Noctalia behaviors worth
knowing before trying this again with any other app.

## Why
Adding `"wezterm"` to `builtin_ids` and running `noctalia msg templates-apply` silently did
nothing, twice, with no error at any log level — cost real time to diagnose. Recording the
cause so it isn't re-debugged from scratch next time a new template is enabled.

## Change
N/A — no live config from this trial is being kept. See `Notes` for the mechanics if you
enable a *different* built-in template in the future.

## Notes
- **A newly-added `builtin_ids` entry is not picked up by `noctalia msg config-reload`.**
  That command does trigger a visible internal reload (bar/idle-behavior counts get
  re-logged), but the template-application code path apparently caches the builtin id list
  at daemon startup. A full daemon restart is required:
  ```bash
  pkill -x noctalia
  nohup noctalia >/tmp/noctalia.log 2>&1 & disown
  ```
  (matches the `exec-once = noctalia &` line in `~/.config/mango/cfg/autostart.conf`).
  Already-enabled templates (e.g. Kitty, Alacritty) DO pick up `config-reload` +
  `templates-apply` fine — it's specifically a *new* id that needs the restart.
- **Noctalia silently skips a template if the target app isn't installed**, even after the
  above restart. Its binary contains the literal string `"skipping template {} -> {}
  (client not installed)"` — no error surfaces anywhere. Install the app first, then
  restart the daemon again, then `templates-apply`.
- **Even with the app installed, the Wezterm template's color-rendering step never fired**
  (`~/.config/wezterm/colors/Noctalia.toml` was never generated), while its `apply.sh` hook
  (inserting `config.color_scheme = "Noctalia"` into `wezterm.lua`) worked fine on its own
  when run directly. Kitty/Alacritty rendered correctly throughout. This looks like a bug
  specific to the Wezterm template in this Noctalia build (`noctalia`/`noctalia-greeter`
  packages, checked 2026-09-20) rather than a general template-system issue — worth
  re-testing if Noctalia gets updated, but not worth chasing further for now.
