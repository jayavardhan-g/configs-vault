pragma Singleton
// Colours follow Noctalia's wallpaper palette by reading its generated GTK4 template
// (re-read whenever Noctalia rewrites it). Values below are the fallback.
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: theme

    property color accent: "#f3bf48"
    property color accentText: "#402d00"
    property color bg: "#0f150a"
    property color surface: "#1c2116"
    property color fg: "#dfe5d3"
    property color danger: "#ffb4ab"

    readonly property color dim: Qt.rgba(fg.r, fg.g, fg.b, 0.6)
    readonly property color faint: Qt.rgba(fg.r, fg.g, fg.b, 0.35)
    readonly property color line: Qt.rgba(fg.r, fg.g, fg.b, 0.12)
    readonly property color raised: Qt.rgba(fg.r, fg.g, fg.b, 0.07)

    readonly property string iconFont: "MesloLGL Nerd Font Propo"

    // Category colours are fixed (not palette-derived) so a category keeps its colour
    // across wallpaper changes.
    readonly property var categoryColors: ["#f38ba8", "#89b4fa", "#a6e3a1", "#f9e2af",
                                           "#cba6f7", "#fab387", "#94e2d5", "#f5c2e7"]

    FileView {
        path: Quickshell.env("HOME") + "/.config/gtk-4.0/noctalia.css"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: theme.parse(text())
    }

    function parse(css) {
        const get = name => {
            const m = css.match(new RegExp("@define-color " + name + " (#[0-9a-fA-F]{6})"));
            return m ? m[1] : null;
        };
        accent = get("accent_bg_color") ?? accent;
        accentText = get("accent_fg_color") ?? accentText;
        bg = get("window_bg_color") ?? bg;
        surface = get("card_bg_color") ?? surface;
        fg = get("window_fg_color") ?? fg;
        danger = get("error_bg_color") ?? danger;
    }
}
