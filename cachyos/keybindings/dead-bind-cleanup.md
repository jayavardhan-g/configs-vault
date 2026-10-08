# Dead-bind cleanup: hyprpicker removed, SUPER+T fixed, SUPER+SHIFT+7 added

**Date:** 2026-09-21
**Category:** keybindings
**Files touched:** `~/.config/hypr/config/binds.lua`, `~/.config/hypr/config/variables.lua`,

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[Xpad]] · [[Neovim]]
<!-- graph:end -->

`~/.config/hypr/config/autostart.lua`

## What
Four fixes found by auditing every live bind and autostart line against what it actually
invokes:

1. **`SUPER+SHIFT+P` removed.** It ran `hyprpicker -a -n`, but hyprpicker was never
   installed — the bind had always been dead. Removed rather than installing it; no need
   for a colour picker here. `SUPER+SHIFT+P` is now free.
2. **`SUPER+T` fixed** — it now opens `nvim` inside `TERMINAL` instead of doing nothing.
3. **`SUPER+SHIFT+7` added**, so a window can be sent to the Xpad notes workspace.
4. **`xhost +SI:localuser:root` removed from `autostart.lua`.** `xhost` was never
   installed, so this ran and failed at every login.

## Why
All three were silent failures — nothing errored, the keys just didn't do anything (or,
for `SUPER+SHIFT+7`, didn't exist), so none of them would surface without deliberately
checking.

## Change
`variables.lua`:
```lua
-- Terminal editor: SUPER+T wraps this in TERMINAL, so it must NOT be launched
-- as a bare desktop app.
EDITOR                = "nvim"
```

`binds.lua`:
```lua
-- Opens the editor in a terminal - same shape as the btop bind
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e " .. EDITOR))

-- Extra workspace 7 (Xpad notes), outside the NUM_WPM*2 grid
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = "7" }))
```
`hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a -n"))` was deleted.

## Notes
- **Why `SUPER+T` did nothing.** It was `hl.dsp.exec_cmd(launchPrefix .. EDITOR)`, i.e.
  `uwsm app -- vim`. `vim.desktop` is `Terminal=true`, but the bind passes the bare
  *command* `vim`, not the desktop ID `vim.desktop`, so uwsm never applied the
  terminal-wrapping the desktop entry asks for. vim started with no terminal attached and
  exited immediately — no window, no error. **Anything `Terminal=true` must be launched as
  `TERMINAL .. " -e " .. cmd`** in this config; `CONTROL+SHIFT+Escape` (btop) is the
  pattern to copy.
- **Why workspace 7 needed both binds written out.** The bind loops in `binds.lua` only
  cover `1 .. NUM_WPM * 2` (= 1–6 with `NUM_WPM = 3`). Workspace 7 sits outside that grid
  (see [[xpad-workspace-and-monitor-persistence]]), so each half has to be spelled out by
  hand. Only the focus half ever was, which is why 7 was the one workspace you could jump
  to but not send a window to.
- **What the `xhost` line did, and why removing it is safe.** X11's display server lets
  any connected client read all keystrokes and screenshot any window, so it gatekeeps
  connections — normally with a per-session cookie in `~/.Xauthority`. `xhost` manages the
  older host-based allow-list alongside that, and `+SI:localuser:root` ("server
  interpreted", local account `root`) grants the root account access to the display. The
  point is letting root GUI apps like `sudo gparted` work instead of failing with
  "cannot open display". Here it only ever applied to **XWayland**; native Wayland apps
  don't use this mechanism at all. It's CachyOS boilerplate, not a deliberate choice —
  it's the one line in that block with no comment. Removing it **only tightens** access
  and can't loosen it, and since `xhost` wasn't installed the line was already a no-op,
  so removal changes nothing at runtime. (Note the genuinely dangerous form is bare
  `xhost +`, which allows *any* client including over the network. This was never that.)
  If a root GUI app is ever needed, `pkexec` is the modern route.
- **`hyprctl binds` will not show you any of this.** It reports what is *bound*, not
  whether the target exists or the key ever fires. Both dead binds registered perfectly
  and looked healthy in its output. Checking a bind means checking the command too —
  `command -v <binary>`, and for a `.desktop` app, whether it is `Terminal=true`.
- Deliberately **not** done in the same pass: `SUPER+CTRL+Up` is the only unbound arrow in
  that family (`Down` is next-empty workspace) — left alone as not worth a bind.
- Free single-modifier slots after this: `SUPER+i/o/y/0/8/9` and
  `SUPER+SHIFT+a/b/c/d/g/i/m/n/o/p/t/u/v/x/y/z/0/8/9`, plus the whole
  `SUPER+CTRL+SHIFT+<letter>` family freed in [[resize]].
