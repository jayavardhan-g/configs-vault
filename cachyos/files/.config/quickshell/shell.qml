// Quickshell runs alongside Noctalia. Only the pomodoro widget lives here for now.
// SUPER+C → `qs ipc call pomodoro toggle` (see ~/.config/hypr/config/binds.lua)
import Quickshell

ShellRoot {
    // Click-through corner timer on every monitor
    Variants {
        model: Quickshell.screens
        PomoPill {}
    }

    PomoPanel {}
}
