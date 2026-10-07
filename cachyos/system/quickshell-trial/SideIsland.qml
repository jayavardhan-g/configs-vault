// Left-edge hover island: rest the cursor on the left edge of the leftmost monitor to slide
// it in; it hides again shortly after the cursor leaves. Media controls + xpad notes (read-only).
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

Scope {
    id: island

    property bool open: false
    property var notes: []

    // Only the leftmost monitor gets the trigger — a left-edge strip on a monitor that sits to
    // the right of another would fire every time the cursor crossed between them.
    readonly property var leftScreen: {
        const screens = Quickshell.screens;
        let best = screens[0];
        for (const s of screens)
            if (s.x < best.x)
                best = s;
        return best;
    }

    // Prefer whichever player is actually playing, else the first one on the bus.
    readonly property var player: {
        const players = Mpris.players.values;
        return players.find(p => p.isPlaying) ?? players[0] ?? null;
    }

    onOpenChanged: if (open) notesProc.running = true

    // xpad keeps one plain-text file per note: ~/.config/xpad/content-*
    Process {
        id: notesProc
        command: ["sh", "-c", "for f in \"$HOME\"/.config/xpad/content-*; do [ -f \"$f\" ] && { cat \"$f\"; printf '\\036'; }; done"]
        stdout: StdioCollector {
            onStreamFinished: island.notes = this.text.split("\x1e").map(s => s.trim()).filter(s => s.length > 0)
        }
    }

    // Short dwell before opening so flinging the cursor left doesn't trigger it
    Timer {
        interval: 150
        running: !island.open && edgeHover.hovered
        onTriggered: island.open = true
    }

    Timer {
        interval: 400
        running: island.open && !edgeHover.hovered && !cardHover.hovered
        onTriggered: island.open = false
    }

    // Invisible hot edge
    PanelWindow {
        screen: island.leftScreen
        anchors { left: true; top: true; bottom: true }
        implicitWidth: 2
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        HoverHandler { id: edgeHover }
    }

    PanelWindow {
        id: win
        screen: island.leftScreen
        anchors.left: true            // left only → vertically centred
        implicitWidth: card.width + 16
        implicitHeight: card.height
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        visible: island.open || card.x > -card.width

        Rectangle {
            id: card
            width: 320
            height: content.implicitHeight + 32
            x: island.open ? 8 : -width - 8
            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            radius: 16
            color: "#1e1e2e"
            border.color: "#313244"
            border.width: 1

            HoverHandler { id: cardHover }

            ColumnLayout {
                id: content
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                spacing: 12

                // ── Media ──
                Text { text: "Media"; color: "#89b4fa"; font.pixelSize: 13; font.bold: true }

                RowLayout {
                    visible: island.player !== null
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        radius: 8
                        color: "#313244"
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: island.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: island.player?.trackTitle || "Unknown title"
                            color: "#cdd6f4"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: island.player?.trackArtist || island.player?.identity || ""
                            color: "#a6adc8"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                        RowLayout {
                            spacing: 4
                            Repeater {
                                model: [
                                    { glyph: "⏮", act: () => island.player.previous() },
                                    { glyph: island.player?.isPlaying ? "⏸" : "▶", act: () => island.player.togglePlaying() },
                                    { glyph: "⏭", act: () => island.player.next() }
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 26
                                    radius: 6
                                    color: btnHover.hovered ? "#45475a" : "#313244"
                                    Text { anchors.centerIn: parent; text: parent.modelData.glyph; color: "#cdd6f4"; font.pixelSize: 13 }
                                    HoverHandler { id: btnHover }
                                    TapHandler { onTapped: parent.modelData.act() }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: island.player === null
                    text: "Nothing playing"
                    color: "#6c7086"
                    font.pixelSize: 12
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#313244" }

                // ── Notes (xpad, read-only) ──
                Text { text: "Notes"; color: "#89b4fa"; font.pixelSize: 13; font.bold: true }

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(notesCol.implicitHeight, island.leftScreen.height * 0.5)
                    contentHeight: notesCol.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: notesCol
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: island.notes
                            delegate: Rectangle {
                                required property string modelData
                                Layout.fillWidth: true
                                implicitHeight: noteText.implicitHeight + 16
                                radius: 8
                                color: "#313244"
                                Text {
                                    id: noteText
                                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                                    text: parent.modelData
                                    color: "#cdd6f4"
                                    font.pixelSize: 12
                                    wrapMode: Text.Wrap
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: island.notes.length === 0
                    text: "No xpad notes"
                    color: "#6c7086"
                    font.pixelSize: 12
                }
            }
        }
    }
}
