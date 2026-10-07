// Settings row: label (+ hint) and a switch, bound to Pomo[key]
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: row
    property string label
    property string hint: ""
    property string key

    Layout.fillWidth: true
    spacing: 8

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        Text { text: row.label; color: Theme.fg; font.pixelSize: 13 }
        Text { visible: row.hint !== ""; text: row.hint; color: Theme.faint; font.pixelSize: 10; Layout.fillWidth: true; wrapMode: Text.Wrap }
    }
    Switch {
        checked: Pomo[row.key]
        onToggled: Pomo.setSetting(row.key, !Pomo[row.key])
    }
}
