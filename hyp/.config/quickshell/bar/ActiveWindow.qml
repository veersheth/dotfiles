import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

// Focused window class in a pill.
Pill {
    id: root

    readonly property var active: ToplevelManager.activeToplevel
    readonly property string appClass: active?.appId ?? ""

    visible: appClass !== ""

    Text {
        Layout.alignment: Qt.AlignVCenter
        text: ""
        font.family: Theme.nerdFont
        font.pixelSize: Theme.iconSize
        color: Theme.foreground
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        Layout.maximumWidth: 260
        elide: Text.ElideRight
        text: root.appClass.length > 0
            ? root.appClass.charAt(0).toUpperCase() + root.appClass.slice(1)
            : ""
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.weight: Font.Medium
        color: Theme.foreground
    }
}
