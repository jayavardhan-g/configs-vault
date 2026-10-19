# adb over Wi-Fi to the phone

**Date:** 2026-10-20
**Category:** android-tools
**Files touched:** `~/.android/adbkey`, `~/.android/adbkey.pub` (created by adb on first run; private key, not stored here)

<!-- graph:begin -->
**Graph:** [[adb]]
<!-- graph:end -->

## What
Installed `android-tools` (adb, fastboot) so Claude Code can debug the Android phone
(Motorola Edge 60 Pro) from the laptop over wireless debugging. No USB cable needed.

## Why
To test and debug the Wake alarm app (fork of Chrono) on the real phone. adb lets Claude
read Android's own records (`dumpsys jobscheduler`, `dumpsys alarm`, `logcat -b all`),
install test APKs, and create test alarms. The first use proved that alarms fired on time
but the ringing work waited in JobScheduler until the phone was unlocked.

## Change
```sh
sudo pacman -S android-tools
```
Pair once per laptop (the phone and laptop must be on the same Wi-Fi):
1. Phone: Settings → System → Developer options → **Wireless debugging** → on →
   **Pair device with pairing code**.
2. Laptop: `adb pair <phone-ip>:<pairing-port> <6-digit-code>`
3. Laptop: `adb connect <phone-ip>:<port shown on the Wireless debugging screen>`
4. Check: `adb devices -l`

If wireless debugging is toggled or the phone reboots, the connect port changes. Turn it
back on and repeat step 3; pairing itself is kept.

Useful commands:
```sh
adb shell dumpsys jobscheduler | grep -A2 -i <package>   # recent job runs ("Job history")
adb shell dumpsys alarm | grep -i <package>               # pending alarms
adb logcat -d -b all -v time > log.txt                    # incl. events buffer (device_idle, am_freeze, ...)
adb disconnect                                            # before any test that needs the phone idle
```

## Notes
- Shizuku on the phone also uses wireless debugging; both work side by side.
- A release build can't be read with `run-as`, so the app's private log files are out of
  reach. Its `print` output in logcat and the system dumps are what adb can see.
- Doze tests: don't poll the phone or use `dumpsys deviceidle force-idle`/`step` during
  the test. On this phone they reset idle state and never reached deep Doze (stuck at
  `QUICK_DOZE_DELAY`). Set the alarm, `adb disconnect`, let the phone idle naturally, then
  reconnect and read `logcat -b all` (look for `device_idle_light`, `device_idle_wake_from_idle`).
- The pairing code, phone IP and ports are per-session values; never record them.
