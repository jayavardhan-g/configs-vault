// Full pomodoro panel (SUPER+C): Timer / Stats / History / Phone / Settings.
// Esc or SUPER+C closes it.
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: panel

    property string tab: "timer"

    screen: Quickshell.screens.find(s => s.name === Pomo.screenName) ?? Quickshell.screens[0]
    visible: Pomo.panelOpen
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "pomodoro"
    implicitWidth: 460
    implicitHeight: 740
    color: "transparent"

    onVisibleChanged: {
        if (visible) {
            tab = "timer";
            card.forceActiveFocus();
        } else {
            Pomo.cancelPairing();       // a pairing code only lives while the panel is open
        }
    }

    // Redraws "heard from 2 min ago" while the Phone tab is showing.
    property real clock: Date.now()
    Timer { interval: 30000; repeat: true; running: panel.visible && panel.tab === "phone"; onTriggered: panel.clock = Date.now() }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 24
        color: Theme.bg
        border.color: Theme.line
        border.width: 1
        focus: true
        Keys.onEscapePressed: Pomo.panelOpen = false
        Keys.onSpacePressed: Pomo.running ? Pomo.pause() : Pomo.start()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // ── header / tabs ── (only the open tab shows its name, so five tabs and close fit)
            RowLayout {
                spacing: 6
                Btn { icon: 0xF051B; label: panel.tab === "timer" ? "Timer" : ""; size: 34; selected: panel.tab === "timer"; onClicked: panel.tab = "timer" }
                Btn { icon: 0xF0128; label: panel.tab === "stats" ? "Stats" : ""; size: 34; selected: panel.tab === "stats"; onClicked: panel.tab = "stats" }
                Btn { icon: 0xF02DA; label: panel.tab === "history" ? "History" : ""; size: 34; selected: panel.tab === "history"; onClicked: panel.tab = "history" }
                Btn { icon: 0xF011C; label: panel.tab === "phone" ? "Phone" : ""; size: 34; selected: panel.tab === "phone"; onClicked: panel.tab = "phone" }
                Btn { icon: 0xF0493; size: 34; selected: panel.tab === "settings"; onClicked: panel.tab = "settings" }
                Item { Layout.fillWidth: true }
                Btn { icon: 0xF0156; size: 34; onClicked: Pomo.panelOpen = false }
            }

            // ════════════════ TIMER ════════════════
            ColumnLayout {
                visible: panel.tab === "timer"
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                Text { text: "Category"; color: Theme.dim; font.pixelSize: 12 }
                Flow {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: Pomo.categories
                        Btn {
                            required property var modelData
                            label: modelData.name
                            dot: modelData.color
                            size: 32
                            selected: Pomo.category === modelData.name
                            onClicked: Pomo.setCategory(modelData.name)
                        }
                    }
                }

                // Big ring
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 230; implicitHeight: 230
                    Ring {
                        anchors.fill: parent
                        progress: Pomo.progress
                        thickness: 12
                        fillColor: Pomo.phaseColor
                    }
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Pomo.phaseLabel + (Pomo.strict && !Pomo.isBreak ? "  ·  strict" : "")
                            color: Pomo.phaseColor
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Pomo.timeText
                            color: Theme.fg
                            font.pixelSize: Pomo.timeText.length > 5 ? 42 : 52
                            font.weight: Font.Light
                            font.features: { "tnum": 1 }
                        }
                        // cycle dots: focus sessions done before the long break (timer mode)
                        Row {
                            visible: !Pomo.stopwatch
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 6
                            Repeater {
                                model: Pomo.longEvery
                                Rectangle {
                                    required property int index
                                    width: 8; height: 8; radius: 4
                                    color: index < Pomo.cycleCount % Pomo.longEvery || (Pomo.phase === "long" && Pomo.cycleCount > 0)
                                           ? Pomo.categoryColor : Theme.line
                                }
                            }
                        }
                    }
                }

                // Controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16
                    Btn {                                                     // stop / give up / finish
                        icon: Pomo.stopwatch ? 0xF012C : 0xF04DB
                        label: Pomo.stopwatch ? "Finish" : Pomo.locked ? "Give up" : ""
                        size: 44
                        enabled: Pomo.active
                        onClicked: Pomo.stop()
                    }
                    Btn {                                                     // play / pause
                        icon: Pomo.running ? 0xF03E4 : 0xF040A
                        size: 64
                        primary: true
                        enabled: !(Pomo.running && Pomo.locked)
                        onClicked: Pomo.running ? Pomo.pause() : Pomo.start()
                    }
                    Btn {                                                     // skip
                        visible: !Pomo.stopwatch
                        icon: 0xF04AD
                        size: 44
                        enabled: Pomo.active && !Pomo.locked
                        onClicked: Pomo.skip()
                    }
                }

                // On the go: this run's lengths and rounds (back to the defaults when it ends)
                RowLayout {
                    visible: !Pomo.stopwatch
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20
                    RunStepper {
                        label: "Focus"
                        value: Pomo.runFocus + "m"
                        canDown: Pomo.runFocus > 1 && !Pomo.locked
                        canUp: Pomo.runFocus < 180
                        onDown: Pomo.setRunMinutes("focus", Pomo.runFocus - 5)
                        onUp: Pomo.setRunMinutes("focus", Pomo.runFocus + 5)
                    }
                    RunStepper {
                        label: "Break"
                        value: Pomo.runShort + "m"
                        canDown: Pomo.runShort > 1
                        canUp: Pomo.runShort < 30
                        onDown: Pomo.setRunMinutes("short", Pomo.runShort - 1)
                        onUp: Pomo.setRunMinutes("short", Pomo.runShort + 1)
                    }
                    RunStepper {
                        label: "Rounds"
                        value: Pomo.runRounds > 0 ? Pomo.runRounds : "∞"
                        canDown: Pomo.runRounds > 0
                        canUp: Pomo.runRounds < 12
                        onDown: Pomo.stepRounds(-1)
                        onUp: Pomo.stepRounds(1)
                    }
                }
                Text {
                    visible: !Pomo.stopwatch && Pomo.runRounds > 0
                    Layout.alignment: Qt.AlignHCenter
                    text: Pomo.active ? "Round " + Math.max(1, Pomo.roundNow) + " of " + Pomo.runRounds
                                      : Pomo.runRounds + " rounds, then stop"
                    color: Theme.dim
                    font.pixelSize: 12
                }

                Item { Layout.fillHeight: true }

                // Daily goal
                ColumnLayout {
                    visible: Pomo.dailyGoalMin > 0
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Text { text: "Daily goal"; color: Theme.dim; font.pixelSize: 12; Layout.fillWidth: true }
                        Text {
                            text: Pomo.fmtDuration(Pomo.todayMin) + " / " + Pomo.fmtDuration(Pomo.dailyGoalMin)
                                  + (Pomo.goalProgress >= 1 ? "  ✓" : "")
                            color: Pomo.goalProgress >= 1 ? Theme.accent : Theme.fg
                            font.pixelSize: 12
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 6; radius: 3
                        color: Theme.raised
                        Rectangle { width: parent.width * Pomo.goalProgress; height: parent.height; radius: 3; color: Theme.accent }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Today  " + Pomo.fmtDuration(Pomo.todayMin) + "  ·  "
                          + Pomo.doneCount(Pomo.since(0)) + " sessions  ·  " + Pomo.streak() + "-day streak"
                    color: Theme.dim
                    font.pixelSize: 12
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Space start/pause · Esc close (timer keeps running in the corner)"
                    color: Theme.faint
                    font.pixelSize: 10
                }
            }

            // ════════════════ STATS ════════════════
            ColumnLayout {
                id: stats
                visible: panel.tab === "stats"
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                property int range: 6          // days back: 0 today, 6 week, 29 month, -1 all
                property var list: Pomo.since(range)
                property var weekData: Pomo.week()
                property real weekMax: Math.max(30, Pomo.dailyGoalMin, ...weekData.map(d => d.total))

                // Tiles
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: [
                            { label: Pomo.dailyGoalMin > 0 ? "Today / goal" : "Today",
                              value: Pomo.fmtDuration(Pomo.todayMin) + (Pomo.dailyGoalMin > 0 ? " / " + Pomo.fmtDuration(Pomo.dailyGoalMin) : "") },
                            { label: "This week", value: Pomo.fmtDuration(Pomo.totalMin(Pomo.since(6))) },
                            { label: "Streak", value: Pomo.streak() + " d" },
                            { label: "Sessions", value: Pomo.doneCount(Pomo.sessions) }
                        ]
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 64
                            radius: 14
                            color: Theme.surface
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text { Layout.alignment: Qt.AlignHCenter; text: modelData.value; color: Theme.fg; font.pixelSize: 15; font.bold: true }
                                Text { Layout.alignment: Qt.AlignHCenter; text: modelData.label; color: Theme.dim; font.pixelSize: 11 }
                            }
                        }
                    }
                }

                // Last 7 days, stacked by category (accent line = daily goal)
                Text { text: "Last 7 days"; color: Theme.dim; font.pixelSize: 12 }
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150

                    RowLayout {
                        anchors.fill: parent
                        spacing: 10
                        Repeater {
                            model: stats.weekData
                            ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 4
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.total > 0 ? Pomo.fmtDuration(modelData.total) : ""
                                    color: Theme.dim
                                    font.pixelSize: 9
                                }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Column {
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: Math.min(parent.width, 26)
                                        Repeater {
                                            model: modelData.parts.slice().reverse()
                                            Rectangle {
                                                required property var modelData
                                                width: parent.width
                                                height: Math.max(2, modelData.min / stats.weekMax * 110)
                                                color: modelData.color
                                            }
                                        }
                                    }
                                    Rectangle {   // baseline
                                        anchors.bottom: parent.bottom
                                        width: parent.width; height: 1
                                        color: Theme.line
                                    }
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.label
                                    color: modelData.label === "Today" ? Theme.fg : Theme.dim
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }
                    // goal line, on the same scale as the bars (110px = weekMax), bars' bottom = 150 - 18
                    Rectangle {
                        visible: Pomo.dailyGoalMin > 0
                        x: 0; width: parent.width; height: 1
                        y: parent.height - 18 - Pomo.dailyGoalMin / stats.weekMax * 110
                        color: Theme.accent
                        opacity: 0.6
                    }
                }

                // Breakdown by category
                RowLayout {
                    Text { text: "By category"; color: Theme.dim; font.pixelSize: 12; Layout.fillWidth: true }
                    Repeater {
                        model: [{ l: "Today", d: 0 }, { l: "Week", d: 6 }, { l: "Month", d: 29 }, { l: "All", d: -1 }]
                        Btn {
                            required property var modelData
                            label: modelData.l
                            size: 26
                            selected: stats.range === modelData.d
                            onClicked: stats.range = modelData.d
                        }
                    }
                }

                ColumnLayout {
                    id: breakdown
                    Layout.fillWidth: true
                    spacing: 8
                    property var rows: Pomo.byCategory(stats.list)
                    property int maxMin: rows.length ? rows[0].min : 1

                    Repeater {
                        model: breakdown.rows
                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 10
                            Rectangle { implicitWidth: 10; implicitHeight: 10; radius: 5; color: modelData.color }
                            Text { text: modelData.name; color: Theme.fg; font.pixelSize: 13; Layout.preferredWidth: 90; elide: Text.ElideRight }
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 6
                                radius: 3
                                color: Theme.raised
                                Rectangle {
                                    width: parent.width * modelData.min / breakdown.maxMin
                                    height: parent.height
                                    radius: 3
                                    color: modelData.color
                                }
                            }
                            Text { text: Pomo.fmtDuration(modelData.min); color: Theme.dim; font.pixelSize: 12; Layout.preferredWidth: 56; horizontalAlignment: Text.AlignRight }
                        }
                    }
                    Text {
                        visible: breakdown.rows.length === 0
                        text: "No focus time in this range yet"
                        color: Theme.faint
                        font.pixelSize: 12
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // ════════════════ HISTORY ════════════════
            ColumnLayout {
                id: history
                visible: panel.tab === "history"
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                property bool confirmReset: false
                Timer { id: resetDisarm; interval: 4000; onTriggered: history.confirmReset = false }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: Pomo.sessions.length + " sessions"
                        color: Theme.dim
                        font.pixelSize: 12
                    }
                    Btn { icon: 0xF0207; label: "Export CSV"; size: 30; enabled: Pomo.sessions.length > 0; onClicked: Pomo.exportCsv() }
                    Btn {
                        icon: 0xF0A7A
                        label: history.confirmReset ? "Click again to erase all" : "Reset stats"
                        size: 30
                        enabled: Pomo.sessions.length > 0
                        selected: history.confirmReset
                        onClicked: {
                            if (history.confirmReset) {
                                Pomo.resetStats();
                                history.confirmReset = false;
                            } else {
                                history.confirmReset = true;
                                resetDisarm.restart();
                            }
                        }
                    }
                }
                Text {
                    text: "Export saves to ~/Downloads. Click a category to change it; − / + adjust minutes."
                    color: Theme.faint
                    font.pixelSize: 10
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: histCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: histCol
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: Pomo.sessions.slice().sort((a, b) => b.end - a.end)
                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 40
                                radius: 10
                                color: Theme.surface

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 6
                                    spacing: 6

                                    Text {
                                        text: Qt.formatDateTime(new Date(modelData.end), "ddd d MMM  HH:mm")
                                        color: Theme.dim
                                        font.pixelSize: 11
                                        font.features: { "tnum": 1 }
                                        Layout.preferredWidth: 104
                                    }
                                    Btn {                                            // cycle category
                                        label: modelData.cat
                                        dot: Pomo.colorOf(modelData.cat)
                                        size: 26
                                        Layout.fillWidth: true
                                        onClicked: {
                                            const names = Pomo.categories.map(c => c.name);
                                            const next = names[(names.indexOf(modelData.cat) + 1) % names.length];
                                            Pomo.updateSession(modelData.id, { cat: next });
                                        }
                                    }
                                    Btn { icon: 0xF0374; size: 24; onClicked: Pomo.updateSession(modelData.id, { min: Math.max(1, modelData.min - 1) }) }
                                    Text {
                                        text: modelData.min + "m"
                                        color: Theme.fg
                                        font.pixelSize: 12
                                        Layout.preferredWidth: 34
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    Btn { icon: 0xF0415; size: 24; onClicked: Pomo.updateSession(modelData.id, { min: modelData.min + 1 }) }
                                    Icon {
                                        code: modelData.done ? 0xF012C : 0xF0B55              // check / partial
                                        color: modelData.done ? Theme.accent : Theme.faint
                                        font.pixelSize: 14
                                    }
                                    Btn { icon: 0xF01B4; size: 26; onClicked: Pomo.deleteSession(modelData.id) }    // delete
                                }
                            }
                        }
                        Text {
                            visible: Pomo.sessions.length === 0
                            text: "No sessions yet"
                            color: Theme.faint
                            font.pixelSize: 12
                        }
                    }
                }
            }

            // ════════════════ PHONE ════════════════
            ColumnLayout {
                visible: panel.tab === "phone"
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                Text {
                    text: Pomo.syncPaired ? "PHONE" : "PAIR A PHONE"
                    color: Theme.accent; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1
                }

                // Not paired: explain, offer to pair.
                ColumnLayout {
                    visible: !Pomo.syncPaired && Pomo.pairingQr === ""
                    Layout.fillWidth: true
                    spacing: 12
                    Text {
                        Layout.fillWidth: true
                        text: "Keep the focus timer, sessions, categories and timer settings in step with the Focus timer in the Sync app on your phone. Messages are encrypted; ntfy.sh only carries them."
                        color: Theme.dim; font.pixelSize: 13; wrapMode: Text.Wrap
                    }
                    Btn { icon: 0xF0432; label: "Pair a phone"; primary: true; size: 36; onClicked: Pomo.startPairing() }
                }

                // Pairing: the QR code, until the phone says hello.
                RowLayout {
                    visible: !Pomo.syncPaired && Pomo.pairingQr !== ""
                    Layout.fillWidth: true
                    spacing: 16
                    Rectangle {
                        implicitWidth: 168; implicitHeight: 168; radius: 14; color: "white"
                        Image {
                            anchors.fill: parent; anchors.margins: 8
                            source: Pomo.pairingQr ? "file://" + Pomo.pairingQr : ""
                            cache: false; smooth: false; fillMode: Image.PreserveAspectFit
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text { Layout.fillWidth: true; text: "Scan with your phone's camera."; color: Theme.fg; font.pixelSize: 13; wrapMode: Text.Wrap }
                        Text {
                            Layout.fillWidth: true
                            text: "The code holds this laptop's name, a private channel and the encryption key. Close the panel and it's gone; a new code is made each time."
                            color: Theme.dim; font.pixelSize: 12; wrapMode: Text.Wrap
                        }
                        Text { text: "Waiting for the phone…"; color: Theme.faint; font.pixelSize: 12 }
                    }
                }

                // Paired.
                ColumnLayout {
                    visible: Pomo.syncPaired
                    Layout.fillWidth: true
                    spacing: 0
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 8
                        spacing: 10
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { text: Pomo.syncPhone || "Phone"; color: Theme.fg; font.pixelSize: 14 }
                            Row {
                                spacing: 4
                                Text { text: "●"; color: "#a6e3a1"; font.pixelSize: 12 }
                                Text { text: "In sync · heard from " + (panel.clock, Pomo.agoText(Pomo.syncLastHeard)); color: Theme.dim; font.pixelSize: 12 }
                            }
                        }
                        Btn { label: "Unpair"; size: 30; onClicked: Pomo.unpairPhone() }
                    }
                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }
                    ColumnLayout {
                        Layout.fillWidth: true; Layout.topMargin: 8; Layout.bottomMargin: 8; spacing: 2
                        Text { text: "Keeps in step"; color: Theme.fg; font.pixelSize: 13 }
                        Text { text: "Timer, sessions, categories and timer settings"; color: Theme.dim; font.pixelSize: 12 }
                    }
                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }
                    ColumnLayout {
                        Layout.fillWidth: true; Layout.topMargin: 8; spacing: 2
                        Text { text: "Phone goes quiet during focus"; color: Theme.fg; font.pixelSize: 13 }
                        Text { text: "Coming next: the phone's Do Not Disturb follows focus"; color: Theme.dim; font.pixelSize: 12 }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // ════════════════ SETTINGS ════════════════
            Flickable {
                visible: panel.tab === "settings"
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: setCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: setCol
                    width: parent.width - 8
                    spacing: 12

                    Text { text: "TIMER"; color: Theme.accent; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1 }
                    SetChoice {
                        label: "Mode"
                        hint: Pomo.active ? "Stop the current session to switch modes." : "Stopwatch counts up with no breaks; Finish saves it as a completed session."
                        key: "mode"
                        enabled: !Pomo.active
                        options: [{ label: "Pomodoro timer", value: "timer" }, { label: "Stopwatch", value: "stopwatch" }]
                    }
                    SetStepper { label: "Focus"; key: "focusMin"; min: 1; max: 180; step: 5; format: v => v + " min"; enabled: !Pomo.stopwatch }
                    SetStepper { label: "Short break"; key: "shortMin"; min: 1; max: 30; step: 1; format: v => v + " min"; enabled: !Pomo.stopwatch }
                    SetStepper { label: "Long break"; key: "longMin"; min: 1; max: 60; step: 5; format: v => v + " min"; enabled: !Pomo.stopwatch }
                    SetStepper { label: "Long break every"; key: "longEvery"; min: 2; max: 8; step: 1; format: v => v + "×"; enabled: !Pomo.stopwatch }
                    SetStepper { label: "Rounds"; hint: "Focus sessions per run before the timer stops; ∞ keeps going. Adjustable per run on the Timer tab."; key: "rounds"; min: 0; max: 12; step: 1; format: v => v > 0 ? v + "×" : "∞"; enabled: !Pomo.stopwatch }
                    SetToggle { label: "Start breaks automatically"; key: "autoBreak" }
                    SetToggle { label: "Start focus after a break automatically"; key: "autoFocus" }
                    SetToggle { label: "Strict mode"; hint: "No pause or skip during focus. You can still give up (saved as incomplete)."; key: "strict" }
                    SetStepper { label: "Daily goal"; hint: "Focus time per day; 0 turns it off."; key: "dailyGoalMin"; min: 0; max: 720; step: 15; format: v => v > 0 ? Pomo.fmtDuration(v) : "Off" }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }
                    Text { text: "DURING FOCUS"; color: Theme.accent; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1 }
                    SetToggle { label: "Do Not Disturb"; hint: "Turns on Noctalia's DND while focus runs. A DND you set yourself is left alone."; key: "dnd" }
                    SetToggle { label: "Keep screen awake"; hint: "Turns on Noctalia's caffeine while focus runs (and off afterwards, even if you'd enabled it yourself)."; key: "caffeine" }
                    SetChoice {
                        label: "Sound at the end of each phase"
                        key: "sound"
                        options: [{ label: "Off", value: "off" }, { label: "Complete", value: "complete" },
                                  { label: "Bell", value: "bell" }, { label: "Alarm", value: "alarm-clock-elapsed" }]
                    }
                    Btn {
                        icon: 0xF040A; label: "Play sound"; size: 28
                        enabled: Pomo.sound !== "off"
                        onClicked: Pomo.playSound()
                    }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }
                    Text { text: "CORNER TIMER"; color: Theme.accent; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1 }
                    SetStepper { label: "Background opacity"; hint: "Clicks always pass through, at any opacity."; key: "timerOpacity"; min: 0; max: 1; step: 0.1; format: v => Math.round(v * 100) + "%" }
                    SetChoice {
                        label: "Show on"
                        key: "monitorMode"
                        options: [{ label: "All monitors", value: "all" }, { label: "One monitor", value: "one" }]
                    }
                    SetChoice {
                        visible: Pomo.monitorMode === "one"
                        label: "Monitor"
                        key: "monitorName"
                        options: Quickshell.screens.map(s => ({ label: s.name, value: s.name }))
                    }
                    SetToggle { label: "Hide during breaks"; key: "hideOnBreak" }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }
                    Text { text: "NOTIFICATIONS"; color: Theme.accent; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1 }
                    SetText { label: "When focus ends"; key: "focusDoneText"; hint: "{category} and {minutes} are filled in." }
                    SetText { label: "When a break ends"; key: "breakDoneText" }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line }
                    Text { text: "CATEGORIES"; color: Theme.accent; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1 }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: "Own focus / short-break length per category; “def” uses the defaults above. The bin removes a category (its past stats are kept)."
                        color: Theme.faint
                        font.pixelSize: 10
                    }
                    Repeater {
                        model: Pomo.categories
                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 4
                            Rectangle { implicitWidth: 10; implicitHeight: 10; radius: 5; color: modelData.color }
                            Text { text: modelData.name; color: Theme.fg; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }

                            Text { text: "focus"; color: Theme.faint; font.pixelSize: 10 }
                            Btn { icon: 0xF0374; size: 22; onClicked: Pomo.setCategoryMinutes(modelData.name, "focusMin", Math.max(0, (modelData.focusMin || 0) - 5)) }
                            Text {
                                text: modelData.focusMin ? modelData.focusMin + "m" : "def"
                                color: modelData.focusMin ? Theme.fg : Theme.faint
                                font.pixelSize: 11; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter
                            }
                            Btn { icon: 0xF0415; size: 22; onClicked: Pomo.setCategoryMinutes(modelData.name, "focusMin", (modelData.focusMin || Pomo.focusMin) + (modelData.focusMin ? 5 : 0)) }

                            Text { text: "break"; color: Theme.faint; font.pixelSize: 10; Layout.leftMargin: 4 }
                            Btn { icon: 0xF0374; size: 22; onClicked: Pomo.setCategoryMinutes(modelData.name, "shortMin", Math.max(0, (modelData.shortMin || 0) - 1)) }
                            Text {
                                text: modelData.shortMin ? modelData.shortMin + "m" : "def"
                                color: modelData.shortMin ? Theme.fg : Theme.faint
                                font.pixelSize: 11; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter
                            }
                            Btn { icon: 0xF0415; size: 22; onClicked: Pomo.setCategoryMinutes(modelData.name, "shortMin", (modelData.shortMin || Pomo.shortMin) + (modelData.shortMin ? 1 : 0)) }

                            Btn { icon: 0xF01B4; size: 24; enabled: Pomo.categories.length > 1; onClicked: Pomo.removeCategory(modelData.name) }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            radius: 16
                            color: Theme.raised
                            border.color: newCat.activeFocus ? Theme.accent : "transparent"
                            TextInput {
                                id: newCat
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                verticalAlignment: TextInput.AlignVCenter
                                color: Theme.fg
                                font.pixelSize: 13
                                clip: true
                                onAccepted: { Pomo.addCategory(text); text = ""; }
                                Keys.onEscapePressed: { text = ""; card.forceActiveFocus(); }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !parent.text && !parent.activeFocus
                                    text: "New category…"
                                    color: Theme.faint
                                    font.pixelSize: 13
                                }
                            }
                        }
                        Btn { icon: 0xF0415; label: "Add"; size: 32; onClicked: { Pomo.addCategory(newCat.text); newCat.text = ""; } }
                    }
                    Item { implicitHeight: 8 }
                }
            }
        }
    }
}
