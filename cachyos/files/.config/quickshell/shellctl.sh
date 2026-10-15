#!/bin/sh
# Do-not-disturb and caffeine for the pomodoro, against whichever desktop shell is
# running: Noctalia (daily) or DMS (on trial; see SHELL_NAME in ~/.config/hypr/config/shell.lua).
#
#   shellctl.sh dnd-status     prints "on" or "off"
#   shellctl.sh dnd-on | dnd-off | caffeine-on | caffeine-off

if pgrep -x noctalia >/dev/null; then
    case "$1" in
        dnd-status)   noctalia msg notification-dnd-status ;;
        dnd-on)       noctalia msg notification-dnd-set on ;;
        dnd-off)      noctalia msg notification-dnd-set off ;;
        caffeine-on)  noctalia msg caffeine-enable ;;
        caffeine-off) noctalia msg caffeine-disable ;;
        *) echo "usage: $0 dnd-status|dnd-on|dnd-off|caffeine-on|caffeine-off" >&2; exit 2 ;;
    esac
else
    case "$1" in
        dnd-status)   [ "$(dms ipc call notifications getDoNotDisturb)" = true ] && echo on || echo off ;;
        dnd-on)       dms ipc call notifications enableDoNotDisturbIndefinitely ;;
        dnd-off)      dms ipc call notifications disableDoNotDisturb ;;
        caffeine-on)  dms ipc call inhibit enable ;;
        caffeine-off) dms ipc call inhibit disable ;;
        *) echo "usage: $0 dnd-status|dnd-on|dnd-off|caffeine-on|caffeine-off" >&2; exit 2 ;;
    esac
fi
