# Pomodoro widget on SUPER+C (Quickshell, click-through corner timer + stats)

**Date:** 2026-10-02
**Category:** system
**Files touched:** `~/.config/quickshell/` (`shell.qml`, `Pomo.qml`, `PomoPill.qml`, `PomoPanel.qml`, `Theme.qml`, `Btn.qml`, `Icon.qml`, `Ring.qml`, `Switch.qml`, `SetStepper.qml`, `SetToggle.qml`, `SetChoice.qml`, `SetText.qml`), `~/.config/hypr/config/binds.lua`, `~/.config/hypr/config/autostart.lua`. Copies: [`../files/.config/quickshell/`](../files/.config/quickshell/), [`../files/.config/hypr/config/`](../files/.config/hypr/config/). Data: `~/.local/share/pomodoro/data.json` (not stored; personal history).

## What
A pomodoro timer with categories and statistics, modelled on Android focus apps (Forest,
Focus To-Do, Flora). Built in Quickshell, running next to Noctalia.
- **SUPER+C** toggles a centred panel on the focused monitor, with four tabs:
  - **Timer:** category chips, a big progress ring, stop / play-pause / skip, cycle dots
    and daily-goal progress. Strict mode turns stop into "Give up" and disables
    pause/skip; stopwatch mode shows "Finish".
  - **Stats:** Today (with goal) / This week / Streak / Sessions tiles, a 7-day bar chart
    stacked by category with a goal line, and a per-category breakdown for Today / Week /
    Month / All.
  - **History:** every session, newest first. Click the category chip to cycle it,
    use −/+ to adjust minutes, use the bin to delete. **Export CSV** writes
    `~/Downloads/pomodoro-YYYY-MM-DD-HHMM.csv` (date, time, category, minutes,
    completed). **Reset stats** needs a second click within 4 s.
  - **Settings (gear)**, scrollable, in sections:
    - *Timer:* mode (pomodoro / stopwatch, switchable only between sessions), focus,
      short and long break, long-break interval, auto-start breaks, auto-start focus,
      strict mode, daily goal (15-min steps, 0 = off).
    - *During focus:* Noctalia Do Not Disturb, keep the screen awake (Noctalia
      caffeine), and a sound at each phase end (off / complete / bell / alarm, from
      `/usr/share/sounds/freedesktop/stereo/`, played with `pw-play`, with a test
      button).
    - *Corner timer:* background opacity (0–100% in 10% steps), all monitors or one
      chosen monitor, hide during breaks.
    - *Notifications:* editable "focus ends" and "break ends" titles, with `{category}`
      and `{minutes}` placeholders.
    - *Categories:* per-category focus and short-break length overriding the defaults
      ("def"), remove, and add.
- In the panel, Space starts or pauses and Esc closes.
- **Stopwatch mode** counts up (shown as h:mm:ss past an hour; the ring loops each hour).
  There are no breaks, and Finish saves a completed session.
- **DND and keep-awake** are on only while a focus session is actually *running*. They
  switch off on pause, break or stop, and are restored after a `qs` restart.
  - DND is only taken over if it was off, so a DND you set yourself is left alone.
    Whether the widget owns it is saved as `dndOwned`.
  - Noctalia has no caffeine status command, so keep-awake can't tell a manual caffeine
    apart. It switches caffeine off whenever focus stops.
- While a cycle is active and the panel is closed, a **"fused notch"** timer sits in the
  top-right corner of **every monitor** (one per screen via `Variants` in `shell.qml`).
  - Shape: a 96px square flush with the top and right edges, with a rounded inner corner
    (r 28) and 14px concave fillets blending it into both edges. It shows a progress ring
    (a fire icon, a coffee icon on breaks, or pause), the time at 20px, and the category.
  - Chosen from four mockups (corner tab, fused notch, quarter dial, corner card)
    published as an artifact.
  - **Fully click-through:** it has an empty input mask (`mask: Region {}`), so pointer
    motion, hover, clicks and scroll all reach whatever is underneath.
  - The background is 40% opaque by default (Settings → Corner timer); the ring and
    digits are solid, and the digits have a faint outline for legibility.
- Defaults: 25 / 5 / 15 min, a long break every 4 sessions, breaks auto-start and focus
  after a break doesn't. Each phase end sends a `notify-send` (shown by Noctalia) and
  plays the chosen sound.
- Colours follow Noctalia's wallpaper palette, read live from its generated
  `~/.config/gtk-4.0/noctalia.css`. Category colours are fixed.
- Everything (settings, categories, history and the running timer) persists to
  `~/.local/share/pomodoro/data.json`, so a running session survives a `qs` restart or
  a re-login.

## Why
Wanted a pomodoro timer that's always visible in a corner but never gets in the way, is
reachable via a shortcut, and keeps per-category stats.
- SUPER+C was taken from the rarely used calculator.
- All controls live in the shortcut panel; the corner timer itself is never clicked.
- Click-through was chosen over a dodging widget (see Notes). It's simpler, nothing moves,
  and clicks always reach the window buttons, app toolbars and bar under the corner.

## Change
```bash
sudo pacman -S quickshell
cp -r cachyos/files/.config/quickshell ~/.config/
```
`~/.config/hypr/config/binds.lua`: SUPER+C replaces the calculator, which keeps the
`XF86Calculator` key:
```lua
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("sh -c 'qs ipc call pomodoro toggle || { qs -d && sleep 1 && qs ipc call pomodoro toggle; }'"))
hl.bind("XF86Calculator", hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
```
`~/.config/hypr/config/autostart.lua`, right after `hl.exec_cmd("noctalia")`:
```lua
hl.exec_cmd("qs -d")
```
IPC (for scripting): `qs ipc call pomodoro toggle | startPause | stop`.

## Notes
- **Why not a Noctalia plugin (tried that route first):**
  - Noctalia desktop widgets render on the `Bottom` layer, below windows (per its
    docs), and their position is fixed by config, so a corner widget would be hidden
    behind tiled windows.
  - Plugin panels are modal (a click shield closes them; one panel at a time).
  - The community `thepunkoff/pomodoro` plugin has no categories, stats or IPC.
- **Decided to keep Quickshell rather than port to a Noctalia plugin** (2026-10-02).
  - Memory measured (PSS): `qs` ~175 MB (almost all Qt/QML runtime baseline; the widget
    itself is small) and `noctalia` ~138 MB for the whole shell. Together that's ~313 MB,
    about 2% of 16 GB, with negligible CPU.
  - Everything except the corner timer would port to a Luau plugin (panel, settings,
    DND/caffeine, sessions). The corner timer would not, because **a Noctalia bar always
    takes clicks** (no click-through), and short bars (`margin_ends`) can only be
    centred on an edge, not put in a corner. Options compared (artifact "Pomodoro Timer
    Placement"):
    - A top-centre island (covers the browser's tabs).
    - A right-edge pill, either overlapping (covers a ~34×150 px strip, usually the
      rightmost window's scrollbar, and takes its clicks; `gaps_out = 2` is too thin to
      hide it in) or `reserve_space = true` (windows ~2% narrower during sessions).
    - A widget in the main bar (invisible while it auto-hides).
  - Kept the click-through notch: it costs no window space and blocks nothing, for
    ~1% of RAM.
  - Replacing Noctalia with a full Quickshell shell was also ruled out. A whole QML shell
    would likely use more than both combined (commonly ~300–600 MB; that's a general
    estimate, not measured here).
- **Timer vs. Noctalia's bar:** the timer draws on top of the bar's right end.
  - Both are on the Overlay layer (`hyprctl layers` shows layer 3); the timer maps
    after the bar, so it's on top. Confirmed with `grim` screenshots.
  - Click-through verified live: a screenshot caught the bar revealed and the cursor
    hovering the bar's power button *through* the timer, with the button's hover state
    showing.
  - Apps with their own hover-revealed top bars (fullscreen browser toolbars, video
    player controls) work the same way. They just draw underneath the translucent timer.
- **Superseded approach: dodging the cursor** (all 2026-10-02; dropped the same day).
  The first design moved the widget to the other end of the top edge when the cursor
  came near. Iterations:
  1. Swapped sides on every touch.
  2. "Right is home", via polling `hyprctl cursorpos` every 250 ms while dodged. Judged
     a waste of resources.
  3. An invisible home-spot window whose pointer-leave sent it back. It broke at the top
     edge when the bar was revealed.
  4. An L-shaped "fence" window with a click-through inside, for proximity. Where the
     fence lay over the bar, moving onto it counted as leaving the bar, and the
     **auto-hide bar slid away**. Moving the fence below the bar fixed that, but the
     widget then stayed dodged whenever the cursor left along the bar.

  Lessons, if dodging is ever revisited:
  - Wayland only reports the cursor to the surface it's over, and Hyprland's event
    socket has no cursor-motion events. So proximity needs either polling or an input
    surface, and any input surface over the bar breaks its auto-hide.
- **QML/Quickshell gotchas hit while building:**
  - A property named `onAccent` is parsed as a signal handler for `accent` ("Cannot
    assign a value to a signal").
  - A custom property named `top` collides with Item's FINAL anchor property.
  - `Hyprland.focusedMonitor` is null right after `qs` starts (until the first focus
    event), and `Hyprland.refreshMonitors()` is async. So SUPER+C asks
    `hyprctl monitors -j` for the focused monitor before opening the panel.
  - If Hyprland restarts while a `qs` launched from an old terminal keeps running, that
    `qs` holds a stale `HYPRLAND_INSTANCE_SIGNATURE` and its Hyprland IPC fails. The
    autostarted one is always correct.
- Stats count every focus minute: completed sessions, plus partial ones ≥1 min when
  stopped or skipped (stored with `done: false`). "Sessions" and the streak count only
  completed ones. Removing a category keeps its history (shown greyed).
- Supersedes the "Quickshell shelved" status in
  [quickshell-trial-shelved.md](quickshell-trial-shelved.md): Quickshell is installed
  and autostarted again for this. The left-edge side island from that trial is still
  not deployed.
