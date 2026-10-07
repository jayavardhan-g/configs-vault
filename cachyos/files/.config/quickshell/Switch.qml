// On/off switch
import QtQuick

Rectangle {
    id: sw
    property bool checked: false
    signal toggled

    implicitWidth: 40; implicitHeight: 22; radius: 11
    color: checked ? Theme.accent : Theme.line
    opacity: enabled ? 1 : 0.4
    Rectangle {
        width: 16; height: 16; radius: 8
        y: 3
        x: sw.checked ? parent.width - width - 3 : 3
        color: sw.checked ? Theme.accentText : Theme.fg
        Behavior on x { NumberAnimation { duration: 120 } }
    }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: sw.toggled() }
}
