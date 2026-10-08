// Settings row: label (+ hint) and a set of option chips, bound to Pomo[key]
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: row
    property string label
    property string hint: ""
    property string key
    property var options: []                     // [{ label, value }]
    property bool enabled: true

    Layout.fillWidth: true
    spacing: 6
    opacity: enabled ? 1 : 0.4

    Text { text: row.label; color: Theme.fg; font.pixelSize: 13 }
    Text { visible: row.hint !== ""; text: row.hint; color: Theme.faint; font.pixelSize: 10; Layout.fillWidth: true; wrapMode: Text.Wrap }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: row.options
            Btn {
                required property var modelData
                label: modelData.label
                size: 28
                enabled: row.enabled
                selected: Pomo[row.key] === modelData.value
                onClicked: Pomo.setSetting(row.key, modelData.value)
            }
        }
    }
}
