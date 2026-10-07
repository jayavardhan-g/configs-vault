// Small rounded button: icon and/or label
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: btn
    property int icon: 0
    property string label: ""
    property bool primary: false
    property bool selected: false
    property color dot: "transparent"   // optional colour dot (category chips)
    property int size: 36
    signal clicked

    implicitHeight: size
    implicitWidth: Math.max(size, row.implicitWidth + (label ? 24 : 0))
    radius: height / 2
    color: primary ? Theme.accent
         : selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
         : hover.hovered ? Theme.line : Theme.raised
    opacity: enabled ? 1 : 0.35
    border.width: selected ? 1 : 0
    border.color: Theme.accent
    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Rectangle {
            visible: btn.dot.a > 0
            implicitWidth: 8; implicitHeight: 8; radius: 4
            color: btn.dot
        }
        Icon {
            visible: btn.icon !== 0
            code: btn.icon
            font.pixelSize: btn.size * 0.5
            color: btn.primary ? Theme.accentText : Theme.fg
        }
        Text {
            visible: btn.label !== ""
            text: btn.label
            color: btn.primary ? Theme.accentText : Theme.fg
            font.pixelSize: 13
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: btn.clicked() }
}
