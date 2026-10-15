import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Modules.Plugins

// A tiny invisible overlay in the bottom-left corner of every monitor. Moving the
// pointer into it opens the window switcher (the dankHyprlandWindows launcher mode,
// trigger "!"). It fires once per entry; leaving the corner re-arms it.
PluginComponent {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                left: true
                bottom: true
            }
            implicitWidth: 2
            implicitHeight: 2
            exclusiveZone: 0
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "dms:hot-corner"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: Quickshell.execDetached(["dms", "ipc", "call", "launcher", "openQuery", "!"])
            }
        }
    }
}
