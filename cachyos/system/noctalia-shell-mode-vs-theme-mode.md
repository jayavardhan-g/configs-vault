# Noctalia shell chrome shifting to light mode

**Date:** 2026-09-15
**Category:** system
**Files touched:** `~/.config/noctalia/config.toml`

<!-- graph:begin -->
**Graph:** [[Noctalia]]
<!-- graph:end -->

## What
Noctalia's bar/panels/launcher (its own UI chrome) would sometimes turn light while
everything else stayed dark, especially noticeable around wallpaper changes. Fixed by
pinning a second, separate mode setting (`shell_mode`) to `"dark"` - not the same field
as `theme.mode`, which was already correctly pinned.

## Why
`[theme] mode = "dark"` controls the app-wide/template palette (GTK, Qt, kitty, btop,
etc. via `theme.templates`). It does **not** control Noctalia's own shell UI - that's a
separate `shell_mode` field (`follow | dark | light | auto`), which wasn't set in
`config.toml` at all and had drifted to `"follow"` in the live persisted state
(`~/.local/state/noctalia/settings.toml`) - "follow" tracks some other signal
independently of `theme.mode`, which is exactly why only the shell chrome flipped while
apps stayed dark, and why it looked wallpaper-related without actually being tied to
`source = "wallpaper"`/`wallpaper_scheme` at all.

Confirmed via `noctalia msg theme-mode-get` (always reported `dark`, i.e. `theme.mode`
was never the problem) and directly reading `~/.local/state/noctalia/settings.toml`,
which showed `shell_mode = "follow"` sitting right next to a correctly-set
`mode = "dark"` on the same `[theme]` block - two independent fields, easy to miss since
only one of them appears by default in `config.toml`.

## Change
`~/.config/noctalia/config.toml`:
```toml
[theme]
mode = "dark"
shell_mode = "dark"
source = "wallpaper"
wallpaper_scheme = "m3-tonal-spot"
```
The actual fix was applied live via Noctalia's own Settings UI (Theme section - the
"shell theme mode" control), which persists straight to
`~/.local/state/noctalia/settings.toml`, not `config.toml`. Added `shell_mode = "dark"`
to `config.toml` too so a fresh install pins both fields from the start rather than
depending on remembering this UI toggle.

## Notes
- **`config.toml` vs `settings.toml`**: `~/.config/noctalia/config.toml` is the
  user-facing declarative file (and what's tracked in this repo); the actual live state
  Noctalia reads/writes at runtime is `~/.local/state/noctalia/settings.toml`, which the
  Settings UI and `noctalia msg theme-mode-set`/`color-scheme-set` write to directly. The
  two can drift - confirmed live: `settings.toml`'s `wallpaper_scheme` had already moved
  to `m3-fruit-salad` while `config.toml` still said `m3-tonal-spot`, unrelated to this
  bug but same root cause (one file is declarative intent, the other is what's actually
  running) - not fixed here since the user didn't report that half as a problem.
- `noctalia msg theme-mode-get`/`theme-mode-set <mode>`/`theme-mode-toggle` exist as CLI/
  IPC commands for the app-wide `mode`; no equivalent `shell-mode-*` command was found in
  `noctalia msg --help` - the Settings UI (or hand-editing `settings.toml`/`config.toml`)
  is the only way to change `shell_mode` directly.
- A closed upstream bug,
  [noctalia-dev/noctalia-shell#2459](https://github.com/noctalia-dev/noctalia-shell/issues/2459)
  ("dark mode schedule toggles the active state instead of setting it"), describes a
  similar-sounding flip-to-light symptom tied to a day/night schedule - not what was
  actually happening here (no `[location]`/schedule config exists on this machine at
  all), but worth knowing about if this recurs in a different shape after a future
  Noctalia update.
