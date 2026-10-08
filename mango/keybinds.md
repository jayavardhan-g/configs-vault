# Keybinds reworked to match the Hyprland setup

**Date:** 2026-09-13
**Category:** mango
**Files touched:** `~/.config/mango/cfg/keybinds.conf`

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Mango]] · [[Noctalia]] · [[CachyOS]]
<!-- graph:end -->

## What
Started from the CachyOS `cachyos-mango-noctalia` skeleton's default binds
(all `SUPER`-based already, but arrow-key-only, with a few keys mapped
differently than the equivalent Hyprland setup) and reworked them to match
the finger-ergonomic habits already built up on Hyprland: vim hjkl movement,
a modal resize mode, and a real special-workspace scratchpad. Requires
[[version-bug-upgrade]] (mangowm 0.17.0+) for the special-tag scratchpad
specifically — none of it works on the 0.16.1 this machine started on.

## Why
User wanted the same muscle memory across both compositors rather than
learning a second scheme, without discarding Mango/Noctalia's own already-
sensible defaults where there was no real Hyprland equivalent to fight with.

## Change

**Vim-style movement, added alongside the existing arrow-key binds (not
replacing them):**
```
bind = SUPER, h, focusdir, left
bind = SUPER, l, focusdir, right
bind = SUPER, k, focusdir, up
bind = SUPER, j, focusdir, down

bind = SUPER+SHIFT, h, exchange_client, left
bind = SUPER+SHIFT, l, exchange_client, right
bind = SUPER+SHIFT, k, exchange_client, up
bind = SUPER+SHIFT, j, exchange_client, down

bind = SUPER+CTRL, h, viewtoleft, 0
bind = SUPER+CTRL, l, viewtoright, 0
```

**Modal resize mode** (Mango's equivalent of Hyprland's `hl.define_submap`,
using its own `keymode=`/`setkeymode` system — see Notes for the syntax):
```
bind = SUPER, r, setkeymode, resize
bind = SUPER, F5, reload_config          # moved off SUPER+R to free it above

# must be the LAST block in the file - see Notes
keymode=resize
bind = NONE, h, resizewin, -40, +0
bind = NONE, l, resizewin, +40, +0
bind = NONE, k, resizewin, +0, -40
bind = NONE, j, resizewin, +0, +40
bind = NONE, Left, resizewin, -40, +0
bind = NONE, Right, resizewin, +40, +0
bind = NONE, Up, resizewin, +0, -40
bind = NONE, Down, resizewin, +0, +40
bind = NONE, Escape, setkeymode, default
bind = NONE, Caps_Lock, setkeymode, default   # see Notes - both needed
bind = SUPER, r, setkeymode, default
keymode=default
```

**Special-tag scratchpad** (the real Hyprland-equivalent hidden workspace,
not Mango's separate minimize-pile mechanism):
```
bind = SUPER, s, toggle_special_tag,
bind = SUPER+SHIFT, s, tag_special_tag,
```
This bumped Mango's own default Noctalia-panel keys off `S`/`SHIFT+S`. They
were relocated to match Hyprland's own key choices for the same panels
instead of picking arbitrary free keys:
```
bind = SUPER, x, spawn, noctalia msg panel-toggle control-center   # was S
bind = SUPER, z, spawn, noctalia msg settings-toggle               # was SHIFT+S
```
Which in turn bumped what used to live on `X`/`Z`, demoted to `ALT+X`/`ALT+Z`
rather than deleted:
```
bind = ALT, x, switch_proportion_preset,   # scroller-layout preset cycle
bind = ALT, z, toggle_scratchpad           # the OLD minimize-pile mechanism
```

**Fullscreen/maximize swapped** to match Hyprland's split (`F`=real
fullscreen, `D`=maximize — Mango's default has them the other way with `F`
as maximize, `SHIFT+F` as fullscreen):
```
bind = SUPER, f, togglefullscreen,
bind = SUPER, d, togglemaximizescreen,
bind = SUPER+SHIFT, f, togglefloating,   # freed up by the swap; also matches
                                          # Hyprland's own SUPER+SHIFT+F
```
Clipboard moved from the default `SUPER+C` to `SUPER+V` (paste mnemonic,
matches Hyprland) - safe since `SUPER+V`'s old `togglefloating` duty is
already covered by `SUPER+SHIFT+F` above:
```
bind = SUPER, v, spawn, noctalia msg panel-toggle clipboard
```

**Monitor-focus/move-to-monitor** — see [[multi-monitor-setup]] for the full
story (a collision bug fix, an abandoned digit-remap experiment, and the
final bracket-key scheme actually in place now).

**Screenshot keys**, matching Hyprland's physical-key convention on top of
Mango's own letter-based ones (kept, not removed):
```
bindr = NONE, Print, spawn, noctalia msg screenshot-fullscreen
bind = NONE, F6, spawn, noctalia msg screenshot-region
```

**Master swap and relative-workspace arrow keys** (2026-09-14), matching two
more Hyprland binds that had no Mango equivalent yet:
```
bind = SUPER, m, zoom,
bind = SUPER+CTRL, Left, viewtoleft, 0
bind = SUPER+CTRL, Right, viewtoright, 0
```
`zoom` is dwm's classic master-swap action (move focused window to the front
of the client list) — the actual dispatcher name is `zoom`, not something
Hyprland-style like `swapwithmaster`; found by grepping the dispatch table
directly rather than guessing. Most meaningful on the `tile` (master-stack)
layout, inert elsewhere — same as Hyprland's `SUPER+M` under its own
non-master layouts. The arrow-key binds sit alongside the existing
`SUPER+CTRL+h/l`, not replacing them.

**Display mode menu** (2026-09-14) — see [[display-mode-menu]] for the new
`SUPER+P` script, ported from Hyprland with one real limitation (no
"Duplicate"/mirror mode — confirmed unsupported anywhere in Mango, not just
a naming difference).

**Trackpad gestures and scroll-wheel tag switching** (2026-09-16) — Mango
ships default `gesturebind`/`axisbind` lines in its stock config, but this
config never sourced any; added them for the first time rather than porting
an existing scheme (Hyprland has no equivalent binds to match):
```
# Scroll-wheel tag switching: SUPER+scroll moves to the adjacent tag that
# actually has a client (skips empty tags).
axisbind = SUPER, UP, viewtoleft_have_client
axisbind = SUPER, DOWN, viewtoright_have_client

# Trackpad gestures.
# 3-finger swipe: directional focus (same as SUPER+hjkl/arrows).
gesturebind = none, left, 3, focusdir, left
gesturebind = none, right, 3, focusdir, right
gesturebind = none, up, 3, focusdir, up
gesturebind = none, down, 3, focusdir, down
# 4-finger swipe: left/right = next/prev tag with a client, up/down =
# enter/leave overview.
gesturebind = none, right, 4, viewprev_have_client
gesturebind = none, left, 4, viewnext_have_client
gesturebind = none, up, 4, enteroverview
gesturebind = none, down, 4, leaveoverview
```
Placed before the `keymode=resize` block (must stay last in the file — see
Notes above).

## Notes
- **Mango's `keymode=`/`setkeymode` modal system**: put `keymode=<name>`
  before a group of `bind` lines and only those apply while in that mode;
  `setkeymode,<name>` (as a bind action) switches modes; a plain `bind`
  outside any `keymode=` line belongs to `default`. **Order in the file
  matters** — everything after a `keymode=X` line belongs to that mode until
  the *next* `keymode=` line, so a mode block not meant to be last must be
  explicitly closed with `keymode=default` (or whatever should follow).
- **`Escape` needed a second bind on `Caps_Lock` to actually work**, because
  [[appearance-and-input]]'s `caps:swapescape` XKB option makes the *physical*
  CapsLock key emit the `Escape` keysym — but Mango's bind matching appears to
  key off the *original* hardware identity of a key for at least this case,
  not the XKB-remapped keysym. Binding both names sidesteps needing to fully
  understand Mango's internal key-resolution order.
- **`bindr` vs `bind`**: append `r` directly onto the word `bind` (e.g.
  `bindr = ...`) to trigger on key-**release** instead of press. Other flags
  stack the same way: `l` = apply even when session-locked, `p` = pass the
  event through to the focused client as well, `c` = allow this bind to fire
  alongside other matches on the same combo (by default only the first match
  in file order fires). Needed for the physical Print key specifically — see
  below.
- **The physical Print key still doesn't work, and can't be fixed from
  config.** Confirmed via `wev` that this key's firmware never sends a press
  event, only release, across every test. Mango's engine requires a press to
  set `server.last_hold_keycode` before it will recognize *any* release for
  keybind purposes (checked directly against the 0.17.0 source,
  `src/input/keyboard.c`) — so even `bindr` can't catch it, because the
  release-matching guard itself never arms. This is a structural Mango
  limitation for this specific key's behavior, not a config mistake. Use
  `SUPER+SHIFT+P` (still bound, unaffected) for full-screen in Mango instead.
  Whether the same physical key works under Hyprland was not yet confirmed.
- **Fn+F6 is not the same thing as the `F6` key.** This laptop's Fn+F6
  hotkey is a firmware-level macro that sends a `Super+Shift+S`-style key
  sequence directly (confirmed via `wev` showing real `S`/`Super_L`/`Shift_L`
  keycodes, no `F6` at all, during that specific combo) — separate from the
  plain `F6` key alone, which does send a clean `F6` keysym and correctly
  triggers the region-screenshot bind above. Don't mistake reports of
  "Fn+F6 toggling the special workspace" for a bug in the `F6` bind itself;
  it's `SUPER+SHIFT+S` firing exactly as designed, from a different physical
  source than expected.
- Not ported from Hyprland: auto-relaunch apps (spotify/claude/labvpn/home
  terminals) into the special-tag on startup. Nothing wired up yet for this.
  (A dedicated Xpad tag was also tried and fully reverted — see
  [[xpad-workspace-and-monitor-persistence]] for why. Mango's `tag_num` is
  back to its default 4 here, with no Xpad-related config left.)
- See [[known-bugs]] for a genuine unfixed upstream bug: moving a window
  onto a monitor that has an active fullscreen client leaves keyboard focus
  stuck until a manual mouse click.
- Parity went the other direction too: Hyprland's session panel was only on
  `SUPER+ALT+C` before; added `SUPER+SHIFT+Q` there as well (alongside, not
  replacing it) to match Mango's own key for the same panel — see
  `~/.config/hypr/config/binds.lua`.
