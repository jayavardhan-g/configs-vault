# Finger mapping for modifier-heavy keybinds

**Date:** 2026-08-29
**Category:** keybindings
**Files touched:** none — this is a usage convention, not a config change

<!-- graph:begin -->
**Graph:** [[Hyprland]]
<!-- graph:end -->

## What
A consistent rule for which finger presses which key across all the vim-style binds in
[[vim-navigation]], [[resize]], [[workspace-switching]], and [[special-workspace-toggle]],
so the whole set can be habituated as one motor pattern instead of memorizing each combo
separately.

## Why
User wanted these binds to become second nature with minimal conscious effort, and asked
specifically how to finger multi-modifier combos like `SUPER+CTRL+h/l`. Worked out that
picking fingers per-combo in isolation produces inconsistent, harder-to-learn patterns —
a single general rule, applied consistently, habituates faster even if a couple of
individual combos aren't each perfectly optimal in isolation.

## The rule
Whichever hand naturally types the **letter** in standard touch-typing does *only* that —
it never also holds a modifier. The other hand carries every modifier the combo needs,
stacking fingers as required:

- **Thumb → Super** (and Alt)
- **Pinky → Ctrl**
- **Ring → Shift**

`h/j/k/l` are right-hand keys in standard touch-typing (H = right index stretching left,
J = right index home, K = right middle, L = right ring), so `hjkl` binds put all modifiers
on the **left** hand. `R` and `S` are left-hand keys, so binds built on them put the
modifier on the **right** hand instead (using Right Alt, which sends Super — see
[[right-alt-as-super]]). `M` is a right-hand key, so it follows the same pattern as `hjkl`.

## Reference table

| Bind | Modifier hand/finger(s) | Letter hand/finger |
|---|---|---|
| `SUPER+h/j/k/l` (focus) | left thumb | right: index (h), index (j), middle (k), ring (l) |
| `SUPER+SHIFT+h/j/k/l` (move window) | left thumb + ring | same right-hand fingers |
| `SUPER+CTRL+h/l` (workspace switch) | left thumb + pinky | right index (h) / ring (l) |
| `SUPER+ALT+h/j/k/l` (nudge floating window) | right thumb (Right Alt = Super) + left thumb (Left Alt) | same right-hand fingers |
| `SUPER+R` (resize submap) | right thumb (Right Alt) | left index |
| `SUPER+M` (swap master) | left thumb | right index |
| `SUPER+S` (toggle special visible) | right thumb (Right Alt) | left ring |
| `SUPER+SHIFT+S` (send to / pull from special) | right thumb (Right Alt) + left pinky (Shift) | left ring (S) |
| `SUPER+SHIFT+F` (toggle float) | left thumb (Super) + left pinky (Shift) | right index (F) |

## Notes
- **Why thumb+pinky / thumb+ring work well together:** thumb and pinky (or thumb and
  ring) are far enough apart on the hand that holding both simultaneously has no
  interference — a natural "spread," not a cramped chord.
- **Why `SUPER+SHIFT+S` isn't just "left thumb + left ring + left pinky":** that would be
  a 3-finger left-hand claw (thumb+pinky+ring, skipping the middle two), which is
  awkward. Since `S` is a left-hand letter, the rule says the modifier(s) belong on the
  *right* hand — but only **Super** actually needs to move there; **Shift** stays paired
  with `S` on the left hand because pinky+ring are *neighboring* fingers, making
  Shift+S a natural same-hand chord (the same motion used for any other shifted
  left-hand key). Moving only Super to the right thumb — the easiest finger to deploy
  cross-hand, since it isn't committed to any home-row letter — avoids both the claw and
  an awkward reach to the right Shift key. This was the corrected version after an
  initial draft of this rule (right pinky for Shift instead) turned out to be a less
  natural fit.
- This table only covers binds actually in use; apply the same rule (letter's hand types
  cleanly, other hand stacks thumb/pinky/ring as needed) to any new bind added later.
