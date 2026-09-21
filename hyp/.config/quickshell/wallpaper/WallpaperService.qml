pragma Singleton
import Quickshell
import QtQuick

Singleton {
    property string current: ""

    // true when the background is a solid color rather than an image path
    readonly property bool   isColor:    current.startsWith("color:")
    // "#rrggbb" when isColor, otherwise ""
    readonly property string colorValue: isColor ? current.substring(6) : ""
    // plain file path when not isColor, otherwise ""
    readonly property string imagePath:  isColor ? "" : current
}
