// Settings row: label + [-] value [+], bound to Pomo[key]
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: row
    property string label
    property string hint: ""
    property string key
    property real min: 0
    property real max: 100
    property real step: 1
    property var format: v => String(v)          // value → text
    property bool enabled: true

    Layout.fillWidth: true
    spacing: 8
    opacity: enabled ? 1 : 0.4

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        Text { text: row.label; color: Theme.fg; font.pixelSize: 13 }
        Text { visible: row.hint !== ""; text: row.hint; color: Theme.faint; font.pixelSize: 10; Layout.fillWidth: true; wrapMode: Text.Wrap }
    }
    Btn {
        icon: 0xF0374; size: 28; enabled: row.enabled
        onClicked: Pomo.setSetting(row.key, Math.max(row.min, Math.round((Pomo[row.key] - row.step) * 100) / 100))
    }
    Text {
        text: row.format(Pomo[row.key])
        color: Theme.fg; font.pixelSize: 13; font.bold: true
        Layout.preferredWidth: 48; horizontalAlignment: Text.AlignHCenter
    }
    Btn {
        icon: 0xF0415; size: 28; enabled: row.enabled
        onClicked: Pomo.setSetting(row.key, Math.min(row.max, Math.round((Pomo[row.key] + row.step) * 100) / 100))
    }
}
