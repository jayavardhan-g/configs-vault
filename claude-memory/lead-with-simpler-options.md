---
name: lead-with-simpler-options
description: "Don't solve the user's literal UI framing when a simpler mechanism already covers the underlying goal"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 714475f4-e8ea-4199-a155-7feb30cce91a
  modified: 2026-09-21T14:37:35.434Z
---

When the user describes a goal in terms of a specific UI/interaction they're picturing
(e.g. "fill the password into the input box when I click the drive"), don't immediately
design toward that literal mechanism (e.g. keystroke-injection autofill via `wtype`/
`ydotool`). Step back and ask what the underlying goal actually is (e.g. "unlock without
retyping the password"), then check whether a simpler path already exists — especially
one already used earlier in the same conversation.

**Why:** Jayavardhan called this out directly — asked for BitLocker password autofill
into a GUI unlock dialog, and I researched/proposed `wtype`+Wayland-protocol keystroke
injection before he suggested the much simpler route: unlock via terminal directly
(`cryptsetup open --type bitlk --key-file=-`, piping the password in from `bw get
password`, no GUI interaction at all). The `--key-file` mechanism had already come up
earlier in the *same* conversation for a plaintext-keyfile approach — piping Bitwarden's
output into that same flag was a one-line connection that got missed because I was
anchored on the literal "fill the input box" framing instead of the actual goal.

**How to apply:** Before designing an automation/integration, especially one involving
extra tooling (input injection, browser extensions, background daemons), pause and check:
is there a boring, direct CLI path to the same end result that avoids the UI entirely?
Prefer that, and only reach for UI-mimicking automation (autotype, autofill) when no
direct path exists. This generalizes beyond BitLocker/Bitwarden — applies to any
system-config task with this user.

**Second form of the same mistake — check what's already installed before adding
anything.** Before installing a new app or writing a script, check whether the software
already running covers it. Concretely: **noctalia ships a plugin registry of 200+ plugins**
(`noctalia msg plugins list`, catalogue in `~/.local/state/noctalia/plugins/sources/`,
upstream `noctalia-dev/official-plugins` and `community-plugins`). Nothing is installed
until enabled, so listing it is free and costs one command.

Missed twice, both found only because Jayavardhan asked something else:
- **Xpad (2026-09-12):** desktop sticky-notes app installed, plus a launch script,
  workspace 7 wiring and monitor-persistence rules. Alternatives *were* weighed, but only
  `sticky` vs `xpad` — two desktop apps. `noctalia/notes` and
  `ahmedhossamdev/sticky-notes` were never considered. (Xpad may still have been right —
  it gives arrangeable note *windows*, the plugins give a shell panel — but it was never
  put on the table.) See [[noctalia-plugin-registry]].
- **2026-09-21:** offered to hand-roll a keybind cheatsheet script, then found
  `kenn/keybind-cheatsheet` already in the registry the same session.

Jayavardhan called this out directly: *"If we already had a notes application why didn't
you say it to me before you suggested xpad?"*

<!-- graph:begin -->
**Graph:** [[Noctalia]] · [[Monitors]] · [[Xpad]] · [[BitLocker]] · [[Bitwarden]]
<!-- graph:end -->
