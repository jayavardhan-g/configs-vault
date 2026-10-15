pragma Singleton
// Colours follow the desktop shell's wallpaper palette by reading the GTK4 colour file
// that ~/.config/gtk-4.0/gtk.css imports: noctalia.css (Noctalia) or dank-colors.css
// (DMS). Both are re-read whenever they change. Values below are the fallback.
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

    readonly property string gtkDir: Quickshell.env("HOME") + "/.config/gtk-4.0/"
    property string colorsFile: "noctalia.css"

    // gtk.css decides which shell's colours are live (shell-theme.sh flips its @import).
    FileView {
        path: theme.gtkDir + "gtk.css"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const m = text().match(/@import url\("((?:noctalia|dank-colors)\.css)"\)/);
            if (m)
                theme.colorsFile = m[1];
        }
    }

    FileView {
        path: theme.gtkDir + theme.colorsFile
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
