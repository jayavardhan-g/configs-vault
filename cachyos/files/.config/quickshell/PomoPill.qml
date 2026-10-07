// Corner timer ("fused notch") shown on every monitor while a pomodoro cycle is active
// and the panel is closed: a 96px square flush with the top and right edges, rounded on
// its inner corner, with concave fillets blending it into both screen edges.
//
// Fully click-through (empty input mask): pointer motion, hover, clicks and scroll all go
// to whatever is underneath — window buttons, an app's hover-revealed toolbar, Noctalia's
// auto-hide bar. The background is translucent so that content stays visible; only the
// ring and the digits are solid. Controls live in the SUPER+C panel.
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes

PanelWindow {
    id: pill

    required property var modelData        // ShellScreen, from Variants in shell.qml
    screen: modelData

    // Geometry (px)
    readonly property int size: 96          // the square
    readonly property int fillet: 14        // concave blend into the screen edges
    readonly property int radius: 28        // rounded inner corner
    readonly property int span: size + fillet

    // Background opacity (Settings → Corner timer); ring and digits stay solid
    readonly property real bgOpacity: Pomo.timerOpacity

    // "One monitor" mode shows it only on the chosen monitor (falls back to the first
    // screen if that monitor isn't connected).
    readonly property string oneMonitor: Quickshell.screens.some(s => s.name === Pomo.monitorName)
                                         ? Pomo.monitorName : (Quickshell.screens[0]?.name ?? "")
    readonly property bool onThisMonitor: Pomo.monitorMode === "all" || modelData.name === oneMonitor

    visible: Pomo.active && !Pomo.panelOpen && onThisMonitor && !(Pomo.hideOnBreak && Pomo.isBreak)

    anchors { top: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay   // above Noctalia's bar
    WlrLayershell.namespace: "pomodoro-timer"
    implicitWidth: span
    implicitHeight: span
    color: "transparent"

    // Empty input region → completely click-through
    mask: Region {}

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, pill.bgOpacity)
            strokeColor: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.10)
            strokeWidth: 1
            PathSvg {
                readonly property int s: pill.size
                readonly property int f: pill.fillet
                readonly property int r: pill.radius
                readonly property int w: pill.span
                path: `M 0 0 A ${f} ${f} 0 0 1 ${f} ${f} V ${s - r} A ${r} ${r} 0 0 0 ${f + r} ${s} H ${w - f} A ${f} ${f} 0 0 1 ${w} ${s + f} V 0 Z`
            }
        }
    }

    // Content, centred on the square
    Item {
        x: pill.fillet
        width: pill.size
        height: pill.size

        Item {
            id: ringBox
            width: 34; height: 34
            anchors.horizontalCenter: parent.horizontalCenter
            y: 12
            Ring {
                anchors.fill: parent
                progress: Pomo.progress
                thickness: 4
                fillColor: Pomo.phaseColor
            }
            Icon {
                anchors.centerIn: parent
                code: !Pomo.running ? 0xF03E4                          // pause
                    : Pomo.phase === "focus" ? 0xF0238 : 0xF0176       // fire / coffee
                font.pixelSize: 13
                color: Pomo.running ? Pomo.phaseColor : Theme.dim
            }
        }

        Text {
            id: time
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: ringBox.bottom
            anchors.topMargin: 4
            text: Pomo.timeText
            color: Pomo.running ? Theme.fg : Theme.dim
            font.pixelSize: 20
            font.bold: true
            font.features: { "tnum": 1 }
            style: Text.Outline                      // keeps digits legible over busy content
            styleColor: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.6)
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: time.bottom
            width: parent.width - 16
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: Pomo.phase === "focus" ? Pomo.category : Pomo.phaseLabel
            color: Theme.dim
            font.pixelSize: 10
        }
    }
}
