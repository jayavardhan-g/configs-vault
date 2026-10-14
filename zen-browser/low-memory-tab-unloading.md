# Low-memory tab unloading (how it really behaves in Zen)

**Date:** 2026-10-08
**Category:** zen-browser
**Files touched:** `nnwin01.Nani/prefs.js` (set via `about:config`; the file itself isn't
stored, since it holds account/sync state)

## What
Profile `nnwin01.Nani` has Firefox's low-memory tab unloader turned on with a 60%
threshold. Investigated why "no tabs ever unload"; the mechanism works, the threshold just
isn't reached in normal use, and Zen gives no visual sign when it does unload.

## Why
Tabs never seemed to unload despite `unloadOnLowMemory = true` and a 60% threshold.

## Change
Current values (`about:config`):
```
browser.tabs.unloadOnLowMemory                     true
browser.low_commit_space_threshold_percent         60
browser.tabs.min_inactive_duration_before_unload   1000   (default 600000 = 10 min)
```

## Notes
Verified 2026-10-08 on Zen 1.22.3b (Firefox 156), Flatpak, in a throwaway profile driven
over Marionette (`--marionette -remote-allow-system-access`):
- **The threshold is "available memory at or below X% of total", not "usage reaches X%".**
  From `xpcom/base/AvailableMemoryWatcherLinux.cpp`:
  `MemAvailable * 100 / MemTotal <= low_commit_space_threshold_percent`, OR
  `MemAvailable < low_commit_space_threshold_mb` (default 200). So 60 = start unloading
  once ~40% of RAM (~6.2 GB of 15.4 GB) is in use. To unload "when usage hits 60%", the
  value would be 40.
- **It only polls while you're using the browser.** The watcher polls `/proc/meminfo`
  every 5 s (every 1 s once low) and stops on `user-interaction-inactive` (≈5 s without
  input). An untouched browser never unloads anything.
- **When low, it unloads one tab per second**, least-recently-used first. It never unloads
  the selected tab, and tabs that are playing media, in PiP, using WebRTC or private are
  never unloaded; pinned tabs go last. Test at threshold 95%: all 6 background tabs gone
  within ~6 s of activity.
- **Once nothing is left to unload, it fires `memory-pressure` every second** while memory
  stays low (cache purges/GC). Measured cost in the test was negligible
  (~0.5% of one core vs ~0.25%).
- **Unloaded tabs look identical in Zen's sidebar.** Zen's UI loads none of Firefox's
  `[pending]` fade rules, so `browser.tabs.fadeOutUnloadedTabs` does nothing here (tested).
  To check what's unloaded, use `about:processes` (unloaded tabs disappear from it) or
  `about:unloads`.
- Zen 1.22 has no time-based unloader (`zen.tab-unloader.*` prefs are gone); the
  memory-based one is the only built-in mechanism.
- `TabUnloader` moved to `moz-src:///browser/components/tabbrowser/TabUnloader.sys.mjs`
  and is registered by the `browser-idle-startup` category. Zen patches it to walk
  `gZenWorkspaces.allStoredTabs`, so tabs in all workspaces are candidates.
- In debugging, sending `user-interaction-active` every 2 s (Marionette) *delays* the first
  poll, because each notification restarts the 5 s timer. Real input only sends it on the
  idle→active transition, so this doesn't affect normal use.
