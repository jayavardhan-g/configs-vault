# System-wide Keybinds Reference

A single searchable index of every keybind on this machine — both window managers
(Hyprland and Mango, used interchangeably — check which one you're actually running),
Vim, and Neovim. Pulled directly from the live config files as of 2026-09-14, not from
the narrative decision-log entries elsewhere in this repo (those explain *why*; this is
just *what*).

**Keep this in sync**: whenever a keybind changes anywhere on this system, update the
matching row here too, in the same session.

Sources:
- Hyprland: `~/.config/hypr/config/binds.lua`
- Mango: `~/.config/mango/cfg/keybinds.conf`
- Vim: `~/.vimrc`
- Neovim: `~/.config/nvim/lua/config/keymaps.lua`, `lua/lsp.lua`, `after/plugin/telescope.lua`, `after/plugin/neotree.lua`

---

## Hyprland

`SUPER` = Windows/Meta key. `MONITOR1` = `eDP-1` (laptop), `MONITOR2` = `HDMI-A-1`
(external). 3 workspaces per monitor (`NUM_WPM=3`): 1-3 on the laptop, 4-6 on the
external monitor, plus a dedicated 7th for Xpad notes.

### Window management
| Key | Action |
|---|---|
| `SUPER+Escape` | Interactive kill-window cursor (`hyprctl kill`) |
| `SUPER+Q` | Close focused window |
| `SUPER+SHIFT+F` | Toggle floating |
| `SUPER+D` | Fullscreen (maximize mode) |
| `SUPER+F` | Fullscreen |
| `SUPER+CTRL+J` | Toggle split direction (dwindle) |
| `SUPER+M` | Swap with master |
| `SUPER+N` | Cycle layout engine: master → dwindle → scrolling |
| `SUPER+Left/Right/Up/Down` | Move focus in direction |
| `SUPER+H/L/K/J` | Move focus in direction (vim-style) |
| `ALT+Tab` | Cycle to next window |
| `SUPER+Tab` | Noctalia window switcher |
| `SUPER+SHIFT+Up/Right/Left/Down` | Move focused window in direction |
| `SUPER+SHIFT+H/L/K/J` | Move focused window in direction (vim-style) |
| `SUPER+SHIFT+mouse_up/down` | Move window to previous/next monitor |
| `SUPER+CTRL+SHIFT+Right/Left` | Move window to next/prev monitor's active workspace |
| `SUPER+SHIFT+CTRL+1..6` (`0`=10th) | Move window to that workspace number, relative per monitor |
| `SUPER+mouse:272` (drag) | Move window with mouse |
| `SUPER+mouse:273` (drag) | Resize window with mouse |
| `SUPER+R` | Enter resize submap (see below) |
| `SUPER+CTRL+SHIFT+H/L/K/J` | Quick resize ±40px, no submap, repeats while held |
| `SUPER+SHIFT+R` | Reset focused window to default tiled size/ratio |
| `SUPER+Minus` / `SUPER+Plus` | Zoom out / in (repeats while held) |
| `SUPER+keypad-` / `SUPER+keypad+` | Zoom out / in (repeats while held) |

**Resize submap** (`SUPER+R` to enter):
| Key | Action |
|---|---|
| `H/L/K/J` | Resize ±20px in direction (repeats while held) |
| `Escape` / `Return` / `SUPER+R` | Exit submap |

### Launchers / apps
| Key | Action |
|---|---|
| `SUPER+Return` | Terminal |
| `SUPER+E` | File manager (Dolphin) |
| `SUPER+T` | Editor |
| `SUPER+C` / `XF86Calculator` | Calculator |
| `SUPER+W` / `SUPER+B` | Browser |
| `CTRL+SHIFT+Escape` | Terminal running `btop` |
| `SUPER+Z` | Noctalia settings toggle |
| `SUPER+X` | Noctalia control center |
| `SUPER+Space` | Noctalia launcher |
| `SUPER+period` | Noctalia launcher, emoji mode |
| `SUPER+ALT+L` | Lock session |
| `SUPER+ALT+C` / `SUPER+SHIFT+Q` | Noctalia session panel |
| `SUPER+P` | Display-mode menu (Extend / laptop-only / external-only) |

### Hardware controls
| Key | Action |
|---|---|
| `XF86AudioRaiseVolume` / `LowerVolume` | Volume up/down (repeats while held) |
| `XF86AudioMute` | Mute |
| `XF86AudioMicMute` | Mic mute |
| `XF86AudioPlay` / `Pause` | Toggle media playback |
| `XF86AudioNext` / `Prev` | Next/previous track |
| `XF86MonBrightnessUp` / `Down` | Brightness up/down (repeats while held) |
| `XF86PowerOff` (short press) | Noctalia session panel (logind ignores the key; long hold = hardware off) |

### Screenshots & utilities
| Key | Action |
|---|---|
| `SUPER+SHIFT+P` | Color picker (`hyprpicker`) |
| `Print` | Full-screen screenshot → satty (Ctrl+S save / Ctrl+C copy) |
| `SUPER+Print` / `F6` | Region screenshot → satty |
| `SUPER+SHIFT+W` | Wallpaper picker panel |
| `SUPER+ALT+R` | Toggle laptop panel refresh rate 144Hz/60Hz |
| `SUPER+V` | Clipboard history panel |
| `SUPER+A` | Notifications panel |

### Workspaces & monitors
| Key | Action |
|---|---|
| `SUPER+bracketleft` / `bracketright` | Focus laptop / external monitor |
| `SUPER+SHIFT+bracketleft` / `bracketright` | Move window to laptop / external monitor |
| `SUPER+1/2/3` | Focus workspace 1/2/3 (laptop) |
| `SUPER+4/5/6` | Focus workspace 4/5/6 (external) |
| `SUPER+7` | Focus workspace 7 (Xpad notes — external, falls back to laptop) |
| `SUPER+SHIFT+1..6` | Move window to that workspace |
| `SUPER+CTRL+1/2/3` | Focus workspace relative to current monitor (1st/2nd/3rd on that monitor) |
| `SUPER+CTRL+Right` / `Left` | Focus next/previous workspace on current monitor |
| `SUPER+CTRL+Down` | Focus next empty workspace on current monitor |
| `SUPER+CTRL+H` / `L` | Same as Left/Right (vim-style) |
| `SUPER+mouse_down` / `mouse_up` | Scroll to prev/next workspace on current monitor |
| `SUPER+S` | Toggle special (scratchpad) workspace visibility |
| `SUPER+SHIFT+S` | Send focused window to special / pull it back |

---

## Mango

`SUPER` = Windows/Meta key. Tags (workspaces): 1-4 general use (`scroller` layout), tag 5
general-purpose (`fair` layout). `[` = `eDP-1` (laptop), `]` = `HDMI-A-1` (external).

### Launchers / apps
| Key | Action |
|---|---|
| `SUPER+Return` | Terminal (kitty) |
| `SUPER+E` | Dolphin |
| `SUPER+B` | Browser (Zen) |
| `SUPER+Q` | Kill focused client |
| `SUPER+Space` | Noctalia launcher |
| `SUPER+X` | Noctalia control center |
| `SUPER+W` | Noctalia wallpaper browser |
| `SUPER+V` | Noctalia clipboard panel |
| `SUPER+SHIFT+Q` | Noctalia session panel |
| `SUPER+P` | Display-mode menu (Extend / laptop-only / external-only) |
| `SUPER+Z` | Noctalia settings toggle |

### Screenshots
| Key | Action |
|---|---|
| `SUPER+SHIFT+P` | Full-screen screenshot → satty |
| `SUPER+ALT+P` | Full-screen screenshot, all monitors → satty |
| `Print` (release-triggered) | Full-screen screenshot → satty |
| `F6` | Region screenshot → satty |

Inside satty: `Ctrl+S` saves to `~/Pictures/satty-<timestamp>.png`, `Ctrl+C` copies to
clipboard (`wl-copy`).

### Config / mode
| Key | Action |
|---|---|
| `SUPER+F5` | Reload Mango config |
| `SUPER+R` | Enter resize mode (see below) |

### Hardware controls
| Key | Action |
|---|---|
| `XF86AudioRaiseVolume` / `LowerVolume` | Volume up/down |
| `XF86AudioMute` | Mute |
| `XF86MonBrightnessUp` / `Down` | Brightness up/down |

### Window focus & movement
| Key | Action |
|---|---|
| `SUPER+Tab` | Focus next window in stack |
| `SUPER+Left/Right/Up/Down` | Focus in direction |
| `SUPER+H/L/K/J` | Focus in direction (vim-style) |
| `SUPER+SHIFT+Up/Down/Left/Right` | Swap (exchange) with window in direction |
| `SUPER+SHIFT+H/L/K/J` | Swap with window in direction (vim-style) |
| `SUPER+M` | Zoom focused window to front of client list (master swap) |

### Window state toggles
| Key | Action |
|---|---|
| `SUPER+G` | Toggle global (window visible on every tag) |
| `ALT+Tab` | Toggle overview |
| `SUPER+SHIFT+F` | Toggle floating |
| `SUPER+F` | Toggle fullscreen |
| `SUPER+D` | Toggle maximize-to-screen |
| `SUPER+ALT+F` | Toggle fake fullscreen |
| `SUPER+I` | Minimize |
| `SUPER+O` | Toggle overlay |
| `SUPER+SHIFT+I` | Restore minimized |
| `ALT+Z` | Toggle minimize-pile scratchpad |
| `SUPER+S` | Toggle special-tag scratchpad overlay |
| `SUPER+SHIFT+S` | Send focused window to special tag / pull it back |

### Layout
| Key | Action |
|---|---|
| `SUPER+N` | Cycle layout for current tag — **persists the result to `layout.conf`** |
| `SUPER+SHIFT+E` | Set scroller proportion to 1.0 |
| `ALT+X` | Switch scroller proportion preset |
| `SUPER+SHIFT+X` / `SUPER+SHIFT+Z` | Increase/decrease gaps |
| `SUPER+SHIFT+R` | Toggle gaps on/off |

### Workspaces (tags) & monitors
| Key | Action |
|---|---|
| `SUPER+1..5` | View tag 1-5 (on the focused monitor) |
| `SUPER+SHIFT+1..5` | Move focused window to that tag |
| `SUPER+CTRL+H` / `L` | View previous/next tag |
| `SUPER+CTRL+Left` / `Right` | Same, arrow-key version |
| `SUPER+bracketleft` / `bracketright` | Focus laptop / external monitor |
| `SUPER+ALT+Left` / `Right` | Focus monitor by direction |
| `SUPER+SHIFT+bracketleft` / `bracketright` | Move focused window to laptop / external monitor (lands on whichever tag that monitor is currently showing) |
| `SUPER+SHIFT+ALT+Left` / `Right` | Same, by direction |

### Mouse bindings
| Binding | Action |
|---|---|
| `SUPER+btn_left` drag | Move window |
| `SUPER+btn_right` drag | Resize window |
| `btn_middle` click | Toggle maximize-to-screen |

### Direct move/resize (no mode)
| Key | Action |
|---|---|
| `CTRL+SHIFT+Up/Down/Left/Right` | Move focused window 50px in direction |
| `CTRL+ALT+Up/Down/Left/Right` | Resize focused window 50px in direction |

**Resize mode** (`SUPER+R` to enter — replaces all normal binds until exited):
| Key | Action |
|---|---|
| `H/L/K/J` or arrow keys | Resize 40px in direction |
| `Escape` / `Caps_Lock` / `SUPER+R` | Exit back to normal mode |

---

## Vim (`~/.vimrc`)

Leader key: `Space`.

| Key | Action |
|---|---|
| `Space` (normal/visual) | No-op (disabled) |
| `j` / `k` | Move by display line (wrapped-line aware) |
| `Esc` | Clear search highlight |
| `Ctrl+S` | Save |
| `<leader>sn` | Save without auto-formatting |
| `Ctrl+Q` | Quit |
| `x` | Delete char without yanking |
| `Ctrl+D` / `Ctrl+U` | Half-page scroll, re-centered |
| `n` / `N` | Next/prev search match, re-centered and unfolded |
| `Up` / `Down` | Resize split ∓2 (horizontal) |
| `Left` / `Right` | Resize split ∓2 (vertical) |
| `Tab` / `Shift+Tab` | Next/previous buffer |
| `<leader>sb` | List buffers, prompt to switch |
| `<leader>+` / `<leader>-` | Increment/decrement number under cursor |
| `<leader>v` | Vertical split |
| `<leader>h` | Horizontal split |
| `<leader>se` | Equalize split sizes |
| `<leader>xs` | Close split |
| `Ctrl+H/J/K/L` | Move focus to split in direction |
| `<leader>to` / `tx` / `tn` / `tp` | New/close/next/previous tab |
| `<leader>x` | Delete buffer |
| `<leader>b` | New empty buffer |
| `<leader>lw` | Toggle line wrap |
| `Ctrl+/` / `Ctrl+_` (normal) | Toggle comment on line |
| `Ctrl+/` / `Ctrl+_` (visual) | Toggle comment on selection |
| `jk` / `kj` (insert) | Exit to normal mode |
| `p` (visual) | Paste without overwriting register |
| `<leader>y` (normal/visual) | Yank via OSC52 (reaches local clipboard even over SSH) |
| `<leader>Y` | Yank to end of line via OSC52 |
| `<leader>e` | Open file explorer (netrw) |
| `l` (inside netrw) | Open file/directory |

---

## Neovim (`~/.config/nvim`)

Leader key: `Space`. **Everything in the Vim section above applies identically here too**
— Neovim's `keymaps.lua` mirrors it — the rows below are only what's different or
additional.

| Key | Action |
|---|---|
| `<leader>rl` | Reload Neovim config without restarting |
| `[d` / `]d` | Jump to previous/next diagnostic (floating preview) |
| `<leader>d` | Show diagnostics for current line |
| `<leader>q` | Diagnostics list (location list) |

### LSP (only active in a buffer with an attached LSP client)
| Key | Action |
|---|---|
| `K` | Hover documentation |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gi` | Go to implementation |
| `gr` | Find references |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |

Format-on-save is automatic for any LSP client that supports it — no keybind needed.

### Telescope (fuzzy finder)
| Key | Action |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | List open buffers |
| `<leader>fo` | Recent files |
| `<leader>fh` | Help tags |
| `<leader>fs` | Grep word under cursor |
| `<leader>fc` | Grep current filename |
| `Ctrl+J` / `Ctrl+K` (inside picker) | Move selection down/up |

### Neo-tree (file explorer)
| Key | Action |
|---|---|
| `<leader>e` | Toggle file explorer (left side) |
| `l` (inside Neo-tree) | Open / go deeper |
| `h` (inside Neo-tree) | Close node |
