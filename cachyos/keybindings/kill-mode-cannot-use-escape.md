# Kill mode can't be bound to Escape: SUPER+Escape → SUPER+ALT+Q

**Date:** 2026-09-21
**Category:** keybindings
**Files touched:** `~/.config/hypr/config/binds.lua`

<!-- graph:begin -->
**Graph:** [[Hyprland]]
<!-- graph:end -->

## What
The force-kill picker (`hyprctl kill` — cursor becomes a crosshair, click a window to kill
it) moved from `SUPER+Escape` to `SUPER+ALT+Q`. On `SUPER+Escape` it was broken in a way
that looked like a flicker: the crosshair appeared and vanished within the same keypress.

## Why
**Escape is kill mode's own cancel key, and the cancel check runs on key RELEASE as well
as press.** `src/managers/KeybindManager.cpp`, `handleInternalKeybinds()`:

```cpp
// handle ESC while in kill mode
if (g_pInputManager->getClickMode() == CLICKMODE_KILL) {
    const auto KBKEY = xkb_keysym_from_name("ESCAPE", XKB_KEYSYM_CASE_INSENSITIVE);
    if (keysym == KBKEY) {
        g_pInputManager->setClickMode(CLICKMODE_DEFAULT);
        return true;
    }
}
```

`exec_cmd` is asynchronous, so the order of events was:

1. Escape **press** → the `SUPER+Escape` bind fires → `hyprctl kill` is spawned.
2. A few milliseconds later `hyprctl kill` lands and kill mode turns on.
3. The **release** of that same Escape key reaches `handleInternalKeybinds`, which is now
   in `CLICKMODE_KILL`, sees the Escape keysym, and cancels.

Net effect: the mode switched on and straight back off on one press. Nothing was
misconfigured — the bind fired correctly every time.

**This is structural, not a tuning problem.** No chord containing Escape can hold kill
mode, regardless of modifiers, because the cancel check only looks at the keysym and
ignores modmask entirely.

## Change
```lua
hl.bind(mainMod .. " + ALT + Q", hl.dsp.exec_cmd("hyprctl kill"))
```
`SUPER+ALT+Q` pairs with `SUPER+Q` (close window) — same letter, more force. The extra
modifier is deliberate: this kills without giving the app a chance to save. `SUPER+Escape`
is now free.

## Notes
- **Diagnostic worth remembering:** the symptom "the crosshair flashes" was the thing that
  cracked this. Before that it looked like the bind wasn't firing at all, and the
  investigation was heading toward keymap resolution — `hyprctl binds` showed the bind
  registered, `kb_options` applied, and `hyprctl kill` valid as a subcommand, so every
  static check passed and none of them could have found this. A bind that fires and then
  undoes itself is indistinguishable from a dead bind unless you watch the cursor.
- **This incidentally confirms how `caps:swapescape` resolves for binds.** The crosshair
  appearing at all proves that pressing the **CapsLock-position** key produces the Escape
  keysym as far as keybind matching is concerned — so `caps:swapescape` does apply to bind
  resolution, not just to text input. That's the assumption behind binding both `escape`
  and `Caps_Lock` as exits in the resize submap ([[resize]]); it holds.
- `CONTROL+SHIFT+Escape` (btop) is unaffected — it doesn't involve kill mode, so nothing
  cancels it. It remains the only Escape bind in the config.
- Related cleanups from the same day: [[dead-bind-cleanup]],
  [[wallpaper-picker-on-super-w]], [[floating-window-nudge]].
