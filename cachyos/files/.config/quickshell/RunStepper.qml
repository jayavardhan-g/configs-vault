// Compact stepper for the Timer tab: label above [-] value [+]
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: st
    property string label
    property string value
    property bool canDown: true
    property bool canUp: true
    signal down
    signal up

    spacing: 2
    Text { Layout.alignment: Qt.AlignHCenter; text: st.label; color: Theme.dim; font.pixelSize: 11 }
    RowLayout {
        spacing: 2
        Btn { icon: 0xF0374; size: 24; enabled: st.canDown; onClicked: st.down() }
        Text {
            text: st.value
            color: Theme.fg; font.pixelSize: 13; font.bold: true; font.features: { "tnum": 1 }
            Layout.preferredWidth: 38; horizontalAlignment: Text.AlignHCenter
        }
        Btn { icon: 0xF0415; size: 24; enabled: st.canUp; onClicked: st.up() }
    }
}
