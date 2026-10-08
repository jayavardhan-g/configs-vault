# Transitions: always stripes (wallpaper changes + lock/unlock)

**Date:** 2026-10-02
**Category:** noctalia
**Files touched:**
- `~/.local/state/noctalia/settings.toml`. Copy: [`files/.local/state/noctalia/settings.toml`](files/.local/state/noctalia/settings.toml), with home paths redacted to `/home/<user>`.
- `~/.config/noctalia/config.toml`. Copy: [`files/.config/noctalia/config.toml`](files/.config/noctalia/config.toml).

## What
Both of Noctalia's random-effect animations now always use **stripes**, at the default
1500 ms:
- **Wallpaper changes:** the picker on SUPER+W, plus the automation change at every
  login and every 30 min.
- **Lock and unlock** of the session lock screen.

Before, both picked a random effect each time.

## Why
Wanted one consistent animation instead of a different random effect at every login,
wallpaper change and lock.

## Change
`~/.local/state/noctalia/settings.toml`, under `[wallpaper]` (this GUI-owned file
already had the key, so it has to be changed here):
```toml
[wallpaper]
transition = [ "stripes" ]
```
`~/.config/noctalia/config.toml`:
```toml
[lockscreen]
# Lock/unlock animation: always stripes (default pool is every effect, picked at random)
transition = [ "stripes" ]
```
Then:
```bash
noctalia msg config-reload
```

## Notes
- Effect values (both settings): `fade`, `wipe`, `disc`, `stripes`, `zoom`,
  `honeycomb`. The binary also contains `wave`, which is undocumented and untested.
  Each list is a pool, and one effect is picked at random per transition, so one entry
  means always that effect.
- **`[wallpaper]` options:**
  - `transition`: leaving it out uses all effects, and in practice **`[]` did too**
    (random effects at every login; the docs don't say).
  - `transition_duration`: in ms, default 1500.
  - `edge_smoothness`: 0–1, default 0.3.
  - `transition_on_startup`: default false. It only covers the *first* wallpaper at
    shell start.
- **`[lockscreen]` options:**
  - `transition`: defaults to all effects. The docs say an empty array *disables*
    lock transitions; note this differs from what `[]` did for wallpapers.
  - `transition_duration`: 100–30000 ms, default 1500.
  - Also `edge_smoothness`, `blur_intensity` (0.5) and `tint_intensity` (0.3).
- **Why there's an animation at every login:** `[wallpaper.automation] enabled = true`
  (in `settings.toml`; defaults `interval_seconds = 1800`, `order = "random"`).
  - Per the docs, automation "picks one image from the resolved browse folder at shell
    startup, then keeps picking on the configured interval".
  - So right after login Noctalia switches to a new random wallpaper, and that switch
    animates. It happens again every 30 min.
  - The greeter is not the source: its config reference has no animation or transition
    keys, and greeter-sync only copies wallpaper, palette, font, corner radius and
    monitor layout.
- Other shell animations (panels and so on, `[shell.animation] enabled` / `speed`) are
  fixed motions, not random effects, and were left alone.
- The stored `settings.toml` copy had the username in its wallpaper paths since the
  [palette-source entry](palette-source-not-persisting.md). It's now redacted to
  `/home/<user>`; restore the real path when replaying.
