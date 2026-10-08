# Migrating Zen Browser profiles from Windows to Linux

**Date:** 2026-09-20
**Category:** zen-browser
**Files touched:** `~/.var/app/app.zen_browser.zen/.zen/profiles.ini`, `~/.var/app/app.zen_browser.zen/.zen/Profile Groups/<StoreID>.sqlite`, `~/.local/share/applications/zen-*.desktop`, `~/.local/bin/zen-*`

<!-- graph:begin -->
**Graph:** [[BitLocker]] · [[Windows]] · [[Zen Browser]]
<!-- graph:end -->

## What
Copied all 4 Zen Browser profiles (Windows profile names: Nani, Nightmare, Study, Fake)
from a BitLocker-encrypted Windows install into the CachyOS flatpak install of Zen
(`app.zen_browser.zen`), registered them as launchable profiles, made one (Nani) the
default, and added per-profile app-launcher entries. The pre-existing Linux Zen profile
was initially left untouched (an additive import, not a merge/overwrite) and later
deleted outright the same day once Nani was confirmed sufficient — see Notes.

## Why
Wanted browsing history, bookmarks, logins, and Zen's own "Spaces" carried over from the
Windows install rather than starting fresh on Linux. Zen is Firefox-based, so profile
data (`places.sqlite`, `key4.db`/`logins.db`, spaces/workspace state) is stored in
cross-platform SQLite/JSON inside the profile folder and survives an OS-to-OS copy intact
— the only things that don't carry over cleanly are the profile *registration* (which
Zen's UI needs to know about) and its "Profiles" switcher panel, which uses a separate
per-install database not derived from `profiles.ini`.

## Change

### 1. Get the Windows profiles readable
The Windows `C:` drive is BitLocker-encrypted; unlocking/mounting it (`cryptsetup
--type bitlk` via `bit-unlock`, mounted at `/mnt/desktop-c` — see
[[bit-unlock-cryptsetup]] in `bitlocker/`) was already set up from an earlier session —
not part of this change. Windows Zen profiles live under
`<C:>\Users\<user>\AppData\Roaming\zen\Profiles\`, listed in
`<same>\zen\profiles.ini`.

### 2. Copy each profile folder, cleanly
Checked each source profile's `*.sqlite-wal` files were 0 bytes (clean shutdown) before
copying — copying a profile with a non-empty WAL risks losing uncommitted writes. Then:

```bash
cp -a "<mounted C:>/Users/<user>/AppData/Roaming/zen/Profiles/<src folder>" \
      ~/.var/app/app.zen_browser.zen/.zen/<new-linux-folder-name>
rm -f ~/.var/app/app.zen_browser.zen/.zen/<new-linux-folder-name>/parent.lock \
      ~/.var/app/app.zen_browser.zen/.zen/<new-linux-folder-name>/lock
find ~/.var/app/app.zen_browser.zen/.zen/<new-linux-folder-name> -name "*.sqlite-wal" -size 0 -delete
find ~/.var/app/app.zen_browser.zen/.zen/<new-linux-folder-name> -name "*.sqlite-shm" -delete
```

`parent.lock`/`lock` are Windows-session artifacts and must be removed or Zen may refuse
to open the profile thinking it's already in use elsewhere.

### 3. Register each profile in `profiles.ini`
Added one `[ProfileN]` block per imported profile (no `Default=1` yet at this stage):

```ini
[Profile2]
Name=Nani
IsRelative=1
Path=nnwin01.Nani
```

Full current state of the file: [`files/.var/app/app.zen_browser.zen/.zen/profiles.ini`](files/.var/app/app.zen_browser.zen/.zen/profiles.ini).
`nnwin01.Nani` etc. are new folder names chosen for the Linux side — no requirement to
match the Windows folder's random-salt name.

### 4. Verify each profile actually opens
Launched each as a separate instance to confirm no corruption before relying on it:

```bash
flatpak run app.zen_browser.zen -P Nani --new-instance
```

Confirmed real content-process trees spawned (tabs rendering) for all four, then closed
each by killing the *actual* `zen` PID — killing the `bwrap` wrapper PID (what
`pgrep -f` matches first for a flatpak-launched process) does **not** terminate the app;
find the child `/app/zen/zen ...` PID and kill that instead.

### 5. Set the default profile
Zen/Firefox check the `[Install<hash>]` section's `Default=` key (not just a profile's
own `Default=1` flag) for which profile a no-flag launch uses:

```ini
[Install2953CB39A2589173]
Default=nnwin01.Nani
Locked=1

[Profile2]
...
Default=1
```

Moved `Default=1` off the old default profile onto the new one, and updated the Install
section's `Default=` path to match. This only affects *future* launches — already-open
windows are unaffected.

### 6. Make imported profiles show up in Zen's in-app "Profiles" switcher
Zen's newer built-in profile-switcher panel (the one under the account icon, offering
"Create a New Profile" / "Sign in to sync") does **not** read `profiles.ini` — it reads a
per-group SQLite database at
`~/.var/app/app.zen_browser.zen/.zen/Profile Groups/<StoreID>.sqlite`, table `Profiles`
(columns: `path, name, avatar, themeId, themeFg, themeBg`). This table is only populated
when a profile is created *through that UI*, so profiles registered by hand-editing
`profiles.ini` are invisible to the switcher even though they launch fine from the CLI.

Fix: read the matching row values from the **Windows-side** copy of the same group DB
(`<mounted C:>/Users/<user>/AppData/Roaming/zen/Profile Groups/<StoreID>.sqlite`) and
insert equivalent rows into the Linux-side DB, using the Linux `profiles.ini` paths:

```bash
sqlite3 ~/.var/app/app.zen_browser.zen/.zen/"Profile Groups"/<StoreID>.sqlite <<'EOF'
INSERT INTO Profiles (path, name, avatar, themeId, themeFg, themeBg) VALUES
  ('nnwin01.Nani', 'Nani', 'flower', 'default-theme@mozilla.org',
   'rgba(255, 255, 255, 0.8)', 'rgba(43, 42, 51, 1)');
  -- one row per profile, values copied from the Windows-side DB's same table
EOF
```

Safe to run while a profile in that group is open — SQLite WAL mode handles the
concurrent write; no need to close the browser first. Note only profiles that already
share the *same* `StoreID` (a value Zen wrote into each imported profile's own
`profiles.ini` entry automatically, on first launch, if the profile folder itself already
belonged to a Windows-side profile group) end up in the same switcher panel — an imported
profile with no `StoreID` won't offer this at all.

### 7. Add app-launcher entries
One `.desktop` file per imported profile in `~/.local/share/applications/`, each launching
a small per-profile wrapper script in `~/.local/bin/` rather than an inline flatpak
command:

```sh
# ~/.local/bin/zen-nani  (chmod +x)
#!/bin/sh
exec /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=launch-script.sh --file-forwarding app.zen_browser.zen -P Nani --new-instance "$@"
```

```ini
[Desktop Entry]
Name=Zen (Nani)
Comment=Zen Browser — Nani profile
Exec=/home/jayavardhan/.local/bin/zen-nani %u
Icon=app.zen_browser.zen
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
Terminal=false
X-MultipleArgs=false
```

Real copies of all four `.desktop` files and wrapper scripts:
[`files/.local/share/applications/`](files/.local/share/applications/),
[`files/.local/bin/`](files/.local/bin/).
Ran `update-desktop-database ~/.local/share/applications` afterward so launchers pick
them up immediately.

**Gotcha (noctalia shell specifically):** the first version of these `.desktop` files
included `StartupWMClass=zen` (copied straight from Zen's own installed entry). Noctalia's
launcher (`~/.cache/noctalia/noctalia.log`, `[desktop_entry]` log lines) treats matching
`StartupWMClass` as "the same app" and silently collapses duplicates to one entry — so
all 4 imported-profile launchers plus the base Zen entry got folded down to effectively
one visible icon, with no warning logged. Confirmed via the app-count in that log
(`refreshed desktop entries: N apps`) jumping from a wrong `+1` to the correct `+4` once
`StartupWMClass` was removed from the 4 new files. Since the wrapper-script `Exec=` also
makes each entry fully distinct (not just near-identical flatpak invocations), both
changes together are the safest combination if this needs redoing on another
noctalia-based setup — omit `StartupWMClass` on any `.desktop` file meant to be a
*distinct* launch target for an app that's already otherwise installed.

## Notes
- Bookmark/history/password merging **into** the pre-existing Linux profile was
  considered but deliberately skipped — the imported Windows profile (Nani) was judged to
  already supersede the old Linux profile's value, so no merge was done. If needed later:
  Zen/Firefox support bookmark export/import via HTML (`about:preferences` → Bookmarks
  Manager) and password export/import via CSV (`about:logins` → "⋯" menu) — both
  additive/non-destructive, no natively-supported way to merge `places.sqlite` history
  across profiles.
- **Update, same day:** the pre-existing Linux profile (`6kha6tir.Default (release)`,
  1.1G) was deleted outright once Nani was confirmed as a full replacement — no merge
  ended up happening. Deleted after confirming no running process had it open (checked
  `lock` symlink + `/proc/<pid>/fd` across all running `zen` PIDs), then removed its
  `[Profile0]` block from `profiles.ini` and confirmed neither `Profile Groups/*.sqlite`
  DB referenced its path. The still-present `xbt3gnri.Default Profile` (`[Profile1]`,
  ~4K, effectively empty) was left alone — not the profile in question, and trivial to
  delete later the same way if it's ever unwanted.
- **Gotcha found from the above:** deleting `[Profile0]` without renumbering the
  remaining `[ProfileN]` sections broke *every* launch path (CLI `-P <name>`, the app
  launchers, and any WM keybind pointing at the app) — all of them fell through to
  Zen/Firefox's classic Profile Manager dialog showing a completely **empty** profile
  list, as if `profiles.ini` had no profiles at all. Cause: the toolkit profile-manager
  parser reads `Profile0`, `Profile1`, `Profile2`, … as a strictly sequential,
  zero-indexed scan and stops at the first missing number — it does not skip gaps or
  scan by section name. Fix: whenever a `[ProfileN]` section is removed, renumber every
  remaining `[ProfileN]` section so they run `0, 1, 2, …` with no gaps (matching the new
  live state in
  [`files/.var/app/app.zen_browser.zen/.zen/profiles.ini`](files/.var/app/app.zen_browser.zen/.zen/profiles.ini)).
  Verified fixed by launching `flatpak run app.zen_browser.zen -P Nani --new-instance`
  and confirming real content processes spawn instead of the Profile Manager dialog.
- Only profiles actually needed were imported this way; if Zen is ever reinstalled fresh,
  repeat steps 2–4 minimum (3, 5–7 optional) per profile to bring than back.
- This whole procedure is Zen/Firefox-profile-format-specific, not Hyprland/CachyOS-caused
  — would apply identically on GNOME, KDE, or any other Linux desktop. The step 7 gotcha
  is the one noctalia-shell-specific exception within it.
