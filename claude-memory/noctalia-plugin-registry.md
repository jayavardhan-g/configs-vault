---
name: noctalia-plugin-registry
description: Noctalia ships a 200+ plugin catalogue - check it before installing an app or writing a script
metadata: 
  node_type: memory
  type: reference
  originSessionId: 9a81cd6e-4cb2-4e35-b841-e155a43c540e
  modified: 2026-09-21T14:37:47.629Z
---

Jayavardhan's shell is **noctalia**, and it carries a plugin registry of **200+ plugins**.
Check it before installing any app or writing any script for desktop functionality — see
[[lead-with-simpler-options]] for why this keeps getting missed.

```
noctalia msg plugins list                      # full catalogue + enabled/disabled state
noctalia msg plugins enable  <author/plugin>   # installs AND enables
noctalia msg plugins disable <author/plugin>
noctalia msg plugins update                    # refresh catalogue
noctalia msg plugins source list|add|remove
```

**"disabled" in that listing means NOT INSTALLED.** Only a catalogue is on disk —
`~/.local/state/noctalia/plugins/sources/` holds shallow git clones of
`noctalia-dev/official-plugins` and `noctalia-dev/community-plugins` (~13M). Plugin *code*
lands in `materialized/` only when enabled. So listing is free; don't describe the
catalogue as "already installed" (I made exactly that mistake and was corrected).

Plugins are Luau with a `plugin.toml` manifest declaring `[[widget]]` entries — a plugin
can supply a bar widget, a panel and a desktop widget at once. Each gets a GUI settings
page: `noctalia msg settings-open-plugin <author/plugin>`.

**Enabling a plugin does not place its widget** — that's done in Settings → Bar. Noctalia
owns `~/.local/state/noctalia/settings.toml` and rewrites it, so prefer the GUI over
hand-editing.

Ones relevant to things already discussed: `noctalia/timer` (countdown),
`nightwatch75/todo`, `noctalia/notes` + `ahmedhossamdev/sticky-notes` (vs the xpad setup),
`kenn/keybind-cheatsheet`, `thepunkoff/pomodoro`, `noctalia/world_clock`,
`davemhammer/gocryptfs` (cf. [[veracrypt-migration-plan]]), and several Claude Code
companions.

Community plugins are arbitrary Luau running inside the shell — worth a glance before
enabling one, and more so before `plugins source add` of a third-party registry.

<!-- graph:begin -->
**Graph:** [[Noctalia]] · [[Quickshell]] · [[Xpad]]
<!-- graph:end -->
