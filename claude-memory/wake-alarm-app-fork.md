---
name: wake-alarm-app-fork
description: "Wake = Jayavardhan's fork of the Chrono alarm app (jayavardhan-g/wake, branch `wake`, clone ~/claude/wake); built only by GitHub Actions on v* tags"
metadata:
  node_type: memory
  type: project
  originSessionId: cca4c73f-8b75-4188-a3cf-3f322f4addb4
  modified: 2026-10-22T20:45:22.045Z
---

**Status (2026-10-23): SHIPPED as v1.1.0 (1.1.0+30), the user's default alarm app.
The project is PAUSED.** The user will only resume it for a feature they really want; don't
propose more edge-case testing. The code is on branch `v3-direct-boot` (worktree
`~/claude/wake/.claude/worktrees/v2-native-ringer`), PR #1 into `wake` waits for the
user to merge. Open issue: a single "Dismiss / Dismiss" sighting on an alarm with a
custom label, not reproduced and location unknown. Untested: the alarm during a phone
call, and swipe-away during a call.

Since 2026-10-19 the Android alarm app has been moving from Chrono (vicolo-dev/chrono,
dormant since Jan 2025) to **Wake**, a fork based on Chrono v0.6.0 `master`. It is a
patched fork, not a rewrite: the user said so explicitly. Repo jayavardhan-g/wake (its
default branch is `wake`), main clone `~/claude/wake`, `upstream` remote =
vicolo-dev/chrono. Package `com.jayavardhan.wake` (the Kotlin namespace stays
com.vicolo.chrono). Phone: Motorola Edge 60 Pro (Android 17), with AppManager + Shizuku.

**Why:** Chrono alarms vibrated with no sound on the Alarm audio channel (it worked
on Media). The confirmed silent-failure path is just_audio skipping play() when audio
session activation fails (upstream #523). The optional foreground notification held a
permanent wake lock, which kept the phone out of deep sleep. The user wants alarms
that left ringing snooze instead of being dismissed (Chrono had no ring timeout at all).

**How to apply:**
- No Flutter, Java or Android SDK on the PC. The Tests workflow (flutter analyze +
  test) runs on push, and the release workflow builds signed split APKs on `v*` tags,
  in the same style as [[ghosttext-custom-stack]].
- The signing key is in `~/.local/share/wake-signing/` (release.p12 + key.properties)
  and is also in the repo's Actions secrets. Losing it means users must reinstall.
- Publishing a release (pushing a tag) needs the user's go-ahead.
- Releases v1.0.0-beta.1 (sound fix) and beta.2 (+ auto-snooze) were published on
  2026-10-19 as prereleases. Auto-snooze: a per-alarm "Ring Duration" setting (Snooze
  group, default 5 min) that snoozes the alarm and counts toward Max Snoozes; once
  none are left it dismisses the alarm and posts a "Missed alarm" notification.
- Repro of #523 on the user's phone: play media, pause it, then let an Alarm-channel
  alarm ring, and it is silent in Chrono. Wake beta.2 rang in that case (the user
  confirmed this on 2026-10-19). Background-kill and reboot tests were in progress then.
  A known risk: rebooting without unlocking. Boot receivers are directBootAware, but the
  alarm data sits in credential-encrypted storage.
- 2026-10-20: alarms on a locked phone rang only on unlock. Cause: android_alarm_manager_plus
  sent the ringing work to JobIntentService/JobScheduler, which waits during Doze. Fix
  (beta.3): the plugin is vendored in `packages/` and the receiver runs the callback
  directly, with goAsync and a 60 s self-releasing wake lock. Verified over adb in light
  Doze: from alarm delivery to the Dart code took about 0.7 s, and sound started about
  2 s after delivery. All tests until then ran with Wake's "Allow background usage"
  switched off (Restricted), and the fix still passed. The user then set it to Optimized.
- The phone denies audio focus to Wake at alarm time ("Audio focus not granted"). That
  is exactly why Chrono was silent.
- Overnight test on 2026-10-20, on Optimized, passed. The phone was in deep Doze from
  06:19 to 08:21. Android left deep Doze about 9 min before the 08:30 alarm clock, and
  did the same before a snooze at 08:59. Wake rang at 08:30:00, with the screen on at
  +0.65 s and audio playing at about +1 s. Deep Doze is never in effect when an
  alarm-clock alarm fires, so light Doze is the case that matters, and it is verified.
- Logcat buffers keep about 45 min on a busy morning, so overnight logs are lost by then.
  Use `adb shell dumpsys batterystats --history`: it has clock times since the last
  charge, `device_idle=full/light/off`, `tmpwhitelist=` for each alarm receiver, and
  `longwake ... AudioMix` while audio plays.
- Testing with `force-idle`/`step` or polling over adb does not work on this phone; see
  the vault entry android-tools/wireless-adb-phone-debugging. The wireless debugging
  port changes overnight, so ask the user for the new one.
- OPEN (2026-10-20): the user slept through Wake's 08:30 alarm and its snoozes, about
  16 min of ringing in total. They heard Google Clock at 09:00, while Wake's 08:59 snooze
  was playing at the same moment. Wake's audio was on the speaker (Bluetooth had
  disconnected at 01:28), and the alarm stream volume was 5/7. Suspect the alarm's own
  Volume, Rising Volume or Melody settings. `dumpsys audio` shows Android 17
  AudioHardening: Wake's focus requests are "ignored" (enforced) and its playback is
  "would be muted" (logged only, not enforced). Google Clock gets exemption code 4 and
  Wake gets 6. An FGS or foreground state may be needed (that is the v2 native service).
- v2 (2026-10-21, branch `worktree-v2-native-ringer`, not merged or released): local
  plugin `packages/wake_ringer`. Ringer.kt plays through MediaPlayer, requests focus and
  vibrates. RingService.kt is a mediaPlayback FGS started only after the sound plays.
  RingtonePlayer tries it first and falls back to just_audio. Verified on the phone:
  the focus request from the FGS was granted (AudioHardening exemption 4, the same as
  Google Clock) and Metrolist paused 0.4 s after the alarm started. Bug found: focus was
  abandoned through a different AudioManager instance, so Wake kept focus and the music
  never resumed. Fixed in e80c148 by always using the applicationContext's AudioManager.
  Retested on the phone on 2026-10-21 at 01:56: the music paused, focus was released on
  dismiss with the same client ID, and Metrolist resumed. e80c148 is installed on the phone.
- Remote test session on 2026-10-21, 02:20–02:55, with the v2 build on the phone. Passed:
  the music paused and resumed on every ring, the "Ringing" FGS notification was shown
  and then removed, auto-snooze ran after 5 min with re-rings at 02:30, 02:40 and 02:50,
  and the alarm ended with a "Missed alarm: auto-test" notification. The DND finding:
  the user's manual DND allows only repeat callers, so ALL alarms are muted
  (`opPlayAudio`). Bedtime mode allows alarms and media but disallows fullScreenIntent
  and peek. Advise turning on "Alarms" in DND.
- Locked-reboot test (2026-10-21) on v2 FAILED: nothing rang before or after unlock. Both
  boot handlers crashed (flutter_boot_receiver BootHandlerService reads CE prefs at
  LOCKED_BOOT_COMPLETED). Chrono crashes the same way.
- v3 (branch `v3-direct-boot`, built on v2 in the same worktree
  `.claude/worktrees/v2-native-ringer`, not merged or tested yet). The plugin's prefs
  moved to DE storage, the plugin reschedules at LOCKED_BOOT, and alarms that fire
  before unlock are handed to wake_ringer's LockedAlarmReceiver (native ring with
  Snooze/Dismiss, auto-snooze, missed notification, re-posted if swiped). LockedAlarms
  keeps per-alarm config and an mp3 copy in DE, with NO labels: the user asked about
  security and agreed to this. flutter_boot_receiver no longer runs at LOCKED_BOOT
  (`tools:node="replace"`).
- v3 locked-boot test PASSED on the phone (2026-10-21, 22:26–22:35): no crash at
  LOCKED_BOOT; the 22:33 alarm rang before unlock with a heads-up "Alarm" notification
  and the FGS was allowed (ALARM_MANAGER_ALARM_CLOCK); Snooze re-rang 61 s later; Dismiss
  worked; no double ring after unlock. Also passed on v2: reboot + unlock and snooze
  across a reboot.
- Another upstream bug, fixed in 326faa1 on v3: a snoozed ONE-TIME alarm was re-armed
  for the next day after its snooze rang. Ringing disables the alarm (cancel nulls the
  runner time), snooze re-enables it, and update() then sees no past time and
  schedules tomorrow. Fixed in Alarm.update(); there are no Alarm unit tests, so it is
  verified on the phone only.
- More v3 commits (2026-10-22/23, all upstream bugs or gaps): the snooze saves the locked
  config (otherwise the default sound and a 5-min snooze were used); lock-screen snoozes
  survive a reboot (LockedBootReceiver + DE snooze store, ring if <1 h late, otherwise
  missed); the missed notification shows the due time; rising volume works (the alarm
  screen used to send an absolute volume that cancelled the ramp, and the just_audio
  ramp stopped after its first step); the alarm screen now sends a volume FACTOR. On
  tasks, after 15 s idle (the user chose this, "volume up, task stays") the factor goes
  back to 1. TaskActivity notifier for typing in the math/retype tasks. Melody import
  dedups by content, clears the file_picker cache, and the Melodies screen deletes
  orphaned files. Installed f249001 on the phone at 01:12 on 23 Oct.
- Tests passed by the user: timer, task volume, folder melody + locked boot + deleted
  folder (falls back to the default), single mp3 deleted (Wake keeps its own copy, so it
  still plays). Pending: rising volume, task idle, dedup import, call + swipe, reboot
  B1–B4.
- Upstream bug reported by the user: the alarm notification gets swiped away (e.g.
  during a call) and the alarm keeps ringing with no way to stop it. The cause is
  awesome_notifications' dismiss path (background isolate plus an IsolateNameServer
  port lookup) failing silently. Planned fix: native Snooze/Dismiss on the FGS
  "Ringing" notification. Not reproduced in the logs yet.
- Limits of remote testing: the phone has a fingerprint lock, so there is no UI
  automation while it is locked. Wake doesn't implement the SET_TIMER intent (empty
  case). The SET_ALARM VIBRATE extra uses the key "Vibrate", but the setting is named
  "Vibration" (upstream bug). Use `cmd audio set-volume <stream> <idx>` (not media_session)
  and `cmd notification set_dnd priority|off`.
- The user's router is a TP-Link TL-WR841N (2.4 GHz only) and sometimes refuses the
  phone ("connection failure"). Suggested: "Use device MAC" on the phone, a DHCP
  reservation, WPA2-AES only, and a fixed channel.
  The beta.3 race: the old focus request was granted only if the alarm activity reached
  the top first.
- adb: the wireless debugging port changes on every silent Wi-Fi reconnect. mDNS
  auto-discovery (`adb mdns services`) often finds the phone without asking the user.
  The phone also advertises legacy `_adb._tcp` on port 5555. When both transports are
  connected, use `adb -s <ip:port>`.
- Still to do: the reboot tests (reboot then unlock, snooze across a reboot, reboot
  without unlocking) and the missing-file, DND, folder melody and full auto-snooze tests.
- The default branch of jayavardhan-g/wake is now `wake`. The manual "Android Build"
  workflow builds the prod flavor as an artifact, which can be installed with `adb install -r`.
- v2 = a native Kotlin ringing service like Google Clock's.
- Constraint: never hold wake locks that block deep sleep.

<!-- graph:begin -->
**Graph:** [[Neovim]] · [[GhostText]]
<!-- graph:end -->
