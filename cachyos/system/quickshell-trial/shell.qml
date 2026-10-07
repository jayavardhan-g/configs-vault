// Minimal Quickshell trial bar — runs alongside Noctalia, bottom edge so the two don't overlap.
// Run: qs            Stop: pkill -x qs  (or Ctrl+C if run in a terminal)
// IPC demo (what a keybind would call): qs ipc call bar toggle
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root
    property bool barVisible: true

    // Same mechanism a Hyprland bind would use instead of `noctalia msg ...`
    IpcHandler {
        target: "bar"
        function toggle(): void { root.barVisible = !root.barVisible }
    }

    SideIsland {}

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // One bar per monitor
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.barVisible

            anchors { bottom: true; left: true; right: true }
            implicitHeight: 28
            color: "#1e1e2e"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                // Workspaces (normal ones only; special workspaces have negative ids)
                Repeater {
                    model: Hyprland.workspaces

                    delegate: Rectangle {
                        required property HyprlandWorkspace modelData
                        visible: modelData.id > 0
                        Layout.preferredWidth: visible ? 24 : 0
                        Layout.preferredHeight: 20
                        radius: 4
                        color: Hyprland.focusedWorkspace?.id === modelData.id ? "#89b4fa" : "#313244"

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.id
                            color: Hyprland.focusedWorkspace?.id === parent.modelData.id ? "#1e1e2e" : "#cdd6f4"
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            // Hyprland's Lua config expects Lua dispatcher syntax, not "workspace N"
                            onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + parent.modelData.id + " })")
                        }
                    }
                }

                // Focused window title
                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    text: Hyprland.activeToplevel?.title ?? ""
                    color: "#a6adc8"
                    elide: Text.ElideRight
                    font.pixelSize: 12
                }

                Text {
                    text: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm:ss")
                    color: "#cdd6f4"
                    font.pixelSize: 12
                }
            }
        }
    }
}
