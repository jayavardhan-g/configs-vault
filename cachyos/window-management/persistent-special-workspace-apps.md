# Auto-relaunch apps into the special workspace, laid out on every start

**Date:** 2026-08-29
**Category:** window-management
**Files touched:** `~/.config/hypr/config/autostart.lua`, `~/.config/hypr/config/windowrules.lua`

<!-- graph:begin -->
**Graph:** [[Hyprland]] · [[kitty]] · [[fish]] · [[Fortinet VPN]] · [[Spotify]]
<!-- graph:end -->

## What
Spotify and three specific `kitty` terminals (one running `claude` in `~/claude`, one
running the `labvpn` fish function, one plain shell in the home directory) now launch
automatically on every Hyprland start and land directly in the special/scratchpad
workspace (see [[special-workspace-toggle]]), instead of the default active workspace.
They're also automatically arranged: `claude` as the master pane at 45% width; the stack
(remaining 55%) is ordered spotify, labvpn, home top-to-bottom, sized spotify (biggest) >
home (medium) > labvpn (smallest).

## Why
User wanted these apps sitting hidden-and-ready (pulled out with `SUPER+S`) without
manually launching and `SUPER+SHIFT+S`-ing each one after every reboot, arranged in a
specific layout (claude given more room since it's the one actually worked in) rather than
whatever the default equal-ish master/stack split produces. Hyprland/Wayland has no
session-restore — every app here is a fresh process on each start, not a resumed one — so
this is "auto-launch + auto-route + auto-arrange," not literal state persistence. Not
worth doing for arbitrary terminals (their value is the specific running session, which
can't be restored either way), but makes sense for these four since a fresh instance is
exactly what's wanted.

## Change

`~/.config/hypr/config/variables.lua` — added a toggle:
```lua
-- Special workspace auto-launch (see config/autostart.lua)
AUTOSTART_HIDDEN_APPS = true -- launch+arrange claude/spotify/labvpn/home into the special workspace on every Hyprland start
```

`~/.config/hypr/config/autostart.lua` — inside the existing `hl.on("hyprland.start", ...)`
block, added (now gated behind `AUTOSTART_HIDDEN_APPS`):
```lua
    -- Auto-hidden apps: routed straight into the special workspace by matching
    -- window_rules in windowrules.lua (titles below must match those rules
    -- exactly). Launched sequentially — each one only after the previous
    -- window has actually mapped — rather than all at once, because Hyprland
    -- assigns master-layout master/stack-order to whichever window's surface
    -- maps *first*, not whichever hl.exec_cmd call fired first. Firing all
    -- four back-to-back races them against each app's own startup latency:
    -- confirmed on a real restart that claude (kitty -> fish -> the Claude
    -- CLI booting) lost that race and ended up in a stack slot instead of
    -- master. wait_then polls for a window (hl.get_windows) every 200ms and
    -- gives up after ~10s (falling through with a nil window rather than
    -- blocking the rest of the chain forever), so one unusually slow app
    -- can't stop the others from launching.
    --
    -- Toggle via AUTOSTART_HIDDEN_APPS in config/variables.lua; takes effect
    -- on the next full Hyprland restart (this hook doesn't rerun on a plain
    -- `hyprctl reload`).
    if AUTOSTART_HIDDEN_APPS then
    local function wait_then(filter, tries_left, fn)
        local w = hl.get_windows(filter)[1]
        if w or tries_left <= 0 then
            fn(w)
        else
            hl.timer(function() wait_then(filter, tries_left - 1, fn) end, { timeout = 200, type = "oneshot" })
        end
    end

    hl.exec_cmd("kitty --title special-claude --directory ~/claude -e fish -c claude")
    wait_then({ title = "special-claude" }, 50, function(claude)
        -- Force master explicitly too, as a safety net — cheap no-op if
        -- claude is already master (expected, since it should be the only
        -- window in the freshly-emptied special workspace at this point).
        if claude then
            hl.dispatch(hl.dsp.focus({ window = claude }))
            hl.dispatch(hl.dsp.layout("swapwithmaster"))
            hl.dispatch(hl.dsp.layout("mfact exact 0.45"))
        end

        hl.exec_cmd("flatpak run com.spotify.Client")
        wait_then({ class = "^(spotify)$" }, 50, function(spotify)
            hl.exec_cmd("kitty --title special-labvpn -e fish -c labvpn")
            wait_then({ title = "special-labvpn" }, 50, function(labvpn)
                hl.exec_cmd("kitty --title special-home")
                wait_then({ title = "special-home" }, 50, function(home)
                    -- spotify (biggest) > home (medium) > labvpn (smallest).
                    -- Master layout's stack is a nested split (spotify vs
                    -- {labvpn, home}, then labvpn vs home within that):
                    -- resizing the *top* stack window (spotify) rescales the
                    -- labvpn/home pair proportionally while preserving
                    -- whatever ratio they already had, but resizing a
                    -- *middle* window (labvpn) only moves its own boundary
                    -- with the window below it (home), leaving spotify
                    -- untouched. So order matters — set the labvpn/home
                    -- ratio first, then grow spotify (which shrinks both
                    -- proportionally without disturbing that ratio):
                    if labvpn then
                        hl.dispatch(hl.dsp.focus({ window = labvpn }))
                        hl.dispatch(hl.dsp.window.resize({ x = 0, y = -80, relative = true }))
                    end
                    if spotify then
                        hl.dispatch(hl.dsp.focus({ window = spotify }))
                        hl.dispatch(hl.dsp.window.resize({ x = 0, y = 150, relative = true }))
                    end
                end)
            end)
        end)
    end)
    end
end)
```

`~/.config/hypr/config/windowrules.lua` — added (matches the titles above):
```lua
-- Auto-hidden apps: sent straight into the special workspace on open (paired with
-- autostart.lua launching them at startup). Kitty instances are told apart by the
-- --title flag; initial_title is used so a later shell/program title change (fish,
-- claude, labvpn's prompt) doesn't cause the rule to stop matching.
hl.window_rule({ match = { class = "^(spotify)$" }, workspace = "special" })
hl.window_rule({ match = { class = "^(kitty)$", initial_title = "^(special-claude)$" }, workspace = "special" })
hl.window_rule({ match = { class = "^(kitty)$", initial_title = "^(special-labvpn)$" }, workspace = "special" })
hl.window_rule({ match = { class = "^(kitty)$", initial_title = "^(special-home)$" }, workspace = "special" })
```

## Notes
- **Enable/disable (added 2026-09-01):** the whole sequence is gated behind
  `AUTOSTART_HIDDEN_APPS` in `config/variables.lua` (defaults `true`). Set it to `false` and
  restart Hyprland to skip the auto-launch entirely — the special workspace then just starts
  empty, as before this feature existed. Verified: `luac -p` on both edited files (syntax
  clean) and `hyprctl reload` (config loads with no errors). Not re-verified via an actual
  restart with the flag set to `false` — the gating is a single `if AUTOSTART_HIDDEN_APPS
  then ... end` wrapped around the previously-verified body, so no new runtime mechanics were
  introduced.
- **Why `initial_title` and not `title`:** `fish`, `claude`, and `labvpn`'s own prompt all
  set the terminal title dynamically once running. `initial_title` is captured once at
  window creation (before any of that happens), so the rule keeps matching regardless of
  what the shell/program does to the title afterward.
- **Why each kitty gets a distinct `--title`:** `class` alone is just `kitty` for all
  three — without a distinguishing title, a plain `class = "kitty"` rule would send
  *every* kitty window (including ones you open normally) straight into special.
- **Why layout is done via `hl.timer` + dispatch, not `workspace_rule`'s `layout_opts`:**
  tried `hl.workspace_rule({ workspace = "special", layout = "master", layout_opts =
  { mfact = 0.45 } })` first — it loads without error and `hyprctl workspacerules` shows
  the rule as registered, but the actual mfact never changes (confirmed live: a freshly
  created test special workspace with this rule still split 55/45, the plain default, not
  45/55). Whatever this Hyprland-Lua build does with `layout_opts` for workspace rules,
  it isn't being honored at runtime. The `hl.dispatch(hl.dsp.layout("mfact exact 0.45"))`
  approach (same mechanism the reset-window-size bind already uses, see [[resize]]) is
  confirmed working instead — a 2.5s `hl.timer` after launch gives all four windows time
  to map before focusing `claude` and setting mfact.
- **How the two resize steps interact (nested-split discovery):** this needed two rounds
  of live testing to get right. First attempt tried resizing only `spotify` (the top
  stack window) directly by +150 — expected it to shrink only its immediate neighbor
  (`labvpn`), but it actually shrank `labvpn` *and* `home` roughly equally instead
  (423px / 200px / 202px). That revealed master layout treats a 3-window stack as a
  **nested** split rather than three independently-resizable panes: `spotify` is split
  against `{labvpn, home}` as a combined block at the top level, and `labvpn`/`home` split
  *within* that block at a second level. Resizing the top-level window rescales the whole
  nested block proportionally, preserving whatever ratio its children already had;
  resizing a window inside the nested block only affects its own immediate boundary
  within that block. So the fix is ordering: set the `labvpn`/`home` ratio *first* (while
  the block is still at its default combined size), *then* grow `spotify`, which shrinks
  the block down while preserving the ratio just set.
- Verified live end-to-end using **five separate temporary named special workspaces**
  (`special:claudetest` through `special:claudetest5` — one per iteration of this layout,
  including the two rounds needed to work out the nested-split behavior above) with
  throwaway `kitty` windows, specifically so the real contents already sitting in
  `special:special` (pre-existing kitty/Spotify windows from normal daily use) wouldn't be
  disturbed by testing. Final confirmed result: spotify 423px > home 255px > labvpn 147px
  — clear monotonic biggest/medium/smallest ordering. All test windows and scratch
  workspaces were cleaned up afterward — nothing about this verification touched the
  user's actual hidden windows. The `claude`-in-`~/claude` variant specifically wasn't
  live-tested (spawning a nested Claude Code session as a test seemed unnecessary risk for
  no extra signal) — `~/claude` existing and `claude` being on `$PATH` were checked
  instead.
- This is not true session restore — if you're mid-task in the `claude` terminal, a
  reboot loses that conversation like any other terminal program. It only guarantees a
  *fresh* instance of each app is sitting there hidden, in this layout, after every start.
- Takes effect on next full Hyprland restart (`autostart.lua`'s `hyprland.start` hook
  doesn't rerun on a plain `hyprctl reload`).

## Bug: claude didn't become master on a real restart (fixed 2026-08-29)

**What happened:** on the first actual Hyprland restart after setting this up, `claude`
ended up in a stack slot ("right middle") instead of becoming master, even though its
`hl.exec_cmd` was listed first in `autostart.lua`.

**Root cause:** all four `hl.exec_cmd` calls fire back-to-back with no synchronization —
Hyprland assigns master/stack-order based on whichever window's Wayland surface actually
*maps* first, not the order the exec calls were issued in. `claude` (kitty → fish → the
Claude CLI itself booting) apparently took longer to actually present its window than one
of the other three, so something else won the race for master. Every previous "verified
live" test in this doc used manual `sleep`-staggered spawns from Bash, which accidentally
avoided this race — the bug only showed up once `autostart.lua` ran for real, with no
staggering, on an actual restart.

**Fix:** replaced the parallel `hl.exec_cmd` calls with a sequential chain using a
`wait_then(filter, tries_left, fn)` helper (shown in the `Change` section above) that
polls `hl.get_windows()` every 200ms and only launches the next app once the previous
one's window is confirmed to exist (giving up after ~10s per app rather than blocking
forever, so one slow app can't prevent the rest from launching). Also added an explicit
`hl.dispatch(hl.dsp.layout("swapwithmaster"))` on `claude` as a cheap defense-in-depth
safety net — a no-op in the expected case (claude already master, being the only window
in an empty special workspace at that point) but a real fix if some future timing edge
case still lets another window slip into master first.

**Verified:** the `wait_then` polling primitive itself, both paths — live-tested via
`hyprctl repl` with a deliberately delayed dummy window (confirmed the callback correctly
waits for and detects a window that only appears ~2.5s later) and with a window that never
appears (confirmed the callback still fires, with a `nil` window, after exhausting
retries, rather than hanging). The full sequential chain wasn't re-tested via an actual
Hyprland restart (too disruptive to trigger unprompted) — the individual pieces (each
`exec_cmd` command, the `wait_then` polling behavior, the resize/master-assignment
dispatches) were each already verified working in isolation across the earlier rounds
above, so this composes them rather than introducing new unverified mechanics.

**Confirmed fixed** (2026-08-29, next restart): user confirmed `claude` correctly lands in
the master pane now.

## Tried and reverted: launching fully invisibly (2026-08-29)

**What was wanted:** the whole launch sequence (windows appearing one by one, visibly, for
several seconds during login) happening completely in the background, with the special
workspace only ever appearing once the user actually presses `SUPER+S`.

**Root cause found:** any newly-created window auto-focuses by default, and a window
becoming focused while sitting in `special` makes Hyprland auto-show the whole overlay as
a side effect — confirmed live, including for windows placed into special via pure
declarative `window_rule` with no explicit script-side focus call at all. On top of that,
the layout script's own `hl.dsp.focus()` calls (needed for `swapwithmaster`/`mfact`/resize
— there's no way to target a window for those without focusing it first) triggered the
same behavior, and the original code only hid the overlay once at the very end, leaving it
visible for the entire multi-second sequence in between.

**Attempted fix:** added `no_focus = true` to all four `window_rule`s (to stop each new
window auto-focusing on creation) plus a `hide_special_if_shown()` helper called after
every focus-requiring step in `autostart.lua` (so any flash from the script's own focus
calls would be instantaneous rather than sustained).

**Why it was reverted:** on the next real restart, two problems remained — the launch was
still visibly showing, *and* `no_focus = true` broke normal click-to-focus on these windows
afterward (couldn't click into them anymore). Given the user's explicit "don't bother with
it if it's hard to do, just revert" — the fix wasn't fully working and wasn't worth chasing
further for a cosmetic issue. Both `autostart.lua` and `windowrules.lua` were reverted back
to the pre-`no_focus` versions shown in the `Change` section above (which still keep the
correct master/stack arrangement — only the visibility-during-launch behavior is
unresolved).

**Status:** unresolved, accepted as-is. The launch sequence is visible for a few seconds
on every login/restart; apps still end up correctly hidden-and-arranged in special once the
sequence finishes. If revisiting this later: the `no_focus` breaking click-to-focus
afterward is the specific thing to solve differently (maybe a rule that's only active
during the launch window rather than permanent, if such a thing is even possible in this
Hyprland-Lua build) — don't just retry plain `no_focus` again.
