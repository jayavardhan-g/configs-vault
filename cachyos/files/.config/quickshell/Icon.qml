// Nerd Font (Material Design) glyph by codepoint
import QtQuick

Text {
    property int code: 0
    text: String.fromCodePoint(code)
    font.family: Theme.iconFont
    font.pixelSize: 18
    color: Theme.fg
}
