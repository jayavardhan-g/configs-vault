// Settings row: label (+ hint) and a single-line text field, bound to Pomo[key].
// Saves on Enter or when the field loses focus.
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: row
    property string label
    property string hint: ""
    property string key

    Layout.fillWidth: true
    spacing: 6

    Text { text: row.label; color: Theme.fg; font.pixelSize: 13 }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 32
        radius: 10
        color: Theme.raised
        border.color: field.activeFocus ? Theme.accent : "transparent"
        TextInput {
            id: field
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.fg
            font.pixelSize: 12
            clip: true
            text: Pomo[row.key]
            onAccepted: { Pomo.setSetting(row.key, text); focus = false; }
            onActiveFocusChanged: if (!activeFocus && text !== Pomo[row.key]) Pomo.setSetting(row.key, text)
        }
    }
    Text { visible: row.hint !== ""; text: row.hint; color: Theme.faint; font.pixelSize: 10; Layout.fillWidth: true; wrapMode: Text.Wrap }
}
