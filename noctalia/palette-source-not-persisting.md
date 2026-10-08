# Wallpaper-based palette source doesn't persist across restarts

**Date:** 2026-09-20
**Category:** noctalia
**Files touched:** `~/.local/state/noctalia/settings.toml`

<!-- graph:begin -->
**Graph:** [[Noctalia]]
<!-- graph:end -->

## What
Setting the color-palette source to "wallpaper" (Material You-style generation from the current wallpaper) kept silently reverting to the "builtin" palette. Root cause: the live state (`noctalia msg color-scheme-get`) correctly showed `wallpaper`, but the on-disk `~/.local/state/noctalia/settings.toml` never actually had a `source` key under `[theme]` — only `builtin`, `community_palette`, `mode`, `shell_mode`, and `wallpaper_scheme` were being persisted. Since `source` only ever lived in memory, it fell back to the persisted default (`builtin`) whenever the Noctalia shell process restarted (login, logout, compositor restart).

Wallpaper rotation itself (manual or via `wallpaper.automation.enabled = true`) is **not** the cause — confirmed by running `noctalia msg wallpaper-next` / `wallpaper-set` repeatedly while `color-scheme-get` stayed on `wallpaper` throughout.

## Why
Jayavardhan set the palette source to wallpaper-based via the Settings UI, but it kept showing up as `builtin` again later. He suspected a keyring/auth issue. Log inspection (`~/.cache/noctalia/noctalia.log`) showed no keyring or polkit failures at all — the only polkit action tied to appearance (`org.noctalia.greeter.sync-appearance`, which syncs theme to the login greeter) never even fired, ruling that out. Comparing the live state (`noctalia msg color-scheme-get`, `noctalia config export`) against the raw on-disk settings.toml showed the `source` key was simply missing from the persisted file — a persistence gap, not an auth failure.

## Change
Explicitly persist the palette source via the CLI instead of relying on whatever UI path was used before (which wasn't writing `source` to disk):

```sh
noctalia msg color-scheme-set wallpaper <scheme-name>
# e.g.
noctalia msg color-scheme-set wallpaper m3-fruit-salad
```

This writes a `source = "wallpaper"` line into `[theme]` in `~/.local/state/noctalia/settings.toml`, alongside the existing `wallpaper_scheme` key — confirmed to actually land on disk (unlike the state before this fix). Full current file mirrored at `files/.local/state/noctalia/settings.toml` in this folder.

Useful companion commands found along the way:
- `noctalia msg color-scheme-get` — prints the live active source + name (`builtin|wallpaper|community|custom`).
- `noctalia config export` — dumps the full *live* config as TOML; diffing this against the raw on-disk settings.toml is how this persistence gap was caught.

## Notes
- This is a Noctalia behavior, not Hyprland/CachyOS-specific — Noctalia is a cross-compositor shell (Niri, Hyprland, Sway, Mango, Labwc, etc.), so this entry belongs here rather than in `cachyos/`.
- As of this entry the machine is running the **Mango** compositor + Noctalia shell (`XDG_CURRENT_DESKTOP=mango`; see `~/noctalia-backup-pre-mango-20260913`, suggesting a migration off Hyprland around 2026-09-13). Existing `cachyos/` entries that assume Hyprland is the active compositor may be stale going forward — worth a pass to confirm/update those separately.
- Not yet verified against an actual full Noctalia process restart (only `noctalia msg config-reload` was tested, which left the in-memory state untouched either way, so it doesn't prove the fix survives a real logout/login). If `source` ever reverts again after a genuine restart, revisit this — the fix here writes the key correctly, but there could be a second code path (e.g. on clean process start with a stale favorite) that overwrites it again.
- `wallpaper.automation` favorites (`[[wallpaper.favorite]]` entries in settings.toml) each carry their own `palette_source`, independent of the global `theme.source` documented here — favoriting a wallpaper while in "builtin" mode pins that specific wallpaper to builtin even after this fix, unless re-favorited while "wallpaper" mode is active.
